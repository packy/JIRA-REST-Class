package JIRA::REST::Class::Mixins;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.05';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: An mixin class for L<JIRA::REST::Class|JIRA::REST::Class> that other objects can inherit methods from.

use Carp;
use Clone::Any qw( clone );
use Data::Dumper::Concise;
use MIME::Base64;
use Readonly;
use Scalar::Util qw( blessed reftype );
use Try::Tiny;

sub jira {
    my $self  = shift;
    my $args  = shift;
    my $class = ref $self ? ref( $self ) : $self;

    if ( blessed $self ) {

        # if we have an object, return it!
        return $self->{jira} if $self->{jira};

        if ( !$args && $self->{args} ) {
            $args = $self->{args};
        }

        # if we have arguments, call ourself using
        # the class name with those args, and cache the result
        if ( $args ) {
            $self->{jira}      = $class->jira( $args );
            $self->{jira_rest} = $self->{jira}->{jira_rest};
            return $self->{jira};
        }
    }

    # called with just the class name
    return JIRA::REST::Class->new( $args );
}

#---------------------------------------------------------------------------

=begin test setup

BEGIN {
    use File::Basename;
    use lib dirname($0).'/../lib';

    use InlineTest;
    use Clone::Any qw( clone );
    use Scalar::Util qw(refaddr);

    use_ok('JIRA::REST::Class::Mixins');
    use_ok('JIRA::REST::Class::Factory');
    use_ok('JIRA::REST::Class::FactoryTypes', qw( %TYPES ));
}

=end test

=begin testing constructor 3

my $jira = JIRA::REST::Class::Mixins->jira(InlineTest->constructor_args);
isa_ok($jira, $TYPES{class}, 'Mixins->jira');
isa_ok($jira->JIRA_REST, 'JIRA::REST', 'JIRA::REST::Class->JIRA_REST');
isa_ok($jira->REST_CLIENT, 'REST::Client', 'JIRA::REST::Class->REST_CLIENT');

=end testing

=cut

#---------------------------------------------------------------------------

sub factory {
    my $self  = shift;
    my $args  = shift;
    my $class = ref $self ? ref( $self ) : $self;

    if ( blessed $self ) {

        # if we have a factory, return it!
        if ( $self->{factory} ) {
            return $self->{factory};
        }

        # if we have arguments, call ourself using
        # the class name with those args, and cache the result
        if ( $args ) {
            $self->{factory} = $class->factory( $args );
            return $self->{factory};
        }
    }

    # called with just the class name
    return JIRA::REST::Class::Factory->new( 'factory', { args => $args } );
}

#---------------------------------------------------------------------------

=begin test setup

sub get_factory {
    JIRA::REST::Class::Mixins->factory(InlineTest->constructor_args);
}

=end test

=begin testing factory 2

my $factory = get_factory();
isa_ok($factory, $TYPES{factory}, 'Mixins->factory');
ok(JIRA::REST::Class::Mixins->obj_isa($factory, 'factory'),
   'Mixins->obj_isa works');

=end testing

=cut

#---------------------------------------------------------------------------

