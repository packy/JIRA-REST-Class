package JIRA::REST::Class::Issue::Transitions::Transition;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.05';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual state transition a JIRA issue can go through.

__PACKAGE__->mk_ro_accessors( qw/ issue to / );
__PACKAGE__->mk_data_ro_accessors( qw/ id name hasScreen fields / );
__PACKAGE__->mk_field_ro_accessors( qw/ summary / );

=accessor B<issue>

The L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object this is a
transition for.

=accessor B<to>

The status this transition will move the issue to, represented as a
L<JIRA::REST::Class::Issue::Status|JIRA::REST::Class::Issue::Status> object.

=accessor B<id>

The id of the transition.

=accessor B<>

The name of the transition.

=accessor B<fields>

The fields for the transition.

=accessor B<summary>

The summary for the transition.

=accessor B<hasScreen>

Heck if I know.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    $self->{to} = $self->make_object( 'status', { data => $self->data->{to} } );

    return;
}

=method B<go>

Perform the transition represented by this object on the issue.

=cut

sub go {
    my ( $self, @args ) = @_;
    $self->issue->post(
        '/transitions',
        {
            transition => { id => $self->id },
            @args
        }
    );

    # reload the issue itself, since it's going to have a new status,
    # which will mean new transitions
    $self->issue->reload;

    # reload these new transitions
    $self->issue->transitions->init( $self->factory );

    return;
}

1;

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
