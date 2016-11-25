package JIRA::REST::Class::Issue;
use base qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

# ABSTRACT: A helper class for C<JIRA::REST::Class> that represents an individual JIRA issue as an object.

use Readonly;
use Scalar::Util qw( weaken );

# creating a bunch of read-only accessors

# contextual returns lists or arrayrefs, depending on context
Readonly my @CONTEXTUAL => qw( components versions );

__PACKAGE__->mk_contextual_ro_accessors(@CONTEXTUAL);

# fields that will be turned into JIRA::REST::Class::User objects
Readonly my @USERS => qw( assignee creator reporter );

# fields that will be turned into DateTime objects
Readonly my @DATES => qw( created duedate lastViewed resolutiondate updated );

# other fields we're objectifying and storing at the top level of the hash
Readonly my @TOP_LEVEL => qw( project issuetype status url );

__PACKAGE__->mk_ro_accessors(@TOP_LEVEL, @USERS, @DATES);

# fields that are under $self->{data}
Readonly my @DATA => qw( expand fields id key self );
__PACKAGE__->mk_data_ro_accessors(@DATA);

# fields that are under $self->{data}->{fields}
Readonly my @FIELDS => qw( aggregateprogress aggregatetimeestimate
                           aggregatetimeoriginalestimate aggregatetimespent
                           description environment fixVersions issuelinks
                           labels priority progress resolution summary
                           timeestimate timeoriginalestimate timespent
                           votes watches workratio );

__PACKAGE__->mk_field_ro_accessors(@FIELDS);

use overload
    '""'   => sub { shift->key },
    '0+'   => sub { shift->id  },
    '<=>'  => sub {
        my($A, $B) = @_;
        my $AA = ref $A ? $A->id : $A;
        my $BB = ref $B ? $B->id : $B;
        $AA <=> $BB
    },
    'cmp'  => sub {
        my($A, $B) = @_;
        my $AA = ref $A ? $A->key : $A;
        my $BB = ref $B ? $B->key : $B;
        $AA cmp $BB
    };

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{url} = $self->jira->strip_protocol_and_host($self->self);

    # make user objects
    foreach my $field ( @USERS ) {
        $self->populate_scalar_field($field, 'user', $field);
    }

    # make date objects
    foreach my $field ( @DATES ) {
        $self->{$field} = $self->make_date( $self->fields->{$field} );
    }

    $self->populate_list_field('components',     'projectcomp',  'components');
    $self->populate_scalar_field('project',      'project',      'project');
    $self->populate_scalar_field('issuetype',    'issuetype',    'issuetype');
    $self->populate_scalar_field('status',       'status',       'status');
    $self->populate_scalar_field('timetracking', 'timetracking', 'timetracking');
    $self->populate_list_field('versions',       'projectvers',  'versions');

    unless (defined &is_bug) {
        # if we haven't defined booleans to determine whether or not this
        # issue is a particular type, define those methods now
        foreach my $type ( $self->jira->issue_types ) {
            (my $subname = lc 'is_'.$type->name) =~ s/\s+|\-/_/g;
            $self->make_subroutine($subname, sub {
                shift->fields->{issuetype}->{id} == $type->id
            });
        }
    }
}

sub component_count { scalar @{ shift->{components} } }

#
# rather than just use the minimal information in the issue's
# parent hash, fetch the parent issue fully when someone first
# uses the parent_accessor
#

sub has_parent { exists shift->fields->{parent} }

__PACKAGE__->mk_lazy_ro_accessor('parent', sub {
    my $self = shift;
    return unless $self->has_parent; # some issues have no parent

    my $parent = $self->fields->{parent}->{self};
    my $url    = $self->jira->strip_protocol_and_host($parent);
    $self->make_object('issue', { data => $self->jira->get($url) });
});

__PACKAGE__->mk_lazy_ro_accessor('changelog', sub {
    my $self = shift;
    $self->make_object('changelog');
});

__PACKAGE__->mk_lazy_ro_accessor('worklog', sub {
    my $self = shift;
    $self->make_object('worklog');
});

__PACKAGE__->mk_lazy_ro_accessor('transitions', sub {
    my $self = shift;
    $self->make_object('transitions');
});

__PACKAGE__->mk_lazy_ro_accessor('timetracking', sub {
    my $self = shift;
    $self->make_object('timetracking');
});

=method B<make_object>

