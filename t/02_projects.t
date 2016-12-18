#!perl
use strict;
use warnings;

use File::Basename;
use lib dirname($0).'/lib'; # we keep testing-only modules in a lib under t!
use lib dirname($0).'/../lib'; # the module itself is under here

use JIRA::REST::Class;
use Test;
use JSON;
use List::Util qw( all );
use Try::Tiny;

use Test::More tests => 22;

Test->setup_server();

try {
    my $host   = Test->server_url();
    my $user   = 'username';
    my $pass   = 'password';
    my $client = JIRA::REST::Class->new($host, $user, $pass);

    # project list

    validate_contextual_accessor($client, {
        method => 'projects',
        class  => 'project',
        data   => [ qw/ JRC KANBAN PACKAY PM SCRUM / ],
    });

    # SCRUM project
    print "#\n# Checking the SCRUM project\n#\n";

    my $proj  = $client->project('SCRUM');

    can_ok_abstract( $proj, qw/ avatarUrls expand id key name self
                                category assigneeType components
                                description issueTypes lead roles versions
                                allowed_components allowed_versions
                                allowed_fix_versions allowed_issue_types
                                allowed_priorities allowed_field_values
                                field_metadata_exists field_metadata
                                field_name
                              / );

    validate_expected_fields( $proj, {
        expand => "description,lead,url,projectKeys",
        id => 10002,
        key => 'SCRUM',
        name => "Scrum Software Development Sample Project",
        projectTypeKey => "software",
        lead => {
            class => 'user',
            expected => {
                key => 'packy'
            },
        },
    });

    validate_contextual_accessor($proj, {
        method => 'versions',
        class  => 'projectvers',
        name   => "SCRUM project's",
        data   => [ "Version 1.0", "Version 2.0", "Version 3.0" ],
    });

}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    warn "Tests died: $error";
};


Test->stop_server();

done_testing();
exit;

