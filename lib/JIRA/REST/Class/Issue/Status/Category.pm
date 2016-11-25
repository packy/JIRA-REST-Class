package JIRA::REST::Class::Issue::Status::Category;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents the category of an issue's status.

__PACKAGE__->mk_data_ro_accessors(qw/ name colorName id key self /);

1;
