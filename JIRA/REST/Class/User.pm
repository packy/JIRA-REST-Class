package JIRA::REST::Class::User;
use strict;
use warnings;
use v5.10;

sub new {
    my $class = shift;
    my $self  = shift;

    return bless $self, $class;
}

sub displayName { shift->{displayName} }
sub name        { shift->{name}        }

1;
