#---------------------------------------------------------------------
package WebService::NFSN::Object;
#
# Copyright 2007 Christopher J. Madsen
#
# Author: Christopher J. Madsen <cjm@pobox.com>
# Created:  3 Apr 2007
# $Id$
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Base class for NFSN API objects
#---------------------------------------------------------------------

use 5.006;
use Carp;
use strict;
use HTTP::Request::Common qw(GET POST PUT);
use URI ();

#=====================================================================
# Package Global Variables:

our $VERSION = '0.01';

#=====================================================================
sub get_converter # ($class, $function)
{
  my $convert = ($_[1] =~ s/:JSON$// ? 'from_json' : '');

  die "$_[0]::$convert not defined"
      if $convert and not defined(&{"$_[0]::$convert"});

  return $convert;
} # end get_converter

#---------------------------------------------------------------------
# Generate the code for an API module:

sub _define
{
  my ($class, %p) = @_;

  ## no critic ProhibitStringyEval

  #...................................................................
  # Create the object_type method for classifying objects:

  eval "package $class; sub object_type { '$p{type}' }";
  die $@ if $@;

  #...................................................................
  # Create an accessor method for each property:

  foreach my $propType (qw(rw ro wo)) {
    my $properties = $p{$propType};

    next unless $properties;

    foreach my $property (@$properties) {
      my $convert = get_converter($class, $property);

      eval <<"END PROPERTY";
package $class;
sub $property
{
  my \$self = shift \@_;

  $convert \$self->${propType}_property('$property' => \@_);
}
END PROPERTY
      die $@ if $@;
    } # end foreach $property
  } # end foreach $propType

  #...................................................................
  # Create an object method for each API method:

  if (my $methods = $p{methods}) {
    while (my ($method, $params) = each %$methods) {
      my $convert = get_converter($class, $method);

      #FIXME validate parameters

      eval <<"END PROPERTY";
package $class;
sub $method
{
  my \$self = shift \@_;

  $convert \$self->POST_request('$method' => \@_);
}
END PROPERTY
      die $@ if $@;
    } # end while each method
  } # end if methods

} # end _define

#=====================================================================
sub new
{
  my ($class, $manager, $id) = @_;

  return bless { manager => $manager,
                 id      => $id,
               }, $class;
} # end new

#---------------------------------------------------------------------
sub GET_request
{
  my ($self, $property) = @_;

  return $self->make_request(GET $self->make_uri($property));
} # end GET_request

#---------------------------------------------------------------------
sub PUT_request
{
  my ($self, $property, $value) = @_;

  return $self->make_request(PUT $self->make_uri($property),
                             Content => $value);
} # end PUT_request

#---------------------------------------------------------------------
sub POST_request
{
  my ($self, $method, %param) = @_;

  return $self->make_request(POST $self->make_uri($method), \%param);
} # end POST_request

#---------------------------------------------------------------------
sub make_request
{
  my $self = shift @_;

  my $res = $self->{manager}->make_request(@_);

  return $res->content;
} # end make_request

#---------------------------------------------------------------------
sub make_uri
{
  my ($self, $name) = @_;

  URI->new(join('/', $self->{manager}->root_url, $self->object_type,
                $self->{id}, $name));
} # end make_url

#---------------------------------------------------------------------
sub ro_property
{
  my ($self, $property) = @_;

  croak "$property is read-only" if @_ > 2;

  return $self->GET_request($property);
} # end ro_property

#---------------------------------------------------------------------
sub rw_property
{
  my ($self, $property, $value) = @_;

  if (@_ > 2) {
    return $self->PUT_request($property, $value);
  } else {
    return $self->GET_request($property);
  }
} # end rw_property

#---------------------------------------------------------------------
sub wo_property
{
  my ($self, $property, $value) = @_;

  croak "$property is write-only" if @_ < 3;

  return $self->PUT_request($property, $value);
} # end wo_property

#=====================================================================
# Package Return Value:

1;

__END__
