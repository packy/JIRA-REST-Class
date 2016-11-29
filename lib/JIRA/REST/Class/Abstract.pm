package JIRA::REST::Class::Abstract;
use base qw( Class::Accessor::Fast );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: An abstract class for C<JIRA::REST::Class> that most of the other objects are based on.

use Scalar::Util qw( weaken blessed );

__PACKAGE__->mk_ro_accessors(qw( data factory issue lazy_loaded ));

=for Pod::Coverage init

=method B<init>

Method to perform post-instantiation initialization of the object. The first argument will be the factory object which created the object.

=cut

sub init {
    my $self    = shift;
    my $factory = shift;
    if ($factory) {
        $self->{factory} = $factory;
        weaken $self->{factory};
    }

    $self->unload_lazy;
}

=method B<unload_lazy>

Clears the hash that tracks lazily loaded methods so they get loaded again.

=cut

sub unload_lazy {
    my $self = shift;
    if ( $self->{lazy_loaded} ) {
        foreach my $field ( keys %{ $self->{lazy_loaded} } ) {
            delete $self->{$field};
            delete $self->{lazy_loaded}->{$field};
        }
    }
    else {
        $self->{lazy_loaded} = { };
    }
}

=method B<factory>

Returns the C<JIRA::REST::Class::Factory> object that created this object.

=method B<jira>

Returns the C<JIRA::REST::Class> object that created this object.

=cut

sub jira { shift->factory->jira }

=internal_method B<JIRA_REST>

An accessor that returns the C<JIRA::REST> object being used.

=cut

sub JIRA_REST { shift->jira->{jira_rest} }

=internal_method B<REST_CLIENT>

An accessor that returns the C<REST::Client> object inside the C<JIRA::REST> object being used.

=cut

sub REST_CLIENT { shift->JIRA_REST->{rest} }

=method B<make_object>

A pass-through method that calls C<JIRA::REST::Class::Factory::make_object()>.

=method B<make_date>

A pass-through method that calls C<JIRA::REST::Class::Factory::make_date()>.

=method B<class_for>

A pass-through method that calls C<JIRA::REST::Class::Factory::get_factory_class()>.

=cut

sub make_object { shift->factory->make_object(@_) }
sub make_date   { shift->factory->make_date(@_) }
sub class_for   { shift->factory->get_factory_class(@_) }

=method B<obj_isa>

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
    my @types = $self->jira->link_types;
    foreach my $type ( @types ) {
        if (lc $link eq lc $type->inward) {
            return $type->name, 'inward';
        }
        if (lc $link eq lc $type->outward) {
            return $type->name, 'outward';
        }
        if (lc $link eq lc $type->name) {
            return $type->name, $dir;
        }
    }

    # we didn't find anything, so just return what we were passed
    return $link, $dir;
}

=internal_method B<populate_scalar_data>

Code to make instantiating objects from $self->data easier.

=cut

sub populate_scalar_data {
    my ($self, $name, $type, $field) = @_;

    $self->{$name} = $self->make_object($type, {
        data => $self->data->{$field}
    });
}

=internal_method B<populate_date_data>

Code to make instantiating DateTime objects from $self->data easier.

=cut

sub populate_date_data {
    my ($self, $name, $field) = @_;
    $self->{$name} = $self->make_date( $self->data->{$field} );
}

=internal_method B<populate_list_data>

Code to make instantiating lists of objects from $self->data easier.

=cut

sub populate_list_data {
    my ($self, $name, $type, $field) = @_;
    $self->{$name} = [
        map {
            $self->make_object($type, { data => $_ })
        } @{ $self->data->{$field} }
    ];
}

=internal_method B<populate_scalar_field>

Code to make instantiating objects from fields easier.

=cut

sub populate_scalar_field {
    my ($self, $name, $type, $field) = @_;
    $self->{$name} = $self->make_object($type, {
        data => $self->fields->{$field}
    });
}

=internal_method B<populate_list_field>

Code to make instantiating lists of objects from fields easier.

=cut

sub populate_list_field {
    my ($self, $name, $type, $field) = @_;
    $self->{$name} = [
        map {
            $self->make_object($type, { data => $_ })
        } @{ $self->fields->{$field} }
    ];
}

###########################################################################
#
# the code in here is liberally borrowed from
# Class::Accessor, Class::Accessor::Fast, and Class::Accessor::Contextual
#

if (eval { require Sub::Name }) {
    Sub::Name->import;
}

=method B<mk_contextual_ro_accessors> list of accessors to make

Because I didn't want to give up Class::Accessor::Fast, but wanted to be
able to make contextual accessors when it was useful.

=cut

