package Webkit::Player::TextEntry;

use strict qw(vars);

use vars qw(@ISA);

@Webkit::Player::TextEntry::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>		{	type => 'id',
										required => 1 },

			name =>					{	type => 'string',
										required => 1 },

			language =>				{	type => 'string',
										required => 1 },
										
			account_type =>			{	type => 'string' },
										
			account_id =>			{	type => 'id' },
			
			content =>				{	type => 'string' }																			
};

sub table
{
        return 'player.text_entry';
}

sub schema
{
        return $schema;
}

1;