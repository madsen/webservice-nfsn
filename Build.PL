#! /usr/bin/perl
#---------------------------------------------------------------------
# Build.PL for WebService-NFSN
#
# Copyright 2010 Christopher J. Madsen
#---------------------------------------------------------------------

use strict;
use warnings;

# Make sure we're using My_Build from our distribution:
use FindBin;
use lib "$FindBin::Bin/tools";

use My_Build;          # Our customized version of Module::Build

my $builder = My_Build->new(
  module_name        => 'WebService::NFSN',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  dist_version_from  => 'lib/WebService/NFSN.pm',
  dynamic_config     => 0,
  # Prerequisites inserted by DistZilla:
##{ $plugin->get_prereqs ##}
);

$builder->create_build_script();
