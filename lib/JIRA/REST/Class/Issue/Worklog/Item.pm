package JIRA::REST::Class::Issue::Worklog::Item;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

use Readonly;

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents an individual worklog item for a JIRA issue as an object.

Readonly my @USERS => qw( author updateAuthor );
Readonly my @DATES => qw( created updated );
__PACKAGE__->mk_ro_accessors(@USERS, @DATES);
__PACKAGE__->mk_data_ro_accessors(qw/ comment id self
                                      timeSpent timeSpentSeconds /);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # make user objects
    foreach my $field (@USERS) {
        $self->populate_scalar_data($field, 'user', $field);
    }

    # make date objects
    foreach my $field (@DATES) {
        $self->populate_date_data($field, $field);
    }
}

1;

=accessor B<author>
This method returns the author of the JIRA issue's work item as a C<JIRA::REST::Class::User> object.

=accessor B<comment>
This method returns the comment of the JIRA issue's work item as a string.

=accessor B<created>
This method returns the creation time of the JIRA issue's work item as a C<DateTime> object.

=accessor B<id>
This method returns the ID of the JIRA issue's work item as a string.

=accessor B<self>
This method returns the JIRA REST API URL of the work item as a string.

=accessor B<started>
This method returns the start time of the JIRA issue's work item as a C<DateTime> object.

=accessor B<timeSpent>
This method returns the time spent on the JIRA issue's work item as a string.

=accessor B<timeSpentSeconds>
This method returns the time spent on the JIRA issue's work item as a number of seconds.

=accessor B<updateAuthor>
This method returns the update author of the JIRA issue's work item as a C<JIRA::REST::Class::User> object.

=accessor B<updated>
This method returns the update time of the JIRA issue's work item as a C<DateTime> object.
