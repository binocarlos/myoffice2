package Webkit::Player::AccountLink;

use strict;

@Webkit::Player::AccountLink::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>	{	type => 'id',
									required => 1 },	
							
			parent_id =>			{	type => 'id',
									required => 1 },
									
			child_id =>			{	type => 'id',
									required => 1 },

			link_type =>		{	type => 'string',
									required => 1 },
							
			created => 			{	type => 'datetime',
									required => 1 }
};

sub table
{
        return 'player.account_link';
}

sub schema
{
        return $schema;
}

1;
