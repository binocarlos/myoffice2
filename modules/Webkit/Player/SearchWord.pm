package Webkit::Player::SearchWord;

use strict;

@Webkit::Player::SearchWord::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>		{	type => 'id',
									required => 1 },	
							
			ou_id =>		{	type => 'id',
								required => 1 },

			word_type =>		{	type => 'string',
							required => 1 },

			word =>			{	type => 'string',
							required => 1 }
};

sub table
{
        return 'player.searchword';
}

sub schema
{
        return $schema;
}

1;
