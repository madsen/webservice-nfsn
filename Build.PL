#! /usr/bin/perl
#---------------------------------------------------------------------
# Build.PL for WebService-NFSN
#
# Copyright 2010 Christopher J. Madsen
#---------------------------------------------------------------------

use strict;
use warnings;

use FindBin;
use lib $FindBin::RealBin;

use inc::My_Build;           # Our customized version of Module::Build

my $builder = inc::My_Build->new(
  module_name        => 'WebService::NFSN',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  dist_version_from  => 'lib/WebService/NFSN.pm',
  dynamic_config     => 0,
  # Automatically inserted by DistZilla:
##{ $plugin->get_prereqs ##}
);

$builder->create_build_script();
