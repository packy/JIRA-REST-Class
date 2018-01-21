package JIRA::REST::Class;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.13';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: An OO Class module built atop L<JIRA::REST|JIRA::REST> for dealing with JIRA issues and their data as objects.

use Carp;
use Clone::Any qw( clone );
use Readonly 2.04;

use JIRA::REST;
use JIRA::REST::Class::Factory;
use parent qw(JIRA::REST::Class::Mixins);

#---------------------------------------------------------------------------
# Constants

Readonly my $DEFAULT_MAXRESULTS => 50;

#---------------------------------------------------------------------------
# Package Variables

my $instance_cache = {};

#---------------------------------------------------------------------------

sub new {
    my ( $class, @arglist ) = @_;

    my $args = $class->_get_known_args(
        \@arglist,
        qw/ url username password rest_client_config
            proxy ssl_verify_none anonymous no_cache no_is_issue_type /
    );

    my $cache_key = q{};
    unless ( $args->{no_cache} ) {
        $cache_key  = $args->{url}      if exists $args->{url};
        $cache_key .= $args->{username} if exists $args->{username};
        if ( exists $instance_cache->{$cache_key} ) {
            return $instance_cache->{$cache_key};
        }
    }

    my $self = bless {
        jira_rest => $class->JIRA_REST( clone( $args ) ),
        factory   => $class->factory( clone( $args ) ),
        args      => clone( $args ),
        userobj   => undef,
    }, $class;

    unless ( $args->{no_cache} ) {
        $instance_cache->{$cache_key} = $self;
    }

    return $self;
}

#---------------------------------------------------------------------------
#
# using Inline::Test to generate testing files from tests
# declared next to the code that it's testing
#

=begin test setup 1

use File::Basename;
use lib dirname($0).'/..';
use MyTest;
use 5.010;

TestServer_setup();

END {
    TestServer_stop();
}

use_ok('JIRA::REST::Class');

sub get_test_client {
    state $test =
        JIRA::REST::Class->new(TestServer_url(), 'username', 'password');
    $test->REST_CLIENT->setTimeout(5);
    return $test;
};

=end test

=cut

#---------------------------------------------------------------------------

=begin testing new 5

my $jira;
try {
    $jira = JIRA::REST::Class->new({
        url       => TestServer_url(),
        username  => 'user',
        password  => 'pass',
        proxy     => '',
        anonymous => 0,
        ssl_verify_none => 1,
        rest_client_config => {},
    });
}
catch {
    $jira = $_; # as good a place as any to stash the error, because
                # isa_ok() will complain that it's not an object.
};

isa_ok($jira, 'JIRA::REST::Class', 'JIRA::REST::Class->new');

my $needs_url_regexp = qr/'?url'? argument must be defined/i;

throws_ok(
    sub {
        JIRA::REST::Class->new();
    },
    $needs_url_regexp,
    'JIRA::REST::Class->new with no parameters throws an exception',
);

throws_ok(
    sub {
        JIRA::REST::Class->new({
            username  => 'user',
            password  => 'pass',
        });
    },
    $needs_url_regexp,
    'JIRA::REST::Class->new with no url throws an exception',
);

throws_ok(
    sub {
        JIRA::REST::Class->new('http://not.a.good.server.com');
    },
    qr/No credentials found/,
    q{JIRA::REST::Class->new with just url tries to find credentials},
);

