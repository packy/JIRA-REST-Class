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

our @EXPORT = qw( chomper ref_is_array ref_is_sub ref_is_class report );

my $port    = 7657;
my $tmpdir  = '/tmp';
my $pidfile = 'jira_rest_class_test.pid';
my $pidpath;
my $log;
my $run;
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

sub check_prereqs {
    server_log();

    state $already_checked;

    unless ( $already_checked++ ) {
        $log->info('checking test server prerequisites');
        $run = 1;
        try {
            die "HTTP::Server::Simple misbehaves on Windows" if $^O =~ /MSWin/;
            require HTTP::Server::Simple;
        }
        catch {
            my $error = $_;  # Try::Tiny puts the error in $_
            diag("Won't run tests because: $error");
            $run = 0;
        };
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
    check_prereqs();
    get_pid();

    # if the server is already running, return
    if ( server_is_running() ) {
        $log->info('server already running on PID '.$pid);
        return;
    }

    try {
        # start the server
        server_log()->info('starting server and sending to background');
        JIRA::REST::Class::TestServer->new($port)->background(sub {
            my $server_pid = shift;
            write_file($pidpath, "$server_pid\n");
            $log->info('started server on PID '.$server_pid);
        });
    };
}

sub server_log {
    unless (defined $log) {
        $log = JIRA::REST::Class::TestServer->get_logger();
    }
    return $log;
}

sub server_pid {
    return $pid;
}

sub server_is_running {
    return unless defined $pid && $pid =~ /^\d+$/;
    kill 0, $pid;
}

sub stop_server {
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

sub run_tests {
    return $run;
}

sub chomper {
    my $thing = Dumper( @_ );
    chomp $thing;
    return $thing;
}

sub ref_is_array { ref_is(shift, 'ARRAY') }
sub ref_is_sub   { ref_is(shift, 'CODE') }

sub ref_is { return ref $_[0] && ref $_[0] eq $_[1] }

sub ref_is_class {
    my $thing = shift;
    my $class = shift;
    return blessed $thing && blessed $thing eq $class;
}

sub report {
    my %args = @_;
    if ($args{expr}) {
        ok(1, ref_is_sub( $args{ok} ) ? $args{ok}->() : $args{ok} );
    }
    else {
        ok(0, ref_is_sub( $args{nok} ) ? $args{nok}->() : $args{nok} );
    }
}

1;
