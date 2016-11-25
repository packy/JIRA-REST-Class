package JIRA::REST::Class::Issue::Changelog::Change;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents an individual change to a JIRA issue as an object.

__PACKAGE__->mk_ro_accessors(qw/ author created /);
__PACKAGE__->mk_data_ro_accessors(qw/ id /);
__PACKAGE__->mk_contextual_ro_accessors(qw/ items /);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # make user object
    $self->populate_scalar_data('author', 'user', 'author');

    # make date object
    $self->populate_date_data('created', 'created');

    # make list of changed items
    $self->populate_list_data('items', 'changeitem', 'items');
}

1;

=accessor B<author>
Returns the author of a JIRA issue's change as a C<JIRA::REST::Class::User> object.

=accessor B<created>
Returns the creation time of a JIRA issue's change as a C<DateTime> object.

=accessor B<id>
Returns the id of a JIRA issue's change.

=accessor B<items>
Returns the list of items modified by a JIRA issue's change as a list of C<JIRA::REST::Class::Issue::Changelog::Change::Item> objects.
