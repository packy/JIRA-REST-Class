package JIRA::REST::Class::Issue::Changelog::Change;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.07';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual change to a JIRA issue as an object.

__PACKAGE__->mk_ro_accessors( qw/ author created / );
__PACKAGE__->mk_data_ro_accessors( qw/ id / );
__PACKAGE__->mk_contextual_ro_accessors( qw/ items / );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    # make user object
    $self->populate_scalar_data( 'author', 'user', 'author' );

    # make date object
    $self->populate_date_data( 'created', 'created' );

    # make list of changed items
    $self->populate_list_data( 'items', 'changeitem', 'items' );

    return;
}

1;

=accessor B<author>

Returns the author of a JIRA issue's change as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=accessor B<created>

Returns the creation time of a JIRA issue's change as a L<DateTime|DateTime>
object.

=accessor B<id>

Returns the id of a JIRA issue's change.

=accessor B<items>

Returns the list of items modified by a JIRA issue's change as a list of
L<JIRA::REST::Class::Issue::Changelog::Change::Item|JIRA::REST::Class::Issue::Changelog::Change::Item>
objects.

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
