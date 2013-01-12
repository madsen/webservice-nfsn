#! /usr/bin/perl
#---------------------------------------------------------------------
# gdipupdt.cgi
# Copyright 2012 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Dynamic DNS server using the GnuDIP HTTP protocol and NFSN API
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

use CGI::Minimal;
use Digest::MD5 qw(md5_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use WebService::NFSN 0.08;      # load credentials from ~/.nfsn-api
use YAML::Tiny qw(LoadFile);

$ENV{HOME}      = '/home/protected'; # location of ~/.nfsn-api
our $configDir  = '/home/protected/gdiupdt';

our $stateDir   = "$configDir/states";
our $configFile = "$configDir/config.yaml";

our $q = CGI::Minimal->new;
our $config;
our $timeout = 60;              # Time salt remains valid

#---------------------------------------------------------------------
sub try (&)
{
  my $code = shift;

  my ($failed, $err);
  {
    local $@;

    $failed = not eval { $try->();  1 };
    $err = $@;
  }

  if ($failed) {
    if ($err) {
      # Under mod_perl, eval catches exit.  Here, we check for an
      # attempt to exit and propagate it.  If you know you're not
      # running under mod_perl, you can remove this if statement.
      if ((ref($err) || '') eq 'APR::Error') {
        require ModPerl::Const;
        ModPerl::Const->import(-compile => 'EXIT');

        exit if $err == ModPerl::EXIT();
      } # end if possible mod_perl exit
    } else {
      $err = 'Unknown error';
    } # end else $err was false even though eval failed
  } # end if $failed

  return $err;
} # end try

#---------------------------------------------------------------------
sub cleanup_state
{
  my $maxAge = $timeout / 80000.0;

  # Remove old salts:
  for my $fn (glob("$stateDir/*")) {
    unlink $fn if -M $fn > $maxAge;
  }
} # end cleanup_state

#---------------------------------------------------------------------
sub send_error
{
  my $msg = shift;

  print STDERR $q->date_rfc1123(time) . " $0: $msg\n";

  print <<'END ERROR';
Status: 500
Content-Type: text/html; charset=ISO-8859-1

<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>
GnuDIP Update Server
</title>
<meta name="retc" content="1">
</head>
<body>
<h1>
GnuDIP Update Server
</h1>
<p style="text-align: center">
Error: Problem with server configuration
</p>
</body>
</html>
END ERROR

  cleanup_state;

  exit 1;
} # end send_error

#---------------------------------------------------------------------
sub send_response
{
  my $response = shift;

  print <<'END HEADER';
Content-Type: text/html; charset=ISO-8859-1

<!DOCTYPE html>
<html>
<head>
<title>
GnuDIP Update Server
</title>
END HEADER

  while (@_) {
    printf qq'<meta name="%s" content="%s">\n', shift, shift;
  }

  print <<"END BODY";
</head>
<body>
<h2>
GnuDIP Update Server
</h2>
<p style="text-align: center">
$response
</p>
</body>
</html>
END BODY

  cleanup_state;

  exit;
} # end send_response

#---------------------------------------------------------------------
sub send_salt
{
  my $saltAlphabet
    = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  my $salt = join('', map {
    substr($saltAlphabet, int(rand(length $saltAlphabet)), 1)
  } 1 .. 10);

  my $time = time;
  my $sign = md5_hex("$salt.$time.$config->{secret_key}");

  send_response(
    'Salt generated',
    salt => $salt,
    time => $time,
    sign => $sign,
  );
} # end send_salt

#---------------------------------------------------------------------
sub handle_update
{
  my %p;

  for my $name (qw( salt time sign user domn pass reqc )) {
    unless (defined($p{$name} = $q->param($name))) {
      send_response("Error: $name is required", retc => 1);
    }
  } # end for required parameters

  unless (md5_hex("$p{salt}.$p{time}.$config->{secret_key}") eq $p{sign}) {
    send_response("Error: Invalid signature", retc => 1);
  } # end unless signature matches

  if ($p{time} + $timeout < time) {
    send_response('Error: Salt value too old', retc => 1);
  } # end if time is too old

  send_error("handle_update: " . try {
    my $user = $config->{users}{$p{user}};
    if ($user) {
      die "User $p{user} has no password\n" unless $user->{password};
      die "User $p{user} has no domains\n" unless 'HASH' eq ref $user->{domains};
    }

    unless ($user and md5_hex("$user->{password}.$p{salt}") eq $p{pass}
            # Protect againt replay attacks.  Salt can only be used once:
            and sysopen(my $test, "$stateDir/$p{sign}",
                       O_WRONLY|O_CREAT|O_EXCL, 0664)) {
      send_response('Error: Invalid login attempt', retc => 1);
    }

    if ($p{reqc} eq '0') {
      unless (defined($p{addr} = $q->param('addr')) and length $p{addr}) {
        send_response("Error: No IP address was passed for request type 0",
                      retc => 1);
      }
    } elsif ($p{reqc} eq '1') {
      $p{addr} = '0.0.0.0';
    } elsif ($p{reqc} eq '2') {
      # NFSN appends comma-separated proxy IPs:
      ($p{addr} = $ENV{'REMOTE_ADDR'} || '0.0.0.0') =~ s/,.*//;
    } else {
      send_response("Error: Invalid client request code $p{reqc}", retc => 1);
    }

    while (my ($domain, $hosts) = each %{ $user->{domains} }) {
      foreach my $host (@$hosts) {
        do_update($domain, $host, $p{addr}) if $p{domn} eq "$host.$domain";
      } # end for each $host in domain
    } # end while each domain

    send_response("Error: Invalid domain $p{domn}", retc => 1);
  }); # end try or send_error
} # end handle_update

#---------------------------------------------------------------------
sub do_update
{
  my ($domainName, $host, $ip) = @_;

  my $ttl = $config->{ttl} || 180;

  my @param = (name => $host, type => 'A');

  my $err = try {
    my $domain = WebService::NFSN->new->dns($domainName);

    # Get the current record(s) and remove any that don't apply:
    my $found;
    my $rrList = $domain->listRRs(@param);
    foreach my $rr (@$rrList) {
      if ($rr->{data} eq $ip) { $found = 1 }
      else {
        #print STDERR "$host.$domainName was $rr->{data}\n";
        $domain->removeRR(@param, data => $rr->{data});
      }
    } # end foreach $rr

    if ($found) {
      #print STDERR "$host.$domainName already listed as $ip\n";
      send_response('No update required', retc => 0, addr => $ip);
    } elsif ($ip eq '0.0.0.0') {
      send_response('Successful offline request', retc => 2);
    } else {
      #print STDERR "Updating $host to $ip...";

      $domain->addRR(@param, data => $ip, ttl => $ttl);

      my $rr = $domain->listRRs(@param);
      send_response('Successful update request', retc => 0, addr => $ip)
          if $rr->[0]{data} eq $ip;
      die "Update failed\n";
    } # end not already listed with the current IP
  }; # end try

  # The try block calls exit on success, so this must be an error:
  print STDERR $q->date_rfc1123(time) . " $0: $err";

  send_response("Update failed", retc => 1);
} # end do_update

#=====================================================================
# Main program:

{
  my $err = try {
    $config = LoadFile($configFile);
    for (qw(secret_key users)) {
      die "$_ expected\n" unless $config->{$_};
    }
  };
  send_error("Loading config from $configFile failed: $err") if $err;
}

if ($ENV{REQUEST_METHOD} eq 'GET' and not $ENV{'QUERY_STRING'}) {
  send_salt();
} else {
  handle_update();
}
