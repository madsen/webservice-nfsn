#---------------------------------------------------------------------
# $Id$
package WebService::NFSN::Site;
#
# Copyright 2007 Christopher J. Madsen
#
# Author: Christopher J. Madsen <cjm@pobox.com>
# Created:  3 Apr 2007
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Access the NearlyFreeSpeech.NET Site API
#---------------------------------------------------------------------

use 5.006;
use strict;

use base 'WebService::NFSN::Object';

#=====================================================================
# Package Global Variables:

our $VERSION = '0.01';

#=====================================================================
BEGIN {
  __PACKAGE__->_define(
    type => 'site',
    methods => {
      addAlias    => [qw(alias)],
      removeAlias => [qw(alias)],
    }
  );
} # end BEGIN

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::NFSN::Site - Access NFSN site API

=head1 VERSION

This document describes WebService::NFSN::Site version 0.01


=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $site = $nfsn->site($SHORT_NAME);
    $site->addAlias('www.example.com');

=head1 DESCRIPTION

WebService::NFSN::Site provides access to NearlyFreeSpeech.NET's
site API.  It is only useful to people who have websites hosted at
NearlyFreeSpeech.NET.

=head1 INTERFACE

=over

=item C<< $site = $nfsn->site($SHORT_NAME) >>

This constructs a new Site object for the specified
C<$SHORT_NAME>.  Equivalent to
S<< C<< $site = WebService::NFSN::Site->new($nfsn, $SHORT_NAME) >> >>.

=back

=head2 Properties

None.

=head2 Methods

=over

=item C<< $site->addAlias(alias => $ALIAS) >>

This adds an alias (such as "www.example.com") to an existing web
site. In addition to the site, you must have permission to access the
domain containing the alias. If the domain is not referenced on our
system, it will be added automatically.

If the domain exists and has DNS managed by NFSN, the necessary
resource records will be created automatically.

=item C<< $site->removeAlias(alias => $ALIAS) >>

Removes an alias from a site.  C<$ALIAS> must be an existing alias for
the site.

=back
