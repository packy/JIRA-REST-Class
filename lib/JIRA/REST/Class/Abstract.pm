package JIRA::REST::Class::Abstract;
use parent qw( Class::Accessor::Fast JIRA::REST::Class::Mixins );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.09';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: An abstract class for L<JIRA::REST::Class|JIRA::REST::Class> that most of the other objects are based on.

use Carp;
use Data::Dumper::Concise;
use Scalar::Util qw( weaken blessed reftype refaddr);

__PACKAGE__->mk_ro_accessors( qw( data issue lazy_loaded ) );

=internal_method B<init>

Method to perform post-instantiation initialization of the object. The first
argument must be the factory object which created the object.  Subclasses of
C<JIRA::REST::Class::Abstract> are expected to call
C<< $self->SUPER::init(@_); >> somewhere in their own C<init()>.

=cut

sub init {
    my $self    = shift;
    my $factory = shift;

    # the first thing we're passed is supposed to be the factory object
    if (   blessed $factory
        && blessed $factory eq 'JIRA::REST::Class::Factory' ) {

        # grab the arguments that the class was called with from the factory
        # and make new factory and class objects with the same aguments so we
        # don't have circular dependency issues

        my $args = $factory->{args};
        $self->factory( $args );
        $self->jira( $args );
    }
    else {
        # if we're not passed a factory, let's complain about it
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        confess 'factory not passed to init!';
    }

    # unload any lazily loaded data
    $self->unload_lazy;

    # init() has to return the object!
    return $self;
}

=internal_method B<unload_lazy>

I'm using a hash to track which lazily loaded methods have already been
loaded, and this method clears that hash (and the field that got loaded) so
they get loaded again.

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
        $self->{lazy_loaded} = {};
    }
    return;
}

=internal_method B<populate_scalar_data>

Code to make instantiating objects from C<< $self->{data} >> easier.  Accepts
three unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting object

=item * nickname for object type being created (to be passed to C<make_object()>)

=item * key under C<< $self->{data} >> that should be passed as the data to C<make_object()>

=back

=cut

sub populate_scalar_data {
    my ( $self, $name, $type, $field ) = @_;

    if ( defined $self->data->{$field} ) {
        $self->{$name} = $self->make_object(
            $type,
            {
                data => $self->data->{$field}
            }
        );
    }
    return;
}

=internal_method B<populate_date_data>

Code to make instantiating DateTime objects from C<< $self->{data} >> easier.
Accepts two unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting object

=item * key under C<< $self->{data} >> that should be passed as the data to C<make_date()>

=back

=cut

sub populate_date_data {
    my ( $self, $name, $field ) = @_;
    if ( defined $self->data->{$field} ) {
        $self->{$name} = $self->make_date( $self->data->{$field} );
    }
    return;
}

=internal_method B<populate_list_data>

Code to make instantiating lists of objects from C<< $self->{data} >> easier.
Like L</populate_scalar_data>, it accepts three unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting list reference

=item * nickname for object type being created (to be passed to C<make_object()>) as each item in the list

=item * key under C<< $self->{data} >> that should be interpreted as a list reference, each element of which is passed as the data to C<make_object()>

=back

=cut

sub populate_list_data {
    my ( $self, $name, $type, $field ) = @_;
    if ( defined $self->data->{$field} ) {
        $self->{$name} = [  # stop perltidy from pulling
            map {           # these lines together
                $self->make_object( $type, { data => $_ } )
            } @{ $self->data->{$field} }
        ];
    }
    else {
        $self->{$name} = [];  # rather than undefined, return an empty list
    }
    return;
}

=internal_method B<populate_scalar_field>

Code to make instantiating objects from C<<  $self->{data}->{fields} >> easier.   Accepts
three unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting object

=item * nickname for object type being created (to be passed to C<make_object()>)

=item * key under C<<  $self->{data}->{fields} >> that should be passed as the data to C<make_object()>

=back

=cut

sub populate_scalar_field {
    my ( $self, $name, $type, $field ) = @_;
    if ( defined $self->fields->{$field} ) {
        $self->{$name} = $self->make_object(
            $type,
            {
                data => $self->fields->{$field}
            }
        );
    }
    return;
}

=internal_method B<populate_list_field>

Code to make instantiating lists of objects from C<<  $self->{data}->{fields} >> easier.
Like L</populate_scalar_field>, it accepts three unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting list reference

=item * nickname for object type being created (to be passed to C<make_object()>) as each item in the list

=item * key under C<<  $self->{data}->{fields} >> that should be interpreted as a list reference, each element of which is passed as the data to C<make_object()>

=back

=cut

sub populate_list_field {
    my ( $self, $name, $type, $field ) = @_;
    if ( defined $self->fields->{$field} ) {
        $self->{$name} = [  # stop perltidy from pulling
            map {           # these lines together
                $self->make_object( $type, { data => $_ } )
            } @{ $self->fields->{$field} }
        ];
    }
    else {
        $self->{$name} = [];  # rather than undefined, return an empty list
    }
    return;
}

###########################################################################
#
# the code in here is liberally borrowed from
# Class::Accessor, Class::Accessor::Fast, and Class::Accessor::Contextual
#

