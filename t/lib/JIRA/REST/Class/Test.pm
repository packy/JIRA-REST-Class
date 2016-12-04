package JIRA::REST::Class::Test;
use base qw( Exporter );
use strict;
use warnings;
use v5.10;

use Data::Dumper::Concise;
use File::Slurp;
use File::Spec::Functions;
use Getopt::Long;
use Scalar::Util qw( blessed reftype );
use Test::More;
use Try::Tiny;

use JIRA::REST::Class::TestServer;

our @EXPORT = qw( chomper can_ok_abstract dump_got_expected get_class );

###########################################################################
#
# support for starting the test server
#

my $port    = 7657;
my $tmpdir  = '/tmp';
my $pidfile = 'jira_rest_class_test.pid';
my $pidpath;
my $log;
my $pid;

sub process_commandline {
    unless (defined $pidpath) {
        GetOptions
            'port=i'    => \$port,
            'pidfile=s' => \$pidfile,
            'tmpdir=s'  => sub {
                my(undef, $value) = @_;
                if (-d $value && -w $value) {
                    $tmpdir = $value;
                    return;
                }
                elsif (! -d $value) {
                    die "$value is not a directory/n";
                }
                elsif (! -w $value) {
                    die "$value is not writable/n";
                }
            };

        get_pid();
    }
}

sub get_pid {
    $pidpath = catfile $tmpdir, $pidfile
        unless defined $pidpath;

    if ( -f $pidpath && -s $pidpath ) {
        $pid = read_file($pidpath);
        chomp $pid;
    }
}

sub setup_server {
    process_commandline();
    get_pid();
    server_log();

    # if the server is already running, return
    if ( server_is_running() ) {
        $log->info('server already running on PID '.$pid);
        return;
    }

    try {
        # start the server
        $log->info('starting server and sending to background');
        $pid = JIRA::REST::Class::TestServer->new($port)->background();
        write_file($pidpath, "$pid\n") if $pid;
    };
    if ((! defined $pid) || $$ == $pid) { exit }
    $log->info("[$$] started server on PID ".$pid);
}

sub server_log {
    unless (defined $log) {
        $log = JIRA::REST::Class::TestServer->get_logger();
    }
    return $log;
}

sub server_pid {
    get_pid();
    return $pid;
}

sub server_is_running {
    return unless defined $pid && $pid =~ /^\d+$/;
    kill 0, $pid;
}

sub stop_server {
    get_pid();
    server_log()->info('stopping server on PID '.$pid);
    kill 15, $pid;  # tell the server to stop

    # remove the temp file
    $pidpath = catfile $tmpdir, $pidfile;
    if ( -f $pidpath ) {
        unlink $pidpath;
    }

    undef $pid;
}

sub server_url {
    return "http://localhost:$port";
}

###########################################################################
#
# functions to make the testing easier
#

sub chomper {
    my $thing = Dumper( @_ );
    chomp $thing;
    return $thing;
}

sub dump_got_expected {
    my $out = '# got = ' . Dumper( $_[0] );
    $out .= 'expected = ' . Dumper( $_[1] );
    $out =~ s/\n/\n# /gsx;
    print $out;
}

sub can_ok_abstract {
    my $thing = shift;
    can_ok( $thing, @_, qw/ data factory issue lazy_loaded init unload_lazy
                            jira JIRA_REST REST_CLIENT make_object make_date
                            class_for obj_isa name_for_user key_for_issue
                            find_link_name_and_direction populate_scalar_data
                            populate_date_data populate_list_data
                            populate_scalar_field populate_list_field
                            mk_contextual_ro_accessors mk_deep_ro_accessor
                            mk_lazy_ro_accessor mk_data_ro_accessors
                            mk_field_ro_accessors make_subroutine
                            dump shallow_dump / );

}

my %types = (
    class        => 'JIRA::REST::Class',
    factory      => 'JIRA::REST::Class::Factory',
    issue        => 'JIRA::REST::Class::Issue',
    changelog    => 'JIRA::REST::Class::Issue::Changelog',
    change       => 'JIRA::REST::Class::Issue::Changelog::Change',
    changeitem   => 'JIRA::REST::Class::Issue::Changelog::Change::Item',
    linktype     => 'JIRA::REST::Class::Issue::LinkType',
    status       => 'JIRA::REST::Class::Issue::Status',
    statuscat    => 'JIRA::REST::Class::Issue::Status::Category',
    timetracking => 'JIRA::REST::Class::Issue::TimeTracking',
    transitions  => 'JIRA::REST::Class::Issue::Transitions',
    transition   => 'JIRA::REST::Class::Issue::Transitions::Transition',
    issuetype    => 'JIRA::REST::Class::Issue::Type',
    worklog      => 'JIRA::REST::Class::Issue::Worklog',
    workitem     => 'JIRA::REST::Class::Issue::Worklog::Item',
    project      => 'JIRA::REST::Class::Project',
    projectcat   => 'JIRA::REST::Class::Project::Category',
    projectcomp  => 'JIRA::REST::Class::Project::Component',
    projectvers  => 'JIRA::REST::Class::Project::Version',
    iterator     => 'JIRA::REST::Class::Iterator',
    sprint       => 'JIRA::REST::Class::Sprint',
    query        => 'JIRA::REST::Class::Query',
    user         => 'JIRA::REST::Class::User',
);

sub get_class {
    my $type = shift;
    return $types{$type};
}

1;
