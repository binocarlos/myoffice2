package Webkit::MyOffice2::MyOfficeUser;

use strict;

@Webkit::MyOffice2::MyOfficeUser::ISA = qw(Webkit::DBObject);

my $schema = {        	org_id => {	required => 1,
					type => 'id' },

			active => {	required => 1,
					type => 'string' },

			username => {	required => 1,
					type => 'string' },

                	password_id => {type => 'id',
                                        required => 1 },

                	tour_id => {	type => 'id',
					required => 1 },

                default_tour_id => {	type => 'id' },

			type =>	{	required => 1,
					type => 'string' },

                firstname => {		type => 'string',
					required => 1 },

                surname => {		required => 1,
                                        type => 'string' },

                title => {		type => 'string' },

                phone => {		type => 'string' },

                privilages => {		type => 'string' },

                mobile => {		type => 'string'} };

sub table
{
        return 'myoffice2.users';
}

sub schema
{
        return $schema;
}

sub get_fullname
{
	my ($self) = @_;

	return $self->firstname.' '.$self->surname;
}

1;
