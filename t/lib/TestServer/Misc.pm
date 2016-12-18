package TestServer::Misc;
use base qw( TestServer::Plugin );
use strict;
use warnings;
use v5.10;

use JSON::PP;

sub import {
    my $class = __PACKAGE__;
    $class->register_dispatch(
        '/test' => sub { $class->test(@_) },
        '/quit' => sub { $class->quit(@_) },
        '/rest/api/latest/configuration' =>
            sub { $class->configuration_response(@_) },
    );
}

sub test {
    my ( $class, $server, $cgi ) = @_;
    $class->response($server, { test => 'SUCCESS' });
}

sub quit {
    my ( $class, $server, $cgi ) = @_;
    $class->response($server, { quit => 'SUCCESS' });
    exit;
}

sub configuration_response {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    $class->response($server, $class->configuration_data($server, $cgi));
}

sub configuration_data {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    return {
      attachmentsEnabled => JSON::PP::true,
      issueLinkingEnabled => JSON::PP::true,
      subTasksEnabled => JSON::PP::true,
      timeTrackingConfiguration => {
        defaultUnit => "minute",
        timeFormat => "pretty",
        workingDaysPerWeek => 5,
        workingHoursPerDay => 8
      },
      timeTrackingEnabled => JSON::PP::true,
      unassignedIssuesAllowed => JSON::PP::true,
      votingEnabled => JSON::PP::true,
      watchingEnabled => JSON::PP::true
    };
}

1;
