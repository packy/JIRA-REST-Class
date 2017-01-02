package JIRA::REST::Class::Issue::Changelog;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.07';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the changelog of a JIRA issue as an object.

__PACKAGE__->mk_contextual_ro_accessors( qw/ changes / );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    $self->{data} = $self->issue->get( '?expand=changelog' );
    my $changes = $self->{changes} = [];

    foreach my $change ( @{ $self->data->{changelog}->{histories} } ) {
        push @$changes,
            $self->issue->make_object( 'change', { data => $change } );
    }

    return;
}

=method B<changes>

Returns a list of individual changes, as
L<JIRA::REST::Class::Issue::Changelog::Change|JIRA::REST::Class::Issue::Changelog::Change> objects.

=cut

1;

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
