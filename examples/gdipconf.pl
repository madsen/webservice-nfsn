#! /usr/bin/perl
#---------------------------------------------------------------------
# gdipconf.pl
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
# Update configuration for the gdipupdt.cgi Dynamic DNS server
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

use YAML::Tiny qw(LoadFile DumpFile);

my $running_at_NFSN = (($ENV{NFSN_SITE_ROOT} || '') eq '/home/');

my ($apiKey, $configDir);

$configDir = '/home/protected/gdipupdt'  if $running_at_NFSN;
$apiKey    = '/home/protected/.nfsn-api' if $running_at_NFSN;

die "You need to edit $0 & gdipupdt.cgi and hardcode \$configDir\n"
    unless $configDir;

#---------------------------------------------------------------------
my $web_gid;

sub set_perm
{
  my ($path, $perm) = @_;

  $web_gid ||= getgrnam('web') or die "Can't find web group: $!";
  chown -1, $web_gid, $path    or die "Can't chown $path: $!";
  chmod $perm, $path           or die "Can't chmod $path: $!";
} # end set_perm

#---------------------------------------------------------------------
sub confirm
{
  my $prompt = shift;

  $prompt .= " [y/N]? ";

  require IO::Prompt;

  IO::Prompt::prompt($prompt, -yes, -tty);
} # end confirm

#---------------------------------------------------------------------
sub read_password
{
  my $user = shift;

  require Digest::MD5;
  require IO::Prompt;

  my $password = IO::Prompt::prompt("Password for $user: ", -e => '*', -tty);

  Digest::MD5::md5_hex($password);
} # end read_password

#=====================================================================
if ($apiKey and not -e $apiKey) {
  print <<'END API';
If you haven't already, you need to sign up for a NFSN API key by going to
  https://members.nearlyfreespeech.net/support/assist?tag=apikey
and filling out that form.

END API

  require IO::Prompt;
  my $user = IO::Prompt::prompt("Your NFSN member login: ", -tty);
  my $key  = IO::Prompt::prompt("Your NFSN API key: ",      -tty);

  print "Creating $apiKey...\n";
  open(my $out, '>', $apiKey) or die "Can't create $apiKey: $!";
  print $out qq'{ "login": "$user",  "api-key": "$key" }\n';
  close $out;
  set_perm($apiKey, 0640) if $running_at_NFSN;
}

unless (-d $configDir) {
  print "Creating $configDir...\n";
  mkdir $configDir or die "mkdir $configDir: $!";
  set_perm($configDir, 0750) if $running_at_NFSN;
}

my $stateDir = "$configDir/states";
unless (-d $stateDir) {
  print "Creating $stateDir...\n";
  mkdir $stateDir or die "mkdir $stateDir: $!";
  set_perm($stateDir, 0770) if $running_at_NFSN;
}

my $configFile = "$configDir/config.yaml";

unless (-e $configFile) {
  print "Creating $configFile...\n";
  open(my $out, '>', $configFile) or die "Can't create $configFile: $!";
  print $out "--- {}\n";       # an empty hash
  close $out;
  set_perm($configFile, 0640) if $running_at_NFSN;
}

my $configChanged;
my $config;
$config = LoadFile($configFile);

unless ($config->{secret_key}) {
  print "Generating secret_key for server...\n";

  $config->{secret_key} = join('', map { chr(0x20 + int rand 0x5F) } 1 .. 32);
  $configChanged = 1;
}

if (@ARGV) {
  my $cmd = shift;

  if ($cmd =~ /^(?: pass(?:w(?:or)?d)? )$/ix) {
    foreach my $user (@ARGV) {
      warn("No user '$user'\n"), next unless $config->{users}{$user};
      $config->{users}{$user}{password} = read_password($user);
      $configChanged = 1;
    }
  } elsif ($cmd =~ /^(?: add )$/ix) {
    my $user   = shift;
    my $domain = shift;
    die "'$domain' doesn't look like a domain\n" unless $domain =~ /\./;
    die "No hosts specifed for $user in $domain\n" unless @ARGV;
    $config->{users}{$user}{password} ||= read_password($user);
    my $hosts = ($config->{users}{$user}{domains}{$domain} ||= []);

    my %have = map { $_ => 1 } @$hosts;

    for my $host (@ARGV) {
      next if $have{$host}++;
      print "Adding $host.$domain to $user...\n";
      push @$hosts, $host;
      $configChanged = 1;
    }

    @$hosts = sort @$hosts if $configChanged;
  } elsif ($cmd =~ /^(?: rm | del(?:ete)? )$/ix) {
    my $user   = shift;
    my $domain = shift;
    if (@ARGV) {
      my $hosts = $config->{users}{$user}{domains}{$domain}
          or die "User '$user' does not have domain '$domain'\n";
      my %delete = map { $_ => 1 } @ARGV;

      @$hosts = grep { $configChanged ||= $delete{$_}; !$delete{$_} } @$hosts;
    } # end if deleting specific hosts
    elsif (defined $domain) {
      my $domains = $config->{users}{$user}{domains};
      $domains->{$domain}
          or die "User '$user' does not have domain '$domain'\n";
      exit unless confirm("Remove all hosts in $domain from $user");
      delete $domains->{$domain};
      $configChanged = 1;
    } else {
      die "No user specified\n" unless $user;
      my $users = $config->{users};
      $users->{$user} or die "No user '$user'\n";
      exit unless confirm("Remove user $user");
      delete $users->{$user};
      $configChanged = 1;
    }
  } else {
    die qq'Unknown command "$cmd"\n';
  }
} # end if @ARGV

exit unless $configChanged;

#---------------------------------------------------------------------
print "Saving $configFile...\n";
umask 027;
DumpFile("$configFile.new", $config);
my ($gid, $mode) = (stat $configFile)[5,2];
chown -1, $gid, "$configFile.new" or die "Can't chown $configFile.new: $!";
chmod $mode, "$configFile.new"    or die "Can't chmod $configFile.new: $!";
rename "$configFile.new", $configFile or die "Can't replace $configFile: $!";
