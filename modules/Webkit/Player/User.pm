package Webkit::Player::User;

use strict;

@Webkit::Player::User::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>	{	type => 'id',
							required => 1 },

			account_id =>		{	type => 'id',
							required => 1 },

			username =>		{	type => 'string',
							required => 1 },

			password =>		{	type => 'string',
							required => 1 },

			firstname =>	{	type => 'string' },
							
			surname =>			{	type => 'string',
							required => 1 },

			created =>		{	type => 'datetime' },
			
			jobtitle =>	{	type => 'string' },
			
			yeargroup => {	type => 'string' },

			title =>	{	type => 'string' }
};

sub table
{
        return 'player.user';
}

sub schema
{
        return $schema;
}

sub error
{
	my ($self) = @_;

	return $self->SUPER::error({
		account_id => 1 });
}

sub load_account
{
	my ($self) = @_;

	if($self->{account_loaded}) { return $self->{account_obj}; }

	my $account_obj = Webkit::Player::Account->load($self->{db}, {
		id => $self->account_id });

	$self->{account_obj} = $account_obj;

	return $account_obj;
}

sub get_name
{
	my ($self) = @_;
	
	return $self->firstname.' '.$self->surname;
}

sub get_initial_name
{
	my ($self) = @_;

	my $initial = substr($self->firstname, 0, 1);
	
	my $ret = uc($initial).' '.$self->surname;
	
	return $ret;	
}

1;
