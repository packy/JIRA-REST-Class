package JIRA::REST::Class::Factory;
use parent qw( Class::Factory::Enhanced );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
$SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A factory class for building all the other classes in L<JIRA::REST::Class|JIRA::REST::Class>.

=head1 DESCRIPTION

This module imports a hash of object type package names from L<JIRA::REST::Class::FactoryTypes|JIRA::REST::Class::FactoryTypes>.

=cut

# we import the list of every class this factory knows how to make
#
use JIRA::REST::Class::FactoryTypes qw( %TYPES );
JIRA::REST::Class::Factory->add_factory_type( %TYPES );

use Carp;
use DateTime::Format::Strptime;

=internal_method B<init>

Initialize the factory object.  Just copies all the elements in the hashref that were passed in to the object itself.

=cut

sub init {
    my $self = shift;
    my $args = shift;
    my @keys = keys %$args;
    @{$self}{@keys} = @{$args}{@keys};
    return $self;
}

=internal_method B<get_factory_class>

Inherited method from L<Class::Factory|Class::Factory/Factory_Methods>.

=internal_method B<make_object>

A tweaked version of C<make_object_for_type> from
L<Class::Factory::Enhanced|Class::Factory::Enhanced/make_object_for_type>
that calls C<init()> with a copy of the factory.

=cut

sub make_object {
    my ( $self, $object_type, @args ) = @_;
    my $class = $self->get_factory_class( $object_type );
    my $obj   = $class->new( @args );
    $obj->init( $self );  # make sure we pass the factory into init()
    return $obj;
}

=internal_method B<make_date>

Make it easy to get L<DateTime|DateTime> objects from the factory. Parses
JIRA date strings, which are in a format that can be parsed by the
L<DateTime::Format::Strptime|DateTime::Format::Strptime> patterns
C<%FT%T.%N%z> or C<%F>

=cut

sub make_date {
    my ( $self, $date ) = @_;
    return unless $date;
    my $pattern = ( $date =~ m/\dt\d/ ) ? '%FT%T.%N%z' : '%F';

    my $parser = DateTime::Format::Strptime->new(
        pattern => $pattern,
        on_error => 'croak',
    );
    return (
        $parser->parse_datetime( $date )
            confess qq{Unable to parse date "$date" using pattern "$pattern"}
    );
}

=internal_method B<factory_error>

Throws errors from the factory with stack traces

=cut

sub factory_error {
    my ( $class, $err, @args ) = @_;

    # start the stacktrace where we called make_object()
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::confess "$err\n", @args;
}

1;

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::related_classes($plugin);
}}
