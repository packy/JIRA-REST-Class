#!perl
use strict;
use warnings;

use File::Basename;
use lib dirname($0).'/lib'; # we keep testing-only modules in a lib under t!
use lib dirname($0).'/../lib'; # the module itself is under here

use constant TESTCOUNT => 11;
use JSON;
use Test::More tests => &TESTCOUNT;
use Try::Tiny;

my $bail;
try {
    die "HTTP::Server::Simple misbehaves on Windows" if $^O =~ /MSWin/;
    require HTTP::Server::Simple;
}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    $bail = "Won't run tests because: $error";
};

BAIL_OUT($bail) if $bail;

use_ok('JIRA::REST::Class');
use_ok('JIRA::REST::Class::Test');

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

    my $pid = JIRA::REST::Class::Test->server_pid();

    isnt( $pid, undef, 'PID defined for server' );

    like( $pid, qr/^\d+$/, "PID '$pid' is numeric" );

    ok( JIRA::REST::Class::Test->server_is_running(),
        sprintf("server is running on PID %s before shutdown",
                $pid || 'undef' ));

    JIRA::REST::Class::Test->stop_server();

    ok( ! JIRA::REST::Class::Test->server_is_running(),
        'server is not running after shutdown' );
}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    warn "Tests died: $error";
};

done_testing();
exit;

