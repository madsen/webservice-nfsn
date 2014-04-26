#---------------------------------------------------------------------
package WebService::NFSN::Email;
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
# ABSTRACT: Access NFSN email forwarding
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
    type => 'email',
    methods => {
      'listForwards:JSON' => [],
      removeForward => [qw(forward)],
      setForward    => [qw(forward dest_email)],
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

=item C<< $email->listForwards() >>

Returns a hash reference listing all forwarding instructions for this
domain.  For each entry, the key is the username and the value is the
forwarding address for that name.  The special username C<*>
represents the "Everything Else" entry.

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


=head1 SEE ALSO

L<WebService::NFSN>

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
INCOMPATIBILITIES
BUGS AND LIMITATIONS
