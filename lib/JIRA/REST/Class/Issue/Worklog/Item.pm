package JIRA::REST::Class::Issue::Worklog::Item;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

use Readonly 2.04;

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual worklog item for a JIRA issue as an object.

Readonly my @USERS     => qw( author updateAuthor );
Readonly my @DATES     => qw( created updated );
Readonly my @ACCESSORS => qw( comment id self timeSpent timeSpentSeconds );

__PACKAGE__->mk_ro_accessors( @USERS, @DATES );
__PACKAGE__->mk_data_ro_accessors( @ACCESSORS );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    # make user objects
    foreach my $field ( @USERS ) {
        $self->populate_scalar_data( $field, 'user', $field );
    }

    # make date objects
    foreach my $field ( @DATES ) {
        $self->populate_date_data( $field, $field );
    }

    return;
}

1;

=accessor B<author>

This method returns the author of the JIRA issue's work item as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=accessor B<comment>

This method returns the comment of the JIRA issue's work item as a string.

=accessor B<created>

This method returns the creation time of the JIRA issue's work item as a
L<DateTime|DateTime> object.

=accessor B<id>

This method returns the ID of the JIRA issue's work item as a string.

=accessor B<self>

This method returns the JIRA REST API URL of the work item as a string.

=accessor B<started>

This method returns the start time of the JIRA issue's work item as a
L<DateTime|DateTime> object.

=accessor B<timeSpent>

This method returns the time spent on the JIRA issue's work item as a string.

=accessor B<timeSpentSeconds>

This method returns the time spent on the JIRA issue's work item as a number
of seconds.

=accessor B<updateAuthor>

This method returns the update author of the JIRA issue's work item as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=accessor B<updated>

This method returns the update time of the JIRA issue's work item as a
L<DateTime|DateTime> object.

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::include_stopwords();
    $OUT .= PodUtil::related_classes($plugin);
}}
