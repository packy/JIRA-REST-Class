package JIRA::REST::Class::Sprint;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the sprint of a JIRA issue as an object (if you're using L<Atlassian GreenHopper|https://www.atlassian.com/software/jira/agile>).

use Readonly 2.04;

Readonly my @ACCESSORS => qw( id rapidViewId state name startDate endDate
                              completeDate sequence );

__PACKAGE__->mk_ro_accessors( @ACCESSORS );

Readonly my $GREENHOPPER_SPRINT => qr{ com [.] atlassian [.] greenhopper [.]
                                       service [.] sprint [.] Sprint }x;

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    my $data = $self->data;
    $data =~ s{ $GREENHOPPER_SPRINT [^ \[ ]+ \[ }{}x;
    $data =~ s{\]$}{}x;
    my @fields = split /,/, $data;
    foreach my $field ( @fields ) {
        my ( $k, $v ) = split /=/, $field;
        if ( $v && $v eq '<null>' ) {
            undef $v;
        }
        $self->{$k} = $v;
    }

    return;
}

1;

__END__

=accessor B<id>

=accessor B<rapidViewId>

=accessor B<state>

=accessor B<name>

=accessor B<startDate>

=accessor B<endDate>

=accessor B<completeDate>

=accessor B<sequence>

=cut

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::include_stopwords();
    $OUT .= PodUtil::related_classes($plugin);
}}

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
