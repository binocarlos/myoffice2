package Webkit::Player::Log;

use strict qw(vars);

use vars qw(@ISA);

@Webkit::Player::Log::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>		{	type => 'id',
										required => 1 },

			account_id =>					{	type => 'id' },

			event_type =>				{	type => 'string',
										required => 1 },
										
			event_date =>			{	type => 'datetime',
										required =>1 },
										
			ou_id =>			{	type => 'id' },
			
			event_desc =>				{	type => 'string' },
			
			ip_address =>				{	type => 'string' },
			
			referer =>				{	type => 'string' }
};

sub table
{
        return 'player.log';
}

sub schema
{
        return $schema;
}

sub get_event_date_summary
{
	my ($self) = @_;
	
	if(!$self->event_date) { return ''; }
	
	return $self->event_date->get_string;
}

1;