lives_ok(
    sub {
        JIRA::REST::Class->new(TestServer_url(), 'user', 'pass');
    },
    q{JIRA::REST::Class->new with url, username, and password does't croak!},
);

=end testing

=cut

#---------------------------------------------------------------------------

=method B<issues> QUERY

=method B<issues> KEY [, KEY...]

The C<issues> method can be called two ways: either by providing a list of
issue keys, or by proving a single hash reference which describes a JIRA
query in the same format used by L<JIRA::REST|JIRA::REST> (essentially,
C<< jql => "JQL query string" >>).

The return value is an array of L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> objects.

=cut

sub issues {
    my ( $self, @args ) = @_;
    if ( @args == 1 && ref $args[0] eq 'HASH' ) {
        return $self->query( $args[0] )->issues;
    }
    else {
        my $jql = sprintf 'key in (%s)', join q{,} => @args;
        return $self->query( { jql => $jql } )->issues;
    }
}

#---------------------------------------------------------------------------
#
# =begin testing issues
# =end testing
#
#---------------------------------------------------------------------------

=method B<query> QUERY

The C<query> method takes a single parameter: a hash reference which
describes a JIRA query in the same format used by L<JIRA::REST|JIRA::REST>
(essentially, C<< jql => "JQL query string" >>).

The return value is a single L<JIRA::REST::Class::Query|JIRA::REST::Class::Query> object.

=cut

sub query {
    my $self = shift;
    my $args = shift;

    my $query = $self->post( '/search', $args );
    return $self->make_object( 'query', { data => $query } );
}

#---------------------------------------------------------------------------
#
# =begin testing query
# =end testing
#
#---------------------------------------------------------------------------

=method B<iterator> QUERY

The C<query> method takes a single parameter: a hash reference which
describes a JIRA query in the same format used by L<JIRA::REST|JIRA::REST>
(essentially, C<< jql => "JQL query string" >>).  It accepts an additional
field, however: C<restart_if_lt_total>.  If this field is set to a true value,
the iterator will keep track of the number of results fetched and, if when
the results run out this number doesn't match the number of results
predicted by the query, it will restart the query.  This is particularly
useful if you are transforming a number of issues through an iterator, and
the transformation causes the issues to no longer match the query.

The return value is a single
L<JIRA::REST::Class::Iterator|JIRA::REST::Class::Iterator> object.  The
issues returned by the query can be obtained in serial by repeatedly calling
L<next|JIRA::REST::Class::Iterator/next> on this object, which returns a
series of L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> objects.

=cut

sub iterator {
    my $self = shift;
    my $args = shift;
    return $self->make_object( 'iterator', { iterator_args => $args } );
}

#---------------------------------------------------------------------------
#
# =begin testing iterator
# =end testing
#
#---------------------------------------------------------------------------

=internal_method B<get>

A wrapper for C<JIRA::REST>'s L<GET|JIRA::REST/"GET RESOURCE [, QUERY]"> method.

=cut

sub get {
    my ( $self, $url, @args ) = @_;
    return $self->JIRA_REST->GET( $url, undef, @args );
}

#---------------------------------------------------------------------------

=begin testing get

validate_wrapper_method( sub { get_test_client()->get('/test'); },
                         { GET => 'SUCCESS' }, 'get() method works' );

=end testing

=cut

#---------------------------------------------------------------------------

=internal_method B<post>

Wrapper around C<JIRA::REST>'s L<POST|JIRA::REST/"POST RESOURCE, QUERY, VALUE [, HEADERS]"> method.

=cut

sub post {
    my ( $self, $url, @args ) = @_;
    return $self->JIRA_REST->POST( $url, undef, @args );
}

#---------------------------------------------------------------------------

=begin testing post

validate_wrapper_method( sub { get_test_client()->post('/test', "key=value"); },
                         { POST => 'SUCCESS' }, 'post() method works' );

=end testing

=cut

#---------------------------------------------------------------------------

=internal_method B<put>

Wrapper around C<JIRA::REST>'s L<PUT|JIRA::REST/"PUT RESOURCE, QUERY, VALUE [, HEADERS]"> method.

=cut

sub put {
    my ( $self, $url, @args ) = @_;
    return $self->JIRA_REST->PUT( $url, undef, @args );
}

#---------------------------------------------------------------------------

=begin testing put

validate_wrapper_method( sub { get_test_client()->put('/test', "key=value"); },
                         { PUT => 'SUCCESS' }, 'put() method works' );

=end testing

=cut

#---------------------------------------------------------------------------

=internal_method B<delete>

Wrapper around C<JIRA::REST>'s L<DELETE|JIRA::REST/"DELETE RESOURCE [, QUERY]"> method.

=cut

sub delete { ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $url, @args ) = @_;
    return $self->JIRA_REST->DELETE( $url, @args );
}

