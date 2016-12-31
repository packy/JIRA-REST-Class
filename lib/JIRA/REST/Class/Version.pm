package JIRA::REST::Class::Version;
use parent qw( Exporter );
use strict;
use warnings;
use 5.010;

#ABSTRACT: The module that exports the current version of L<JIRA::REST::Class|JIRA::REST::Class> to the rest of the modules in the project.

#pod =head1 DESCRIPTION
#pod
#pod The sole purpose of this module is to have a single point of modification
#pod for the version number for the release.  I'm using Dist::Zilla's
#pod L<BumpVersionAfterRelease|Dist::Zilla::Plugin::BumpVersionAfterRelease>,
#pod which modifies the source code after a release is built, and I didn't want
#pod ALL of my source files to get modified, since I would then have to commit
#pod ALL of those changes into git.
#pod
#pod I've chosen not to have $VERSION imported by default, so it's obvious to
#pod anyone reading the code using this module that it's getting its $VERSION
#pod variable from this module.
#pod
#pod =cut

our @EXPORT_OK = qw( $VERSION $SOURCE );

#pod =head2 $VERSION
#pod
#pod The version of the L<JIRA::REST::Class|JIRA::REST::Class> module.
#pod
#pod =cut

our $VERSION = '0.05';

#pod =head2 $SOURCE
#pod
#pod Where this L<JIRA::REST::Clas|JIRA::REST::Class> module claims to be
#pod installed from.
#pod
#pod Currently, the possible values are 'CPAN' and 'GitHub'. The value for this
#pod variable is set to default to 'GitHub' in the master source, but the process
#pod for packaging the module for distribution on CPAN modifies the code so it
#pod contains 'CPAN'.
#pod
#pod Useful if you are concerned with whether features are implemented or not,
#pod since code from GitHub should report a version one version ahead of the
#pod last tagged release, due to the actions of
#pod L<BumpVersionAfterRelease|Dist::Zilla::Plugin::BumpVersionAfterRelease>.
#pod
#pod =for stopwords BumpVersionAfterRelease
#pod
#pod =cut

our $SOURCE = 'CPAN';

# the following line will be commented out by Dist::Zilla
## $SOURCE = 'GitHub';  # COMMENT

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik BumpVersionAfterRelease

=head1 NAME

JIRA::REST::Class::Version - The module that exports the current version of L<JIRA::REST::Class|JIRA::REST::Class> to the rest of the modules in the project.

=head1 VERSION

version 0.05

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

=head2 $VERSION

The version of the L<JIRA::REST::Class|JIRA::REST::Class> module.

=head2 $SOURCE

Where this L<JIRA::REST::Clas|JIRA::REST::Class> module claims to be
installed from.

Currently, the possible values are 'CPAN' and 'GitHub'. The value for this
variable is set to default to 'GitHub' in the master source, but the process
for packaging the module for distribution on CPAN modifies the code so it
contains 'CPAN'.

Useful if you are concerned with whether features are implemented or not,
since code from GitHub should report a version one version ahead of the
last tagged release, due to the actions of
L<BumpVersionAfterRelease|Dist::Zilla::Plugin::BumpVersionAfterRelease>.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
