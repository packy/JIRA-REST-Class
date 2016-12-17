package JIRA::REST::Class::Mixins;
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: An mixin class for C<JIRA::REST::Class> that other objects can inherit methods from.

use Carp;
use Data::Dumper::Concise;
use MIME::Base64;
use Scalar::Util qw( blessed reftype );

=for stopwords jira

=internal_method B<jira>

Returns a C<JIRA::REST::Class> object with credentials for the last JIRA user.

=cut

sub jira {
    my $self  = shift;
    my $args  = shift;
    my $class = ref $self ? ref($self) : $self;

    if (blessed $self) {
        # if we have an object, return it!
        return $self->{jira} if $self->{jira};

        if (!$args && $self->{args}) {
            $args = $self->{args};
        }

        # if we have arguments, call ourself using
        # the class name with those args, and cache the result
        if ($args) {
            $self->{jira}      = $class->jira($args);
            $self->{jira_rest} = $self->{jira}->{jira_rest};
            return $self->{jira};
        }
    }

    # called with just the class name
    return JIRA::REST::Class->new($args);
}

=internal_method B<factory>

An accessor for the C<JIRA::REST::Class::Factory>.

=cut

sub factory {
    my $self  = shift;
    my $args  = shift;
    my $class = ref $self ? ref($self) : $self;

    if (blessed $self) {
        # if we have a factory, return it!
        if ($self->{factory}) {
            return $self->{factory};
        }

        # if we have arguments, call ourself using
        # the class name with those args, and cache the result
        if ($args) {
            $self->{factory} = $class->factory($args);
            return $self->{factory};
        }
    }

    # called with just the class name
    return JIRA::REST::Class::Factory->new('factory', { args => $args });
}

=internal_method B<JIRA_REST>

An accessor that returns the C<JIRA::REST> object being used.

=cut

sub JIRA_REST {
    my $self = shift;
    my $args = shift;
    my $class = ref $self ? ref($self) : $self;

    if (blessed $self) {
        # method called on a class object

        # if we have a copy of the JIRA::REST object, return it!
        return $self->{jira_rest} if $self->{jira_rest};

        # if we have arguments, call ourself using
        # the class name with those args, and cache the result
        return $self->{jira_rest} = $class->JIRA_REST($args)
            if $args;
    }

    # called with just the class name

    if ( _JIRA_REST_version_has_named_parameters() ) {
        return JIRA::REST->new($args);
    }

    # still support the old style arguments for JIRA::REST
    my $jira_rest = JIRA::REST->new($args->{url},
                                    $args->{username},
                                    $args->{password},
                                    $args->{rest_client_config});

    my $rest = $jira_rest->{rest};
    my $ua   = $rest->getUseragent;
    $ua->ssl_opts(SSL_verify_mode => 0, verify_hostname => 0)
        if $args->{ssl_verify_none};

    unless ($args->{username} && $args->{password}) {
        if (my $auth = $rest->{_headers}->{Authorization}) {
            my(undef, $encoded) = split /\s+/, $auth;
            ($args->{username}, $args->{password}) =
                split /:/, decode_base64 $encoded;
        }
    }

    return $jira_rest;
}

sub _JIRA_REST_version_has_named_parameters {
    eval {
        # we don't want SIGDIE taking us someplace
        # if VERSION throws an exception
        local $SIG{__DIE__} = undef;

        JIRA::REST->VERSION && JIRA::REST->VERSION(0.017);
    };
}

=internal_method B<REST_CLIENT>

An accessor that returns the C<REST::Client> object inside the C<JIRA::REST> object being used.

=internal_method B<make_object>

A pass-through method that calls C<JIRA::REST::Class::Factory::make_object()>.

=internal_method B<make_date>

A pass-through method that calls C<JIRA::REST::Class::Factory::make_date()>.

=internal_method B<class_for>

A pass-through method that calls C<JIRA::REST::Class::Factory::get_factory_class()>.

=cut

sub REST_CLIENT { shift->JIRA_REST->{rest} }
sub make_object { shift->factory->make_object(@_) }
sub make_date   { shift->factory->make_date(@_) }
sub class_for   { shift->factory->get_factory_class(@_) }

