package JIRA::REST::Class::Issue;
use strict;
use warnings;
use v5.10;

use Data::Dumper::Concise;
use JIRA::REST::Class::Issue::Changelog;
use JIRA::REST::Class::Issue::Transitions;
use JIRA::REST::Class::Sprint;
use JIRA::REST::Class::Status;

sub new {
    my $class = shift;
    my $jira  = shift;
    my $issue = shift;
    my $self  = { issue => $issue, jira => $jira };
    my $host = $jira->{rest}->getHost;
    ($self->{url} = $issue->{self}) =~ s{^$host}{};

    $self = bless $self, $class;

    $self->_define_is_issue_types;

    return $self;
}

sub url    { shift->{url} }
sub jira   { shift->{jira} }
sub issue  { shift->{issue} }
sub id     { shift->issue->{id} }
sub key    { shift->issue->{key} }
sub fields { shift->issue->{fields} }

sub parentkey { shift->fields->{parent}->{key} }

sub dump {
    my $self = shift;
    return $self->key . ' = ' . Dumper($self->issue);
}

sub summary      { shift->fields->{summary} }
sub description  { shift->fields->{description} }
sub project      { shift->fields->{project} }
sub project_key  { shift->project->{key}    }
sub project_name { shift->project->{name}   }

sub status_name { shift->status->{name} }

sub assignee { shift->fields->{assignee}->{name} }
sub assignee_display { shift->fields->{assignee}->{displayName} }

sub reporter { shift->fields->{reporter}->{name} }
sub reporter_display { shift->fields->{reporter}->{displayName} }

sub resolution { shift->fields->{resolution}->{name} }

sub status {
    my $self = shift;
    unless ($self->{status}) {
        $self->{status} = 
          JIRA::REST::Class::Status->new($self->fields->{status});
    }
    return $self->{status};
}

sub changelog {
    my $self = shift;
    unless ($self->{changelog}) {
        $self->{changelog} = JIRA::REST::Class::Issue::Changelog->new($self);
    }
    return $self->{changelog};
}

sub worklog {
    my $self = shift;
    my $data = $self->GET('/worklog');
    return @{ $data->{worklogs} };
}

sub timetracking {
    my $self = shift;
    unless ( $self->fields->{timetracking} ) {
        my $data = $self->GET('', { fields => 'timetracking' });
        $self->fields->{timetracking} = $data->{fields}->{timetracking};
    }
    return $self->fields->{timetracking};
}

sub originalEstimate         { shift->timetracking->{originalEstimate} }
sub remainingEstimate        { shift->timetracking->{remainingEstimate} }
sub originalEstimateSeconds  { shift->timetracking->{originalEstimateSeconds} }
sub remainingEstimateSeconds { shift->timetracking->{remainingEstimateSeconds} }

sub set_original_estimate {
    my $self = shift;
    my $est  = shift;
    $self->put_field( timetracking => { originalEstimate => $est } );
}

sub transitions {
    my $self = shift;
    return JIRA::REST::Class::Issue::Transitions->new($self);
}

sub add_comment {
    my $self = shift;
    my $text = shift;
    $self->POST("/comment", { body => $text });
}

sub labels { @{ shift->fields->{labels} } }

sub add_label {
    my $self  = shift;
    my $label = shift;
    $self->update( labels => [ { add => $label } ] );
}

sub remove_label {
    my $self  = shift;
    my $label = shift;
    $self->update( labels => [ { remove => $label } ] );
}

sub add_component {
    my $self = shift;
    my $comp = shift;
    $self->update( components => [ { add => { name => $comp } } ] );
}

sub remove_component {
    my $self = shift;
    my $comp = shift;
    $self->update( components => [ { remove => { name => $comp } } ] );
}

sub set_assignee {
    my $self = shift;
    my $name = shift;
    $self->put_field(assignee => { name => $name });
}

sub set_reporter {
    my $self = shift;
    my $name = shift;
    $self->put_field(reporter => { name => $name });
}

sub add_issue_link {
    my $self = shift;
    my $type = shift;
    my $key  = shift;
    my $links = [{
        add => {
            type        => { name => $type },
            inwardIssue => { key => $key },
        },
    }];
    $self->update( issuelinks => $links );
}

sub issuelinks {
    my $self = shift;
    my $links = $self->fields->{issuelinks};
    return unless ref $links eq 'ARRAY';
    return @$links;
}

