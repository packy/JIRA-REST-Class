package JIRA::REST::Class::Project::Component;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.07';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a component of a JIRA project as an object.

__PACKAGE__->mk_data_ro_accessors( qw( id isAssigneeTypeValid name self ) );

1;

=accessor B<id>

The ID of the project category.

=accessor B<isAssigneeTypeValid>

A boolean indicating whether the assignee type is valid.

=accessor B<name>

The name of the project category.

=accessor B<self>

Returns the JIRA REST API URL of the project category.

=for stopwords isAssigneeTypeValid

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
