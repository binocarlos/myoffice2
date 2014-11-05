package Webkit::MyOffice2::Contact;

use strict;

@Webkit::MyOffice2::Contact::ISA = qw(Webkit::DBObject);

my $schema = {	org_id => {	type => 'id',
				required => 1 },

		tour_id =>	{	type => 'id',
					required => 1 },

		supplier_id => {	type => 'id' },

		position => {	type => 'string' },

		vehicle_desc =>	{	type => 'string' },

		vehicle_reg => 	{	type => 'string' },

		venue_id => 	{ 	type => 'id' },

		name => 	{	required => 1,
					type => 'string' },

		type => 	{	required => 1,
					type => 'string' },

		phone => 	{	type => 'string' },

		fax => 		{	type => 'string' },

		mobile => 	{	type => 'string' },

		email => 	{	type => 'string' } };

sub table
{
        return 'myoffice2.contact';
}

sub schema
{
        return $schema;
}

1;
