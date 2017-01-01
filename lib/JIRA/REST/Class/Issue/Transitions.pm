package JIRA::REST::Class::Issue::Transitions;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

use Carp;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the state transitions a JIRA issue can go through.  Currently assumes a state diagram consisting of Open/In Progress/Resolved/Reopened/In QA/Verified/Closed.

__PACKAGE__->mk_contextual_ro_accessors( qw/ transitions / );

=method B<transitions>

Returns an array of
L<JIRA::REST::Class::Issue::Transitions::Transition|JIRA::REST::Class::Issue::Transitions::Transition>
objects representing the transitions the issue can currently go through.

=accessor B<issue>

The L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object this is a
transition for.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );
    $self->_refresh_transitions;
    return;
}

sub _refresh_transitions {
    my $self = shift;

    $self->{data}
        = $self->issue->get( '/transitions?expand=transitions.fields' );

    $self->{transitions} = [  #
        map {                 #
            $self->issue->make_object( 'transition', { data => $_ } )
        } @{ $self->data->{transitions} }
    ];

    return;
}

=method B<find_transition_named>

Returns the transition object for the named transition provided.

=cut

sub find_transition_named {
    my $self = shift;
    my $name = shift or confess 'no name specified';

    $self->_refresh_transitions;

    foreach my $transition ( $self->transitions ) {
        next unless $transition->name eq $name;
        return $transition;
    }

    croak sprintf "Unable to find transition '%s'\n"
        . "issue status: %s\n"
        . "transitions:  %s\n",
        $name,
        $self->issue->status->name,
        $self->dump( [ $self->transitions ] );
}

=method B<block>

Blocks the issue.

=cut

sub block { return shift->find_transition_named( 'Block Issue' )->go( @_ ) }

=method B<close>

Closes the issue.

=cut

## no critic (ProhibitBuiltinHomonyms ProhibitAmbiguousNames)
sub close { return shift->find_transition_named( 'Close Issue' )->go( @_ ) }
## use critic

=method B<verify>

Verifies the issue.

=cut

sub verify { return shift->find_transition_named( 'Verify Issue' )->go( @_ ) }

=method B<resolve>

Resolves the issue.

=cut

sub resolve { return shift->find_transition_named( 'Resolve Issue' )->go( @_ ) }

=method B<reopen>

Reopens the issue.

=cut

sub reopen { return shift->find_transition_named( 'Reopen Issue' )->go( @_ ) }

=method B<start_progress>

Starts progress on the issue.

=cut

sub start_progress {
    return shift->find_transition_named( 'Start Progress' )->go( @_ );
}

=method B<stop_progress>

Stops progress on the issue.

=cut

sub stop_progress {
    return shift->find_transition_named( 'Stop Progress' )->go( @_ );
}

=method B<start_qa>

Starts QA on the issue.

=cut

sub start_qa { return shift->find_transition_named( 'Start QA' )->go( @_ ) }

=method B<transition_walk>

This method takes three unnamed parameters:
  + The name of the end target issue status
  + A hashref mapping possible current states to intermediate states
    that will progress the issue towards the end target issue status
  + A callback subroutine reference that will be called after each
    transition with the name of the current issue state and the name
    of the state it is transitioning to (defaults to an empty subroutine
    reference).

=cut

my %state_to_transition = (
    'Open'        => 'Stop Progress',
    'In Progress' => 'Start Progress',
    'Resolved'    => 'Resolve Issue',
    'In QA'       => 'Start QA',
    'Verified'    => 'Verify Issue',
    'Closed'      => 'Close Issue',
    'Reopened'    => 'Reopen Issue',
    'Blocked'     => 'Block Issue',
);

sub transition_walk {
    my $self     = shift;
    my $target   = shift;
    my $map      = shift;
    my $callback = shift // sub { };
    my $name     = $self->issue->status->name;

    my $orig_assignee = $self->issue->assignee // q{};

    until ( $name eq $target ) {
        if ( exists $map->{$name} ) {
            my $to = $map->{$name};
            unless ( exists $state_to_transition{$to} ) {
                die "Unknown target state '$to'!\n";
            }
            my $trans
                = $self->find_transition_named( $state_to_transition{$to} );
            $callback->( $name, $to );
            $trans->go;
        }
        else {
            die "Don't know how to transition from '$name' to '$target'!\n";
        }

        # get the new status name
        $name = $self->issue->status->name;
    }

    # put the owner back to who it's supposed
    # to be if it changed during our walk
    my $current_assignee = $self->issue->assignee // q{};
    if ( $current_assignee ne $orig_assignee ) {
        $self->issue->set_assignee( $orig_assignee );
    }

    return;
}

1;

=head1 SEE ALSO

=head2 JIRA REST API Reference L<Do transition|https://docs.atlassian.com/jira/REST/latest/#api/2/issue-doTransition>

The fields that can be set on transition, in either the fields parameter or the
update parameter can be determined using the
C</rest/api/2/issue/{issueIdOrKey}/transitions?expand=transitions.fields>
resource. If a field is not configured to appear on the transition screen, then
it will not be in the transition metadata, and a field validation error will
occur if it is submitted.

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
