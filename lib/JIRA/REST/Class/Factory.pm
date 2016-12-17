package JIRA::REST::Class::Factory;
use base qw( Class::Factory::Enhanced );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A factory class for building all the other classes in C<JIRA::REST::Class>.

# here is our list of every class this factory knows how to make
#
JIRA::REST::Class::Factory->add_factory_type(
    factory      => 'JIRA::REST::Class::Factory',
    issue        => 'JIRA::REST::Class::Issue',
    changelog    => 'JIRA::REST::Class::Issue::Changelog',
    change       => 'JIRA::REST::Class::Issue::Changelog::Change',
    changeitem   => 'JIRA::REST::Class::Issue::Changelog::Change::Item',
    comment      => 'JIRA::REST::Class::Issue::Comment',
    linktype     => 'JIRA::REST::Class::Issue::LinkType',
    status       => 'JIRA::REST::Class::Issue::Status',
    statuscat    => 'JIRA::REST::Class::Issue::Status::Category',
    timetracking => 'JIRA::REST::Class::Issue::TimeTracking',
    transitions  => 'JIRA::REST::Class::Issue::Transitions',
    transition   => 'JIRA::REST::Class::Issue::Transitions::Transition',
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

use Carp;
use DateTime::Format::Strptime;

=internal_method B<init>

Initialize the factory object.  Just copies all the elements in the hashref that were passed in to the object itself.

=cut

sub init {
    my $self = shift;
    my $args = shift;
    my @keys = keys %$args;
    @{$self}{@keys} = @{$args}{@keys};
    return $self;
}

=internal_method B<make_object>

A tweaked version of the object creator from C<Class::Factory::Enhanced> that calls C<init()> with a copy of the factory.

=cut

sub make_object {
    my ($self, $object_type, @args) = @_;
    my $class = $self->get_factory_class($object_type);
    my $obj = $class->new(@args);
    $obj->init($self); # make sure we pass the factory into init()
    return $obj;
}

=internal_method B<make_date>

Make it easy to get C<DateTime> objects from the factory.

=cut

sub make_date {
    my ($self, $date) = @_;
    return unless $date;
    my $pattern = '%FT%T.%N%z';
    state $parser = DateTime::Format::Strptime->new( pattern => $pattern );
    return( $parser->parse_datetime($date) or
        confess qq{Unable to parse date "$date" using pattern "$pattern"} );
}

=internal_method B<factory_error>

Throws errors from the factory with stack traces

=cut

sub factory_error {
    my $class = shift;
    my $err   = shift;
    # start the stacktrace where we called make_object()
    local $Carp::CarpLevel = $Carp::CarpLevel+2;
    confess "$err\n", @_;
}

1;
