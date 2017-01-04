package JIRA::REST::Class::Issue::Status::Category;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.09';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the category of an issue's status.

__PACKAGE__->mk_data_ro_accessors( qw/ name colorName id key self / );

1;

=accessor id

The id of the status category.

=accessor key

The key of the status category.

=accessor name

The name of the status category.

=accessor colorName

The color name of the status category.

=accessor self

The full URL for the JIRA REST API call for the status category.

=for stopwords colorName

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
