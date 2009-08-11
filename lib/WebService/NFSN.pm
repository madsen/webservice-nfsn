#---------------------------------------------------------------------
package WebService::NFSN;
#
# Copyright 2007 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 3 Apr 2007
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
# Client for the NearlyFreeSpeech.NET API
#---------------------------------------------------------------------

use 5.006;
use strict;
use warnings;
use Carp qw(carp croak);
use Digest::SHA1 'sha1_hex';
use LWP::UserAgent ();
use UNIVERSAL 'isa';

#=====================================================================
# Package Global Variables:

our $VERSION = '0.08';

our $saltAlphabet
    = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

our $ua = LWP::UserAgent->new(agent => "WebService-NFSN/$VERSION ");

our @throw_parameters = (
  show_trace     => 1,
  ignore_package => __PACKAGE__,
  ignore_class   => 'WebService::NFSN::Object'
);

#=====================================================================
# Load a JSON package and define our decode_json function:

BEGIN
{
  ## no critic ProhibitStringyEval

  eval "use JSON::XS ();";

  if ($@) {
    # Can't find JSON::XS, try JSON (2.0 or later):
    eval "use JSON qw(decode_json); 1" or die $@;
  } else {
    if ($JSON::XS::VERSION >= 2) {
      *decode_json = \&JSON::XS::decode_json;
    } else {
      *decode_json = \&JSON::XS::from_json; # old name for decode_json
    } # end else found JSON::XS prior to version 2.0
  } # end else we were able to load JSON::XS
} # end BEGIN

#=====================================================================
# Define exceptions:

use Exception::Class (
  'WebService::NFSN::HTTPError' => {
    fields => [ qw(request response) ],
  },

    'WebService::NFSN::LWPError' => {
      isa    => 'WebService::NFSN::HTTPError',
    },

    'WebService::NFSN::NFSNError' => {
      isa    => 'WebService::NFSN::HTTPError',
      fields => [ qw(debug nfsn) ],
    },
);

#---------------------------------------------------------------------
# Include both the error & debug fields:

sub WebService::NFSN::NFSNError::full_message
{
  my ($self) = @_;

  $self->error . "\n" . $self->debug;
} # end WebService::NFSN::NFSNError::full_message

#=====================================================================
# Package WebService::NFSN:

sub new
{
  my ($class, $login, $apiKey) = @_;

  # If we didn't get login information, try reading it from .nfsn-api:
  if (@_ == 1) {
    require File::Spec;

    # Try the current directory, then the home directory:
    my $filename = '.nfsn-api';
    $filename = File::Spec->catfile($ENV{HOME}, $filename)
        if (not -e $filename and $ENV{HOME} and -d $ENV{HOME});

    # If we found it, read the file:
    if (not -e $filename) {
      carp("Unable to locate $filename");
    } else {
      # Read in the file:
      local $_;
      open(my $in, '<', $filename) or croak("Can't open $filename: $!");
      my $contents = '';
      $contents .= $_ while <$in>;
      close $in or croak("Error closing $filename: $!");

      # Parse the JSON object:
      my $hashRef = eval { decode_json($contents) };
      croak("Error parsing $filename: $@") if $@;
      croak("$filename did not contain a JSON object")
          unless isa($hashRef, 'HASH');

      croak(qq'$filename did not define "login"')
          unless defined ($login  = $hashRef->{login});
      croak(qq'$filename did not define "api-key"')
          unless defined ($apiKey = $hashRef->{'api-key'});
    } # end else -e $filename
  } # end if login & apiKey were not supplied

  # Make sure we have all our parameters:
  croak("You must supply a login")    unless defined $login;
  croak("You must supply an API key") unless defined $apiKey;

  return bless { login => $login,
                 apiKey => $apiKey,
                 url    => 'https://api.nearlyfreespeech.net',
               }, $class;
} # end new

#---------------------------------------------------------------------
BEGIN {
  # Create access methods for each object type:
  #   (Member is not auto-generated, because it has a default value)

  foreach my $class (qw(Account DNS Email Site)) {

    my $sub = lc $class;

    eval <<"END CHILD CONSTRUCTOR"; ## no critic ProhibitStringyEval
sub $sub
{
  require WebService::NFSN::$class;

  WebService::NFSN::$class->new(\@_);
}
END CHILD CONSTRUCTOR

    die $@ if $@;
  } # end foreach class
} # end BEGIN

