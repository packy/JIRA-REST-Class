package JIRA::REST::Class::Sprint;
use base qw( Class::Accessor );
use strict;
use warnings;
use v5.10;

sub new {
    my $class = shift;
    my $jira  = shift;
    my $data  = shift;
    my $self  = { jira => $jira };

    $data =~ s{com\.atlassian\.greenhopper\.service\.sprint\.Sprint[^\[]+\[}{};
    $data =~ s{\]$}{};
    my @fields = split /,/, $data;
    foreach my $field (@fields) {
        my ($k, $v) = split /=/, $field;
        $self->{$k} = $v;
    }
    $class->mk_ro_accessors(keys %$self);
    return $class->SUPER::new($self);
}

sub sprintlist {
    my $invocant = shift;

    my $class  = ref( $invocant ) ? __PACKAGE__ : $invocant;
    my $jira   = ref( $invocant ) ? $invocant   : shift;
    my $fields = shift;

    my $sprint_field = $jira->field_name('Sprint');

    my @sprints;
    foreach my $sprint ( @{ $fields->{$sprint_field} } ) {
        push @sprints, $class->new($jira, $sprint);
    }
    return @sprints;
}

sub greenhopper_api_url {
    my $self = shift;
    my $url  = $self->jira->rest_api_url_base;
    $url =~ s{/rest/api/.+}{/rest/greenhopper/latest};
    return $url;
}

sub add_issues {
    my $self = shift;
    my $url = join '/', q{},
      'sprint', $self->id, 'issues', 'add';

    my $args = { issueKeys => \@_ };
    my $host = $self->jira->{rest}->getHost;

    $self->jira->{rest}->setHost($self->greenhopper_api_url);
    $self->jira->{rest}->PUT($url, undef, $args);
    $self->jira->_content;
    $self->jira->{rest}->setHost($host);
}

sub remove_issues {
    my $self = shift;
    my $url = join '/', q{},
      'sprint', $self->id, 'issues', 'remove';
    my $args = { issueKeys => \@_ };
    my $host = $self->jira->{rest}->getHost;

    $self->jira->{rest}->setHost($self->greenhopper_api_url);
    $self->jira->{rest}->PUT($url, undef, $args);
    $self->jira->_content;
    $self->jira->{rest}->setHost($host);
}

1;
