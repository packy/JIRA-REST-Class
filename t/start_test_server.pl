#!/usr/bin/env perl

use File::Basename;
use lib dirname($0).'/../t/lib';
use lib dirname($0).'/../lib';

use JIRA::REST::Class::Test;

JIRA::REST::Class::Test->server_log->info('-' x 50);

JIRA::REST::Class::Test->setup_server();

exit;
