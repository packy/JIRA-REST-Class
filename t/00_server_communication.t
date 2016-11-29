#!perl
use strict;
use warnings;

use File::Basename;
use lib dirname($0).'/lib'; # we keep testing-only modules in a lib under t!
use lib dirname($0).'/../lib'; # the module itself is under here

use constant TESTCOUNT => 7;
use Test::More tests => &TESTCOUNT;
use Try::Tiny;

use JIRA::REST::Class::Test;

JIRA::REST::Class::Test->process_commandline();

JIRA::REST::Class::Test->check_prereqs();

SKIP: {
    skip('test prereqs not met', &TESTCOUNT)
        unless JIRA::REST::Class::Test->run_tests;

    use_ok('JIRA::REST::Class');
    use_ok('JIRA::REST::Class::TestServer');

    JIRA::REST::Class::Test->setup_server();

    # testing connection to server via JIRA::REST::Class
    try {
        my $host   = JIRA::REST::Class::Test->server_url();
        my $user   = 'username';
        my $pass   = 'password';
        my $client = JIRA::REST::Class->new($host, $user, $pass);

        ok( $client, qq{client returned from new()} );
        ok(
            ref($client) && ref($client) eq 'JIRA::REST::Class',
            "client is blessed as JIRA::REST::Class"
        );

        is( $client->url, $host,
            "client->url returns JIRA url");

        is( $client->username, $user,
            "client->username returns JIRA username");

        is( $client->password, $pass,
            "client->password returns JIRA password");
    }
    catch {
        my $error = $_;  # Try::Tiny puts the error in $_
        warn "Tests died: $error";
    };

}

done_testing();
exit;