A pass-through method that calls C<JIRA::REST::Class::Factory::make_object()>, but adds a weakened link to this issue in the object as well.

=cut

sub make_object {
    my $self = shift;
    my $type = shift;
    my $args = shift || {};

    # if we weren't passed an issue, link to ourselves
    unless (exists $args->{issue}) {
        $args->{issue} = $self;
    }

    my $class = $self->factory->get_factory_class($type);
    my $obj = $class->new($args);

    if (exists $obj->{issue}) {
        weaken $obj->{issue}; # make the link to ourselves weak
    }

    $obj->init($self);    # NOW we call init

    return $obj;
}

###########################################################################

=method B<add_comment>

Adds whatever is passed in as a comment on the issue.

=cut

sub add_comment {
    my $self = shift;
    my $text = shift;
    $self->post("/comment", { body => $text });
}

=method B<add_label>

Adds whatever is passed in as a label for the issue.

=cut

sub add_label {
    my $self  = shift;
    my $label = shift;
    $self->update( labels => [ { add => $label } ] );
}

=method B<remove_label>

Removes whatever is passed in from the labels for the issue.

=cut

sub remove_label {
    my $self  = shift;
    my $label = shift;
    $self->update( labels => [ { remove => $label } ] );
}

=method B<add_component>

Adds whatever is passed in as a component for the issue.

=cut

sub add_component {
    my $self = shift;
    my $comp = shift;
    $self->update( components => [ { add => { name => $comp } } ] );
}

=method B<remove_component>

Removes whatever is passed in from the components for the issue.

=cut

sub remove_component {
    my $self = shift;
    my $comp = shift;
    $self->update( components => [ { remove => { name => $comp } } ] );
}

=method B<set_assignee>

Sets the assignee for the issue to be the user passed in.  Can either be a string representing the name or a C<JIRA::REST::Class::User> object.

=cut

sub set_assignee {
    my $self = shift;
    my $name = $self->name_for_user(@_);
    $self->put_field(assignee => { name => $name });
}

=method B<set_reporter>

Sets the reporter for the issue to be the user passed in.  Can either be a string representing the name or a C<JIRA::REST::Class::User> object.

=cut

sub set_reporter {
    my $self = shift;
    my $name = $self->name_for_user(shift);
    $self->put_field(reporter => { name => $name });
}

=method B<add_issue_link>

Adds a link from this issue to another one.  Accepts the link type (either a string representing the name or a C<JIRA::REST::Class::Issue::LinkType>), the issue to be linked to, and (optionally) the direction of the link (inward/outward).  If the direction cannot be determined from the name of the link type, the default direction is 'inward';

=cut

sub add_issue_link {
    my ($self, $type, $key, $dir) = @_;
    $key = $self->key_for_issue($key);
    ($type, $dir) = $self->find_link_name_and_direction($type, $dir);

    my $links = [{
        add => {
            type         => { name => $type },
            $dir.'Issue' => { key => $key },
        },
    }];
    $self->update( issuelinks => $links );
}

=method B<add_subtask>

Adds a subtask to the current issue.  Accepts the summary and description of the task as parameters, along with an optional hash reference of additional fields to define for the subtask.  The project key and parent key are taken from the current issue, and the issue type ID is assigned from ...

TODO: currently, this is hardcoded to use issue type id 8, Technical Task. This should be genericized.

=cut

sub add_subtask {
    my $self    = shift;
    my $summary = shift;
    my $desc    = shift;
    my $fields  = shift;

    my $data = {
        fields => {
            project     => { key => $self->project->{key} },
            parent      => { key => $self->key },
            summary     => $summary,
            description => $desc,
            issuetype   => { id => 8 }
        }
    };

    if ($fields) {
        foreach my $field (keys %$fields) {
            $data->{fields}->{$field} = $fields->{$field};
        }
    }

    my $result  = $self->jira->post('issue', $data);
    my $url = 'issue/' . $result->{id};

    return $self->factory->make_object('issue', {
        data => $self->jira->get($url)
    });
}

###########################################################################

=method B<update>

Puts an update to JIRA.  Accepts a hash of fields => values to be put.

=cut

sub update {
    my $self = shift;
    my $hash = {};
    while (@_) {
        my $field = shift;
        my $value = shift;
        $hash->{$field} = $value;
    }
    $self->put({
        update => $hash,
    });
}

=method B<put_field>

