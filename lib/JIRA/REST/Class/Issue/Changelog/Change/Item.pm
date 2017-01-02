package JIRA::REST::Class::Issue::Changelog::Change::Item;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.05';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual item in an individual change to a JIRA issue as an object.

__PACKAGE__->mk_data_ro_accessors(
    qw/ field fieldtype from fromString to toString / ##
);

1;

=accessor B<field>

=accessor B<fieldtype>

=accessor B<from>

=accessor B<fromString>

=accessor B<to>

=accessor B<toString>

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::include_stopwords();
    $OUT .= PodUtil::related_classes($plugin);
}}
