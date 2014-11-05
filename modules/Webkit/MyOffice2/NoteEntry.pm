package Webkit::MyOffice2::NoteEntry;

use strict;

@Webkit::MyOffice2::NoteEntry::ISA = qw(Webkit::DBObject);

my $schema = {	org_id => 	{	type => 'id',
					required => 1},

		users_id => 	{	type => 'id',
					required => 1 },

		created => 	{	type => 'date',
					required => 1 },

		content => {	type => 'string' } };

sub table
{
        return 'myoffice2.note_entry';
}

sub schema
{
        return $schema;
}

sub get_date_title
{
	my ($self) = @_;

	return $self->created->get_string;
}



1;
