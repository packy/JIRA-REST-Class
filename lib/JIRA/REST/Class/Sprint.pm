package JIRA::REST::Class::Sprint;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents the sprint of a JIRA issue as an object.

__PACKAGE__->mk_ro_accessors(qw/ id rapidViewId state name startDate endDate
                                 completeDate sequence /);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $data = $self->data;
    $data =~ s{com\.atlassian\.greenhopper\.service\.sprint\.Sprint[^\[]+\[}{};
    $data =~ s{\]$}{};
    my @fields = split /,/, $data;
    foreach my $field (@fields) {
        my ($k, $v) = split /=/, $field;
        if ($v && $v eq '<null>') {
            undef $v;
        }
        $self->{$k} = $v;
    }
}

1;

=accessor B<id>

=accessor B<rapidViewId>

=accessor B<state>

=accessor B<name>

=accessor B<startDate>

=accessor B<endDate>

=accessor B<completeDate>

=accessor B<sequence>

=cut

__END__

# These methods don't work, probably because JIRA doesn't have a well-defined
# interface for adding/removing issues from a sprint.

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
