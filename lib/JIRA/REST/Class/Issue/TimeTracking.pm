package JIRA::REST::Class::Issue::TimeTracking;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for L<JIRA::REST::Class> that represents the time tracking for a JIRA issue as an object.

use Contextual::Return;

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    my $data = $self->issue->get( q{}, { fields => 'timetracking' } );
    $self->{data} = $data->{fields}->{timetracking};
}

=accessor B<originalEstimate>

Returns the original estimate as a number of seconds in numeric context, and as a w/d/h/m/s string in a string context.

=cut

sub originalEstimate {
    my $self = shift;
    #<<<
    return
        NUM { $self->data->{originalEstimateSeconds} }
        STR { $self->data->{originalEstimate} }
    ;
    #>>>
}

=accessor B<remainingEstimate>

Returns the remaining estimate as a number of seconds in numeric context, and as a w/d/h/m/s string in a string context.

=cut

sub remainingEstimate {
    my $self = shift;
    #<<<
    return
        NUM { $self->data->{remainingEstimateSeconds} }
        STR { $self->data->{remainingEstimate} }
    ;
    #>>>
}

=accessor B<timeSpent>

Returns the time spent as a number of seconds in numeric context, and as a w/d/h/m/s string in a string context.

=cut

sub timeSpent {
    my $self = shift;
    #<<<
    return
        NUM { $self->data->{timeSpentSeconds} }
        STR { $self->data->{timeSpent} }
    ;
    #>>>
}

=method B<set_originalEstimate>

Sets the original estimate to the amount of time given.  Accepts any time format that JIRA uses.

=cut

sub set_originalEstimate {
    my $self = shift;
    my $est  = shift;
    $self->update( { originalEstimate => $est } );
}

=method B<set_remainingEstimate>

Sets the remaining estimate to the amount of time given.  Accepts any time format that JIRA uses.

=cut

sub set_remainingEstimate {
    my $self = shift;
    my $est  = shift;
    $self->update( { remainingEstimate => $est } );
}

=method B<update>

Accepts a hashref of timetracking fields to update. The acceptable fields are determined by JIRA, but I think they're originalEstimate and remainingEstimate.

=cut

sub update {
    my $self   = shift;
    my $update = shift;

    foreach my $key ( qw/ originalEstimate remainingEstimate / ) {

        # if we're updating the key, don't change it
        next if exists $update->{$key};

        # since we're not updating the key, copy the original value
        # into the update, because the REST interface has an annoying
        # tendency to reset those values if you don't explicitly set them
        if ( defined $self->data->{$key} ) {
            $update->{$key} = $self->data->{$key};
        }
    }

    $self->issue->put_field( timetracking => $update );
}

1;

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::include_stopwords();
    $OUT .= PodUtil::related_classes($plugin);
}}
