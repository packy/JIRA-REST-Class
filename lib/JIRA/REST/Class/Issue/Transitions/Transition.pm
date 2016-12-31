package JIRA::REST::Class::Issue::Transitions::Transition;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the state transitions a JIRA issue can go through.

__PACKAGE__->mk_ro_accessors( qw/ issue to / );
__PACKAGE__->mk_data_ro_accessors( qw/ id name hasScreen fields / );
__PACKAGE__->mk_field_ro_accessors( qw/ summary / );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    $self->{to} = $self->make_object( 'status', { data => $self->data->{to} } );

    return;
}

#pod =method B<go>
#pod
#pod Perform the transition represented by this object on the issue.
#pod
#pod =cut

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

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik

=head1 NAME

JIRA::REST::Class::Issue::Transitions::Transition - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the state transitions a JIRA issue can go through.

=head1 VERSION

version 0.05

=head1 METHODS

=head2 B<go>

Perform the transition represented by this object on the issue.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue::Status|JIRA::REST::Class::Issue::Status>

=item * L<JIRA::REST::Class::Version|JIRA::REST::Class::Version>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
