#!perl
use strict;
use warnings;

use File::Basename;
use lib dirname($0).'/lib'; # we keep testing-only modules in a lib under t!
use lib dirname($0).'/../lib'; # the module itself is under here

use JIRA::REST::Class;
use JIRA::REST::Class::Test;
use List::Util qw( all );
use Try::Tiny;

use Test::More tests => 16;

JIRA::REST::Class::Test->setup_server();

try {
    my $host   = JIRA::REST::Class::Test->server_url();
    my $user   = 'username';
    my $pass   = 'password';
    my $client = JIRA::REST::Class->new($host, $user, $pass);

    validate_contextual_accessor($client, {
        method => 'issue_types',
        class  => 'issuetype',
        data   => [ sort qw/ Bug Epic Improvement Sub-task Story Task /,
                    'New Feature' ],
    });

    print "#\n# Checking the 'Bug' issue type\n#\n";

    my ($bug) = sort $client->issue_types;

    can_ok_abstract( $bug, qw/ description iconUrl id name self subtask / );

    validate_expected_fields( $bug, {
        description => "jira.translation.issuetype.bug.name.desc",
        iconUrl => "$host/secure/viewavatar?size=xsmall&avatarId=10303"
                .  "&avatarType=issuetype",
        id => 10004,
        name => "Bug",
        self => "$host/rest/api/latest/issuetype/10004",
        subtask => JSON::PP::false,
    });
}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    warn "Tests died: $error";
};

JIRA::REST::Class::Test->stop_server();

done_testing();
exit;

