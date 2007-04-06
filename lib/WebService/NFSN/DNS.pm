#---------------------------------------------------------------------
# $Id$
package WebService::NFSN::DNS;
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
# Access the NearlyFreeSpeech.NET DNS API
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
    type => 'dns',
    ro   => [qw(serial)],
    rw   => [qw(expire minTTL refresh retry)],
    methods => {
      addRR          => [qw(name type data)],
      'listRRs:JSON' => [qw(name? type? data?)],
      removeRR       => [qw(name type data)],
      updateSerial   => [],
    }
  );
} # end BEGIN

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::NFSN::DNS - Access NFSN DNS information

=head1 VERSION

This document describes WebService::NFSN::DNS version 0.01


=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $expire = $nfsn->dns($DOMAIN)->expire;

=head1 DESCRIPTION

WebService::NFSN::DNS provides access to NearlyFreeSpeech.NET's DNS
API.  It is only useful to people who have websites hosted at
NearlyFreeSpeech.NET.

All times are specified in seconds.

=head1 INTERFACE

=over

=item C<< $dns = $nfsn->dns($DOMAIN) >>

This constructs a new DNS object for the specified
C<$DOMAIN> (like C<'example.com'>).  Equivalent to
S<< C<< $dns = WebService::NFSN::DNS->new($nfsn, $DOMAIN) >> >>.

=back

=head2 Properties

=over

=item C<< $dns->expire( [$NEW_EXPIRE] ) >>

Gets or sets the "expire" value for the domain. To quote RFC1912: "How
long a secondary [nameserver] will still treat its copy of the zone
data as valid if it can't contact the primary [nameserver]."

The expire value must be:

=over

=item *

Between 86400 and 2678400, and

=item *

Greater than or equal to the C<refresh> and C<retry> values.

=back

=item C<< $dns->minTTL( [$NEW_TTL] ) >>

Gets or sets the DNS minimum TTL (minTTL), the smallest TTL value (in
seconds) allowed for any resource record in the zone. If a resource
record has a smaller TTL value than minTTL, the server will substitute
the minimum value.

The minimum value is 60 (one minute) and the maximum value is 2678400 (31 days).

=item C<< $dns->refresh( [$NEW_REFRESH] ) >>

Gets or sets the refresh value for the domain. To quote RFC 1912: "How
often a secondary [nameserver] will poll the primary [name]server to
see if the serial number for the zone has increased (so it knows to
request a new copy of the data for the zone). Set this to how long
your secondaries can comfortably contain out-of-date data." In other
words, set this for the minimum amount of time you're willing to wait
for a change you make to the domain's DNS records to propagate.

The refresh value must be:

=over

=item *

Greater than or equal to the C<minTTL> value, and

=item *

Less than or equal to the C<expire> value.

=back

=item C<< $dns->retry( [$NEW_RETRY] ) >>

Gets or sets the retry value for the domain. To quote RFC 1912: "If a
secondary was unable to contact the primary at the last refresh, wait
the retry value before trying again."

The retry value must be:

=over

=item *

Greater than or equal to 60, and

=item *

Less than or equal to the expire value.

=back

=item C<< $dns->serial() >>

Returns the current serial value for this domain. To quote RFC 1912:
"Each zone has a serial number associated with it. Its use is for
keeping track of who has the most current data. If and only if the
primary's serial number of the zone is greater will the secondary ask
the primary for a copy of the new zone data (see special case below)."
In other words, the serial indicates the "version" of the data.

The serial is maintained by the DNS system, and cannot be directly
modified. You may, however, update the serial number in order to cause
other nameservers to refresh any cached data in it by calling the
C<updateSerial> method.

=back

=head2 Methods

Most DNS methods take 3 parameters:

=over

=item name

Name of the resource record.  This does not include the C<$DOMAIN>
associated with the Site object; C<www> means C<www.example.com> (if
the Site object is for C<example.com>).  The empty string refers to the
domain itself.

=item type

Type of the resource record.
Must be one of: A, AAAA, CNAME, MX, NS, PTR, SRV, TXT.

=item data

Contents of the resource record.
Must be in the same format as the "data" field in the member interface.

=back

These are the methods:

=over

=item C<< $dns->addRR(name => $NAME, type => $TYPE, data => $DATA) >>

Adds a new resource record to the domain's DNS. Any record that can be
added through the member interface can be added through this method as
well, including the SPF Email Protection record.

=item C<< $dns->listRRs([name => $NAME,] [type => $TYPE,] [data => $DATA]) >>

Returns an array reference containing a hash reference for each
matching record.  All RR's except the SOA RR are eligible to be
returned. (The SOA RR is accessed/manipulated directly through object
methods.)

Each hash has the following fields: C<ttl>, C<name>, C<data>, C<type>,
and C<scope>.  (C<scope> is either "system" or "member").

All parameters are optional.  If supplied, only records that exactly
match the parameter(s) are returned.

=item C<< $dns->removeRR(name => $NAME, type => $TYPE, data => $DATA) >>

Removes a resource record from the domain's DNS. Only "member"
resource records (as indicated by their C<scope>) and the SPF
Email Protection resource record can be removed.  The parameters must
match an existing record.

=item C<< $dns->updateSerial() >>

Updates the serial of this domain.
See the C<serial> property for more details.

=back
