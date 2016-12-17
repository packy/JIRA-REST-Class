package JIRA::REST::Class::Version;
use base qw( Exporter );
use strict;
use warnings;
use v5.10;

#ABSTRACT: The module that exports the current version of L<JIRA::REST::Class> to the rest of the modules in the project.

=head1 DESCRIPTION

The sole purpose of this module is to have a single point of modification
for the version number for the release.  I'm using Dist::Zilla's
L<BumpVersionAfterRelease|Dist::Zilla::Plugin::BumpVersionAfterRelease>,
which modifies the source code after a release is built, and I didn't want
ALL of my source files to get modified, since I would then have to commit
ALL of those changes into git.

I've chosen not to have $VERSION imported by default, so it's obvious to
anyone reading the code using this module that it's getting its $VERSION
variable from this module.

=cut

our @EXPORT_OK = qw( $VERSION $SOURCE );

=head2 $VERSION

The version of the L<JIRA::REST::Class> module.

=cut

our $VERSION = '0.03';

=head2 $SOURCE

Where this L<JIRA::REST::Class> module claims to be installed from.

Currently, the possible values are 'CPAN' and 'GitHub'. The value for this
variable is set to default to 'GitHub' in the master source, but the process
for packaging the module for distribution on CPAN modifies the code so it
contains 'CPAN'.

Useful if you are concerned with whether features are implemented or not,
since code from GitHub should report a version one version ahead of the
last tagged release, due to the actions of L<BumpVersionAfterRelease|Dist::Zilla::Plugin::BumpVersionAfterRelease>.

=cut

our $SOURCE = 'CPAN';
# the following line will be commented out by Dist::Zilla
$SOURCE = 'GitHub'; # COMMENT

1;
