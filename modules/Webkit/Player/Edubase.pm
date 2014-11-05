package Webkit::Player::Edubase;

use strict;

@Webkit::Player::Edubase::ISA = qw(Webkit::DBObject);

my $schema = {
			lea_number =>		{	type => 'string' },
			
			school_number =>	{	type => 'string' },
			
			lea_name =>			{	type => 'string' },
			
			school_name =>		{	type => 'string' }	
};



sub table
{
        return 'player.edubase';
}

sub schema
{
        return $schema;
}

1;
