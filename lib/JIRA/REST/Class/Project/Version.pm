package JIRA::REST::Class::Project::Version;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.05';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

use Readonly;

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a version of a JIRA project as an object.

Readonly my @ACCESSORS => qw( archived id name projectId released self );

__PACKAGE__->mk_data_ro_accessors( @ACCESSORS );

=head1 DESCRIPTION

This object represents a version of JIRA project as an object.  It is
overloaded so it returns the C<name> of the project version when
stringified, the C<id> of the project version when it is used in a numeric
context, and the value of the C<released> field if is used in a boolean
context.  If two of these objects are compared I<as strings>, the C<name> of
the project versions will be used for the comparison, while numeric
comparison will compare the C<id>s of the project versions.

=cut

#<<<
use overload
    '""'   => sub { shift->name    },
    '0+'   => sub { shift->id      },
    'bool' => sub { shift->released },
    '<=>'  => sub {
        my($A, $B) = @_;
        my $AA = ref $A ? $A->id : $A;
        my $BB = ref $B ? $B->id : $B;
        $AA <=> $BB
    },
    'cmp'  => sub {
        my($A, $B) = @_;
        my $AA = ref $A ? $A->name : $A;
        my $BB = ref $B ? $B->name : $B;
        $AA cmp $BB
    };
#>>>

1;

=accessor B<archived>

A boolean indicating whether the version is archived.

=accessor B<id>

The id of the project version.

=accessor B<name>

The name of the project version.

=accessor B<projectId>

The ID of the project this is a version of.

=accessor B<released>

A boolean indicating whether the version is released.

=accessor B<self>

Returns the JIRA REST API URL of the project version.

=for stopwords projectId

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