#---------------------------------------------------------------------------

=begin testing delete

validate_wrapper_method( sub { get_test_client()->delete('/test'); },
                         { DELETE => 'SUCCESS' }, 'delete() method works' );

=end testing

=cut

#---------------------------------------------------------------------------

=internal_method B<data_upload>

Similar to
L<< JIRA::REST->attach_files|JIRA::REST/"attach_files ISSUE FILE..." >>,
but entirely from memory and only attaches one file at a time. Returns the
L<HTTP::Response|HTTP::Response> object from the post request.  Takes the
following named parameters:

=over 4

=item + B<url>

The relative URL to POST to.  This will have the hostname and REST version
information prepended to it, so all you need to provide is something like
C</issue/>I<issueIdOrKey>C</attachments>.  I'm allowing the URL to be
specified in case I later discover something this can be used for besides
attaching files to issues.

=item + B<name>

The name that is specified for this file attachment.

=item + B<data>

The actual data to be uploaded.  If a reference is provided, it will be
dereferenced before posting the data.

=back

I guess that makes it only a I<little> like
C<< JIRA::REST->attach_files >>...

=cut

sub data_upload {
    my ( $self, @args ) = @_;
    my $args = $self->_get_known_args( \@args, qw/ url name data / );
    $self->_check_required_args(
        $args,
        url  => 'you must specify a URL to upload to',
        name => 'you must specify a name for the file data',
        data => 'you must specify the file data',
    );

    my $name = $args->{name};
    my $data = ref $args->{data} ? ${ $args->{data} } : $args->{data};

    # code cribbed from JIRA::REST
    #
    my $url      = $self->rest_api_url_base . $args->{url};
    my $rest     = $self->REST_CLIENT;
    my $response = $rest->getUseragent()->post(
        $url,
        %{ $rest->{_headers} },
        'X-Atlassian-Token' => 'nocheck',
        'Content-Type'      => 'form-data',
        'Content'           => [
            file => [ undef, $name, Content => $data ],
        ],
    );

    #<<< perltidy should ignore these lines
    $response->is_success
        or croak $self->JIRA_REST->_error( ## no critic (ProtectPrivateSubs)
            $self->_croakmsg( $response->status_line, $name )
        );
    #>>>

    return $response;
}

#---------------------------------------------------------------------------

=begin testing data_upload

my $expected = {
  "Content-Disposition" => "form-data; name=\"file\"; filename=\"file.txt\"",
  POST => "SUCCESS",
  data => "An OO Class module built atop L<JIRA::REST|JIRA::REST> for dealing with "
       .  "JIRA issues and their data as objects.",
  name => "file.txt"
};

my $test1_name = 'return value from data_upload()';
my $test2_name = 'data_upload() method succeeded';
my $test3_name = 'data_upload() method returned expected data';

my $test = get_test_client();
my $results;
my $got;

try {
    $results = $test->data_upload({
        url  => "/data_upload",
        name => $expected->{name},
        data => $expected->{data},
    });
    $got = $test->JSON->decode($results->decoded_content);
}
catch {
    $results = $_;
    diag($test->REST_CLIENT->getHost);
};

my $test1_ok = isa_ok( $results, 'HTTP::Response', $test1_name );
my $test2_ok = ok($test1_ok && $results->is_success, $test2_name );
$test2_ok ? is_deeply( $got, $expected, $test3_name ) : fail( $test3_name );

=end testing

=cut

#---------------------------------------------------------------------------

=method B<maxResults>