Puts a value to a field.  Accepts the field name and the value as parameters.

=cut

sub put_field {
    my $self  = shift;
    my $field = shift;
    my $value = shift;
    $self->put({
        fields => { $field => $value },
    });
}

=method B<reload>

Reload the issue from the JIRA server.

=cut

sub reload {
    my $self = shift;
    $self->{data} = $self->get;
    $self->init;
}

###########################################################################

=internal_method B<get>

Wrapper around C<JIRA::REST>'s GET method that defaults to this issue's URL. Allows for extra parameters to be specified.

=cut

sub get {
    my $self  = shift;
    my $extra = shift // q{};
    $self->jira->get($self->url . $extra, @_);
}

=internal_method B<delete>

Wrapper around C<JIRA::REST::Class>' DELETE method that defaults to this issue's URL. Allows for extra parameters to be specified.

=cut

sub delete {
    my $self  = shift;
    my $extra = shift // q{};
    $self->jira->delete($self->url . $extra, @_);
}

=internal_method B<put>

Wrapper around C<JIRA::REST::Class>' PUT method that defaults to this issue's URL. Allows for extra parameters to be specified.

=cut

sub put {
    my $self = shift;
    $self->jira->put($self->url, @_);
}

=internal_method B<post>

Wrapper around C<JIRA::REST::Class>' POST method that defaults to this issue's URL. Allows for extra parameters to be specified.

=cut

sub post {
    my $self = shift;
    my $extra = shift // q{};
    $self->jira->post($self->url . $extra, @_);
}

=method B<sprints>

Generates a list of C<JIRA::REST::Class::Sprint> objects from the fields for an issue.  Uses the field_name() method on the C<JIRA::REST::Class> object to determine the name of the custom sprint field.

=cut

__PACKAGE__->mk_lazy_ro_accessor('sprints', sub {
    my $self = shift;

    # in my configuration, 'Sprint' is a custom field
    my $sprint_field = $self->jira->field_name('Sprint');

    my @sprints;
    foreach my $sprint ( @{ $self->fields->{$sprint_field} } ) {
        push @sprints, $self->make_object('sprint', { data => $sprint } );
    }
    return \@sprints;
});

=method B<children>

Returns a list of issue objects that are children of the issue. Requires the ScriptRunner plugin.

=cut

sub children {
    my $self = shift;
    my $key  = $self->key;
    my $children = $self->{jira}->query({
        jql => qq{issueFunction in subtasksOf("key = $key")}
    });

    return unless $children->issue_count;
    return $children->issues;
}


###########################################################################

=method B<start_progress>

Moves the status of the issue to 'In Progress', regardless of what the current status is.

=cut

sub start_progress {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('In Progress', {
        'Open'        => 'In Progress',
        'Reopened'    => 'In Progress',
        'In QA'       => 'In Progress',
        'Blocked'     => 'In Progress',
        'Resolved'    => 'Reopened',
        'Verified'    => 'Reopened',
        'Closed'      => 'Reopened',
    }, $callback);
}

=method B<start_qa>

Moves the status of the issue to 'In QA', regardless of what the current status is.

=cut

sub start_qa {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('In QA', {
        'Open'        => 'In Progress',
        'In Progress' => 'Resolved',
        'Reopened'    => 'Resolved',
        'Resolved'    => 'In QA',
        'Blocked'     => 'In QA',
        'Verified'    => 'Reopened',
        'Closed'      => 'Reopened',
    }, $callback);
}

=method B<resolve>

Moves the status of the issue to 'Resolved', regardless of what the current status is.

=cut

sub resolve {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('Resolved', {
        'Open'        => 'In Progress',
        'In Progress' => 'Resolved',
        'Reopened'    => 'Resolved',
        'Blocked'     => 'In Progress',
        'In QA'       => 'In Progress',
        'Verified'    => 'Reopened',
        'Closed'      => 'Reopened',
    }, $callback);
}

=method B<open>

Moves the status of the issue to 'Open', regardless of what the current status is.

=cut

sub open {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('Open', {
        'In Progress' => 'Open',
        'Reopened'    => 'In Progress',
        'Blocked'     => 'In Progress',
        'In QA'       => 'In Progress',
        'Resolved'    => 'Reopened',
        'Verified'    => 'Reopened',
        'Closed'      => 'Reopened',
    }, $callback);
}

=method B<close>

Moves the status of the issue to 'Closed', regardless of what the current status is.

