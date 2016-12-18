package TestServer;
use base qw( HTTP::Server::Simple::CGI );
use strict;
use warnings;
use v5.10;

use Carp;
use Data::Dumper::Concise;
use JSON::PP;
use Log::Any;
use Log::Any::Adapter;

use TestServer::IssueTypes;
use TestServer::Projects;
use TestServer::Misc;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{logger} = get_logger()->clone( prefix => "[pid $$] $class: " );
    return $self;
}

sub log { shift->{logger} }

sub get_logger {
    if ($ENV{JIRA_REST_CLASS_TESTLOG}) {
        Log::Any::Adapter->set( File => $ENV{JIRA_REST_CLASS_TESTLOG} );
    }
    return Log::Any->get_logger()
}

sub print_banner {
    my $self = shift;
    # get a new logger with the new pid
    my $class = ref $self;
    $self->{logger} = $self->log->clone( prefix => "[pid $$] $class: " );
    $self->log->info( 'running on http://localhost:' . $self->port );
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

    my $handler = TestServer::Plugin->DISPATCH_TABLE->{$path};

    if (ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($self, $cgi);
    }
    elsif ($path eq '/test') {
        print "HTTP/1.0 200 OK\r\nSUCCESS";
        $self->log->info("successful /test request");
    }
    elsif ($path eq '/quit') {
        print "HTTP/1.0 200 OK\r\n";
        $self->log->info("stopping server on $$ due to /quit request");
        exit;
    }
    else {
        my $response = "HTTP/1.0 404 NOT FOUND\r\n\n$path";
        print $response;
        $self->log->error("ERROR:\n".$response);
    }
}

1;
