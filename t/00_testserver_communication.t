#!perl
use strict;
use warnings;

use File::Basename;
use lib dirname($0).'/lib'; # we keep testing-only modules in a lib under t!
use lib dirname($0).'/../lib'; # the module itself is under here

use constant TESTCOUNT => 12;
use JSON;
use Test::More tests => &TESTCOUNT;
use Try::Tiny;

use_ok('JIRA::REST::Class');
use_ok('Test');

Test->setup_server();
my $log = Test->server_log->clone( prefix => "[pid $$] " );

# testing connection to server via JIRA::REST::Class
try {
    my $host   = Test->server_url();
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

    my $pid = Test->server_pid();

    isnt( $pid, undef, 'PID defined for server' );

    like( $pid, qr/^\d+$/, "PID '$pid' is numeric" );

    ok( Test->server_is_running(),
        sprintf("server is running on PID %s",
                $pid || 'undef' ));

    is( Test->test_server(), '{"test":"SUCCESS"}',
        'server test URL works' );

    is( Test->stop_server(), '{"quit":"SUCCESS"}',
        'server stop reports success' );
}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    warn "Tests died: $error";
};

done_testing();
exit;

