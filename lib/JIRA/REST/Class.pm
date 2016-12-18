package JIRA::REST::Class;
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: An OO Class module built atop L<JIRA::REST> for dealing with JIRA issues and their data as objects.

use Carp;
use Clone::Any qw( clone );

use JIRA::REST;
use JIRA::REST::Class::Factory;
use base qw(JIRA::REST::Class::Mixins);

sub new {
    my $class = shift;

    my $args = $class->_get_known_args(
        \@_, qw/url username password rest_client_config
                proxy ssl_verify_none anonymous/
    );

    return bless {
        jira_rest => $class->JIRA_REST(clone($args)),
        factory   => $class->factory(clone($args)),
        args      => clone($args),
    }, $class;
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
use v5.10;

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

throws_ok(
    sub {
        JIRA::REST::Class->new();
    },
    qr/URL argument must be defined/,
    'JIRA::REST::Class->new with no parameters throws an exception',
);

throws_ok(
    sub {
        JIRA::REST::Class->new({
            username  => 'user',
            password  => 'pass',
        });
    },
    qr/URL argument must be defined/,
    'JIRA::REST::Class->new with no url throws an exception',
);

throws_ok(
    sub {
        JIRA::REST::Class->new('https://jira.example.com/');
    },
    qr/No credentials found/,
    q{JIRA::REST::Class->new with just url tries to find credentials},
);

lives_ok(
    sub {
        JIRA::REST::Class->new('https://jira.example.com/',
                               'user', 'pass');
    },
    q{JIRA::REST::Class->new with url, username, and password does't croak!},
);

=end testing

#---------------------------------------------------------------------------

=method B<issues> QUERY

=method B<issues> KEY [, KEY...]

The C<issues> method can be called two ways: either by providing a list of
issue keys, or by proving a single hash reference which describes a JIRA
query in the same format used by L<JIRA::REST> (essentially, jql => "JQL
query string").

The return value is an array of C<JIRA::REST::Class::Issue> objects.

=cut

sub issues {
    my $self = shift;
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        return $self->query(shift)->issues;
    }
    else {
        my $list = join(',', @_);
        my $jql  = "key in ($list)";
        return $self->query({ jql => $jql })->issues;
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
describes a JIRA query in the same format used by L<JIRA::REST>
(essentially, jql => "JQL query string").

The return value is a single C<JIRA::REST::Class::Query> object.

=cut

sub query {
    my $self = shift;
    my $args = shift;

    my $query = $self->post('/search', $args);
    return $self->make_object('query', { data => $query });
}

#---------------------------------------------------------------------------
#
# =begin testing query
# =end testing
#
#---------------------------------------------------------------------------

=method B<iterator> QUERY

The C<query> method takes a single parameter: a hash reference which
describes a JIRA query in the same format used by L<JIRA::REST>
(essentially, jql => "JQL query string").  It accepts an additional field,
however: restart_if_lt_total.  If this field is set to a true value, the
iterator will keep track of the number of results fetched and, if when the
results run out this number doesn't match the number of results predicted
by the query, it will restart the query.  This is particularly useful if
you are transforming a number of issues through an iterator, and the
transformation causes the issues to no longer match the query.

The return value is a single C<JIRA::REST::Class::Iterator> object.
The issues returned by the query can be obtained in serial by
repeatedly calling B<next> on this object, which returns a series
of C<JIRA::REST::Class::Issue> objects.

=cut

sub iterator {
    my $self = shift;
    my $args = shift;
    return $self->make_object('iterator', { iterator_args => $args });
}

#---------------------------------------------------------------------------
#
# =begin testing iterator
# =end testing
#
#---------------------------------------------------------------------------

=internal_method B<get> URL [, QUERY]

A wrapper for L<JIRA::REST>'s GET method.

=cut

sub get {
    my $self = shift;
    my $url  = shift;
    return $self->JIRA_REST->GET($url, undef, @_);
}

#---------------------------------------------------------------------------

=begin testing get

validate_wrapper_method( sub { get_test_client()->get('/test'); },
                         { GET => 'SUCCESS' }, 'get() method works' );

=end testing

#---------------------------------------------------------------------------

=internal_method B<post>

Wrapper around L<JIRA::REST>'s POST method.

=cut

sub post {
    my $self = shift;
    my $url  = shift;
    $self->JIRA_REST->POST($url, undef, @_);
}

#---------------------------------------------------------------------------

=begin testing post

validate_wrapper_method( sub { get_test_client()->post('/test', "key=value"); },
                         { POST => 'SUCCESS' }, 'post() method works' );

=end testing

#---------------------------------------------------------------------------

=internal_method B<put>

Wrapper around L<JIRA::REST>'s PUT method.

=cut

sub put {
    my $self = shift;
    my $url  = shift;
    $self->JIRA_REST->PUT($url, undef, @_);
}

#---------------------------------------------------------------------------

=begin testing put

validate_wrapper_method( sub { get_test_client()->put('/test', "key=value"); },
                         { PUT => 'SUCCESS' }, 'put() method works' );

=end testing

#---------------------------------------------------------------------------

=internal_method B<delete>

Wrapper around L<JIRA::REST>'s DELETE method.

=cut

sub delete {
    my $self = shift;
    my $url  = shift;
    $self->JIRA_REST->DELETE($url, @_);
}

#---------------------------------------------------------------------------

=begin testing delete

validate_wrapper_method( sub { get_test_client()->delete('/test'); },
                         { DELETE => 'SUCCESS' }, 'delete() method works' );

=end testing

#---------------------------------------------------------------------------

=internal_method B<data_upload>

Similar to C<< JIRA::REST->attach_files >>, but entirely from memory and
only attaches one file at a time. Returns the L<HTTP::Response> object from
the post request.  Takes the following named parameters:

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
    my $self = shift;
    my $args = $self->_get_known_args(\@_, qw/ url name data /);
    $self->_check_required_args($args,
        url  => "you must specify a URL to upload to",
        name => "you must specify a name for the file data",
        data => "you must specify the file data",
    );

    my $name = $args->{name};
    my $data = ref $args->{data} ? ${ $args->{data} } : $args->{data};

    # code cribbed from JIRA::REST
    #
    my $rest = $self->REST_CLIENT;
    my $response = $rest->getUseragent()->post(
        $self->rest_api_url_base . $args->{url},
        %{ $rest->{_headers} },
        'X-Atlassian-Token' => 'nocheck',
        'Content-Type'      => 'form-data',
        'Content'           => [
            file => [
                undef,
                $name,
                Content => $data,
            ],
        ],
    );

    $response->is_success
        or croak $self->JIRA_REST->_error(
            $self->_croakmsg($response->status_line, $name)
        );

    return $response;
}

#---------------------------------------------------------------------------

=begin testing data_upload

my $expected = {
  "Content-Disposition" => "form-data; name=\"file\"; filename=\"file.txt\"",
  POST => "SUCCESS",
  data => "An OO Class module built atop C<JIRA::REST> for dealing with "
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
};

my $test1_ok = isa_ok( $results, 'HTTP::Response', $test1_name );
my $test2_ok = ok($test1_ok && $results->is_success, $test2_name );
$test2_ok ? is_deeply( $got, $expected, $test3_name ) : fail( $test3_name );

=end testing

#---------------------------------------------------------------------------

=method B<maxResults>

An accessor that allows setting a global default for maxResults.

Defaults to 50.

=cut

sub maxResults {
    my $self = shift;
    if (@_) {
        $self->{maxResults} = shift;
    }
    unless (exists $self->{maxResults} && defined $self->{maxResults}) {
        $self->{maxResults} = 50;
    }
    return $self->{maxResults};
}

=method B<issue_types>

Returns a list of defined issue types (as C<JIRA::REST::Class::Issue::Type>
objects) for this server.

=cut

sub issue_types {
    my $self = shift;

    unless ($self->{issue_types}) {
        my $types = $self->get('/issuetype');
        $self->{issue_types} = [ map {
            $self->make_object('issuetype', { data => $_ });
        } @$types ];
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

#---------------------------------------------------------------------------

=method B<projects>

Returns a list of projects (as C<JIRA::REST::Class::Project> objects) for
this server.

=cut

sub projects {
    my $self = shift;

    unless ($self->{project_list}) {
        # get the project list from JIRA
        my $projects = $self->get('/project');

        # build a list, and make a hash so we can
        # grab projects later by id, key, or name.

        my $list = $self->{project_list} = [];
        $self->{project_hash} = { map {
            my $p = $self->make_object('project', { data => $_ });
            push @$list, $p;
            $p->id => $p, $p->key => $p, $p->name => $p
        } @$projects };
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

#---------------------------------------------------------------------------

=method B<project> PROJECT_ID || PROJECT_KEY || PROJECT_NAME

Returns a C<JIRA::REST::Class::Project> object for the project
specified. Returns undef if the project doesn't exist.

=cut

sub project {
    my $self = shift;
    my $proj = shift || return; # if nothing was passed, we return nothing

    # if we were passed a project object, just return it
    return $proj if $self->obj_isa($proj, 'project');

    $self->projects; # load the project hash if it hasn't been loaded

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

#---------------------------------------------------------------------------

=method B<SSL_verify_none>

Disables the SSL options SSL_verify_mode and verify_hostname on the user
agent used by this class' C<REST::Client> object.

=cut

sub SSL_verify_none {
    my $self = shift;
    $self->REST_CLIENT->getUseragent()->ssl_opts( SSL_verify_mode => 0,
                                                  verify_hostname => 0 );
}

=internal_method B<rest_api_url_base>

Returns the base URL for this JIRA server's REST API.

=cut

sub rest_api_url_base {
    my $self = shift;
    if ($self->_JIRA_REST_version_has_separate_path) {
        (my $host = $self->REST_CLIENT->getHost) =~ s{/$}{};
        my $path = $self->JIRA_REST->{path};
        return $host . $path;
    }
    else {
        my ($base) = $self->REST_CLIENT->getHost =~ m{^(.+?rest/api/[^/]+)/?};
        return $base;
    }
}

=internal_method B<strip_protocol_and_host>

A method to take the provided URL and strip the protocol and host from it.

=cut

sub strip_protocol_and_host {
    my $self = shift;
    my $host = $self->REST_CLIENT->getHost;
    (my $url = shift) =~ s{^$host}{};
    return $url;
}

=accessor B<args>

An accessor for the copy of the arguments passed to the constuctor.

=cut

sub args { shift->{args} }

=accessor B<url>

An accessor for the URL passed to the L<JIRA::REST> object.

=cut

sub url { shift->args->{url} }

=accessor B<username>

An accessor for the username passed to the L<JIRA::REST> object.

=cut

sub username { shift->args->{username} }

=accessor B<password>

An accessor for the password passed to the L<JIRA::REST> object.

=cut

sub password { shift->args->{password} }

=accessor B<rest_client_config>

An accessor for the REST client config passed to the L<JIRA::REST> object.

=cut

sub rest_client_config { shift->args->{rest_client_config} }

=accessor B<anonymous>

An accessor for the C<anonymous> prameter passed to the L<JIRA::REST> object.

=cut

sub anonymous { shift->args->{anonymous} }

=accessor B<proxy>

An accessor for the C<proxy> parameter passed to the L<JIRA::REST> object.

=cut

sub proxy { shift->args->{proxy} }

#---------------------------------------------------------------------------

=begin testing parameter_accessors 7

try{
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

    is($test->strip_protocol_and_host($url . "/foo"),
       "/foo", q{strip_protocol_and_host() works as expected});

    is($test->maxResults, 50, q{maxResults() default is correct});

    is($test->maxResults(10), 10, q{maxResults(N) returns N});

    is($test->maxResults, 10,
       q{maxResults() was successfully set by previous call});
};

=end testing

=cut

#---------------------------------------------------------------------------

1;

__END__

{{ include( "pod/synopsis.pod" )->fill_in; }}

{{ include( "pod/description.pod" )->fill_in; }}

{{ include( "pod/constructor.pod" )->fill_in; }}

{{ include( "pod/mixins.pod" )->fill_in; }}

{{ include( "pod/see-also.pod" )->fill_in; }}

=head1 REPOSITORY

L<https://github.com/packy/JIRA-REST-Class>

{{ include( "pod/credits.pod" )->fill_in; }}

{{
   use Path::Tiny;
   $OUT .= q{=for stopwords};
   for my $word ( sort( path("stopwords.ini")->lines( { chomp => 1 } ) ) ) {
       $OUT .= qq{ $word};
   }
   $OUT .= qq{\n};
}}
