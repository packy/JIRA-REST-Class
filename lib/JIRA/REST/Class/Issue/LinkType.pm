package JIRA::REST::Class::Issue::LinkType;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for L<JIRA::REST::Class> that represents a JIRA link type as an object.

__PACKAGE__->mk_data_ro_accessors(qw( id name inward outward self ));

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
