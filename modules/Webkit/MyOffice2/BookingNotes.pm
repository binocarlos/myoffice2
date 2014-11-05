package Webkit::MyOffice2::BookingNotes;

use strict;

@Webkit::MyOffice2::BookingNotes::ISA = qw(Webkit::DBObject);

my $schema = {	org_id => 	{	type => 'id',
					required => 1},

		tour_id =>        {	type => 'id',
                                        required => 1 },

         	venue_id =>        {	type => 'id',
                                        required => 1 },       

		notes => {		type => 'string' } };

sub table
{
        return 'myoffice2.booking_notes';
}

sub schema
{
        return $schema;
}

1;
