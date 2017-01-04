package JIRA::REST::Class::Issue::LinkType;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA link type as an object.

__PACKAGE__->mk_data_ro_accessors( qw( id name inward outward self ) );

1;

=accessor B<id>

The id of the link type.

=accessor B<name>

The name of the link type.

=accessor B<inward>

The text for the inward name of the link type.

=accessor B<outward>

The text for the outward name of the link type.

=accessor B<self>

The full URL for the JIRA REST API call for the link type.

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
