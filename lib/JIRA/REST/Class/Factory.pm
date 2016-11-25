package JIRA::REST::Class::Factory;
use base qw( Class::Factory::Enhanced );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A factory class for building all the other classes in C<JIRA::REST::Class>.

JIRA::REST::Class::Factory->add_factory_type(
    factory      => 'JIRA::REST::Class::Factory',
    issue        => 'JIRA::REST::Class::Issue',
    changelog    => 'JIRA::REST::Class::Issue::Changelog',
    change       => 'JIRA::REST::Class::Issue::Changelog::Change',
    changeitem   => 'JIRA::REST::Class::Issue::Changelog::Change::Item',
    linktype     => 'JIRA::REST::Class::Issue::LinkType',
    status       => 'JIRA::REST::Class::Issue::Status',
    statuscat    => 'JIRA::REST::Class::Issue::Status::Category',
    timetracking => 'JIRA::REST::Class::Issue::TimeTracking',
    transistions => 'JIRA::REST::Class::Issue::Transitions',
    transistion  => 'JIRA::REST::Class::Issue::Transitions::Transition',
    issuetype    => 'JIRA::REST::Class::Issue::Type',
    worklog      => 'JIRA::REST::Class::Issue::Worklog',
    workitem     => 'JIRA::REST::Class::Issue::Worklog::Item',
    project      => 'JIRA::REST::Class::Project',
    projectcat   => 'JIRA::REST::Class::Project::Category',
    projectcomp  => 'JIRA::REST::Class::Project::Component',
    projectvers  => 'JIRA::REST::Class::Project::Version',
    iterator     => 'JIRA::REST::Class::Iterator',
    sprint       => 'JIRA::REST::Class::Sprint',
    query        => 'JIRA::REST::Class::Query',
    user         => 'JIRA::REST::Class::User',
);

use DateTime::Format::Strptime;

=internal_method B<jira>

Accessor for the C<JIRA::REST::Class> object used to talk to the server.

=cut

sub jira { shift->{jira} }

=internal_method B<make_object>

A tweaked version of the object creator from C<Class::Factory::Enhanced>.

=cut

sub make_object {
    my ($self, $object_type, @args) = @_;
    my $class = $self->get_factory_class($object_type);
    my $obj = $class->new(@args);
    $obj->init($self);
    return $obj;
}

=internal_method B<make_date>

Make it easy to get C<DateTime> objects from the factory.

=cut

sub make_date {
    my ($self, $date) = @_;
    return unless $date;
    state $parser = DateTime::Format::Strptime->new( pattern => '%FT%T.%N%Z' );
    return $parser->parse_datetime($date);
}

1;
