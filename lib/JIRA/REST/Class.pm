package JIRA::REST::Class;
use base qw( JIRA::REST );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

=head1 NAME

JIRA::REST::Class - An OO Class module built atop JIRA::REST for dealing with
                    JIRA issues and their data as objects.

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

An OO Class module built atop JIRA::REST for dealing with JIRA issues and their
data as objects.

This code is a work in progress, so it's bound to be incomplete.  I add methods
to it as I discover I need them.

=head1 CONSTRUCTOR

=head2 new(URL, USERNAME, PASSWORD [, REST_CLIENT_CONFIG])

The constructor is entirely inherited from JIRA::REST,
and accepts up to four arguments:

=over

=item * URL

A string or a URI object denoting the base URL of the JIRA
server. This is a required argument.

You may choose a specific API version by appending the
C</rest/api/VERSION> string to the URL's path. It's more common to
left it unspecified, in which case the C</rest/api/latest> string is
appended automatically to the URL.

=item * USERNAME

The username of a JIRA user.

It can be undefined if PASSWORD is also undefined. In such a case the
user credentials are looked up in the C<.netrc> file.

=item * PASSWORD

The HTTP password of the user. (This is the password the user uses to
log in to JIRA's web interface.)

It can be undefined, in which case the user credentials are looked up
in the C<.netrc> file.

=item * REST_CLIENT_CONFIG

A JIRA::REST object uses a REST::Client object to make the REST
invocations. This optional argument must be a hash-ref that can be fed
to the REST::Client constructor. Note that the C<URL> argument
overwrites any value associated with the C<host> key in this hash.

To use a network proxy please set the 'proxy' argument to the string or URI
object describing the fully qualified (including port) URL to your network
proxy. This is an extension to the REST::Client configuration and will be
removed from the hash before passing it on to the REST::Client constructor.

=back

=cut

use JIRA::REST::Class::Iterator;
use JIRA::REST::Class::Query;

=head1 METHODS

=head2 B<issues> QUERY

=head2 B<issues> KEY [, KEY...]

The C<issues> method can be called two ways: either by providing a list of
issue keys, or by proving a single hash reference which describes a JIRA query
in the same format used by C<JIRA::REST> (essentially, jql => "JQL query
string").

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

=head2 B<query> QUERY

The C<query> method takes a single parameter: a hash reference which describes a
JIRA query in the same format used by C<JIRA::REST> (essentially, jql => "JQL
query string").

The return value is a single C<JIRA::REST::Class::Query> object.

=cut

sub query {
    my $self = shift;
    my $args = shift;

    my $query = $self->POST('/search', undef, $args);
    return JIRA::REST::Class::Query->new($self, $query);
}

=head2 B<query> QUERY

The C<query> method takes a single parameter: a hash reference which describes a
JIRA query in the same format used by C<JIRA::REST> (essentially, jql => "JQL
query string").

The return value is a single C<JIRA::REST::Class::Query> object.

=cut

sub iterator {
    my $self = shift;
    my $args = shift;
    return JIRA::REST::Class::Iterator->new($self, $args);
}

=head2 B<get> URL [, QUERY]

A wrapper for C<JIRA::REST>'s GET method.

=cut

sub get {
    my $self = shift;
    my $url  = shift;
    my $args = shift;
    return $self->GET($url, undef, $args);
}

=head2 B<maxResults>

An accessor that allows setting a global default for maxResults. Defaults to 50.

=cut

sub maxResults {
    return shift->_accessor('CLASS_maxResults', sub { 50 }, @_);
}

=head2 B<project>

An accessor that sets the project you want to fetch metadata (allowed
components, versions, fix versions, issue types) for.

=cut

sub project {
    return shift->_accessor('CLASS_project', sub {
                                die "You must define a project!\n"
                            }, @_);
}

=head2 B<issue_types>

Returns a list of defined issue types for this server.

=cut

sub issue_types {
    my $self = shift;
    unless (defined $self->{CLASS_issue_types}) {
        my $types = $self->get('/issuetype');
        $self->{CLASS_issue_types} = [ map { $_->{name} } @$types ];
    }
    return @{ $self->{CLASS_issue_types} };
}

=head2 B<metadata>

Returns the metadata associated with the first issue in the project indicated by
the C<project> accessor.

=cut

sub metadata {
    my $self = shift;
    unless (defined $self->{CLASS_metadata}) {
        my $results = $self->POST('/search', undef, {
            jql => "project = ".$self->project,
            maxResults => 1,
        });
        my $key = $results->{issues}->[0]->{key};
        $self->{CLASS_metadata} = $self->get("/issue/$key/editmeta");
    }
    return $self->{CLASS_metadata};
}

=head2 B<allowed_components>

Returns a list of the allowed values for the 'components' field in the project
indicated by the C<project> accessor.

=cut

sub allowed_components   { shift->allowed_field_values('components');  }

=head2 B<allowed_versions>

Returns a list of the allowed values for the 'versions' field in the project
indicated by the C<project> accessor.

=cut

sub allowed_versions     { shift->allowed_field_values('versions'); }

=head2 B<allowed_fix_versions>

Returns a list of the allowed values for the 'fixVersions' field in the project
indicated by the C<project> accessor.

=cut

sub allowed_fix_versions { shift->allowed_field_values('fixVersions'); }

=head2 B<allowed_issue_types>

Returns a list of the allowed values for the 'issuetype' field in the project
indicated by the C<project> accessor.

=cut

sub allowed_issue_types  { shift->allowed_field_values('issuetype');   }

=head2 B<allowed_priorities>

Returns a list of the allowed values for the 'priority' field in the project
indicated by the C<project> accessor.

=cut

sub allowed_priorities   { shift->allowed_field_values('priority');    }

=head2 B<SSL_verify_none>

Disables the SSL options SSL_verify_mode and verify_hostname on the user agent
used by this class' C<REST::Client> object.

=cut

sub SSL_verify_none {
    my $self = shift;
    $self->rest->getUseragent()->ssl_opts( SSL_verify_mode => 0,
                                           verify_hostname => 0 );
}

=head1 INTERNAL METHODS

=head2 B<allowed_field_values> FIELD_NAME

Returns a list of allowable values for the specified field.

=cut

sub allowed_field_values {
    my $self = shift;
    my $name = shift;

    my @list =
      map { $_->{name} } @{ $self->field_metadata($name)->{allowedValues} };

    return @list;
}

=head2 B<field_metadata_exists> FIELD_NAME

Boolean indicating whether there is metadata for a given field.

=cut

sub field_metadata_exists {
    my $self = shift;
    my $name = shift;
    my $fields = $self->metadata->{fields};
    return 1 if exists $fields->{$name};
    my $name2 = $self->field_name($name);
    return (exists $fields->{$name2} ? 1 : 0);
}


=head2 B<field_metadata> FIELD_NAME

Looks for metadata under either a field's key or name.

=cut

sub field_metadata {
    my $self = shift;
    my $name = shift;
    my $fields = $self->metadata->{fields};
    if (exists $fields->{$name}) {
        return $fields->{$name};
    }
    my $name2 = $self->field_name($name);
    if (exists $fields->{$name2}) {
        return $fields->{$name2};
    }
    return;
}

=head2 B<field_name> FIELD_KEY

Looks up field names in the project metadata.

=cut

sub field_name {
    my $self = shift;
    my $name = shift;

    unless (defined $self->{CLASS_field_names}) {
        my $data = $self->metadata->{fields};

        $self->{CLASS_field_names} =
          { map { $data->{$_}->{name} => $_ } keys %$data };
    }

    return $self->{CLASS_field_names}->{$name};
}

=head2 B<rest_api_url_base>

Returns the base URL for this JIRA server's REST API.

=cut

sub rest_api_url_base {
    my $self = shift;
    my $url  = $self->field_metadata('assignee')->{autoCompleteUrl};
    my ($base) = $url =~ m{^(.+?rest/api/[^/]+)/};
    return $base;
}

=head2 B<rest>

An accessor that returns the C<REST::Client> object being used.

=cut

sub rest { shift->{rest} }

=head2 B<_accessor> FIELD, SUB_RETURNING_DEFAULT_VALUE [, VALUE_TO_SET]

A utility method for creating a setter/accessor that has a default value.

=cut

sub _accessor {
    my $self    = shift;
    my $field   = shift;
    my $default = shift;
    unless (defined $self->{$field}) {
        if (@_) {
            $self->{$field} = shift;
        }
        else {
            $self->{$field} = $default->();
        }
    }
    return $self->{$field};
}

1;

=head1 SEE ALSO

=over

=item * C<JIRA::REST>

JIRA::REST::Class is a subclass of JIRA::REST, and uses it to perform
all this module's mid-level interaction with JIRA.

=item * C<REST::Client>

JIRA::REST uses a REST::Client object to perform the low-level interactions.

=item * L<JIRA REST API Reference|https://docs.atlassian.com/jira/REST/latest/>

Atlassian's official JIRA REST API Reference.

=back

=head1 REPOSITORY

L<https://github.com/packy/JIRA-REST-Class>

=head1 AUTHOR

Packy Anderson, E<lt>packy@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Packy Anderson

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
