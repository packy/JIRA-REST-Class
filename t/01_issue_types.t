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

SKIP: {
    skip('test prereqs not met') unless JIRA::REST::Class::Test->run_tests;

    try {
        my $host   = JIRA::REST::Class::Test->server_url();
        my $user   = 'username';
        my $pass   = 'password';
        my $client = JIRA::REST::Class->new($host, $user, $pass);

        # comparison data
        my @types = sort qw/ Bug Epic Improvement Sub-task Story Task /,
            'New Feature';

        my $type_count = scalar @types;

        my $type_class = 'JIRA::REST::Class::Issue::Type';

        # make the calls and get results
        my $scalar_types = $client->issue_types;

        my $scalar_types_is_arrayref = ref_is_array($scalar_types);

        my $scalar_types_has_correct_count =
            $scalar_types_is_arrayref && @$scalar_types == $type_count;

        my @list_types = $client->issue_types;

        my $list_types_is_array = @list_types > 1;

        my $list_types_has_correct_count = @list_types == $type_count;

        my $all_blessed = all { ref_is_class($_, $type_class) } @list_types;

        my @list_type_names = sort map {
            ref_is_class($_, $type_class) ? $_->name : $_
        } @list_types;

        # report the results
        report(
            expr => $scalar_types_is_arrayref,
            ok   => "issue_types returns arrayref in scalar context",
            nok  => "issue_types returns $scalar_types in scalar context",
        );

        report(
            expr => $scalar_types_has_correct_count,
            ok   => "issue_types arrayref has $type_count items",
            nok  => "in scalar context, issue_types returns:"
                 .  chomper($scalar_types),
        );

        report(
            expr => $list_types_is_array,
            ok   => "issue_types returns a list of correct size "
                 .  "in list context",
            nok  => "in list context, issue_types returns: "
                 .  chomper(\@list_types),
        );

        report(
            expr => $all_blessed,
            ok => "all issues blessed into ".$type_class,
            nok => sub {
                my @bad = grep {
                    blessed $_ && blessed $_ eq $type_class
                } @list_types;

                "some issues not blessed as $type_class: "
                    . chomper(\@bad)
            }
        );

        is_deeply( \@list_type_names, \@types,
                   "issue_types returns the expected issue types");

    }
    catch {
        my $error = $_;  # Try::Tiny puts the error in $_
        warn "Tests died: $error";
    };
}

done_testing();
exit;

