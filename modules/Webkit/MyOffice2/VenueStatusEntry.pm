package Webkit::MyOffice2::VenueStatusEntry;

use strict;

@Webkit::MyOffice2::VenueStatusEntry::ISA = qw(Webkit::DBObject);

my $schema = {	 org_id => {	type => 'id',
				required => 1},

		tour_id => {	type => 'id',
				required => 1 },

		created => {	type => 'datetime',
				required => 1 },

		showing_id => {	type => 'id' },

		booking_id => {	type => 'id' },

		field => {	type => 'string',
				required => 1 },

		value => {	type => 'string',
				required => 1 } };

sub table
{
        return 'myoffice2.venue_status_entry';
}

sub schema
{
        return $schema;
}

1;
