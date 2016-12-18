package Test;
use base qw( Exporter );
use strict;
use warnings;
use v5.10;

use Data::Dumper::Concise;
use File::Slurp;
use File::Spec::Functions;
use Getopt::Long;
use JSON::PP;
use REST::Client;
use Scalar::Util qw( blessed reftype );
use Test::More;
use Try::Tiny;

use TestServer;

our @EXPORT = qw( chomper can_ok_abstract dump_got_expected get_class
                  validate_contextual_accessor validate_expected_fields  );

###########################################################################
#
# support for starting the test server
#

my $port = 7657;
my $rest;
my $log;
my $pid;


sub setup_server {
    server_log();

    try {
        # start the server
        $log->info('starting server and sending to background');
        $pid = TestServer->new($port)->background();
    };
    if ((! defined $pid) || $$ == $pid) { exit }
    $log->info("started server on PID ".$pid);
}

sub server_log {
    unless (defined $log) {
        $log = TestServer->get_logger->clone( prefix => "[pid $$] " );
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

sub rest {
    my ($method, $request) = @_;
    unless (defined $rest) {
        $rest = REST::Client->new;
        $rest->setHost(server_url());
    }
    my $result = $rest->$method($request)->responseContent();
    $log->info($result);
    return $result;
}

sub test_server {
    return rest('GET' => '/test');
}

sub stop_server {
    return rest('GET' => '/quit');
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
    can_ok( $thing, @_, qw/ data issue lazy_loaded init unload_lazy
                            populate_scalar_data populate_date_data
                            populate_list_data populate_scalar_field
                            populate_list_field mk_contextual_ro_accessors
                            mk_deep_ro_accessor mk_lazy_ro_accessor
                            mk_data_ro_accessors mk_field_ro_accessors
                            make_subroutine / );
}

sub can_ok_mixins {
    my $thing = shift;
    can_ok( $thing, @_, qw/ jira factory JIRA_REST REST_CLIENT
                            _JIRA_REST_version_has_named_parameters
                            make_object make_date class_for obj_isa
                            name_for_user key_for_issue dump deep_copy
                            shallow_copy find_link_name_and_direction
                            _get_known_args _check_required_args
                            _croakmsg _quoted_list / );
}


use JIRA::REST::Class::FactoryTypes qw( %TYPES );

sub get_class {
    my $type = shift;
    return exists $TYPES{$type} ? $TYPES{$type} : $type;
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
    if ($obj->isa(get_class('abstract'))) {
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
