package JIRA::REST::Class::FactoryTypes;
use parent qw( Exporter );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.05';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

#ABSTRACT: The module that exports the list of object types in the L<JIRA::REST::Class|JIRA::REST::Class> module to L<JIRA::REST::Class::Factory|JIRA::REST::Class::Factory> and the testing code.

=head1 DESCRIPTION

The sole purpose of this module is to have a single point of modification
for the hash that defines short names for the object types.

=cut

our @EXPORT_OK = qw( %TYPES );

=head2 %TYPES

A hash where the keys map to the full names of the classes of objects in the
L<JIRA::REST::Class|JIRA::REST::Class> package.

=cut

our %TYPES = (
    class        => 'JIRA::REST::Class',
    factory      => 'JIRA::REST::Class::Factory',
    abstract     => 'JIRA::REST::Class::Abstract',
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

1;

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
