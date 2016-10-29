package JIRA::REST::Class::Issue::Changelog;
use strict;
use warnings;
use v5.10;

sub new {
    my $class = shift;
    my $issue = shift;
    my $jira  = $issue->jira;
    my $self  = { issue => $issue, jira => $jira };

    my $data = $issue->GET('?expand=changelog');
    foreach my $change ( @{ $data->{changelog}->{histories} } ) {
        push @{ $self->{changes} },
          JIRA::REST::Class::Issue::Changelog::Change->new($change);
    }

    return bless $self, $class;
}

sub changes {
    my $self = shift;
    return @{ $self->{changes} };
}

package JIRA::REST::Class::Issue::Changelog::Change;
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::User;
use DateTime::Format::Strptime;

my $parser = DateTime::Format::Strptime->new( pattern => '%FT%T.%N%Z' );


sub new {
    my $class  = shift;
    my $change = shift;
    my $self   = { };

    $self->{author} = JIRA::REST::Class::User->new($change->{author});

    $self->{created} = $parser->parse_datetime($change->{created});

    foreach my $field ( qw/ id items / ) {
        $self->{$field} = $change->{$field};
    }

    return bless $self, $class;
}

sub created { shift->{created} }
sub author  { shift->{author} }

1;
