package JIRA::REST::Class::Issue::Type;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for L<JIRA::REST::Class> that represents a JIRA issue type as an object.

use Readonly;

Readonly my @ACCESSORS => qw( description iconUrl id name self subtask );

__PACKAGE__->mk_data_ro_accessors( @ACCESSORS );

=head1 DESCRIPTION

This object represents a type of JIRA issue as an object.  It is overloaded
so it returns the C<key> of the issue type when stringified, the C<id> of
the issue type when it is used in a numeric context, and the value of the
C<subtask> field if is used in a boolean context.  If two of these objects
are compared I<as strings>, the C<key> of the issue types will be used for
the comparison, while numeric comparison will compare the C<id>s of the
issue types.

=cut

#<<<
use overload
    '""'   => sub { shift->name    },
    '0+'   => sub { shift->id      },
    'bool' => sub { shift->subtask },
    '<=>'  => sub {
        my( $A, $B ) = @_;
        my $AA = ref $A ? $A->id : $A;
        my $BB = ref $B ? $B->id : $B;
        $AA <=> $BB
    },
    'cmp'  => sub {
        my( $A, $B ) = @_;
        my $AA = ref $A ? $A->name : $A;
        my $BB = ref $B ? $B->name : $B;
        $AA cmp $BB
    };
#>>>

1;

=accessor B<description>

Returns the description of the issue type.

=accessor B<iconUrl>

Returns the URL of the icon the issue type.

=accessor B<id>

Returns the id of the issue type.

=accessor B<name>

Returns the name of the issue type.

=accessor B<self>

Returns the JIRA REST API URL of the issue type.

=accessor B<subtask>

Returns a boolean indicating whether the issue type is a subtask.

=for stopwords iconUrl

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