=internal_method B<obj_isa>

When passed a scalar that could be an object and a class string, returns whether the scalar is, in fact, an object of that class.  Looks up the actual class using C<class_for()>, which calls  C<JIRA::REST::Class::Factory::get_factory_class()>.

=cut

sub obj_isa  {
    my ($self, $obj, $type) = @_;
    return unless blessed $obj;
    my $class = $self->class_for($type);
    $obj->isa( $class );
}

=method B<name_for_user>

When passed a scalar that could be a C<JIRA::REST::Class::User> object, returns the name of the user if it is a C<JIRA::REST::Class::User> object, or the unmodified scalar if it is not.

=cut

sub name_for_user {
    my($self, $user) = @_;
    return $self->obj_isa($user, 'user') ? $user->name : $user;
}

=method B<key_for_issue>

When passed a scalar that could be a C<JIRA::REST::Class::Issue> object, returns the key of the issue if it is a C<JIRA::REST::Class::Issue> object, or the unmodified scalar if it is not.

=cut

sub key_for_issue {
    my($self, $issue) = @_;
    return $self->obj_isa($issue, 'issue') ? $issue->key : $issue;
}

=method B<find_link_name_and_direction>

When passed two scalars, one that could be a C<JIRA::REST::Class::Issue::LinkType> object and another that is a direction (inward/outward), returns the name of the link type and direction if it is a C<JIRA::REST::Class::Issue::LinkType> object, or attempts to determine the link type and direction from the provided scalars.

=cut

