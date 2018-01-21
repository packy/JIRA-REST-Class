package JIRA::REST::Class::Project::Category;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.13';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the category of a JIRA project as an object.

__PACKAGE__->mk_data_ro_accessors( qw( description id name self ) );

1;

=accessor B<description>

The description of the project category.

=accessor B<id>

The ID of the project category.

=accessor B<name>

The name of the project category.

=accessor B<self>

Returns the JIRA REST API URL of the project category.

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
