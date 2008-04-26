#---------------------------------------------------------------------
# $Id$
package My_Build;
#
# Copyright 2008 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Customize Module::Build for WebService::NFSN
#---------------------------------------------------------------------

use strict;
use warnings;
use File::Spec ();
use Module::Build ();

# Use Module::Build::DistVersion if we can get it:
BEGIN {
  eval q{ use Module::Build::DistVersion 0.03;
          use base 'Module::Build::DistVersion'; };
  eval q{ use base 'Module::Build'; } if $@;
  die $@ if $@;
}

#=====================================================================
# Package Global Variables:

our $VERSION = '0.01';

#=====================================================================
sub ACTION_distdir
{
  my $self = shift @_;

  print STDERR <<"END" unless $self->isa('Module::Build::DistVersion');
\a\a\a\n
WebService-NFSN uses Module::Build::DistVersion to automatically copy
version numbers to the appropriate places.  You might want to install
that and re-run Build.PL if you intend to create a distribution.
\n
END

  $self->SUPER::ACTION_distdir(@_);
} # end ACTION_distdir

#---------------------------------------------------------------------
# Explain that JSON 2 can substitute for JSON::XS:

sub prereq_failures
{
  my $self = shift @_;

  my $out = $self->SUPER::prereq_failures(@_);

  return $out unless $out;

  if (my $attrib = $out->{requires}{'JSON::XS'}) {
    my $message;

    eval "use JSON 2 ();";

    if (not $@) {
      # JSON 2.0 or later is an acceptable replacement for JSON::XS:
      delete $out->{requires}{'JSON::XS'};

      # Clean out empty hashrefs:
      delete $out->{requires} unless %{$out->{requires}};
      undef $out              unless %$out;
    } else {
      $attrib->{message} .= "\n\n" . <<'';
   JSON 2.0 or later can substitute for JSON::XS, but its pure-Perl
   implementation is slower, and you don't have it installed either.

    } # end else we couldn't load JSON 2 either
  } # end if JSON::XS failed

  return $out;
} # end prereq_failures

#=====================================================================
# Package Return Value:

1;
