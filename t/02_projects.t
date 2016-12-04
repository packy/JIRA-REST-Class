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

    #
    # comparison data
    #
    my @data = qw/ JRC KANBAN PACKAY PM SCRUM /;

    my $class  = get_class('project');
    my $method = get_class('class').'->projects';

    #
    # run some tests
    #
    my $scalar = $client->projects;

    print "# Checking the $method accessor\n";

    is( ref $scalar, 'ARRAY',
        "$method in scalar context returns arrayref" );

    cmp_ok( @$scalar, '==', @data,
            "$method arrayref has correct number of items" );

    my @list = $client->projects;

    cmp_ok( @list, '==', @data, "$method returns correct size list ".
            "in list context");

    subtest "Checking object types returned by $method", sub {
        foreach my $item ( sort @list ) {
            isa_ok( $item, $class, "$item" );
        }
    };

    my $list = [ map { "$_" } sort @list ];
    is_deeply( $list, \@data,
               "$method returns the expected projects")
        or dump_got_expected($list, \@data);

    can_ok_abstract( $list[0], qw/ avatarUrls expand id key name self
                                   category assigneeType components description
                                   issueTypes lead roles versions
                                   allowed_components allowed_versions
                                   allowed_fix_versions allowed_issue_types
                                   allowed_priorities allowed_field_values
                                   field_metadata_exists field_metadata
                                   field_name
                                 / );
    print "# Checking the SCRUM project\n";
    my $proj = $client->project('SCRUM');

    my %expected = (
        expand => "description,lead,url,projectKeys",
        id => 10002,
        key => 'SCRUM',
        name => "Scrum Software Development Sample Project",
        projectTypeKey => "software",
    );

    foreach my $field ( sort keys %expected ) {
        my $value  = $expected{$field};
        my $quoted = ($value =~ /^\d+$/) ? $value : qq{'$value'};

        is( $proj->$field, $value, "$field() method returns $quoted");
    }

    isa_ok( $proj->lead,        get_class('user'),    $class.'->lead');
    is( $proj->lead->key,       'packy', $class.q{->lead->key is 'packy'});

    isa_ok( $proj->factory,     get_class('factory'), $class.'->factory');

    isa_ok( $proj->jira,        get_class('class'),   $class.'->jira');

    isa_ok( $proj->JIRA_REST,   'JIRA::REST',         $class.'->JIRA_REST');

    isa_ok( $proj->REST_CLIENT, 'REST::Client',       $class.'->REST_CLIENT');

    print "# Checking the SCRUM project's versions() accessor \n";

    @data = ("Version 1.0", "Version 2.0", "Version 3.0");
    $method = $class.'->versions';
    $class  = get_class('projectvers');

    $scalar = $proj->versions;

    is( ref $scalar, 'ARRAY',
        "$method in scalar context returns arrayref" );

    cmp_ok( @$scalar, '==', @data,
            "$method arrayref has correct number of items" );

    my @list = $proj->versions;

    cmp_ok( @list, '==', @data, "$method returns correct size list ".
            "in list context");

    subtest "Checking object types returned by $method", sub {
        foreach my $item ( sort @list ) {
            isa_ok( $item, $class, "$item" );
        }
    };

    my $list = [ map { "$_" } sort @list ];
    is_deeply( $list, \@data,
               "$method returns the expected versions")
        or dump_got_expected($list, \@data);

}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    warn "Tests died: $error";
};


JIRA::REST::Class::Test->stop_server();

done_testing();
exit;

