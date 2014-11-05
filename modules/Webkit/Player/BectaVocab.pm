package Webkit::Player::BectaVocab;

use strict qw(vars);

use vars qw(@ISA);

@Webkit::Player::BectaVocab::ISA = qw(Webkit::DBObject);

my $schema = {
			term_id =>		{	type => 'string',
							required => 1 },

			term_name =>		{	type => 'string',
							required => 1 },

			term_type =>		{	type => 'string',
							required => 1 }
};

sub table
{
        return 'player.becta_vocab';
}

sub schema
{
        return $schema;
}

1;
