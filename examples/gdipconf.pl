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

my $configDir;

$configDir = '/home/protected/gdipupdt' if $running_at_NFSN;

die "You need to edit $0 and hardcode \$configDir\n" unless $configDir;

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
sub read_password
{
  my $user = shift;

  require Digest::MD5;
  require IO::Prompt;

  my $password = IO::Prompt::prompt("Password for $user: ", -e => '*', -tty);

  Digest::MD5::md5_hex($password);
} # end read_password

#=====================================================================
unless (-d $configDir) {
  print "Creating $configDir...\n";
  mkdir $configDir or die "mkdir $configDir: $!";
  set_perm($configDir, 0750) if $running_at_NFSN;
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

  if ($cmd =~ /^(?: addu(?:se?rs?)? | pass(?:w(?:or)?d)? )$/ix) {
    foreach my $user (@ARGV) {
      $config->{users}{$user}{password} = read_password($user);
      $config->{users}{$user}{domains} ||= {};
      $configChanged = 1;
    }
  } elsif ($cmd =~ /^(?: addh(?:o?sts?)? )$/ix) {
    my $user   = shift;
    my $domain = shift;
    die "No user '$user'\n" unless $config->{users}{$user};
    die "'$domain' doesn't look like a domain\n" unless $domain =~ /\./;
    die "No hosts specifed for $user in $domain\n" unless @ARGV;
    my $hosts = ($config->{users}{$user}{domains}{$domain} ||= []);

    my %have = map { $_ => 1 } @$hosts;

    for my $host (@ARGV) {
      next if $have{$host}++;
      print "Adding $host.$domain to $user...\n";
      push @$hosts, $host;
      $configChanged = 1;
    }

    @$hosts = sort @$hosts if $configChanged;
  } else {
    die qq'Unknown command "$cmd"\n';
  }
} # end if @ARGV

exit unless $configChanged;

#---------------------------------------------------------------------
print "Saving $configFile...\n";
umask 027;
DumpFile("$configFile.new", $config);
my ($gid, $mode) = (stat "$configFile.new")[5,2];
chown -1, $gid, "$configFile.new" or die "Can't chown $configFile.new: $!";
chmod $mode, "$configFile.new"    or die "Can't chmod $configFile.new: $!";
rename "$configFile.new", $configFile or die "Can't replace $configFile: $!";