if ( eval { require Sub::Name } ) {
    Sub::Name->import;
}

=internal_method B<mk_contextual_ro_accessors>

Because I didn't want to give up
L<Class::Accessor::Fast|Class::Accessor::Fast>, but wanted to be able to
make contextual accessors when it was useful.  Accepts a list of accessors
to make.

=cut

sub mk_contextual_ro_accessors {
    my ( $class, @fields ) = @_;

    foreach my $field ( @fields ) {
        my $accessor = sub {
            if ( @_ == 1 ) {
                my $ptr = $_[0];
                return $ptr->{$field} unless wantarray;
                return @{ $ptr->{$field} } if ref( $ptr->{$field} ) eq 'ARRAY';
                return %{ $ptr->{$field} } if ref( $ptr->{$field} ) eq 'HASH';
                return $ptr->{$field};
            }
            else {
                my $caller = caller;
                $_[0]->_croak( "'$caller' cannot alter the value of '$field' "
                        . "on objects of class '$class'" );
            }
        };

        $class->make_subroutine( $field, $accessor );
    }

    return $class;
}

=internal_method B<mk_deep_ro_accessor>

Why do accessors have to be only for the top level of the hash?  Why can't
they be several layers deep?  This method takes a list of keys for the hash
this object is based on and creates a contextual accessor that goes down
deeper than just the first level.

  # create accessor for $self->{foo}->{bar}->{baz}
  __PACKAGE__->mk_deep_ro_accessor(qw/ foo bar baz /);

=cut

sub mk_deep_ro_accessor {
    my ( $class, @field ) = @_;

    my $accessor = sub {
        if ( @_ == 1 ) {
            my $ptr = $_[0];
            foreach my $f ( @field ) {
                $ptr = $ptr->{$f};
            }
            return $ptr unless wantarray;
            return @$ptr if ref( $ptr ) eq 'ARRAY';
            return %$ptr if ref( $ptr ) eq 'HASH';
            return $ptr;
        }
        else {
            my $caller = caller;
            $_[0]->_croak( "'$caller' cannot alter the value of '$field[-1]' "
                    . "on objects of class '$class'" );
        }
    };

    $class->make_subroutine( $field[-1], $accessor );

    return $class;
}

=internal_method B<mk_lazy_ro_accessor>

Takes two parameters: field to make a lazy accessor for, and a subroutine
reference to construct the value of the accessor when it IS loaded.

This method makes an accessor with the given name that checks to see if the
value for the accessor has been loaded, and, if it hasn't, runs the provided
subroutine to construct the value and stores that value for later use.
Especially good for loading values that are objects populated by REST calls.

  # code to construct a lazy accessor named 'foo'
  __PACKAGE__->mk_lazy_ro_accessor('foo', sub {
      my $self = shift;
      # make the value for foo, in say, $foo
      return $foo;
  });

=cut

sub mk_lazy_ro_accessor {
    my ( $class, $field, $constructor ) = @_;

    my $accessor = sub {
        if ( @_ == 1 ) {
            unless ( $_[0]->{lazy_loaded}->{$field} ) {
                $_[0]->{$field} = $constructor->( @_ );
                $_[0]->{lazy_loaded}->{$field} = 1;
            }
            return $_[0]->{$field} unless wantarray;
            return @{ $_[0]->{$field} } if ref( $_[0]->{$field} ) eq 'ARRAY';
            return %{ $_[0]->{$field} } if ref( $_[0]->{$field} ) eq 'HASH';
            return $_[0]->{$field};
        }
        else {
            my $caller = caller;
            $_[0]->_croak( "'$caller' cannot alter the value of '$field' "
                    . "on objects of class '$class'" );
        }
    };

    $class->make_subroutine( $field, $accessor );

    return $class;
}

=internal_method B<mk_data_ro_accessors>

Makes accessors for keys under C<< $self->{data} >>

=cut

sub mk_data_ro_accessors {
    my ( $class, @args ) = @_;

    foreach my $field ( @args ) {
        $class->mk_deep_ro_accessor( qw( data ), $field );
    }
    return;
}

=internal_method B<mk_field_ro_accessors>

Makes accessors for keys under C<< $self->{data}->{fields} >>

=cut

sub mk_field_ro_accessors {
    my ( $class, @args ) = @_;

    foreach my $field ( @args ) {
        $class->mk_deep_ro_accessor( qw( data fields ), $field );
    }
    return;
}

=internal_method B<make_subroutine>

Takes a subroutine name and a subroutine reference, and blesses the
subroutine into the class used to call this method.  Can be called with
either a class name or a blessed object reference.

=cut

{
    # we're going some magic here, so we turn off our self-restrictions
    no strict 'refs'; ## no critic (ProhibitNoStrict)

    sub make_subroutine {
        my ( $proto, $name, $sub ) = @_;
        my ( $class ) = ref $proto || $proto;

        my $fullname = "${class}::$name";
        unless ( defined &{$fullname} ) {
            subname( $fullname, $sub ) if defined &subname;
            *{$fullname} = $sub;
        }
        return;
    }

}  # end of ref no-stricture zone

1;

__END__

{{ include( "pod/mixins.pod" )->fill_in; }}

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
