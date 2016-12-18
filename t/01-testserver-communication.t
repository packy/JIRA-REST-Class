#!perl
use strict;
use warnings;

use File::Basename;
use lib dirname($0);

use constant TESTCOUNT => 11;
use JSON;
use Test::More tests => &TESTCOUNT;
use Try::Tiny;

use MyTest;

use_ok('JIRA::REST::Class');

TestServer_setup();
my $log = TestServer_log->clone( prefix => "[pid $$] " );

# testing connection to server via JIRA::REST::Class
try {
    my $host   = TestServer_url();
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

    my $pid = TestServer_pid();

    isnt( $pid, undef, 'PID defined for server' );

    like( $pid, qr/^\d+$/, "PID '$pid' is numeric" );

    ok( TestServer_is_running(),
        sprintf("server is running on PID %s",
                $pid || 'undef' ));

    is( TestServer_test(), '{"GET":"SUCCESS"}',
        'server test URL works' );

    is( TestServer_stop(), '{"quit":"SUCCESS"}',
        'server stop reports success' );
}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    warn "Tests died: $error";
};

done_testing();
exit;