sub add_subtask {
    my $self    = shift;
    my $summary = shift;
    my $desc    = shift;
    my $fields  = shift;

    my $data = {
        fields => {
            project     => { key => $self->project->{key} },
            parent      => { key => $self->key },
            summary     => $summary,
            description => $desc,
            issuetype   => { id => 8 }
        }
    };

    if ($fields) {
        foreach my $field (keys %$fields) {
            $data->{fields}->{$field} = $fields->{$field};
        }
    }

    my $result  = $self->jira->POST('issue', undef, $data);

    my $issue = $self->jira->GET('issue/'.$result->{id});

    return JIRA::REST::Class::Issue->new($self->jira, $issue);
}

sub update {
    my $self  = shift;
    my $hash = {};
    while (@_) {
        my $field = shift;
        my $value = shift;
        $hash->{$field} = $value;
    }
    $self->PUT({
        update => $hash,
    });
}

sub put_field {
    my $self  = shift;
    my $field = shift;
    my $value = shift;
    $self->PUT({
        fields => { $field => $value },
    });
}

sub reload {
    my $self = shift;
    $self->{issue} = $self->GET;
    # remove lazy loading cache data
    delete $self->{status};
    delete $self->{changelog};
}

sub GET {
    my $self  = shift;
    my $extra = shift // q{};
    $self->jira->GET($self->url . $extra, @_);
}

sub DELETE {
    my $self  = shift;
    my $extra = shift // q{};
    $self->jira->GET($self->url . $extra, @_);
}

sub PUT {
    my $self = shift;
    $self->jira->PUT($self->url, undef, @_);
}

sub POST {
    my $self = shift;
    my $extra = shift // q{};
    $self->jira->POST($self->url . $extra, undef, @_);
}

sub sprints {
    my $self = shift;
    return JIRA::REST::Class::Sprint->sprintlist($self->jira,
                                                 $self->fields);
}

sub children {
    my $self = shift;
    my $key  = $self->key;
    my $children = $self->jira->query({
        jql => qq{issueFunction in subtasksOf("key = $key")}
    });

    return unless $children->issue_count;
    return $children->issues;
}

sub _define_is_issue_types {
    my $self = shift;
    my @types = $self->jira->issue_types;

    foreach my $name ( @types ) {
        (my $sub = lc "is_$name") =~ s/\s+|\-/_/g;

        no strict 'refs';
        next if exists &$sub;
        *{$sub} = sub {
            shift->fields->{issuetype}->{name} eq $name;
        };
    }
}


###########################################################################

sub start_progress {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('In Progress', {
        'Open'        => 'In Progress',
        'Reopened'    => 'In Progress',
        'In QA'       => 'In Progress',
        'Blocked'     => 'In Progress',
        'Resolved'    => 'Reopened',
        'Verified'    => 'Reopened',
        'Closed'      => 'Reopened',
    }, $callback);
}

sub start_qa {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('In QA', {
        'Open'        => 'In Progress',
        'In Progress' => 'Resolved',
        'Reopened'    => 'Resolved',
        'Resolved'    => 'In QA',
        'Blocked'     => 'In QA',
        'Verified'    => 'Reopened',
        'Closed'      => 'Reopened',
    }, $callback);
}

sub resolve {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('Resolved', {
        'Open'        => 'In Progress',
        'In Progress' => 'Resolved',
        'Reopened'    => 'Resolved',
        'Blocked'     => 'In Progress',
        'In QA'       => 'In Progress',
        'Verified'    => 'Reopened',
        'Closed'      => 'Reopened',
    }, $callback);
}

sub to_open {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('Open', {
        'In Progress' => 'Open',
        'Reopened'    => 'In Progress',
        'Blocked'     => 'In Progress',
        'In QA'       => 'In Progress',
        'Resolved'    => 'Reopened',
        'Verified'    => 'Reopened',
        'Closed'      => 'Reopened',
    }, $callback);
}

sub close {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('Closed', {
        'Open'        => 'In Progress',
        'In Progress' => 'Resolved',
        'Reopened'    => 'Resolved',
        'Blocked'     => 'In Progress',
        'In QA'       => 'Verified',
        'Resolved'    => 'Closed',
        'Verified'    => 'Closed',
    }, $callback);
}


1;
