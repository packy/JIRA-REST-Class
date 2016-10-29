package JIRA::REST::Class;
use base qw( JIRA::REST );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Iterator;
use JIRA::REST::Class::Query;

sub rest { shift->{rest} }

sub SSL_verify_none {
    my $self = shift;
    $self->rest->getUseragent()->ssl_opts( SSL_verify_mode => 0,
                                           verify_hostname => 0 );
}

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

sub query {
    my $self = shift;
    my $args = shift;

    my $query = $self->POST('/search', undef, $args);
    return JIRA::REST::Class::Query->new($self, $query);
}

sub iterator {
    my $self = shift;
    my $args = shift;
    return JIRA::REST::Class::Iterator->new($self, $args);
}

sub get {
    my $self = shift;
    my $url  = shift;
    my $args = shift;
    return $self->GET($url, undef, $args);
}

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

sub maxResults {
    return shift->_accessor('CLASS_maxResults', sub { 50 }, @_);
}

sub project {
    return shift->_accessor('CLASS_project', sub {
                                die "You must define a project!\n"
                            }, @_);
}

sub issue_types {
    my $self = shift;
    unless (defined $self->{CLASS_issue_types}) {
        my $types = $self->get('/issuetype');
        $self->{CLASS_issue_types} = [ map { $_->{name} } @$types ];
    }
    return @{ $self->{CLASS_issue_types} };
}

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

sub allowed_components   { shift->allowed_field_values('components');  }
sub allowed_versions     { shift->allowed_field_values('versions'); }
sub allowed_fix_versions { shift->allowed_field_values('fixVersions'); }
sub allowed_issue_types  { shift->allowed_field_values('issuetype');   }
sub allowed_priorities   { shift->allowed_field_values('priority');    }

sub allowed_field_values {
    my $self = shift;
    my $name = shift;

    my @list =
      map { $_->{name} } @{ $self->field_metadata($name)->{allowedValues} };

    return @list;
}

sub field_metadata_exists {
    my $self = shift;
    my $name = shift;
    my $fields = $self->metadata->{fields};
    return 1 if exists $fields->{$name};
    my $name2 = $self->field_name($name);
    return (exists $fields->{$name2} ? 1 : 0);
}


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

sub rest_api_url_base {
    my $self = shift;
    my $url  = $self->field_metadata('assignee')->{autoCompleteUrl};
    my ($base) = $url =~ m{^(.+?rest/api/[^/]+)/};
    return $base;
}

1;
