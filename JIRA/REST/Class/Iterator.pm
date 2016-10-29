package JIRA::REST::Class::Iterator;
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Issue;
use Data::Dumper::Concise;

sub new {
    my $class = shift;
    my $jira  = shift;
    my $args  = shift;
    my $self  = { jira => $jira };

    unless (exists $args->{maxResults}) {
        $args->{maxResults} = $jira->maxResults;
    }
    if (exists $args->{restart_if_fetched_ne_total}) {
        $self->{restart_if_fetched_ne_total} =
          $args->{restart_if_fetched_ne_total};
        delete $args->{restart_if_fetched_ne_total};
    }
    $self->{iterator_args} = $args;

    $self = bless $self, $class;

    $self->set_search_iterator($args); # fetch the first bunch of issues

    return $self;
}

sub jira { shift->{jira} }

sub set_search_iterator {
    my $self = shift;
    my $args  = shift;

    $self->jira->set_search_iterator($args);

    # fetch results using code borrowed from JIRA::REST
    my $iter = $self->jira->{iter};
    $iter->{params}{startAt} = $iter->{offset};
    $iter->{results}         = $self->jira->POST('/search', undef,
                                                 $iter->{params});

    # since there seems to be a problem with getting all the results in one
    # search, let's track how many we get so we can re-search if necessary
    $self->{total} = $self->jira->{iter}->{results}->{total};
    $self->{fetched} = 0;
}

sub next {
    my $self = shift;

    my $issue = $self->jira->next_issue;

    if (! $issue && $self->{fetched} < $self->{total} &&
        $self->{restart_if_fetched_ne_total}) {
        # ok, we didn't get as many results as we were promised,
        # so let's try the search again
        $self->set_search_iterator($self->{iterator_args});
        $issue = $self->jira->next_issue;
    }

    if ( $issue ) {
        $self->{fetched}++;
        return JIRA::REST::Class::Issue->new($self->jira, $issue);
    }

    return;
}

sub issue_count {
    my $self = shift;
    return $self->{total};
}

1;
