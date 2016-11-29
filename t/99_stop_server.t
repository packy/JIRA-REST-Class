#!perl
use strict;
use warnings;

use File::Basename;
use lib dirname($0).'/lib'; # we keep testing-only modules in a lib under t!
use lib dirname($0).'/../lib'; # the module itself is under here

use Test::More;
use Try::Tiny;

use JIRA::REST::Class::Test;

JIRA::REST::Class::Test->setup_server();

my $pid = JIRA::REST::Class::Test->server_pid();

SKIP: {
    isnt( $pid, undef, 'PID defined for server' );

    like( $pid, qr/^\d+$/, "PID '$pid' is numeric" );

    ok( JIRA::REST::Class::Test->server_is_running(),
        sprintf("server is running on PID %s before shutdown",
                $pid || 'undef' ));

    JIRA::REST::Class::Test->stop_server();

    ok( ! JIRA::REST::Class::Test->server_is_running(),
        'server is not running after shutdown' );
}

done_testing();
exit;
