package JIRA::REST::Class::Status;
use strict;
use warnings;
use v5.10;

sub new {
    my $class = shift;
    my $self  = shift;

    return bless $self, $class;
}

sub id          { shift->{id}   }
sub name        { shift->{name} }

sub category     { shift->{statusCategory}->{name} }
sub category_id  { shift->{statusCategory}->{id}   }
sub category_key { shift->{statusCategory}->{key}  }

1;
