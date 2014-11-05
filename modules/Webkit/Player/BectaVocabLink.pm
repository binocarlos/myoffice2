package Webkit::Player::BectaVocabLink;

use strict qw(vars);

use vars qw(@ISA);

@Webkit::Player::BectaVocabLink::ISA = qw(Webkit::DBObject);

my $schema = {
			parent_id =>		{	type => 'id',
							required => 1 },

			child_id =>		{	type => 'id',
							required => 1 }
};

sub table
{
        return 'player.becta_vocab_link';
}

sub schema
{
        return $schema;
}

1;
