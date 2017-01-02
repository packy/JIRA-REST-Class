package JIRA::REST::Class::Issue::Comment;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.07';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a comment on a JIRA issue as an object.

use Readonly;

# fields that will be turned into JIRA::REST::Class::User objects
Readonly my @USERS => qw( author updateAuthor );

# fields that will be turned into DateTime objects
Readonly my @DATES => qw( created updated );

__PACKAGE__->mk_ro_accessors( @USERS, @DATES );

__PACKAGE__->mk_data_ro_accessors( qw/ body id self visibility / );

__PACKAGE__->mk_contextual_ro_accessors();

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    # make user objects
    foreach my $field ( @USERS ) {
        $self->populate_scalar_data( $field, 'user', $field );
    }

    # make date objects
    foreach my $field ( @DATES ) {
        $self->{$field} = $self->make_date( $self->data->{$field} );
    }

    return;
}

=method B<delete>

Deletes the comment from the issue. Returns nothing.

=cut

sub delete { ## no critic (ProhibitBuiltinHomonyms)
    my $self = shift;
    $self->issue->delete( '/comment/' . $self->id );

    # now that we've deleted this comment, the
    # lazy accessor will need to be reloaded
    undef $self->issue->{comments};

    return;
}

1;

=accessor B<author>

The author of the comment as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=accessor B<updateAuthor>

The updateAuthor of the comment as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=accessor B<created>

The created date for the comment as a L<DateTime|DateTime> object.

=accessor B<updated>

The updated date for the comment as a L<DateTime|DateTime> object.

=accessor B<body>

The body of the comment as a string.

=accessor B<id>

The ID of the comment.

=accessor B<self>

The full URL for the JIRA REST API call for the comment.

=accessor B<visibility>

A hash reference representing the visibility of the comment.

=for stopwords iconUrl updateAuthor

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
