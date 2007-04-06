#---------------------------------------------------------------------
# $Id$
package My_Build;
#
# Copyright 2007 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 18 Feb 2007
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
use File::Spec ();
use base 'Module::Build';

#=====================================================================
# Package Global Variables:

our $VERSION = '0.01';

#=====================================================================
sub ACTION_distdir
{
  my $self = shift @_;

  $self->SUPER::ACTION_distdir(@_);

  # Process README, inserting version number & removing comments:

  my $out = File::Spec->catfile($self->dist_dir, 'README');
  my @stat = stat($out) or die;

  unlink $out or die;

  open(IN,  '<', 'README') or die;
  open(OUT, '>', $out)     or die;

  while (<IN>) {
    next if /^\$\$/;            # $$ indicates comment
    s/\$\%v\%\$/ $self->dist_version /ge;

    print OUT $_;
  } # end while IN

  close IN;
  close OUT;

  utime @stat[8,9], $out;       # Restore modification times
  chmod $stat[2],   $out;       # Restore access permissions
} # end ACTION_distdir

#=====================================================================
# Package Return Value:

1;
