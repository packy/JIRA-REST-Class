package JIRA::REST::Class::Abstract;
use base qw( Class::Accessor::Fast JIRA::REST::Class::Mixins );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: An abstract class for C<JIRA::REST::Class> that most of the other objects are based on.

use Carp;
use Data::Dumper::Concise;
use Scalar::Util qw( weaken blessed reftype refaddr);

__PACKAGE__->mk_ro_accessors(qw( data issue lazy_loaded ));

=method B<init>

Method to perform post-instantiation initialization of the object. The first argument will be the factory object which created the object.

=cut

sub init {
    my $self    = shift;
    my $factory = shift;

    # the first thing we're passed is supposed to be the factory object
    if (blessed $factory && blessed $factory eq 'JIRA::REST::Class::Factory') {

        # grab the arguments that the class was called with from the factory
        # and make new factory and class objects with the same aguments so we
        # don't have circular dependency issues

        my $args = $factory->{args};
        $self->factory($args);
        $self->jira($args);
    }
    else {
        # if we're not passed a factory, let's complain about it
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        confess "factory not passed to init!";
    }

    # unload any lazily loaded data
    $self->unload_lazy;

    # init() has to return the object!
    return $self;
}

=internal_method B<unload_lazy>

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

=internal_method B<populate_scalar_data>

Code to make instantiating objects from $self->data easier.

=cut

sub populate_scalar_data {
    my ($self, $name, $type, $field) = @_;

    if (defined $self->data->{$field}) {
        $self->{$name} = $self->make_object($type, {
            data => $self->data->{$field}
        });
    }
}

=internal_method B<populate_date_data>

Code to make instantiating DateTime objects from $self->data easier.

=cut

sub populate_date_data {
    my ($self, $name, $field) = @_;
    if (defined $self->data->{$field}) {
        $self->{$name} = $self->make_date( $self->data->{$field} );
    }
}

=internal_method B<populate_list_data>

Code to make instantiating lists of objects from $self->data easier.

=cut

sub populate_list_data {
    my ($self, $name, $type, $field) = @_;
    if (defined $self->data->{$field}) {
        $self->{$name} = [
            map {
                $self->make_object($type, { data => $_ })
            } @{ $self->data->{$field} }
        ];
    }
    else {
        $self->{$name} = []; # rather than undefined, return an empty list
    }
}

=internal_method B<populate_scalar_field>

Code to make instantiating objects from fields easier.

=cut

sub populate_scalar_field {
    my ($self, $name, $type, $field) = @_;
    if (defined $self->fields->{$field}) {
        $self->{$name} = $self->make_object($type, {
            data => $self->fields->{$field}
        });
    }
}

=internal_method B<populate_list_field>

Code to make instantiating lists of objects from fields easier.

=cut

sub populate_list_field {
    my ($self, $name, $type, $field) = @_;
    if (defined $self->fields->{$field}) {
        $self->{$name} = [
            map {
                $self->make_object($type, { data => $_ })
            } @{ $self->fields->{$field} }
        ];
    }
    else {
        $self->{$name} = []; # rather than undefined, return an empty list
    }
}

###########################################################################
#
# the code in here is liberally borrowed from
# Class::Accessor, Class::Accessor::Fast, and Class::Accessor::Contextual
#

if (eval { require Sub::Name }) {
    Sub::Name->import;
}

=internal_method B<mk_contextual_ro_accessors> list of accessors to make

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

=internal_method B<mk_deep_ro_accessor> LIST OF KEYS TO HASH

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

=internal_method B<mk_lazy_ro_accessor> field, sub_ref_to_construct_value

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


1;

