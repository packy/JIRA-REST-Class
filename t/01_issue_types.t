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
    my @data = sort qw/ Bug Epic Improvement Sub-task Story Task /,
        'New Feature';

    my $class = 'JIRA::REST::Class::Issue::Type';
    my $method = 'JIRA::REST::Class->issue_types';

    #
    # run some tests
    #
    my $scalar = $client->issue_types;

    is( ref $scalar, 'ARRAY',
        "$method in scalar context returns arrayref" );

    cmp_ok( @$scalar, '==', @data,
            "$method arrayref has correct number of items" );

    my @list = $client->issue_types;

    cmp_ok( @list, '==', @data, "$method returns a list of ".
            "correct size in list context");

    subtest "Checking object types returned by $method", sub {
        foreach my $type ( sort @list ) {
            isa_ok( $type, $class, "$type" );
        }
    };

    my $list = [ map { "$_" } sort @list ];
    is_deeply( $list, \@data,
               "$method returns the expected issue types")
        or dump_got_expected($list, \@data);

    can_ok_abstract( $list[0], qw/ description iconUrl id name self subtask / );

}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    warn "Tests died: $error";
};

JIRA::REST::Class::Test->stop_server();

done_testing();
exit;

