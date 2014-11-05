package Webkit::Player::ActivityFeedback;

use strict qw(vars);

use vars qw(@ISA);

@Webkit::Player::ActivityFeedback::ISA = qw(Webkit::DBObject);

my $schema = {
				installation_id =>		{	type => 'id',
											required => 1 },
	
				ou_id =>				{	type => 'id',
											required => 1 },
											
				created =>				{	type => 'datetime',
											required => 1 },
											
				feedback_type =>		{	type => 'string',
											required => 1 },
											
				name =>					{	type => 'string',
											required => 1 },
											
				email =>				{	type => 'string' },
				
				rating =>				{	type => 'integer' },
				
				feedback =>				{	type => 'string',
											required => 1 },				
};

sub table
{
        return 'player.activity_feedback';
}

sub schema
{
        return $schema;
}

1;