sub find_link_name_and_direction {
    my ($self, $link, $dir) = @_;

    return unless defined $link;

    # determine the link directon, if provided. defaults to inward.
    $dir = ($dir && $dir =~ /out(?:ward)?/) ? 'outward' : 'inward';

    # if we were passed a link type object, return
    # the name and the direction we were given
    if ( $self->obj_isa($link, 'linktype') ) {
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

=method B<dump>

Returns a stringified representation of the object's data generated somewhat by Data::Dumper::Concise, but only going one level deep.  If it finds objects in the data, it will attempt to represent them in some abbreviated fashion which may not display all the data in the object.

=cut

sub dump {
    my $self = shift;
    my $result;
    if (@_) {
        $result = $self->shallow_copy( @_ );
    }
    else {
        $result = $self->shallow_copy( $self );
    }
    return ref($result) ? Dumper($result) : $result;
}

=internal_method B<deep_copy>

 Returns a deep copy of the hashref it is passed

 Example:

    my $bar = Class->deep_copy($foo);
    $bar->{XXX} = 'new value'; # $foo->{XXX} isn't changed

=cut

sub deep_copy {
    my $class = shift;
    my $thing = shift;
    if (not ref $thing) {
        return $thing;
    }
    elsif (ref $thing eq 'ARRAY') {
        return [ map { $class->deep_copy($_) } @$thing ];
    }
    elsif (ref $thing eq 'HASH') {
        return +{ map { $_ => $class->deep_copy($thing->{$_}) } keys %$thing };
    }
}

=internal_method B<shallow_copy> THING

A utility function to produce a shallow copy of a thing (mostly not going down into the contents of objects within objects).

=cut

sub shallow_copy {
    shift; # we don't need $self
    return __shallow_copy(@_, 'top');
}

sub __shallow_copy {
    my $thing = shift;
    my $top   = pop;

    if (not ref $thing) {
        return $thing;
    }

    if ( my $class = blessed $thing ) {
        if ($class eq 'JSON::PP::Boolean') {
            return $thing ? 'JSON::PP::true' : 'JSON::PP::false';
        }
        elsif ($class eq 'JSON') {
            return "$thing";
        }
        elsif ($class eq 'REST::Client') {
            return '%s->host(%s)', $class, $thing->getHost;
        }
        elsif ($class eq 'DateTime') {
            return "DateTime(  $thing  )";
        }
        elsif ($top) {
            if (reftype $thing eq 'ARRAY') {
                chomp ( my $data = Dumper([
                    map { __shallow_copy($_) } @{$thing}
                ]) );
                return "bless( $data => $class )";
            }
            elsif (reftype $thing eq 'HASH') {
                chomp ( my $data = Dumper({
                    map { $_ => __shallow_copy($thing->{$_}) } keys %{$thing}
                }) );
                return "bless( $data => $class )";
            }
            return Dumper($thing);
        }
        else {
            foreach my $method (qw/ name key id /) {
                if ( $thing->can($method) ) {
                    my $value = $thing->$method // 'undef';
                    return sprintf '%s->%s(%s)',
                        $class, $method, $value;
                }
            }
            return "$thing";
        }
    }

    if (ref $thing eq 'SCALAR') {
        return $$thing;
    }
    elsif (ref $thing eq 'ARRAY') {
        return [ map { __shallow_copy($_) } @{$thing} ];
    }
    elsif (ref $thing eq 'HASH') {
        return +{
            map { $_ => __shallow_copy($thing->{$_}) } keys %{$thing}
        };
    }
    return $thing;
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

sub _get_known_args {
    my $self = shift;
    my $in   = shift;
    my $out  = {};
    my @args = @_;

    # $in is an arrayref with a single hashref in it
    if (@$in == 1 && ref $$in[0] && ref $$in[0] eq 'HASH') {
        # copy that hashref into $in
        $in = $self->deep_copy($in->[0]);

        # moving arguments using the semi-magical hash reference slice
        @{$out}{@args} = delete @{$in}{@args};

        # if there are leftover keys
        if (keys %$in) {
            # get the package->name of the sub that called US
            (my $sub = +(caller(1))[3]) =~ s/(.*)::([^:]+)$/$1->$2/;

            # croak from the perspective of our CALLER's caller
            local $Carp::CarpLevel = $Carp::CarpLevel + 2;

            my $arguments = 'argument' . (keys %$in == 1 ? q{} : q{s});

            croak "$sub: unknown $arguments - "
                . $self->_quoted_list(sort keys %$in);
        }
    }
    else {
        # if there aren't more arguments than we have names for
        if (@$in <= @args) {
            # copy arguments positionally
            @{$out}{@args} = @$in;
        }
        else {
            # get the package->name of the sub that called US
            (my $sub = +(caller(1))[3]) =~ s/(.*)::([^:]+)$/$1->$2/;

            my $got  = scalar @$in;
            my $max  = scalar @args;
            my $list = $self->_quoted_list(@args);

            # croak from the perspective of our CALLER's caller
            local $Carp::CarpLevel = $Carp::CarpLevel + 2;

            croak "$sub: too many arguments - got $got, max $max ($list)";
        }
    }

    return $out;
}

# accepts a hashref and a list of required arguments

sub _check_required_args {
    my $self = shift;
    my $args = shift;
    my @args = @_;
    while ( my($arg, $err) = splice @args, 0, 2 ) {
        next if exists  $args->{$arg}
             && defined $args->{$arg}
             && length  $args->{$arg};

        # get the package->name of the sub that called US
        (my $sub = +(caller(1))[3]) =~ s/(.*)::([^:]+)$/$1->$2/;

        # croak from the perspective of our CALLER's caller
        local $Carp::CarpLevel = $Carp::CarpLevel + 2;

        croak "$sub: ".$err;
    }
}

# internal function so I don't have to build a "Package::subroutine:" prefix
# whenever I want to croak

sub _croakmsg {
    my $self = shift;
    my $msg  = shift;
    my $args = @_ ? q{(}.join(q{, },@_).q{)} : q{};

    # get the package->name of the sub that called US
    (my $sub = +(caller(1))[3]) =~ s/(.*)::([^:]+)$/$1->$2/;

    return join q{ }, "$sub$args:", $msg;
}

#
# __PACKAGE__->_quoted_list(qw/ a b c /) returns q/'a', 'b', 'c'/
#
sub _quoted_list {
    my $self = shift;
    return q{'} . join(q{', '}, @_) . q{'};
}


1;
