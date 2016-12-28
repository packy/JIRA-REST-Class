package PodUtil;
use strict;
use warnings;
use 5.010;

use lib 'lib';
use Data::Dumper::Concise;
use JIRA::REST::Class::FactoryTypes qw( %TYPES );
use Path::Tiny;

sub include_stopwords {
    my $OUT = q{=for stopwords};

    for my $word ( sort( path( 'stopwords.ini' )->lines( { chomp => 1 } ) ) ) {
        $OUT .= qq{ $word};
    }
    $OUT .= qq{\n};

    return $OUT;
}

sub related_classes {
    my ( $plugin ) = @_;
    my $base       = 'JIRA::REST::Class';
    my $classes    = qr/${base}[:\w]*/ix;

    my $file = $plugin->tt_file;

    $plugin->log( 'processing ' . $file->name );

    my $content = $file->content;
    my ( $pkg ) = $content =~ /package\s+($classes)/x;
    $plugin->log( "  package $pkg" );

    my %related;
    foreach my $class ( $content =~ /($classes)/gx ) {
        next if $class eq $pkg;
        $plugin->log( "    found $class " );
        $related{$class} = 1;
    }

    foreach my $nickname ( $content =~ /make_object[(]([^,]+)/gx ) {

        # the first argument to make_object() is a perl string,
        # so let's just use eval to find the value of that string.
        $nickname = eval $nickname; ## no critic ( ProhibitStringyEval )
        next unless $nickname && exists $TYPES{$nickname};
        my $class = $TYPES{$nickname};
        next if $class eq $pkg;
        $plugin->log( "    found $class from make_object($nickname)" );
        $related{$class} = 1;
    }

    my @list = sort keys %related;
    return q{} unless @list;

    my $OUT = "\n=head1 RELATED CLASSES\n\n=over 2\n\n";
    foreach my $item ( @list ) {
        $OUT .= sprintf qq{=item * L<%s|%s>\n\n}, $item, $item;
    }
    $OUT .= "=back\n\n";
    return $OUT;
}

1;