A getter/setter method that allows setting a global default for the L<maxResults pagination parameter for JIRA's REST API |https://docs.atlassian.com/jira/REST/latest/#pagination>.  This determines the I<maximum> number of results returned by the L<issues|/"issues QUERY"> and L<query|/"query QUERY"> methods; and the initial number of results fetched by the L<iterator|/"iterator QUERY"> (when L<next|JIRA::REST::Class::Iterator/next> exhausts that initial cache of results it will automatically make subsequent calls to the REST API to fetch more results).

Defaults to 50.

  say $jira->maxResults; # returns 50

  $jira->maxResults(10); # only return 10 results at a time

=cut

sub maxResults {
    my $self = shift;
    if ( @_ ) {
        $self->{maxResults} = shift;
    }
    unless ( exists $self->{maxResults} && defined $self->{maxResults} ) {
        $self->{maxResults} = $DEFAULT_MAXRESULTS;
    }
    return $self->{maxResults};
}

=method B<issue_types>

Returns a list of defined issue types (as
L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type> objects)
for this server.

=cut

sub issue_types {
    my $self = shift;

    unless ( $self->{issue_types} ) {
        my $types = $self->get( '/issuetype' );
        $self->{issue_types} = [  # stop perltidy from pulling
            map {                 # these lines together
                $self->make_object( 'issuetype', { data => $_ } );
            } @$types
        ];
    }

    return @{ $self->{issue_types} } if wantarray;
    return $self->{issue_types};
}

#---------------------------------------------------------------------------

=begin testing issue_types 16

try {
    my $test = get_test_client();

    validate_contextual_accessor($test, {
        method => 'issue_types',
        class  => 'issuetype',
        data   => [ sort qw/ Bug Epic Improvement Sub-task Story Task /,
                    'New Feature' ],
    });

    print "#\n# Checking the 'Bug' issue type\n#\n";

    my ($bug) = sort $test->issue_types;

    can_ok_abstract( $bug, qw/ description iconUrl id name self subtask / );

    my $host = TestServer_url();

    validate_expected_fields( $bug, {
        description => "jira.translation.issuetype.bug.name.desc",
        iconUrl => "$host/secure/viewavatar?size=xsmall&avatarId=10303"
                .  "&avatarType=issuetype",
        id => 10004,
        name => "Bug",
        self => "$host/rest/api/latest/issuetype/10004",
        subtask => JSON::PP::false,
    });
};

=end testing

=cut

#---------------------------------------------------------------------------

=method B<projects>

Returns a list of projects (as
L<JIRA::REST::Class::Project|JIRA::REST::Class::Project> objects) for this
server.

=cut

sub projects {
    my $self = shift;

    unless ( $self->{project_list} ) {

        # get the project list from JIRA
        my $projects = $self->get( '/project' );

        # build a list, and make a hash so we can
        # grab projects later by id, key, or name.

        my $list = $self->{project_list} = [];

        my $make_project_hash_entry = sub {
            my $prj = shift;
            my $obj = $self->make_object( 'project', { data => $prj } );

            push @$list, $obj;

            return $obj->id => $obj, $obj->key => $obj, $obj->name => $obj;
        };

        $self->{project_hash} = { ##
            map { $make_project_hash_entry->( $_ ) } @$projects
        };
    }

    return @{ $self->{project_list} } if wantarray;
    return $self->{project_list};
}

#---------------------------------------------------------------------------

=begin testing projects 5

my $test = get_test_client();

try {
    validate_contextual_accessor($test, {
        method => 'projects',
        class  => 'project',
        data   => [ qw/ JRC KANBAN PACKAY PM SCRUM / ],
    });
};

=end testing

=cut

#---------------------------------------------------------------------------

=method B<project> PROJECT_ID || PROJECT_KEY || PROJECT_NAME

Returns a L<JIRA::REST::Class::Project|JIRA::REST::Class::Project> object
for the project specified. Returns undef if the project doesn't exist.

=cut

sub project {
    my $self = shift;
    my $proj = shift || return;  # if nothing was passed, we return nothing

    # if we were passed a project object, just return it
    return $proj if $self->obj_isa( $proj, 'project' );

    $self->projects;  # load the project hash if it hasn't been loaded

    return unless exists $self->{project_hash}->{$proj};
    return $self->{project_hash}->{$proj};
}

