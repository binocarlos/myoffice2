package Webkit::AppLog;

use vars qw(@ISA);

use strict;

@ISA = qw(Webkit::DBObject);

my $schema = {		org_id => {	type => 'id',
					required => 1 },

			users_id => {	type => 'id',
					required => 1 },

			application_id => {	type => 'string',
						required => 1 },

			sub_application_id => {	type => 'string',
						required => 1 },

			method => {	type => 'string',
					required => 1 },

			requested => {	type => 'datetime',
					required => 1 },

			params => {	type => 'string' },

			sql => {	type => 'string' } };


sub table
{
        return 'webkit.log';
}

sub schema
{
        return $schema;
}

1;
