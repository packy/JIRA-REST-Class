package JIRA::REST::Class::Query;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA query as an object.  Attempts to return an array of all results from the query.

=method B<issue_count>

A count of the number of issues matched by the query.

=cut

sub issue_count { return shift->data->{total} }

=method B<issues>

Returns a list of L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue>
objects matching the query.

=cut

sub issues {
    my $self   = shift;
    my @issues = map {  #
        $self->make_object( 'issue', { data => $_ } );
    } @{ $self->data->{issues} };
    return @issues;
}

1;

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