#---------------------------------------------------------------------------

=begin testing project 17

try {
    print "#\n# Checking the SCRUM project\n#\n";

    my $test = get_test_client();

    my $proj = $test->project('SCRUM');

    can_ok_abstract( $proj, qw/ avatarUrls expand id key name self
                                category assigneeType components
                                description issueTypes lead roles versions
                                allowed_components allowed_versions
                                allowed_fix_versions allowed_issue_types
                                allowed_priorities allowed_field_values
                                field_metadata_exists field_metadata
                                field_name
                              / );

    validate_expected_fields( $proj, {
        expand => "description,lead,url,projectKeys",
        id => 10002,
        key => 'SCRUM',
        name => "Scrum Software Development Sample Project",
        projectTypeKey => "software",
        lead => {
            class => 'user',
            expected => {
                key => 'packy'
            },
        },
    });

    validate_contextual_accessor($proj, {
        method => 'versions',
        class  => 'projectvers',
        name   => "SCRUM project's",
        data   => [ "Version 1.0", "Version 2.0", "Version 3.0" ],
    });
};

=end testing

=cut

#---------------------------------------------------------------------------

=method B<SSL_verify_none>

Sets to false the SSL options C<SSL_verify_mode> and C<verify_hostname> on
the L<LWP::UserAgent|LWP::UserAgent> object that is used by
L<REST::Client|REST::Client> (which, in turn, is used by
L<JIRA::REST|JIRA::REST>, which is used by this module).

=cut

sub SSL_verify_none { ## no critic (NamingConventions::Capitalization)
    my $self = shift;
    return $self->REST_CLIENT->getUseragent()->ssl_opts(
        SSL_verify_mode => 0,
        verify_hostname => 0
    );
}

=internal_method B<rest_api_url_base>

Returns the base URL for this JIRA server's REST API.  For example, if your JIRA server is at C<http://jira.example.com>, this would return C<http://jira.example.com/rest/api/latest>.

=cut

sub rest_api_url_base {
    my $self = shift;
    if ( $self->_JIRA_REST_version_has_separate_path ) {
        ( my $host = $self->REST_CLIENT->getHost ) =~ s{/$}{}xms;
        my $path = $self->JIRA_REST->{path} // q{/rest/api/latest};
        return $host . $path;
    }
    else {
        my ( $base )
            = $self->REST_CLIENT->getHost =~ m{^(.+?rest/api/[^/]+)/?}xms;
        return $base // $self->REST_CLIENT->getHost . '/rest/api/latest';
    }
}

=internal_method B<strip_protocol_and_host>

A method to take the provided URL and strip the protocol and host from it.  For example, if the URL C<http://jira.example.com/rest/api/latest> was passed to this method, C</rest/api/latest> would be returned.

=cut

sub strip_protocol_and_host {
    my $self = shift;
    my $host = $self->REST_CLIENT->getHost;
    ( my $url = shift ) =~ s{^$host}{}xms;
    return $url;
}

=accessor B<args>

An accessor that returns a copy of the arguments passed to the
constructor. Useful for passing around to utility objects.

=cut

sub args { return shift->{args} }

=accessor B<url>

An accessor that returns the C<url> parameter passed to this object's
constructor.

=cut

sub url { return shift->args->{url} }

=accessor B<username>

An accessor that returns the username used to connect to the JIRA server,
even if the username was read from a C<.netrc> or
L<Config::Identity|Config::Identity> file.

=cut

sub username {
    my $self = shift;

    unless ( defined $self->args->{username} ) {
        $self->args->{username} = $self->user_object->name;
    }

    return $self->args->{username};
}

=accessor B<user_object>

An accessor that returns the user used to connect to the JIRA server as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object, even if the username
was read from a C<.netrc> or L<Config::Identity|Config::Identity> file.  Works
by making the JIRA REST API call L</rest/api/latest/myself|https://docs.atlassian.com/jira/REST/cloud/#api/2/myself>.

