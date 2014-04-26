#---------------------------------------------------------------------
package WebService::NFSN::Site;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
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
# ABSTRACT: Access NFSN site API
#---------------------------------------------------------------------

use 5.006;
use strict;
use warnings;

use parent 'WebService::NFSN::Object';

#=====================================================================
# Package Global Variables:

our $VERSION = '1.02';

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

=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $site = $nfsn->site($SHORT_NAME);
    $site->addAlias(alias => 'www.example.com');

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


=head1 SEE ALSO

L<WebService::NFSN>

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
INCOMPATIBILITIES
BUGS AND LIMITATIONS
