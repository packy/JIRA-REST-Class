package JIRA::REST::Class;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: An OO Class module built atop C<JIRA::REST> for dealing with JIRA issues and their data as objects.

=head1 SYNOPSIS

  use JIRA::REST::Class;

  my $jira = JIRA::REST::Class->new('https://jira.example.net',
                                    'myuser', 'mypass');

  # if your server uses self-signed SSL certificates
  $jira->SSL_verify_none;

  # allow the class to fetch the metadata for your project
  $jira->project('MYPROJECT');

  # get issue by key
  my ($issue) = $jira->issues('MYPROJECT-101');

  # get multiple issues by key
  my @issues = $jira->issues('MYPROJECT-101', 'MYPROJECT-102', 'MYPROJECT-103');

  # get multiple issues through search
  my @issues =
      $jira->issues({ jql => 'project = "'MYPROJECT" and status = "open"' });

  # get an iterator for a search
  my $search =
      $jira->iterator({ jql => 'project = "'MYPROJECT" and status = "open"' });

  if ( $search->issue_count ) {
      printf "Found %d open issues in MYPROJECT:\n", $search->issue_count;
      while ( my $issue = $search->next ) {
          printf "  Issue %s is open\n", $issue->key;
      }
  }
  else {
      print "No open issues in MYPROJECT.\n";
  }

=head1 DESCRIPTION

An OO Class module built atop C<JIRA::REST> for dealing with JIRA issues and their
data as objects.

This code is a work in progress, so it's bound to be incomplete.  I add methods
to it as I discover I need them.  I also code for fields that might exist in my JIRA server's configuration but not in yours.  It is my intent to make things more generic as I go on so they will "just work" no matter how your server is configured.

=constructor new(URL, USERNAME, PASSWORD [, REST_CLIENT_CONFIG])

The constructor C<new()> mimics the constructor for C<JIRA::REST>, and accepts up to four arguments (this documentation is lifted directly from  C<JIRA::REST>'s documentation):

=over

=item * URL

A string or a URI object denoting the base URL of the JIRA server. This is a required argument.

You may choose a specific API version by appending the C</rest/api/VERSION> string to the URL's path. It's more common to left it unspecified, in which case the C</rest/api/latest> string is appended automatically to the URL.

=item * USERNAME

The username of a JIRA user.

It can be undefined if PASSWORD is also undefined. In such a case the user credentials are looked up in the C<.netrc> file.

=item * PASSWORD

The HTTP password of the user. (This is the password the user uses to log in to JIRA's web interface.)

It can be undefined, in which case the user credentials are looked up in the C<.netrc> file.

=item * REST_CLIENT_CONFIG

A C<JIRA::REST> object uses a C<REST::Client> object to make the REST invocations. This optional argument must be a hash-ref that can be fed to the C<REST::Client> constructor. Note that the C<URL> argument overwrites any value associated with the C<host> key in this hash.

To use a network proxy please set the 'proxy' argument to the string or URI object describing the fully qualified (including port) URL to your network proxy. This is an extension to the C<REST::Client> configuration and will be removed from the hash before passing it on to the C<REST::Client> constructor.

=back

=cut

use Scalar::Util qw( weaken blessed );

use JIRA::REST;
use JIRA::REST::Class::Factory;

sub new {
    my $class = shift;
    my @args  = @_;
    my ($url, $username, $password, $rest_client_config) = @args;

    my $self = bless {
        jira_rest => JIRA::REST->new(@args),
        factory   => JIRA::REST::Class::Factory->new('factory'),
        url       => $url,
        username  => $username,
        password  => $password,
        rest_client_config => $rest_client_config
    }, $class;

    # so every other object can get to it easily,
    # let's put a reference to ourself in the factory
    $self->{factory}->{jira} = $self;
    weaken $self->{factory}->{jira};

    return $self;
}


=method B<issues> QUERY

=method B<issues> KEY [, KEY...]

The C<issues> method can be called two ways: either by providing a list of issue keys, or by proving a single hash reference which describes a JIRA query in the same format used by C<JIRA::REST> (essentially, jql => "JQL query string").

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

The C<query> method takes a single parameter: a hash reference which describes a JIRA query in the same format used by C<JIRA::REST> (essentially, jql => "JQL query string").

The return value is a single C<JIRA::REST::Class::Query> object.

=cut

sub query {
    my $self = shift;
    my $args = shift;

    my $query = $self->JIRA_REST->POST('/search', undef, $args);
    return $self->factory->make_object('query', { data => $query });
}

=method B<iterator> QUERY

The C<query> method takes a single parameter: a hash reference which describes a JIRA query in the same format used by C<JIRA::REST> (essentially, jql => "JQL query string").  It accepts an additional field, however: restart_if_lt_total.  If this field is set to a true value, the iterator will keep track of the number of results fetched and, if when the results run out this number doesn't match the number of results predicted by the query, it will restart the query.  This is particularly useful if you are transforming a number of issues through an iterator, and the transformation causes the issues to no longer match the query.

The return value is a single C<JIRA::REST::Class::Iterator> object.  The issues returned by the query can be obtained in serial by repeatedly calling B<next> on this object, which returns a series of C<JIRA::REST::Class::Issue> objects.

=cut

sub iterator {
    my $self = shift;
    my $args = shift;
    return $self->factory->make_object('iterator', { iterator_args => $args });
}

=method B<get> URL [, QUERY]

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

=method B<maxResults>

An accessor that allows setting a global default for maxResults. Defaults to 50.

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

Returns a list of defined issue types (as C<JIRA::REST::Class::Issue::Type> objects) for this server.

=cut

sub issue_types {
    my $self = shift;
    unless ($self->{issue_types}) {
        my $types = $self->get('/issuetype');
        $self->{issue_types} = [ map {
            $self->factory->make_object('issuetype', { data => $_ });
        } @$types ];
    }

    return @{ $self->{issue_types} } if wantarray;
    return $self->{issue_types};
}

=method B<projects>

Returns a list of projects (as C<JIRA::REST::Class::Project> objects) for this server.

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
            my $p = $self->factory->make_object('project', { data => $_ });
            push @$list, $p;
            $p->id => $p, $p->key => $p, $p->name => $p
        } @$projects };
    }

    return @{ $self->{project_list} } if wantarray;
    return $self->{project_list};
}

=method B<project> PROJECT_ID || PROJECT_KEY || PROJECT_NAME

Returns a C<JIRA::REST::Class::Project> object for the project specified. Returns undef if the project doesn't exist.

=cut

sub project {
    my $self = shift;
    my $proj = shift || return; # if nothing was passed, we return nothing

    # if we were passed a project object, just return it
    return $proj
        if blessed $proj
        && $proj->isa($self->factory->get_factory_class('project'));

    $self->projects; # load the project hash if it hasn't been loaded

    return unless exists $self->{project_hash}->{$proj};
    return $self->{project_hash}->{$proj};
}

=method B<SSL_verify_none>

Disables the SSL options SSL_verify_mode and verify_hostname on the user agent
used by this class' C<REST::Client> object.

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
    my ($type) = $self->issue_types;  # grab the first issue type
    (my $base = $type->self) =~ m{^(.+?rest/api/[^/]+)/};
    return $base;
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

sub url { shift->{url} }

=internal_method B<username>

An accessor for the username passed to the C<JIRA::REST> object.

=cut

sub username { shift->{username} }

=internal_method B<password>

An accessor for the password passed to the C<JIRA::REST> object.

=cut

sub password { shift->{password} }

=internal_method B<rest_client_config>

An accessor for the REST client config passed to the C<JIRA::REST> object.

=cut

sub rest_client_config { shift->{rest_client_config} }

=internal_method B<factory>

An accessor for the C<JIRA::REST::Class::Factory>.

=cut

sub factory { shift->{factory} }

=internal_method B<JIRA_REST>

An accessor that returns the C<JIRA::REST> object being used.

=cut

sub JIRA_REST { shift->{jira_rest} }

=internal_method B<REST_CLIENT>

An accessor that returns the C<REST::Client> object inside the C<JIRA::REST> object being used.

=cut

sub REST_CLIENT { shift->JIRA_REST->{rest} }

1;

=head1 SEE ALSO

=over

=item * C<JIRA::REST>

C<JIRA::REST::Class> uses C<JIRA::REST> to perform all its interaction with JIRA.

=item * C<REST::Client>

C<JIRA::REST> uses a C<REST::Client> object to perform its low-level interactions.

=item * L<JIRA REST API Reference|https://docs.atlassian.com/jira/REST/latest/>

Atlassian's official JIRA REST API Reference.

=back

=head1 REPOSITORY

L<https://github.com/packy/JIRA-REST-Class>
