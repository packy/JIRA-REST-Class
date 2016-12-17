package JIRA::REST::Class::Issue::Changelog;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents the changelog of a JIRA issue as an object.

__PACKAGE__->mk_contextual_ro_accessors(qw/ changes /);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{data} = $self->issue->get('?expand=changelog');
    my $changes = $self->{changes} = [];

    foreach my $change ( @{ $self->data->{changelog}->{histories} } ) {
        push @$changes, $self->issue->make_object('change', { data => $change });
    }
}

=method B<changes>

Returns a list of individual changes, as C<JIRA::REST::Class::Issue::Changelog::Change> objects.

=cut

1;
