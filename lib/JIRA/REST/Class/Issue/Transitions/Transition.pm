package JIRA::REST::Class::Issue::Transitions::Transition;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents the state transitions a JIRA issue can go through.

__PACKAGE__->mk_ro_accessors(qw/ issue to /);
__PACKAGE__->mk_data_ro_accessors(qw/ id name hasScreen fields /);
__PACKAGE__->mk_field_ro_accessors(qw/ summary /);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{to} = $self->make_object('status', { data => $self->data->{to} });
}

=method B<go>

Perform the transition represented by this object on the issue.

=cut

sub go {
    my $self = shift;
    $self->issue->post("/transitions", {
        transition => { id => $self->id }, @_
    });

    # reload the issue's transitions, since these have now changed
    $self->issue->transitions->init($self->factory);
}

1;
