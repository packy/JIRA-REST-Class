package JIRA::REST::Class::User;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents a JIRA user as an object.

__PACKAGE__->mk_data_ro_accessors(qw( active avatarUrls displayName emailAddress key name self timeZone));

1;

=method B<active>
A boolean indicating whether or not the user is active.

=method B<avatarUrls>
A hashref of the different sizes available for the project's avatar.

=method B<displayName>
The display name of the user.

=method B<emailAddress>
The email address of the user.

=method B<key>
The key for the user.

=method B<name>
The short name of the user.

=method B<self>
The URL of the JIRA REST API for the user

=method B<timeZone>
The home time zone of the user.