sub JIRA_REST { ## no critic (Capitalization)
    my $self  = shift;
    my $args  = shift;
    my $class = ref $self ? ref( $self ) : $self;

    if ( blessed $self ) {

        # method called on a class object

        # if we have a copy of the JIRA::REST object, return it!
        return $self->{jira_rest} if $self->{jira_rest};

        # if we have arguments, call ourself using
        # the class name with those args, and cache the result
        return $self->{jira_rest} = $class->JIRA_REST( $args )
            if $args;
    }

    # called with just the class name

    if ( _JIRA_REST_version_has_named_parameters() ) {
        return JIRA::REST->new( $args );
    }

    # still support the old style arguments for JIRA::REST
    my $jira_rest = JIRA::REST->new(
        $args->{url},      $args->{username},
        $args->{password}, $args->{rest_client_config}
    );

    my $rest = $jira_rest->{rest};
    my $ua   = $rest->getUseragent;
    $ua->ssl_opts( SSL_verify_mode => 0, verify_hostname => 0 )
        if $args->{ssl_verify_none};

    unless ( $args->{username} && $args->{password} ) {
        if ( my $auth = $rest->{_headers}->{Authorization} ) {
            my ( undef, $encoded ) = split /\s+/, $auth;
            ( $args->{username}, $args->{password} ) =  #
                split /:/, decode_base64 $encoded;
        }
    }

    return $jira_rest;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
## these are private to the whole module, not just this package
sub _JIRA_REST_version { ## no critic (Capitalization)
    my $version = shift;
    my $has_version;
    try {
        # we don't want SIGDIE taking us someplace
        # if VERSION throws an exception
        local $SIG{__DIE__} = undef;

        $has_version = JIRA::REST->VERSION && JIRA::REST->VERSION( $version );
    };
    return $has_version;
}

sub _JIRA_REST_version_has_named_parameters { ## no critic (Capitalization)
    ## no critic (ProhibitMagicNumbers)
    state $retval = _JIRA_REST_version( 0.016 );
    ## use critic
    return $retval;
}

sub _JIRA_REST_version_has_separate_path { ## no critic (Capitalization)
    ## no critic (ProhibitMagicNumbers)
    state $retval = _JIRA_REST_version( 0.015 );
    ## use critic
    return $retval;
}
## use critic

## no critic (Capitalization)
sub REST_CLIENT { return shift->JIRA_REST->{rest} }
sub JSON        { return shift->JIRA_REST->{json} }
## use critic
sub make_object { return shift->factory->make_object( @_ ) }
sub make_date   { return shift->factory->make_date( @_ ) }
sub class_for   { return shift->factory->get_factory_class( @_ ) }

sub obj_isa {
    my ( $self, $obj, $type ) = @_;
    return unless blessed $obj;
    my $class = $self->class_for( $type );
    return $obj->isa( $class );
}

sub name_for_user {
    my ( $self, $user ) = @_;
    return $self->obj_isa( $user, 'user' ) ? $user->name : $user;
}

sub key_for_issue {
    my ( $self, $issue ) = @_;
    return $self->obj_isa( $issue, 'issue' ) ? $issue->key : $issue;
}

sub find_link_name_and_direction {
    my ( $self, $link, $dir ) = @_;

    return unless defined $link;

    # determine the link directon, if provided. defaults to inward.
    $dir = ( $dir && $dir =~ /out(?:ward)?/x ) ? 'outward' : 'inward';

    # if we were passed a link type object, return
    # the name and the direction we were given
    if ( $self->obj_isa( $link, 'linktype' ) ) {
        return $link->name, $dir;
    }

    # search through the link types
    # work in progress
    #   my @types = $self->jira->link_types;
    #   foreach my $type ( @types ) {
    #       if (lc $link eq lc $type->inward) {
    #           return $type->name, 'inward';
    #       }
    #       if (lc $link eq lc $type->outward) {
    #           return $type->name, 'outward';
    #       }
    #       if (lc $link eq lc $type->name) {
    #           return $type->name, $dir;
    #       }
    #   }

    # we didn't find anything, so just return what we were passed
    return $link, $dir;
}

###########################################################################

sub dump { ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, @args ) = @_;
    my $result;
    if ( @args ) {
        $result = $self->cosmetic_copy( @args );
    }
    else {
        $result = $self->cosmetic_copy( $self );
    }
    return ref( $result ) ? Dumper( $result ) : $result;
}

sub cosmetic_copy {
    shift;  # we don't need $self
    return __cosmetic_copy( @_, 'top' );
}

#---------------------------------------------------------------------------

=begin testing cosmetic_copy 3

my @PROJ = InlineTest->project_data;
my $orig = [ @PROJ ];
my $copy = JIRA::REST::Class::Mixins->cosmetic_copy($orig);

is_deeply( $orig, $copy, "simple cosmetic copy has same content as original" );

cmp_ok( refaddr($orig), 'ne', refaddr($copy),
        "simple cosmetic copy has different address as original" );

# make a complex reference to copy
my $factory = get_factory();
$orig = [ map { $factory->make_object('project', { data => $_ }) } @PROJ ];
$copy = JIRA::REST::Class::Mixins->cosmetic_copy($orig);

is_deeply( $copy, [
  "JIRA::REST::Class::Project->name(JIRA::REST::Class)",
  "JIRA::REST::Class::Project->name(Kanban software development sample project)",
  "JIRA::REST::Class::Project->name(PacKay Productions)",
  "JIRA::REST::Class::Project->name(Project Management Sample Project)",
  "JIRA::REST::Class::Project->name(Scrum Software Development Sample Project)"
], "complex cosmetic copy is properly serialized");

=end testing

=cut

#---------------------------------------------------------------------------

