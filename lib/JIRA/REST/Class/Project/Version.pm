package JIRA::REST::Class::Project::Version;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents a version of a JIRA project as an object.

__PACKAGE__->mk_data_ro_accessors(qw/ archived id name projectId released self /);

use overload
    '""'   => sub { shift->name    },
    '0+'   => sub { shift->id      },
    'bool' => sub { shift->subtask },
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