#---------------------------------------------------------------------
sub member
{
  my ($self, $member) = @_;

  require WebService::NFSN::Member;

  WebService::NFSN::Member->new($self, $member || $self->{login});
} # end member

#---------------------------------------------------------------------
sub make_request
{
  my ($self, $req) = @_;

  # Collect member name & request URI:
  my $login = $self->{login};
  my $uri = $req->uri->path;

  # Generate a random 16 character salt value:
  my $salt = join('', map {
    substr($saltAlphabet, int(rand(length $saltAlphabet)), 1)
  } 1 .. 16);

  # Generate the NFSN authentication hash:
  my $body_hash = sha1_hex($req->content);

  my $time = time;

  my $hash = sha1_hex("$login;$time;$salt;$self->{apiKey};$uri;$body_hash");

  $req->header('X-NFSN-Authentication' => "$login;$time;$salt;$hash");

  # Send the request to the NFSN API server:
  my $res = $self->{last_response} = $ua->request($req);

  # Throw an exception if there was an error:
  if ($res->is_error) {
    my $param = eval { decode_json($res->content) };

    # Throw NFSNError if we decoded the response successfully:
    if (isa($param, 'HASH') and defined $param->{error}) {
      # If bad timestamp, list the dates:
      my $debug = delete $param->{debug};
      if ($debug and
          $debug eq "The authentication timestamp is out of range.") {
        $debug .= ("\n Client request date:  " . gmtime($time) .
                   "\n Server response date: " . $res->header('Date'));
      } # end if authentication timestamp out of range

      WebService::NFSN::NFSNError->throw(
        error => delete($param->{error}),
        debug => $debug,
        nfsn  => $param,
        request  => $req,
        response => $res,
        @throw_parameters
      );
    } # end if throwing NFSNError

    # Otherwise, throw LWPError:
    WebService::NFSN::LWPError->throw(
      error => sprintf('%s: %s', $res->code, $res->message),
      request  => $req,
      response => $res,
      @throw_parameters
    );
  } # end if error

  # Return the successful response:
  return $res;
} # end make_request

#---------------------------------------------------------------------
sub last_response { $_[0]{last_response} }
sub root_url      { $_[0]{url}           }

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::NFSN - Client for the NearlyFreeSpeech.NET API

=head1 VERSION

This document describes $Id$


=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $balance = $nfsn->account($ACCOUNT_ID)->balance;

    $nfsn = WebService::NFSN->new; # Get credentials from ~/.nfsn-api

=head1 DESCRIPTION

WebService::NFSN is a client library for NearlyFreeSpeech.NET's member
API.  It is only useful to people who have websites hosted at
NearlyFreeSpeech.NET.

Much of this documentation was adapted from the original API
documentation at L<https://api.nearlyfreespeech.net/>.

=head1 INTERFACE

=over

=item C<< $nfsn = WebService::NFSN->new( [$USER, $API_KEY] ) >>

This constructs a new API manager object.  C<$USER> is your NFSN
member login.  You can get your C<$API_KEY> by making a Secure Support
Request at L<https://members.nearlyfreespeech.net/support/request>.

If you call new without parameters, it will look for a file named
F<.nfsn-api> in the current directory and (if not found there) in your
home directory.  The file must contain a JSON object that defines the
keys C<login> and C<api-key>.  Any additional keys are ignored.

Example F<.nfsn-api> file:

 { "login": "USER",  "api-key": "API_KEY" }

=item C<< $nfsn->account($ACCOUNT_ID) >>

Returns a L<WebService::NFSN::Account> object for the specified
account number (a string like C<'A1B2-C3D4E5F6'>).

=item C<< $nfsn->dns($DOMAIN) >>

Returns a L<WebService::NFSN::DNS> object for the specified domain
(like C<'example.com'>).

=item C<< $nfsn->email($DOMAIN) >>

Returns a L<WebService::NFSN::Email> object for the specified domain.

=item C<< $nfsn->member( [$USER] ) >>

Returns a L<WebService::NFSN::Member> object for the specified member
login.  If C<$USER> is omitted, it defaults to the member login that
was passed to C<new>.

=item C<< $nfsn->site($SHORT_NAME) >>

Returns a L<WebService::NFSN::Site> object for the specified site
(identified by its short name).

=item C<< $nfsn->last_response >>

