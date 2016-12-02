#!perl
use strict;
use warnings;

use File::Basename;
use lib dirname($0).'/lib'; # we keep testing-only modules in a lib under t!
use lib dirname($0).'/../lib'; # the module itself is under here

use JIRA::REST::Class;
use JIRA::REST::Class::Test;
use List::Util qw( all );
use Test::More;
use Try::Tiny;

JIRA::REST::Class::Test->setup_server();

try {
    my $host   = JIRA::REST::Class::Test->server_url();
    my $user   = 'username';
    my $pass   = 'password';
    my $client = JIRA::REST::Class->new($host, $user, $pass);

    # comparison data
    my @projects = qw/ JRC KANBAN PACKAY PM SCRUM /;

    my $proj_count = scalar @projects;

    my $proj_class = 'JIRA::REST::Class::Project';

    # make the calls and get results
    my $scalar_proj = $client->projects;

    my $scalar_proj_is_arrayref = ref_is_array($scalar_proj);

    my $scalar_proj_has_correct_count =
        $scalar_proj_is_arrayref && @$scalar_proj == $proj_count;

    my @list_proj = $client->projects;

    my $list_proj_is_array = @list_proj > 1;

    my $list_proj_has_correct_count = @list_proj == $proj_count;

    my $all_blessed = all { ref_is_class($_, $proj_class) } @list_proj;

    my @list_proj_keys = sort map {
        ref_is_class($_, $proj_class) ? $_->key : $_
    } @list_proj;

    # report the results
    report(
        expr => $scalar_proj_is_arrayref,
        ok   => "projects returns arrayref in scalar context",
        nok  => "projects returns $scalar_proj in scalar context",
    );

    report(
        expr => $scalar_proj_has_correct_count,
        ok   => "projects arrayref has $proj_count items",
        nok  => "in scalar context, projects returns:"
             .  chomper($scalar_proj),
    );

    report(
        expr => $list_proj_is_array,
        ok   => "projects returns a list of correct size "
             .  "in list context",
        nok  => "in list context, projects returns: "
             .  chomper(\@list_proj),
    );

    report(
        expr => $all_blessed,
        ok => "all issues blessed into ".$proj_class,
        nok => sub {
            my @bad = grep {
                blessed $_ && blessed $_ eq $proj_class
            } @list_proj;

            "some issues not blessed as $proj_class: " . chomper(\@bad)
        }
    );

    is_deeply( \@list_proj_keys, \@projects,
               "projects returns the expected project keys");

}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    warn "Tests died: $error";
};


JIRA::REST::Class::Test->stop_server();

done_testing();
exit;

