package JIRA::REST::Class::TestServer;
use base qw( HTTP::Server::Simple::CGI );
use strict;
use warnings;
use v5.10;

use Carp;
use Data::Dumper::Concise;
use JSON;
use Log::Any;
use Log::Any::Adapter;

use JIRA::REST::Class::TestServer::IssueTypes;
use JIRA::REST::Class::TestServer::Projects;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{logger} = get_logger();
    return $self;
}

sub log { shift->{logger} }

sub get_logger {
    if ($ENV{JIRA_REST_CLASS_TESTLOG}) {
        Log::Any::Adapter->set( File => $ENV{JIRA_REST_CLASS_TESTLOG} );
    }
    return Log::Any->get_logger;
}

sub print_banner {
    my $self = shift;
    $self->log->info( ref($self) . ' running on http://localhost:' .
                      $self->port );
}

sub background {
    my $self  = shift;
    my $call  = shift;
    my $child = fork;
    croak "Can't fork: $!" unless defined($child);
    return if $child;

    exit if fork; # double-forking to avoid zombies

    srand(); # after a fork, we need to reset the random seed
             # or we'll get the same numbers in both branches
    if ( $^O !~ /MSWin32/ ) {
        require POSIX;
        POSIX::setsid()
              or croak "Can't start a new session: $!";
    }
    $call->($$) if defined $call;

    $self->run(@_); # should never return
    exit;           # just to be sure
}

sub valid_http_method {
    my $self = shift;
    my $method = shift or return 0;
    return $method =~ /^(?:GET|POST|PUT|DELETE)$/; # not handling others
}

sub handle_request {
    my ( $self, $cgi ) = @_;

    my $uri     = $cgi->request_uri || q{};
    my $path    = $cgi->path_info;
    my $method  = $cgi->request_method;
    if ($method eq 'POST') {
        $uri .= "\nPOSTDATA:" . Dumper($cgi->param('POSTDATA'));
    }
    elsif ($method eq 'PUT') {
        $uri .= "\nPUTDATA:" . Dumper($cgi->param('PUTDATA'));
    }

    $self->log->info("REQUEST: $method $uri");

    my $handler = JIRA::REST::Class::TestServer::Plugin->DISPATCH_TABLE->{$path};

    if (ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($self, $cgi);
    }
    else {
        my $response = "HTTP/1.0 404 NOT FOUND\r\n\n$path";
        print $response;
        $self->log->error("ERROR:\n".$response);
    }
}

1;
