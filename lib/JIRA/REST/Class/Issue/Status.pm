package JIRA::REST::Class::Issue::Status;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.11';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the status of a JIRA issue as an object.

__PACKAGE__->mk_ro_accessors( qw/ category / );
__PACKAGE__->mk_data_ro_accessors( qw/ description iconUrl id name self / );
__PACKAGE__->mk_contextual_ro_accessors( qw/ transitions / );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    $self->{category} = $self->make_object(
        'statuscat',
        {
            data => $self->data->{statusCategory}
        }
    );

    return;
}

1;

=method B<description>

Returns the description of the status.

=method B<iconUrl>

Returns the URL of the icon the status.

=method B<id>

Returns the id of the status.

=method B<name>

Returns the name of the status.

=method B<self>

Returns the JIRA REST API URL of the status.

=method B<category>

Returns the category of the status as a
L<JIRA::REST::Class::Issue::Status::Category|JIRA::REST::Class::Issue::Status::Category>
object.

=for stopwords iconUrl

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
