package Webkit::Player::Keyword;

use strict;

@Webkit::Player::Keyword::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>	{	type => 'id',
							required => 1 },

			account_id => 		{	type => 'id',
							required => 1 },

			ou_id =>		{	type => 'id',
							required => 1 },

			keyword_type =>		{	type => 'string',
							required => 1 },

			word =>			{	type => 'string' },

			value =>		{	type => 'string',
							required => 1 }
};

sub table
{
        return 'player.keyword';
}

sub schema
{
        return $schema;
}

1;
