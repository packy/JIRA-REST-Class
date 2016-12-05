package JIRA::REST::Class::Project;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents a JIRA project as an object.

__PACKAGE__->mk_data_ro_accessors(qw( avatarUrls expand id key name projectTypeKey self ));

_make_lazy_ro_accessors(qw/ category assigneeType components description
                            issueTypes lead roles versions /);

use overload
    '""'   => sub { shift->key },
    '0+'   => sub { shift->id  },
    '<=>'  => sub {
        my($A, $B) = @_;
        my $AA = ref $A ? $A->id : $A;
        my $BB = ref $B ? $B->id : $B;
        $AA <=> $BB
    },
    'cmp'  => sub {
        my($A, $B) = @_;
        my $AA = ref $A ? $A->name : $A;
        my $BB = ref $B ? $B->name : $B;
        $AA cmp $BB
    };

sub _make_lazy_ro_accessors {
    foreach my $field (@_) {
        __PACKAGE__->mk_lazy_ro_accessor($field, sub {
            my $self = shift;
            $self->_do_lazy_load(@_);
            $self->{$field};
        }, @_);
    }
}

sub _do_lazy_load {
    my $self  = shift;

    (my $url = $self->self) =~ s{.*/project}{/project};
    my $data = $self->jira->get($url);

    $self->{assigneeType} = $data->{assigneeType};

    $self->{components} = [ map {
        $self->make_object('projectcomp', { data => $_ });
    } @{ $data->{components} } ];

    $self->{description} = $data->{description};

    $self->{issueTypes} = [ map {
        $self->make_object('issuetype', { data => $_ });
    } @{ $data->{issueTypes} } ];

    $self->{lead} = $self->make_object('user', { data => $data->{lead} });

    $self->{roles} = $data->{roles};

    $self->{versions} = [ map {
        my $v = $self->make_object('projectvers', { data => $_ });
        $self->{version_hash}->{$v->id} = $self->{version_hash}->{$v->name} = $v;
        $v;
    } @{ $data->{versions} } ];

    foreach my $field ( @_ ) {
        $self->{lazy_loaded}->{$field} = 1;
    }
}

=method B<assigneeType>
This method returns the assignee type of the project.

=method B<avatarUrls>
A hashref of the different sizes available for the project's avatar.

=method B<components>
A list of the components for the project.

=method B<description>
Returns the description of the project.

=method B<expand>
Heck if I know what this field does.

=method B<id>
Returns the id of the project.

=method B<issueTypes>
A list of valid issue types for the project.

=method B<key>
Returns the key of the project.

=method B<lead>
Returns the project lead as a C<JIRA::REST::Class::User> object.

=method B<name>
Returns the name of the project.

=method B<category>
Returns a hashref of the category of the project.

=method B<self>
Returns the JIRA REST API URL of the project.

=method B<versions>
Returns a list of the versions of the project.

=method B<metadata>

Returns the metadata associated with this project.

=cut

sub metadata {
    my $self = shift;

    unless (defined $self->{metadata}) {
        my ($first_issue) = $self->jira->issues({
            jql => "project = " . $self->key,
            maxResults => 1,
        });
        my $issuekey = $first_issue->key;
        $self->{metadata} = $self->get("/issue/$issuekey/editmeta");
    }

    return $self->{metadata};
}

=method B<allowed_components>

Returns a list of the allowed values for the 'components' field in the project.

=cut

sub allowed_components   { shift->allowed_field_values('components', @_);  }

=method B<allowed_versions>

Returns a list of the allowed values for the 'versions' field in the project.

=cut

sub allowed_versions     { shift->allowed_field_values('versions', @_); }

=method B<allowed_fix_versions>

Returns a list of the allowed values for the 'fixVersions' field in the project.

=cut

sub allowed_fix_versions { shift->allowed_field_values('fixVersions', @_); }

=method B<allowed_issue_types>

Returns a list of the allowed values for the 'issuetype' field in the project.

=cut

sub allowed_issue_types  { shift->allowed_field_values('issuetype', @_);   }

=method B<allowed_priorities>

Returns a list of the allowed values for the 'priority' field in the project.

=cut

sub allowed_priorities   { shift->allowed_field_values('priority', @_);    }

=internal_method B<allowed_field_values> FIELD_NAME

Returns a list of allowable values for the specified field in the project.

=cut

sub allowed_field_values {
    my $self = shift;
    my $name = shift;

    my @list = map {
        $_->{name}
    } @{ $self->field_metadata($name)->{allowedValues} };

    return @list;
}

=internal_method B<field_metadata_exists> FIELD_NAME

Boolean indicating whether there is metadata for a given field in the project.

=cut

sub field_metadata_exists {
    my $self = shift;
    my $name = shift;
    my $fields = $self->metadata->{fields};
    return 1 if exists $fields->{$name};
    my $name2 = $self->field_name($name);
    return (exists $fields->{$name2} ? 1 : 0);
}


=internal_method B<field_metadata> FIELD_NAME

Looks for metadata under either a field's key or name in the project.

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

=internal_method B<field_name> FIELD_KEY

Looks up field names in the project metadata in the project.

=cut

sub field_name {
    my $self = shift;
    my $name = shift;

    unless ($self->{field_names}) {
        my $data = $self->metadata->{fields};

        $self->{field_names} = { map {
            $data->{$_}->{name} => $_
        } keys %$data };
    }

    return $self->{field_names}->{$name};
}


1;
