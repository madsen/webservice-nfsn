#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id$
# Copyright 2007 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Simple client script for using the NFSN API
#---------------------------------------------------------------------

use strict;
use warnings;
use Data::Dumper;
use WebService::NFSN;

my ($user, $key, $type, $id, $command, @parameters) = @ARGV;

die <<"" unless defined $command;
Usage: $0 USER API_KEY TYPE ID COMMAND [PARAMETERS...]\n
Examples:
  $0 USER KEY account A1B2-C3D4E5F6 balance
  $0 USER KEY account A1B2-C3D4E5F6 friendlyName NewName
  $0 USER KEY dns example.com listRRs name www
  $0 USER KEY dns example.com addRR name bob type A data 10.0.0.5
  $0 USER KEY email example.com forward name dest_email 'to\@example.net'
  $0 USER KEY member USER accounts
  $0 USER KEY site SHORT_NAME addAlias alias www.example.com

my $nfsn = WebService::NFSN->new($user, $key);

die "Unknown type $type\n" unless $nfsn->can($type);
my $obj = $nfsn->$type($id);

die "Unknown command $command\n" unless $obj->can($command);
my $result = eval { $obj->$command(@parameters); };

if ($@) {
  my $err = $@;
  my $res = $nfsn->last_response;
  print STDERR $res->as_string if $res;
  die $err;
}

$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse    = 1;
print Dumper($result);
