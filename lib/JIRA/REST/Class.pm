package JIRA::REST::Class;
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: An OO Class module built atop C<JIRA::REST> for dealing with JIRA issues and their data as objects.

use Carp;

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
        jira_rest => $class->JIRA_REST($args),
        factory   => $class->factory($args),
        args      => $args,
    }, $class;
}


=method B<issues> QUERY

=method B<issues> KEY [, KEY...]

The C<issues> method can be called two ways: either by providing a list of
issue keys, or by proving a single hash reference which describes a JIRA
query in the same format used by C<JIRA::REST> (essentially, jql => "JQL
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

=method B<query> QUERY

The C<query> method takes a single parameter: a hash reference which
describes a JIRA query in the same format used by C<JIRA::REST>
(essentially, jql => "JQL query string").

The return value is a single C<JIRA::REST::Class::Query> object.

=cut

sub query {
    my $self = shift;
    my $args = shift;

    my $query = $self->post('/search', $args);
    return $self->make_object('query', { data => $query });
}

=method B<iterator> QUERY

The C<query> method takes a single parameter: a hash reference which
describes a JIRA query in the same format used by C<JIRA::REST>
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

=internal_method B<get> URL [, QUERY]

A wrapper for C<JIRA::REST>'s GET method.

=cut

sub get {
    my $self = shift;
    my $url  = shift;
    return $self->JIRA_REST->GET($url, undef, @_);
}

=internal_method B<post>

Wrapper around C<JIRA::REST>'s POST method.

=cut

sub post {
    my $self = shift;
    my $url  = shift;
    $self->JIRA_REST->POST($url, undef, @_);
}

=internal_method B<put>

Wrapper around C<JIRA::REST>'s PUT method.

=cut

sub put {
    my $self = shift;
    my $url  = shift;
    $self->JIRA_REST->PUT($url, undef, @_);
}

=internal_method B<delete>

Wrapper around C<JIRA::REST>'s DELETE method.

=cut

sub delete {
    my $self = shift;
    my $url  = shift;
    $self->JIRA_REST->DELETE($url, @_);
}

=internal_method B<data_upload>

Similar to C<< JIRA::REST->attach_files >>, but entirely from memory and
only attaches one file at a time. Takes the following named parameters:

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
}

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

=internal_method B<url>

An accessor for the URL passed to the C<JIRA::REST> object.

=cut

sub url { shift->{args}->{url} }

=internal_method B<username>

An accessor for the username passed to the C<JIRA::REST> object.

=cut

sub username { shift->{args}->{username} }

=internal_method B<password>

An accessor for the password passed to the C<JIRA::REST> object.

=cut

sub password { shift->{args}->{password} }

=internal_method B<rest_client_config>

An accessor for the REST client config passed to the C<JIRA::REST> object.

=cut

sub rest_client_config { shift->{args}->{rest_client_config} }

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