sub mk_contextual_ro_accessors {
    my($class, @fields) = @_;

    foreach my $field ( @fields ) {
        my $accessor = sub {
            if (@_ == 1) {
                return $_[0]->{$field} unless wantarray;
                return @{ $_[0]->{$field} } if ref($_[0]->{$field}) eq 'ARRAY';
                return %{ $_[0]->{$field} } if ref($_[0]->{$field}) eq 'HASH';
                return $_[0]->{$field};
            }
            else {
                my $caller = caller;
                $_[0]->_croak("'$caller' cannot alter the value of '$field' " .
                              "on objects of class '$class'");
            }
        };

        $class->make_subroutine($field, $accessor);
    }

    return $class;
};

=method B<mk_deep_ro_accessor> LIST OF KEYS TO HASH

Why do accessors have to be only for the top level of the hash?  Why can't they be several layers deep?  This method takes a list of keys for the hash this object is based on and creates an accessor that goes down deeper than just the first level.

=cut

sub mk_deep_ro_accessor {
    my($class, @field) = @_;

    my $accessor = sub {
        if (@_ == 1) {
            my $ptr = $_[0];
            foreach my $f (@field) {
                $ptr = $ptr->{$f};
            }
            return $ptr unless wantarray;
            return @$ptr if ref($ptr) eq 'ARRAY';
            return %$ptr if ref($ptr) eq 'HASH';
            return $ptr;
        }
        else {
            my $caller = caller;
            $_[0]->_croak("'$caller' cannot alter the value of '$field[-1]' " .
                          "on objects of class '$class'");
        }
    };

    $class->make_subroutine($field[-1], $accessor);

    return $class;
};

=method B<mk_lazy_ro_accessor> field, sub_ref_to_construct_value

Makes an accessor that checks to see if the value for the accessor has been loaded, and, if it hasn't, runs the provided subroutine to construct the value.  Especially good for loading values that are objects populated by REST calls.

=cut

sub mk_lazy_ro_accessor {
    my($class, $field, $constructor) = @_;

    my $accessor = sub {
        if (@_ == 1) {
            unless ($_[0]->{lazy_loaded}->{$field}) {
                $_[0]->{$field} = $constructor->(@_);
                $_[0]->{lazy_loaded}->{$field} = 1;
            }
            return $_[0]->{$field} unless wantarray;
            return @{ $_[0]->{$field} } if ref($_[0]->{$field}) eq 'ARRAY';
            return %{ $_[0]->{$field} } if ref($_[0]->{$field}) eq 'HASH';
            return $_[0]->{$field};
        }
        else {
            my $caller = caller;
            $_[0]->_croak("'$caller' cannot alter the value of '$field' " .
                          "on objects of class '$class'");
        }
    };

    $class->make_subroutine($field, $accessor);

    return $class;
};

=internal_method B<mk_data_ro_accessors>

Makes accessors for keys under $self->{data}

=cut

sub mk_data_ro_accessors {
    my $class = shift;

    foreach my $field ( @_ ) {
        $class->mk_deep_ro_accessor(qw( data ), $field);
    }
}

=internal_method B<mk_field_ro_accessors>

Makes accessors for keys under $self->{data}->{fields}

=cut

sub mk_field_ro_accessors {
    my $class = shift;

    foreach my $field ( @_ ) {
        $class->mk_deep_ro_accessor(qw( data fields ), $field);
    }
}

=internal_method B<make_subroutine>

Takes a subroutine name and a subroutine reference, and blesses the subroutine into the class used to call this method.  Can be called with either a class name or a blessed object reference.

=cut

{   # we're going some magic here
    no strict 'refs'; ## no critic

    sub make_subroutine {
        my($proto, $name, $sub) = @_;
        my($class) = ref $proto || $proto;

        my $fullname = "${class}::$name";
        unless (defined &{$fullname}) {
            subname($fullname, $sub) if defined &subname;
            *{$fullname} = $sub;
        }
    }

} # end of ref no-stricture zone

###########################################################################

=method B<dump>

Returns a stringified representation of the issue's data generated by Data::Dumper::Concise.

=cut

sub dump {
    my $self = shift;
    return $self->shallow_dump( $self );
}

=internal_method B<shallow_dump> THING

A utility function to produce a shallow dump of a thing.

=cut

sub shallow_dump {
    shift; # we don't need $self
    return Dumper( __shallow_copy(@_, 'top') );
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
        elsif ($top) {
            if (reftype $thing eq 'ARRAY') {
                return [ map { __shallow_copy($_) } @{$thing} ], $class;
            }
            elsif (reftype $thing eq 'HASH') {
                return +{
                    map { $_ => __shallow_copy($thing->{$_}) } keys %{$thing}
                }, $class;
            }
            return Dumper($thing);
        }
        else {
            foreach my $method (qw/ name key id /) {
                if ( $thing->can($method) ) {
                    return sprintf '%s->%s(%s)',
                        $class, $method, $thing->$method;
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

1;

