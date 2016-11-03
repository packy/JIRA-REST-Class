package JIRA::REST::Class::Query;
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Issue;

sub new {
    my $class = shift;
    my $jira  = shift;
    my $query = shift;
    my $self  = { jira => $jira, query => $query };
    return bless $self, $class;
}

sub jira { shift->{jira} }

sub issue_count {
    my $self = shift;
    return $self->{query}->{total};
}

sub issues {
    my $self = shift;
    my @issues = map {
        JIRA::REST::Class::Issue->new($self->jira, $_);
    } @{ $self->{query}->{issues} };
    return @issues;
}

1;