=cut

sub close {
    my $self     = shift;
    my $callback = shift // sub {};

    $self->transitions->transition_walk('Closed', {
        'Open'        => 'In Progress',
        'In Progress' => 'Resolved',
        'Reopened'    => 'Resolved',
        'Blocked'     => 'In Progress',
        'In QA'       => 'Verified',
        'Resolved'    => 'Closed',
        'Verified'    => 'Closed',
    }, $callback);
}


1;

=accessor B<expand>

A comma-separated list of fields in the issue that weren't expanded in the initial REST call.

=accessor B<fields>

Returns a reference to the fields hash for the issue.

=accessor B<aggregateprogress>

Returns the aggregate progress for the issue as a hash reference.

TODO: Turn this into an object.

=accessor B<aggregatetimeestimate>

Returns the aggregate time estimate for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.

=accessor B<aggregatetimeoriginalestimate>

Returns the aggregate time original estimate for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.

=accessor Baggregatetimespent>

Returns the aggregate time spent for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.

=accessor B<assignee>

Returns the issue's assignee as a C<JIRA::REST::Class::User> object.

=method B<changelog>

Returns the issue's change log as a C<JIRA::REST::Class::Changelog> object.

=accessor B<components>

Returns a list of the issue's components as C<JIRA::REST::Class::Project::Component> objects. If called in a scalar context, returns an array reference to the list, not the number of elements in the list.

=accessor B<component_count>

Returns a count of the issue's components.

=accessor B<created>

Returns the issue's creation date as a C<DateTime> object.

=accessor B<creator>

Returns the issue's assignee as a C<JIRA::REST::Class::User> object.

=accessor B<description>

Returns the description of the issue.

=accessor B<duedate>

Returns the issue's due date as a C<DateTime> object.

=accessor B<environment>

Returns the issue's environment as a hash reference.

TODO: Turn this into an object.

=accessor B<fixVersions>

Returns a list of the issue's fixVersions.

TODO: Turn this into a list of objects.

=accessor B<issuelinks>

Returns a list of the issue's links.

TODO: Turn this into a list of objects.

=accessor B<issuetype>

Returns the issue type as a C<JIRA::REST::Class::Issue::Type> object.

=accessor B<labels>

Returns the issue's labels as an array reference.

=accessor B<lastViewed>

Returns the issue's last view date as a C<DateTime> object.

=accessor B<parent>

Returns the issue's parent as a C<JIRA::REST::Class::Issue> object.

=accessor B<has_parent>

Returns a boolean indicating whether the issue has a parent.

=accessor B<priority>

Returns the issue's priority as a hash reference.

TODO: Turn this into an object.

=accessor B<progress>

Returns the issue's progress as a hash reference.

TODO: Turn this into an object.

=accessor B<project>

Returns the issue's project as a C<JIRA::REST::Class::Project> object.

=accessor B<reporter>

Returns the issue's reporter as a C<JIRA::REST::Class::User> object.

=accessor B<resolution>

Returns the issue's resolution.

TODO: Turn this into an object.

=accessor B<resolutiondate>

Returns the issue's resolution date as a C<DateTime> object.

=accessor B<status>

Returns the issue's status as a C<JIRA::REST::Class::Status> object.

=accessor B<summary>

Returns the summary of the issue.

=accessor B<timeestimate>

Returns the time estimate for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.

=accessor B<timeoriginalestimate>

Returns the time original estimate for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.

=accessor B<timespent>

Returns the time spent for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.

=accessor B<timetracking>

Returns the time tracking of the issue as a C<JIRA::REST::Class::Issue::TimeTracking> object.

=accessor B<transitions>

Returns the valid transitions for the issue as a C<JIRA::REST::Class::Issue::Transitions> object.

=accessor B<updated>

Returns the issue's updated date as a C<DateTime> object.

=accessor B<versions>

versions

=accessor B<votes>

votes

=accessor B<watches>

watches

=accessor B<worklog>

Returns the issue's change log as a C<JIRA::REST::Class::Worklog> object.

=accessor B<workratio>

workratio

=accessor B<id>

Returns the issue ID.

=accessor B<key>

Returns the issue key.

=accessor B<self>

Returns the JIRA REST API's full URL for this issue.

=accessor B<url>

Returns the JIRA REST API's URL for this issue in a form used by C<JIRA::REST::Class>.

