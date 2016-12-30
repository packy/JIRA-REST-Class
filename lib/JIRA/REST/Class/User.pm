package JIRA::REST::Class::User;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

use JIRA::REST::Class::Version qw( $VERSION );

# ABSTRACT: A helper class for L<JIRA::REST::Class> that represents a JIRA user as an object.

use Readonly;

Readonly my @ACCESSORS = qw( active avatarUrls displayName emailAddress key
                             name self timeZone );

__PACKAGE__->mk_data_ro_accessors( @ACCESSORS );

1;

=accessor B<active>

A boolean indicating whether or not the user is active.

=accessor B<avatarUrls>

A hashref of the different sizes available for the project's avatar.

=accessor B<displayName>

The display name of the user.

=accessor B<emailAddress>

The email address of the user.

=accessor B<key>

The key for the user.

=accessor B<name>

The short name of the user.

=accessor B<self>

The URL of the JIRA REST API for the user

=accessor B<timeZone>

The home time zone of the user.

=cut

__END__

{{
    require "pod/PodUtil.pm";
    $OUT .= PodUtil::include_stopwords();
    $OUT .= PodUtil::related_classes($plugin);
}}
