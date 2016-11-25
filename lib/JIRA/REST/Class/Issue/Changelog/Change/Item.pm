package JIRA::REST::Class::Issue::Changelog::Change::Item;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

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
