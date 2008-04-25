#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id$
# Copyright 2007 Christopher J. Madsen
#
# Build.PL for WebService-NFSN
#---------------------------------------------------------------------

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin; # Make sure we're using My_Build from our distribution

use My_Build;          # Our customized version of Module::Build

my $builder = My_Build->new(
  module_name        => 'WebService::NFSN',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  dist_version_from  => 'lib/WebService/NFSN.pm',
  requires => {
      'perl'                  => '5.006',
      'Digest::SHA1'          => 0,
      'Exception::Class'      => 0,
      'JSON::XS'              => 1,
      'LWP'                   => 5,
      'HTTP::Request::Common' => 0,
      'URI'                   => 1,
  },
  recommends => {
      'Data::Dumper'  => 0,     # Some of the examples use this
  },
  build_requires => {
      'FindBin'       => 0,
      'File::Spec'    => 0,
      'Module::Build' => '0.21',
      'Test::More'    => 0,
  },
  create_makefile_pl => 'passthrough',
  dynamic_config     => 0,
  meta_merge         => { no_index => { file => ['My_Build.pm'] }},
);

$builder->create_build_script();
