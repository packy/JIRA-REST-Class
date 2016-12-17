package JIRA::REST::Class::Issue::Changelog::Change::Item;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents an individual item in an individual change to a JIRA issue as an object.

__PACKAGE__->mk_data_ro_accessors(qw/ field fieldtype
                                      from fromString
                                      to toString /);

1;

=accessor B<field>

=accessor B<fieldtype>

=accessor B<from>

=accessor B<fromString>

=accessor B<to>

=accessor B<toString>

{{
   use Path::Tiny;
   $OUT .= q{=for stopwords};
   for my $word ( sort( path("stopwords.ini")->lines( { chomp => 1 } ) ) ) {
       $OUT .= qq{ $word};
   }
   $OUT .= qq{\n};
}}
