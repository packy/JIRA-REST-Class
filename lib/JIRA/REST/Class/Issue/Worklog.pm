package JIRA::REST::Class::Issue::Worklog;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the worklog of a JIRA issue as an object.

__PACKAGE__->mk_contextual_ro_accessors( qw/ items / );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    $self->{data} = $self->issue->get( '/worklog' );
    my $items = $self->{items} = [];

    foreach my $item ( @{ $self->data->{worklogs} } ) {
        push @$items,
            $self->issue->make_object( 'workitem', { data => $item } );
    }

    return;
}

=method B<items>

Returns a list of individual work items, as
L<JIRA::REST::Class::Issue::Worklog::Item|JIRA::REST::Class::Issue::Worklog::Item>
objects.

=for stopwords worklog

=cut

1;

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
