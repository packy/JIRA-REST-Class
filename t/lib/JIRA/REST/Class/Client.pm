package JIRA::REST::Class::Client;
use base qw( JIRA::REST );
use strict;
use warnings;
use v5.10;

use utf8;
 
use Carp;
use URI;
use MIME::Base64;
use URI::Escape;
use JSON;
use REST::Client;

sub new {
    my ($class, $URL, $username, $password, $rest_client_config) = @_;
 
    # Make sure $URL isa URI
    if (! defined $URL) {
        croak __PACKAGE__ . "::new: URL argument must be defined.\n";
    } elsif (! ref $URL) {
        $URL = URI->new($URL);
    } elsif (! $URL->isa('URI')) {
        croak __PACKAGE__ . "::new: URL argument must be an URI object.\n";
    }
 
    # See if the user wants a specific JIRA Core REST API version:
    my $path = $URL->path('') || '/rest/api/latest';
    $path =~ m@^/rest/api/(?:latest|\d+)$@
        or croak __PACKAGE__ . "::new: invalid path in URL: '$path'\n";
 
    # If username and password are not set we try to lookup the credentials
    if (! defined $username || ! defined $password) {
        ($username, $password) = _search_for_credentials($URL, $username);
    }
 
    croak __PACKAGE__ . "::new: USERNAME argument must be a string.\n"
        unless defined $username && ! ref $username && length $username;
 
    croak __PACKAGE__ . "::new: PASSWORD argument must be a string.\n"
        unless defined $password && ! ref $password && length $password;
 
    $rest_client_config = {} unless defined $rest_client_config;
    croak __PACKAGE__ . "::new: REST_CLIENT_CONFIG argument must be a hash-ref.\n"
        unless
        defined $rest_client_config
        &&  ref $rest_client_config
        &&  ref $rest_client_config eq 'HASH';
 
    # remove the REST::Client faux config 'proxy' if set and use it later.
    my $proxy = delete $rest_client_config->{proxy};
 
    my $rest = REST::Client->new($rest_client_config);
 
    # Set proxy to be used
    $rest->getUseragent->proxy(['http','https'] => $proxy) if $proxy;
 
    # Set default base URL
    $rest->setHost($URL);
 
    # Follow redirects/authentication by default
    $rest->setFollow(1);
 
    # Since JIRA doesn't send an authentication chalenge, we may
    # simply force the sending of the authentication header.
    # if both the username and password are anonymous, don't authenticate.
    unless ($username eq 'anonymous' && $password eq 'anonymous') {
        $rest->addHeader(Authorization => 'Basic ' . encode_base64("$username:$password"));
    }
 
    # Configure UserAgent name
    $rest->getUseragent->agent(__PACKAGE__);
 
    return bless {
        rest => $rest,
        json => JSON->new->utf8->allow_nonref,
        path => $path,
    } => $class;
}

sub _build_path {
    my ($self, $path, $query) = @_;
 
    $path = $self->{path} . $path unless $path =~ m:^/rest/:;
 
    if (defined $query) {
        croak $self->_error("The QUERY argument must be a hash-ref.")
            unless ref $query && ref $query eq 'HASH';
        return $path . '?'. join('&', map {$_ . '=' . uri_escape($query->{$_})} keys %$query);
    } else {
        return $path;
    }
}

sub GET {
    my ($self, $path, $query) = @_;
 
    my $bpath = $self->_build_path($path, $query);
    print "PATH: $bpath";
    $self->{rest}->GET($bpath);
 
    return $self->_content();
}


1;
