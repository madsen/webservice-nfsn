#---------------------------------------------------------------------
# $Id$
package WebService::NFSN::Member;
#
# Copyright 2007 Christopher J. Madsen
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
# Access the NearlyFreeSpeech.NET Member API
#---------------------------------------------------------------------

use 5.006;
use strict;
use warnings;

use base 'WebService::NFSN::Object';

#=====================================================================
# Package Global Variables:

our $VERSION = '0.05';

#=====================================================================
BEGIN {
  __PACKAGE__->_define(
    type => 'member',
    ro => [qw(accounts:JSON sites:JSON)],
  );
} # end BEGIN

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::NFSN::Member - Access NFSN member API

=head1 VERSION

This document describes $Id$


=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $accounts = $nfsn->member->accounts;

=head1 DESCRIPTION

WebService::NFSN::Member provides access to NearlyFreeSpeech.NET's
member API.  It is only useful to people who have websites hosted at
NearlyFreeSpeech.NET.

=head1 INTERFACE

=over

=item C<< $member = $nfsn->member( [$USER] ) >>

This constructs a new Member object for the specified
C<$USER>.  If C<$USER> is omitted, it defaults to the member login that
was passed to C<< WebService::NFSN->new >>.  Equivalent to
S<< C<< $member = WebService::NFSN::Member->new($nfsn, $USER) >> >>.

=back

=head2 Properties

=over

=item C<< $member->accounts() >>

Returns a list of all accounts owned by this member (as an array
reference of account IDs).

=item C<< $member->sites() >>

Returns a list of all sites owned by this member (as an array
reference of short names).

=back

=head2 Methods

None.


=head1 SEE ALSO

L<WebService::NFSN>
