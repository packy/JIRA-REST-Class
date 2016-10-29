package JIRA::REST::Class::Issue::Transitions;
use strict;
use warnings;
use v5.10;

use Data::Dumper::Concise;

# https://docs.atlassian.com/jira/REST/latest/#api/2/issue-doTransition

# The fields that can be set on transtion, in either the fields parameter or
# the update parameter can be determined using the
#
# /rest/api/2/issue/{issueIdOrKey}/transitions?expand=transitions.fields
#
# resource. If a field is not configured to appear on the transition screen,
# then it will not be in the transition metadata, and a field validation error
# will occur if it is submitted.

sub new {
    my $class = shift;
    my $issue = shift;

    my $transitions =
      $issue->GET('/transitions?expand=transitions.fields');

    my $self = { transitions => $transitions, issue => $issue };

    return bless $self, $class;
}

sub issue  { shift->{issue} }
use Carp;
sub transition_id {
    my $self = shift;
    my $name = shift or confess "no name specified";
    my $transitions = $self->{transitions};
    foreach my $transition ( @{ $transitions->{transitions} } ) {
        next unless $transition->{name} eq $name;
        return $transition->{id};
    }
    die "Unable to find transition '$name'\n\ntransitions: "
      . Dumper($transitions) . "\nissue: " . Dumper($self->{issue});
}

sub transition {
    my $self = shift;
    my $id   = shift;
    $self->issue->POST("/transitions", { transition => { id => $id }, @_ });
}

sub block {
    my $self = shift;
    $self->transition($self->transition_id("Block Issue"), @_);
}

sub close {
    my $self = shift;
    $self->transition($self->transition_id("Close Issue"), @_);
}

sub verify {
    my $self = shift;
    $self->transition($self->transition_id("Verify Issue"), @_);
}

sub resolve {
    my $self = shift;
    $self->transition($self->transition_id("Resolve Issue"), @_);
}

sub reopen {
    my $self = shift;
    $self->transition($self->transition_id("Reopen Issue"), @_);
}

sub start_progress {
    my $self = shift;
    $self->transition($self->transition_id("Start Progress"), @_);
}

sub stop_progress {
    my $self = shift;
    $self->transition($self->transition_id("Stop Progress"), @_);
}

sub start_qa {
    my $self = shift;
    $self->transition($self->transition_id("Start QA"), @_);
}

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

sub status_name { shift->issue->status_name }

sub transition_walk {
    my $self     = shift;
    my $target   = shift;
    my $map      = shift;
    my $callback = shift // sub {};

    my $assignee = $self->issue->assignee;
    my $name     = $self->status_name;

    until ($name eq $target) {
        if (exists $map->{$name} ) {
            my $to = $map->{$name};
            unless ( exists $state_to_transition{$to} ) {
                die "Unknown target state '$to'!\n";
            }
            my $id = $self->transition_id( $state_to_transition{$to} )
              or die "No transition id for target state '$to'!\n";
            $callback->($name, $to);
            $self->transition($id);
        }
        else {
            die "Don't know how to transition from '$name' to '$target'!\n";
        }

        # refresh the data for this issue
        $self->issue->reload;
        $self->{transitions} =
          $self->issue->GET('/transitions?expand=transitions.fields');

        $name = $self->status_name;

    }

    # put the owner back to who it's supposed to be
    $self->issue->set_assignee($assignee);
}

1;