sub __cosmetic_copy {
    my $thing = shift;
    my $top   = pop;

    if ( not ref $thing ) {
        return $thing;
    }

    my $hash_copy = sub { };

    if ( my $class = blessed $thing ) {
        if ( $class eq 'JSON::PP::Boolean' ) {
            return $thing ? 'JSON::PP::true' : 'JSON::PP::false';
        }
        if ( $class eq 'JSON' ) {
            return "$thing";
        }
        if ( $class eq 'REST::Client' ) {
            return '%s->host(%s)', $class, $thing->getHost;
        }
        if ( $class eq 'DateTime' ) {
            return "DateTime(  $thing  )";
        }
        if ( $top ) {
            if ( reftype $thing eq 'ARRAY' ) {
                chomp( my $data = Dumper( __array_copy( $thing ) ) );
                return "bless( $data => $class )";
            }
            if ( reftype $thing eq 'HASH' ) {
                chomp( my $data = Dumper( __hash_copy( $thing ) ) );
                return "bless( $data => $class )";
            }
            return Dumper( $thing );
        }
        else {
            my $fallback;

            # see if the object has any of these methods
            foreach my $method ( qw/ name key id / ) {
                if ( $thing->can( $method ) ) {
                    my $value = $thing->$method;

                    # if the method returned a value, great!
                    return sprintf '%s->%s(%s)', $class, $method, $value
                        if defined $value;

                    # we can use it as a stringification if we have to
                    $fallback //= sprintf '%s->%s(undef)', $class, $method;
                }
            }

            # fall back to either a $class->$method(undef)
            # or the default stringification
            return $fallback ? $fallback : "$thing";
        }
    }

    if ( ref $thing eq 'SCALAR' ) {
        return $$thing;
    }
    elsif ( ref $thing eq 'ARRAY' ) {
        return __array_copy( $thing );
    }
    elsif ( ref $thing eq 'HASH' ) {
        return __hash_copy( $thing );
    }
    return $thing;
}

sub __array_copy {
    my $thing = shift;
    return [ map { __cosmetic_copy( $_ ) } @$thing ];
}

sub __hash_copy {
    my $thing = shift;
    return +{ map { $_ => __cosmetic_copy( $thing->{$_} ) } keys %$thing };
}

###########################################################################
#
# internal helper functions

# accepts a reference to an array and a list of known arguments.
#
# + if the array has a single element and it's a hashref, it moves
#   elements based on the argument list from that hashref into a
#   result hashref and then complains if there are elements in the
#   first hashref left over.
#
# + if the array has multiple elements, it assigns the elements to
#   the result hashref in the order of the argument list, and
#   complains if the array has more elements than there are arguments.
#
# In either case, the result hashref is returned.

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _get_known_args {
## use critic
    my ( $self, $in, @args ) = @_;
    my $out = {};

    # get the package->name of the sub that called US
    my $sub = $self->__subname( caller 1 );

    # if we croak, croak from the perspective of our CALLER's caller
    local $Carp::CarpLevel = $Carp::CarpLevel + 2;

    # $in is an arrayref with a single hashref in it
    if ( @$in == 1 && ref $in->[0] && ref $in->[0] eq 'HASH' ) {

        # copy that hashref into $in
        $in = clone( $in->[0] );

        # moving arguments using the semi-magical hash reference slice
        @{$out}{@args} = delete @{$in}{@args};

        # if there are leftover keys
        if ( keys %$in ) {
            my $arguments = 'argument' . ( keys %$in == 1 ? q{} : q{s} );

            croak "$sub: unknown $arguments - "
                . $self->_quoted_list( sort keys %$in );
        }
    }
    else {
        # if there aren't more arguments than we have names for
        if ( @$in <= @args ) {

            # copy arguments positionally
            @{$out}{@args} = @$in;
        }
        else {
            my $got  = scalar @$in;
            my $max  = scalar @args;
            my $list = $self->_quoted_list( @args );

            croak "$sub: too many arguments - got $got, max $max ($list)";
        }
    }

    return $out;
}

#---------------------------------------------------------------------------

=begin testing _get_known_args 5

package InlineTestMixins;
use Test::Exception;
use Test::More;

sub test_too_many_args {
    JIRA::REST::Class::Mixins->_get_known_args(
        [ qw/ url username password rest_client_config proxy
              ssl_verify_none anonymous unknown1 unknown2 / ],
        qw/ url username password rest_client_config proxy
            ssl_verify_none anonymous/
    );
}

# also excercizes __subname()

throws_ok( sub { test_too_many_args() },
           qr/^InlineTestMixins->test_too_many_args:/,
           '_get_known_args constructs caller string okay' );

throws_ok( sub { test_too_many_args() },
           qr/too many arguments/,
           '_get_known_args catches too many args okay' );

sub test_unknown_args {
    JIRA::REST::Class::Mixins->_get_known_args(
        [ { map { $_ => $_ } qw/ url username password
                                rest_client_config proxy
                                ssl_verify_none anonymous
                                unknown1 unknown2 / } ],
        qw/ url username password rest_client_config proxy
            ssl_verify_none anonymous /
    );
}

