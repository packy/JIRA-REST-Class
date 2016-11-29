package JIRA::REST::Class::Issue::Transitions;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

use Carp;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents the state transitions a JIRA issue can go through.

__PACKAGE__->mk_contextual_ro_accessors(qw/ transitions /);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{data} = $self->issue->get('/transitions?expand=transitions.fields');

    $self->{transitions} = [ map {
        $self->issue->make_object('transition', { data => $_ })
    } @{ $self->data->{transitions} } ];
}


=internal_method B<find_transition_named>

Returns the transition object for the named transition provided.

=cut

sub find_transition_named {
    my $self = shift;
    my $name = shift or confess "no name specified";

    foreach my $transition ( $self->transitions ) {
        next unless $transition->name eq $name;
        return $transition;
    }

    die "Unable to find transition '$name'\n"
      . "\ntransitions: " . $self->shallow_dump($self->transitions)
      . "\nissue: " . $self->shallow_dump($self->issue);
}

=method B<block>

Blocks the issue.

=cut

sub block { shift->find_transition_named("Block Issue")->go(@_) }

=method B<close>

Closes the issue.

=cut

sub close { shift->find_transition_named("Close Issue")->go(@_) }

=method B<verify>

Verifies the issue.

=cut

sub verify { shift->find_transition_named("Verify Issue")->go(@_) }

=method B<resolve>

Resolves the issue.

=cut

sub resolve { shift->find_transition_named("Resolve Issue")->go(@_) }

=method B<reopen>

Reopens the issue.

=cut

sub reopen { shift->find_transition_named("Reopen Issue")->go(@_) }

=method B<start_progress>

Starts progress on the issue.

=cut

sub start_progress { shift->find_transition_named("Start Progress")->go(@_) }

=method B<stop_progress>

Stops progress on the issue.

=cut

sub stop_progress { shift->find_transition_named("Stop Progress")->go(@_) }

=method B<start_qa>

Starts QA on the issue.

=cut

sub start_qa { shift->find_transition_named("Start QA")->go(@_) }

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
    my $callback = shift // sub {};

    my $assignee = $self->issue->assignee;
    my $name     = $self->issue->status->name;

    until ($name eq $target) {
        if (exists $map->{$name} ) {
            my $to = $map->{$name};
            unless ( exists $state_to_transition{$to} ) {
                die "Unknown target state '$to'!\n";
            }
            my $trans = $self->find_transition_named( $state_to_transition{$to} )
              or die "No transition for target state '$to'!\n";
            $callback->($name, $to);
            $trans->go;
        }
        else {
            die "Don't know how to transition from '$name' to '$target'!\n";
        }

        # refresh the data for this issue
        $self->issue->reload;
        $self->init($self->factory);
        $name = $self->issue->status->name;
    }

    # put the owner back to who it's supposed
    # to be if it changed during our walk
    if ($self->issue->assignee ne $assignee) {
        $self->issue->set_assignee($assignee);
    }
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



