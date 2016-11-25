package JIRA::REST::Class::Issue::LinkType;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents a JIRA link type as an object.

__PACKAGE__->mk_data_ro_accessors(qw( id name inward outward self ));

1;

=method B<id>

The id of the link type.

=method B<name>

The name of the link type.

=method B<inward>

The text for the inward name of the link type.

=method B<outward>

The text for the outward name of the link type.

=method B<self>

The full URL for the JIRA REST API call for the link type.
