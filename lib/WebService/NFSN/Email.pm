#---------------------------------------------------------------------
# $Id$
package WebService::NFSN::Email;
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
# Access the NearlyFreeSpeech.NET Email API
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
    type => 'email',
    methods => {
      removeForward => [qw(forward)],
      setForward    => [qw(forward dest_email)],
    }
  );
} # end BEGIN

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::NFSN::Email - Access NFSN email forwarding

=head1 VERSION

This document describes WebService::NFSN::Email version 0.01


=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $email = $nfsn->email($DOMAIN);
    $email->setForward(forward => 'name',
                       dest_email => 'to@example.com');

=head1 DESCRIPTION

WebService::NFSN::Email provides access to NearlyFreeSpeech.NET's
email forwarding API.  It is only useful to people who have
NearlyFreeSpeech.NET's email forwarding service.

=head1 INTERFACE

=over

=item C<< $email = $nfsn->email($DOMAIN) >>

This constructs a new Email object for the specified
C<$DOMAIN> (like C<'example.com'>).  Equivalent to
S<< C<< $email = WebService::NFSN::Email->new($nfsn, $DOMAIN) >> >>.

=back

=head2 Properties

None.

=head2 Methods

=over

=item C<< $email->removeForward(forward => $NAME) >>

Removes forwarding instructions from C<"$NAME\@$DOMAIN">.

=item C<< $email->setForward(forward => $NAME, dest_email => $TO) >>

This method is used to create a new email forward or update an
existing one. C<$NAME> is only the username component, so if you have
C<example.com> and you want to set up an email forward for forwarding
C<testuser@example.com> to C<realuser@example.net> then you would pass
C<testuser> as C<$NAME> and C<realuser@example.net> as C<$TO>.

If C<$NAME> already had a forwarding address, it will be overwritten
with the new C<$TO>.

To cause an email address to bounce, forward it to
C<bounce@nearlyfreespeech.net>. To cause it to be silently discarded,
forward it to C<discard@nearlyfreespeech.net>.

=back