# also excercizes _quoted_list()

throws_ok( sub { test_unknown_args() },
           qr/unknown arguments - 'unknown1', 'unknown2'/,
           '_get_known_args catches unknown args okay' );

my %expected = (
    map { $_ => $_ } qw/ url username password
                         rest_client_config proxy
                         ssl_verify_none anonymous /
);

sub test_positional_args {
    JIRA::REST::Class::Mixins->_get_known_args(
        [ qw/ url username password rest_client_config proxy
              ssl_verify_none anonymous / ],
        qw/ url username password rest_client_config proxy
            ssl_verify_none anonymous /
    );
}

is_deeply( test_positional_args(), \%expected,
           '_get_known_args processes positional args okay' );

sub test_named_args {
    JIRA::REST::Class::Mixins->_get_known_args(
        [ { map { $_ => $_ } qw/ url username password
                                rest_client_config proxy
                                ssl_verify_none anonymous / } ],
        qw/ url username password rest_client_config proxy
            ssl_verify_none anonymous /
    );
}

is_deeply( test_named_args(), \%expected,
           '_get_known_args processes named args okay' );

=end testing

=cut

#---------------------------------------------------------------------------

# accepts a hashref and a list of required arguments

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _check_required_args {
## use critic
    my ( $self, $args, @args ) = @_;

    while ( my ( $arg, $err ) = splice @args, 0, 2 ) {
        next
            if exists $args->{$arg}
            && defined $args->{$arg}
            && length $args->{$arg};

        # get the package->name of the sub that called US
        my $sub = $self->__subname( caller 1 );

        # croak from the perspective of our CALLER's caller
        local $Carp::CarpLevel = $Carp::CarpLevel + 2;

        croak "$sub: " . $err;
    }
    return;
}

#---------------------------------------------------------------------------

=begin testing _check_required_args 1

use Test::Exception;
use Test::More;

sub test_missing_req_args {
    my %args = map { $_ => $_ } qw/ username password /;
    JIRA::REST::Class::Mixins->_check_required_args(
        \%args,
        url  => "you must specify a URL to connect to",
    );
}

throws_ok( sub { test_missing_req_args() },
           qr/you must specify a URL to connect to/,
           '_check_required_args identifies missing args okay' );

=end testing

=cut

#---------------------------------------------------------------------------

# internal function so I don't have to build a "Package->subroutine:" prefix
# whenever I want to croak

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _croakmsg {
## use critic
    my ( $self, $msg, @args ) = @_;
    my $args = @args ? q{(} . join( q{, }, @args ) . q{)} : q{};

    # get the package->name of the sub that called US
    my $sub = $self->__subname( caller 1 );

    return join q{ }, "$sub$args:", $msg;
}

#---------------------------------------------------------------------------

=begin testing _croakmsg 2

package InlineTestMixins;
use Test::More;

sub test_croakmsg_noargs {
    JIRA::REST::Class::Mixins->_croakmsg("I died");
}

# also excercizes __subname()

is( test_croakmsg_noargs(),
    'InlineTestMixins->test_croakmsg_noargs: I died',
    '_croakmsg constructs no argument string okay' );

sub test_croakmsg_args {
    JIRA::REST::Class::Mixins->_croakmsg("I died", qw/ arg1 arg2 /);
}

is( test_croakmsg_args(),
    'InlineTestMixins->test_croakmsg_args(arg1, arg2): I died',
    '_croakmsg constructs argument string okay' );

=end testing

=cut

#---------------------------------------------------------------------------

#
# __PACKAGE__->_quoted_list(qw/ a b c /) returns q/'a', 'b', 'c'/
#
sub _quoted_list {
    my $self = shift;
    return q{'} . join( q{', '}, @_ ) . q{'};
}

#
#                              arguments provided by caller(n)
# __PACKAGE__->__subname('Some::Pkg', 'filename', lineno, 'Some::Pkg::subname')
#   returns 'Some::Pkg->subname'
#
sub __subname {
    my ( $self, @caller_n ) = @_;
    Readonly my $OUR_CALLERS_CALLER => 3;
    ( my $sub = $caller_n[$OUR_CALLERS_CALLER] ) =~ s/(.*)::([^:]+)$/$1->$2/xs;
    return $sub;
}

# put a reference to JIRA::REST::Class::Abstract here for related classes

1;

__END__

{{ include( "pod/mixins.pod" )->fill_in; }}

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::include_stopwords();
    $OUT .= PodUtil::related_classes($plugin);
}}