Returns the L<HTTP::Response> object containing the raw response from
the last query sent to API.NearlyFreeSpeech.NET.  You shouldn't
normally need this, but it may be handy for debugging.

=back


=head1 DIAGNOSTICS

=head2 WebService::NFSN::HTTPError

Most errors you might get from WebService::NFSN are
L<Exception::Class> based objects.  WebService::NFSN::HTTPError is the
abstract base class for these errors.  The C<request> field contains
the L<HTTP::Request> object that failed, and the C<response> field
contains the original L<HTTP::Response> object.

WebService::NFSN throws errors from two classes derived from
WebService::NFSN::HTTPError:

=head3 WebService::NFSN::LWPError

If WebService::NFSN cannot get a response from the NFSN server, it
throws an error of class WebService::NFSN::LWPError.  Examine the
C<response> field for details.

=head3 WebService::NFSN::NFSNError

If the NFSN server returns an error response, it becomes an error of
class WebService::NFSN::NFSNError.  The C<error> and C<debug> fields
contain the values received from NFSN.  Any additional fields returned
by NFSN are available in the C<nfsn> field (which is a hash
reference).  You can also examine the original C<response>.

Possible errors include:

=over

=item C<The API request could not be authenticated>

You're probably using the wrong member login or API key.

=item C<The authentication timestamp is out of range>

The clocks of the NFSN API server and your computer need to be
synchronised to within 5 seconds, and they aren't.  You may need to
set up NTP on your computer.

=back

=head2 Simple Errors

The following errors do not use Exception::Class, because you should
never see them unless you have an error in your program.  They are
classified like Perl's built-in diagnostics (L<perldiag>):

     (S) A severe warning
     (F) A fatal error (trappable)

=over

=item C<< Missing required "%s" parameter for %s >>

(F) You failed to supply a parameter required by the method you called.

=item C<< "%s" is not a parameter of %s >>

(S) You supplied a parameter not recognized by the method you called.
This is only a warning; the parameter is still passed along to NFSN
(in case it was added in a newer version of the API).

=item C<< %s is read-only >>

(F) You tried to modify a read-only property.

=item C<< %s is write-only >>

(F) You tried to read a write-only property.

=item C<< Can't open %s >>

(F) There was an error when opening the .nfsn-api file.

=item C<< Error closing %s >>

(F) There was an error when closing the .nfsn-api file.

=item C<< Error parsing .nfsn-api: %s >>

(F) .nfsn-api did not contain valid JSON.

=item C<< .nfsn-api did not contain a JSON object >>

(F) .nfsn-api did not contain a JSON object (it must begin with C<{>).

=item C<< .nfsn-api did not define %s >>

(F) .nfsn-api must include the keys C<login> and C<api-key>.

=item C<< You must supply a login >>

(F) You didn't pass a member login to the constructor, and no
F<.nfsn-api> file was found.

=item C<< You must supply an API key >>

(F) You passed a login name to the constructor, but no API key.

=item C<< Unable to locate .nfsn-api >>

(S) You didn't pass login credentials to the constructor, and it
couldn't find a F<.nfsn-api> file to load.

=back


=head1 CONFIGURATION AND ENVIRONMENT

WebService::NFSN has an optional configuration file named
F<.nfsn-api>.  See L<the constructor|"INTERFACE"> for the details.
The home directory is specified by C<$ENV{HOME}>.


=head1 DEPENDENCIES

L<Digest::SHA1>, L<Exception::Class>, L<JSON::XS>, L<LWP> (requires
C<https> support), and L<URI>.  These are all available from CPAN.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

The server's SSL certificate is not verified, so WebService::NFSN is
vulnerable to a man-in-the-middle attack.  However, due to the design
of NFSN's API, the attacker should only be able to monitor/suppress
your queries and monitor/alter the responses.  The attacker should not
be able to send (properly authenticated) altered requests to the real
NFSN server.

If someone knows how to have LWP verify the server's certificate,
please let me know.


=head1 AUTHOR

Christopher J. Madsen  S<< C<< <perl AT cjmweb.net> >> >>

Please report any bugs or feature requests to
S<< C<< <bug-WebService-NFSN AT rt.cpan.org> >> >>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=WebService-NFSN>


=head1 LICENSE AND COPYRIGHT

Copyright 2007 Christopher J. Madsen

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
