package JIRA::REST::Class::Issue::Type;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents a JIRA issue type as an object.

__PACKAGE__->mk_data_ro_accessors(qw/ description iconUrl id name self subtask /);

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
