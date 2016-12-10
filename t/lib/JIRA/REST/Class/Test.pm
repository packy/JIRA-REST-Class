package JIRA::REST::Class::Test;
use base qw( Exporter );
use strict;
use warnings;
use v5.10;

use Data::Dumper::Concise;
use File::Slurp;
use File::Spec::Functions;
use Getopt::Long;
use JSON;
use Scalar::Util qw( blessed reftype );
use Test::More;
use Try::Tiny;

use JIRA::REST::Class::TestServer;

our @EXPORT = qw( chomper can_ok_abstract dump_got_expected get_class
                  validate_contextual_accessor validate_expected_fields  );

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
                            dump shallow_copy / );

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
    return exists $types{$type} ? $types{$type} : $type;
}

sub validate_contextual_accessor {
    my $obj        = shift;
    my $args       = shift;
    my $methodname = $args->{method};
    my $class      = get_class($args->{class});
    my $objectname = $args->{name} || ref $obj;
    my $method     = join '->', ref($obj), $methodname;
    my @data       = @{ $args->{data} };

    print "#\n# Checking the $objectname->$methodname accessor\n#\n";

    my $scalar = $obj->$methodname;

    is( ref $scalar, 'ARRAY',
        "$method in scalar context returns arrayref" );

    cmp_ok( @$scalar, '==', @data,
            "$method arrayref has correct number of items" );

    my @list = $obj->$methodname;

    cmp_ok( @list, '==', @data, "$method returns correct size list ".
                                "in list context");

    subtest "Checking object types returned by $method", sub {
        foreach my $item ( sort @list ) {
            isa_ok( $item, $class, "$item" );
        }
    };

    my $list = [ map { "$_" } sort @list ];
    is_deeply( $list, \@data,
               "$method returns the expected $methodname")
        or dump_got_expected($list, \@data);
}

sub validate_expected_fields {
    my $obj    = shift;
    my $expect = shift;
    my $isa    = ref $obj || q{};
    if ($obj->isa('JIRA::REST::Class::Abstract')) {
        # common accessors for ALL JIRA::REST::Class::Abstract objects
        $expect->{factory}     = { class => 'factory' };
        $expect->{jira}        = { class => 'class' };
        $expect->{JIRA_REST}   = { class => 'JIRA::REST' };
        $expect->{REST_CLIENT} = { class => 'REST::Client' };
    }

    foreach my $field ( sort keys %$expect ) {
        my $value  = $expect->{$field};

        if (! ref $value) {
            # expected a scalar
            my $quoted = ($value =~ /^\d+$/) ? $value : qq{'$value'};
            is( $obj->$field, $value, "'$isa->$field' returns $quoted");
        }
        elsif (ref $value && ref($value) =~ /^JSON::PP::/) {
            # expecting a boolean
            my $quoted = $value ? 'true' : 'false';
            is( $obj->$field, $value, "'$isa->$field' returns $quoted");
        }
        else {
            # expecting an object
            my $class = get_class($value->{class});
            my $obj2  = $obj->$field;

            isa_ok( $obj2, $class,  $isa.'->'.$field);

            my $expect2 = $value->{expected};
            next unless $expect2 && ref $expect2 eq 'HASH';

            # check simple accessors on the object
            foreach my $field2 ( sort keys %$expect2 ) {
                my $value2 = $expect2->{$field2};
                my $quoted = ($value2 =~ /^\d+$/) ? $value2 : qq{'$value2'};
                is( $obj->$field->$field2, $value2,
                    "'$isa->$field->$field2' method returns $quoted");
            }
        }
    }
}

1;
