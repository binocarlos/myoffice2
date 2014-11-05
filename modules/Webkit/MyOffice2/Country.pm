package Webkit::MyOffice2::Country;

use strict;

@Webkit::MyOffice2::Country::ISA = qw(Webkit::DBObject);

my $schema = {	code => { 	type => 'string',
				required => 1 },

		name => {	type => 'string',
				required => 1 },

		field_order => {	type => 'integer',
					required => 1 } };

sub table
{
        return 'myoffice2.country';
}

sub schema
{
        return $schema;
}

1;
