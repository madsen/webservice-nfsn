#---------------------------------------------------------------------
# $Id$
package WebService::NFSN::Account;
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
# Access the NearlyFreeSpeech.NET Account API
#---------------------------------------------------------------------

use 5.006;
use strict;
use JSON::XS 'from_json';

use base 'WebService::NFSN::Object';

#=====================================================================
# Package Global Variables:

our $VERSION = '0.01';

#=====================================================================
BEGIN {
  __PACKAGE__->_define(
    type => 'account',
    ro => [qw(balance balanceCash balanceCredit balanceHigh
            status:JSON sites:JSON)],
    rw => [qw(friendlyName)],
    methods => {
      addWarning    => [qw(balance)],
      removeWarning => [qw(balance)],
    }
  );
} # end BEGIN

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::NFSN::Account - Access NFSN account information

=head1 VERSION

This document describes WebService::NFSN::Account version 0.01


=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $balance = $nfsn->account($ACCOUNT_ID)->balance;

=head1 DESCRIPTION

WebService::NFSN::Account provides access to NearlyFreeSpeech.NET's account
API.  It is only useful to people who have websites hosted at
NearlyFreeSpeech.NET.

=head1 INTERFACE

=over

=item C<< $account = $nfsn->account($ACCOUNT_ID) >>

This constructs a new Account object for the specified
C<$ACCOUNT_ID> (a string like C<'A1B2-C3D4E5F6'>).  Equivalent to
S<< C<< $account = WebService::NFSN::Account->new($nfsn, $ACCOUNT_ID) >> >>.

=back

=head2 Properties

=over

=item C<< $account->balance() >>

Returns the current available account balance, without regard for distinctions
between cash and credit.

=item C<< $account->balanceCash() >>

Returns the current account cash balance.

=item C<< $account->balanceCredit() >>

Returns the current account credit balance. Credit balances represent
nonrefundable funds.

=item C<< $account->balanceHigh() >>

Returns the highest account balance ever recorded for this account. This can
be useful in conjunction with the C<balance> property to determine the
relative health of the account (for example, as a percentage).

=item C<< $account->friendlyName( [$NEW_NAME] ) >>

Gets or sets the account friendly name, an alternative to the 12-digit
account number that is intended to be more friendly to work with. For
example, if you have two accounts, you could name one "Personal" and
the other "Business."

You cannot use the account friendly name in API calls; it is intended
to be read/parsed only by humans.

The friendly name must be between 1 and 64 characters and is a
SimpleText field. It must be unique across all your accounts (but
other members may have accounts with the same friendly name).

=item C<< $account->status() >>

Returns the account status, which provides general information about
the health of the account.

The value returned is a hash reference with the following elements:

=over

=item C<status>

A text string describing the status.

=item C<short>

A 2-4 character uppercase abbreviation of the status.

=item C<color>

The recommended HTML color for displaying the status.

=back

=item C<< $account->sites() >>

Returns a list of sites associated with this account (as an array
reference of short names).

=back

=head2 Methods

=over

=item C<< $account->addWarning(balance => $BALANCE) >>

This adds a balance warning to the account, so that an email will be
sent when the balance drops below C<$BALANCE>.

C<$BALANCE> must be a positive dollar value specified to at
most two decimal digits (one cent).

=item C<< $account->removeWarning(balance => $BALANCE) >>

Removes an existing balance warning.

C<$BALANCE> must be the dollar value of an existing
balance warning, specified as a decimal number.

=back


=head1 SEE ALSO

L<WebService::NFSN>
