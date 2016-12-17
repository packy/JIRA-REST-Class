package JIRA::REST::Class::Issue::Worklog;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents the worklog of a JIRA issue as an object.

__PACKAGE__->mk_contextual_ro_accessors(qw/ items /);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{data} = $self->issue->get('/worklog');
    my $items = $self->{items} = [];

    foreach my $item ( @{ $self->data->{worklogs} } ) {
        push @$items,  $self->issue->make_object('workitem', { data => $item });
    }
}

=method B<items>

Returns a list of individual work items, as C<JIRA::REST::Class::Issue::Worklog::Item> objects.

=for stopwords worklog

=cut

1;