=cut

sub user_object {
    my $self = shift;

    unless ( defined $self->{userobj} ) {
        my $data = $self->get( '/myself' );
        $self->{userobj} = $self->make_object( 'user', { data => $data } );
    }

    return $self->{userobj};
}

=accessor B<password>

An accessor that returns the password used to connect to the JIRA server,
even if the username was read from a C<.netrc> or
L<Config::Identity|Config::Identity> file.

=cut

sub password {
    my $self = shift;

    unless ( $self->args->{password} ) {

        # we don't have the password cached, so get it from
        # the Authorization header we're sending to JIRA

        my $rest = $self->JIRA_REST->{rest};
        if ( my $auth = $rest->{_headers}->{Authorization} ) {
            my ( undef, $encoded ) = split /\s+/, $auth;
            ( undef, $self->args->{password} ) =
              split /:/, decode_base64 $encoded;
        }
    }

    return $self->args->{password};
}

=accessor B<rest_client_config>

An accessor that returns the C<rest_client_config> parameter passed to this
object's constructor.

=cut

sub rest_client_config { return shift->args->{rest_client_config} }

=accessor B<anonymous>

An accessor that returns the C<anonymous> parameter passed to this object's constructor.

=cut

sub anonymous { return shift->args->{anonymous} }

=accessor B<proxy>

An accessor that returns the C<proxy> parameter passed to this object's constructor.

=cut

sub proxy { return shift->args->{proxy} }

#---------------------------------------------------------------------------

=begin testing parameter_accessors 15

try {
    print "#\n# Checking parameter accessors\n#\n";

    my $test = get_test_client();
    my $url  = TestServer_url();

    my $args = {
        url       => $url,
        username  => 'username',
        password  => 'password',
        proxy     => undef,
        anonymous => undef,
        rest_client_config => undef,
        ssl_verify_none => undef,
    };

    # the args accessor will have keys for ALL the possible arguments,
    # whether they were passed in or not.

    cmp_deeply( $test,
                methods( args      => { %$args, },
                         url       => $args->{url},
                         username  => $args->{username},
                         password  => $args->{password},
                         proxy     => $args->{proxy},
                         anonymous => $args->{anonymous},
                         rest_client_config => $args->{rest_client_config} ),
                q{All accessors for parameters passed }.
                q{into the constructor okay});

    my $ua = $test->REST_CLIENT->getUseragent();
    $test->SSL_verify_none;
    cmp_deeply($ua->{ssl_opts}, { SSL_verify_mode => 0, verify_hostname => 0 },
               q{SSL_verify_none() does disable SSL verification});

    is($test->rest_api_url_base($url . "/rest/api/latest/foo"),
       $url . "/rest/api/latest", q{rest_api_url_base() works as expected});

    is($test->strip_protocol_and_host($test->REST_CLIENT->getHost . "/foo"),
       "/foo", q{strip_protocol_and_host() works as expected});

    is($test->maxResults, 50, q{maxResults() default is correct});

    is($test->maxResults(10), 10, q{maxResults(N) returns N});

    is($test->maxResults, 10,
       q{maxResults() was successfully set by previous call});

    print "# testing user_object() accessor\n";
    my $userobj = $test->user_object();

    validate_expected_fields( $userobj, {
        key => 'packy',
        name => 'packy',
        displayName => "Packy Anderson",
        emailAddress => 'packy\@cpan.org',
    });

};

=end testing

=cut

#---------------------------------------------------------------------------

1;

__END__

{{
    for my $pod (qw/ synopsis description constructor mixins
                     see-also repository credits /) {
        $OUT .= include( "pod/$pod.pod" )->fill_in . "\n\n";
    }

    require "pod/PodUtil.pm";
    $OUT .= PodUtil::include_stopwords();
    $OUT .= PodUtil::related_classes($plugin);
}}
