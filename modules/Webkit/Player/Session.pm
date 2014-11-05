package Webkit::Player::Session;

use strict;

@Webkit::Player::Session::ISA = qw(Webkit::DBObject);

my $schema = {
			user_id =>		{	type => 'id' },

			session_id =>		{	type => 'string',
							required => 1 },

			created =>		{	type => 'datetime',
							required => 1 },

			modified =>		{	type => 'datetime',
							required => 1 },

			data =>			{	type => 'string' }
};

my $hours_inactive = 2;

sub table
{
        return 'player.session';
}

sub schema
{
        return $schema;
}

### Login is the constructor - either loads from session_id or username + password

sub login
{
	my ($classname, $data) = @_;

	if(!$data->{db})
	{
		Webkit::Error->wkerror("You must give a DB to create a new session");
		return;
	}

	my $session = Webkit::Player::Session->constructor($data->{db});

	if($data->{session_id}=~/\w/)
	{
		return $session->session_id_login($data->{installation_id}, $data->{session_id});
	}
	elsif($data->{account_id}=~/\w/)
	{
		return $session->account_id_password_login($data->{installation_id}, $data->{account_id}, lc($data->{password}));	
	}
	else
	{
		if($data->{use_shib})
		{
			return $session->shib_login($data->{account}, $data->{user});
		}
		else
		{
			return $session->username_login($data->{installation_id}, lc($data->{username}), lc($data->{password}));
		}
	}
}

### do the login with a session_id (load session)

sub session_id_login
{
	my ($self, $installation_id, $session_id) = @_;

	my $session_obj = Webkit::Player::Session->load($self->{db}, {
		clause => 'session_id = ?',
		binds => [$session_id] });

	if(!$session_obj)
	{
		return;
	}

	if($session_obj->get('installation_id')!=$installation_id)
	{
		return;
	}

	if($session_obj->user_id>0)
	{
		my $user_obj = Webkit::Player::User->constructor($self->{db});
		$user_obj->assign_data($session_obj->get('user_data'));

		my $account_obj = Webkit::Player::Account->constructor($self->{db});
		$account_obj->assign_data($session_obj->get('account_data'));

		$session_obj->{user} = $user_obj;
		$session_obj->{account} = $account_obj;
	}

	return $session_obj;
}

sub account_id_password_login
{
	my ($self, $installation_id, $account_id, $password) = @_;
	
	my $user_obj = Webkit::Player::User->load($self->{db}, {
		clause => 'account_id = ? and password = ? and installation_id = ?',
		binds => [$account_id, $password, $installation_id] });
		
	if(!$user_obj) { return; }

	my $account_obj = $user_obj->load_account;

	$self->{user} = $user_obj;
	$self->{account} = $account_obj;

	$self->user_id($user_obj->get_id);
	$self->init_values;

	$self->set('installation_id', $installation_id);
	$self->set('user_data', $user_obj->{data});
	$self->set('account_data', $account_obj->{data});

	$self->{db}->begin_transaction;

	$self->create;

	$self->{db}->commit;

	return $self;		
}

sub shib_login
{
	my ($self, $account_obj, $user_obj) = @_;

	$self->{user} = $user_obj;
	$self->{account} = $account_obj;

	$self->user_id($user_obj->get_id);
	$self->init_values;

	$self->set('installation_id', $account_obj->installation_id);
	$self->set('user_data', $user_obj->{data});
	$self->set('account_data', $account_obj->{data});

	$self->{db}->begin_transaction;

	$self->create;

	$self->{db}->commit;

	return $self;
}

### do the login with username/password (load user obj)

sub username_login
{
	my ($self, $installation_id, $username, $password) = @_;

	my $user_obj = Webkit::Player::User->load($self->{db}, {
		clause => 'username = ? and password = ? and installation_id = ?',
		binds => [$username, $password, $installation_id] });

	if(!$user_obj) { return; }

	my $account_obj = $user_obj->load_account;

	$self->{user} = $user_obj;
	$self->{account} = $account_obj;

	$self->user_id($user_obj->get_id);
	$self->init_values;

	$self->set('installation_id', $installation_id);
	$self->set('user_data', $user_obj->{data});
	$self->set('account_data', $account_obj->{data});

	$self->{db}->begin_transaction;

	$self->create;

	$self->{db}->commit;

	return $self;
}

### generic method to init the values of the session

sub init_values
{
	my ($self) = @_;

	my $now_date = Webkit::DateTime->now;

	$self->created($now_date);
	$self->modified($now_date);

	$self->session_id($self->get_session_id);
}

sub get_session_id
{
	my ($self) = @_;
	
	use CGI::Session;

    my $cgisession = new CGI::Session("driver:File", undef, {Directory=>'/tmp'});
    
    return $cgisession->id();

	#return Apache::Session::Generate::MD5::generate();	
}

### set and get session values (stored in session_data);

sub set
{
	my ($self, $prop, $value) = @_;

	$self->{session_data}->{$prop} = $value;

	return $self->{session_data}->{$prop};
}

sub get
{
	my ($self, $prop) = @_;

	return $self->{session_data}->{$prop};
}

#### Overrides the standard method to parse the data field once loaded

sub assign_data
{
	my ($self, $data) = @_;

	$self->SUPER::assign_data($data);

	$self->{session_data} = $self->parse_session_data;
}

######## Overrides the standard method to ensure that 'data' is flattened first

sub get_flattened_value
{
	my ($self, $key) = @_;

	if($key ne 'data')
	{
		return $self->SUPER::get_flattened_value($key);
	}

	return $self->flatten_session_data;
}

#########################
# this will provide you with a flattend (string) version of the current $self->{session_data}

sub flatten_session_data
{
	my ($self) = @_;

	my $data;

	foreach my $prop (keys %{$self->{session_data}})
	{
		$data->{$prop} = $self->{session_data}->{$prop};
	}

        my $flattened = Data::Dumper->Dump([$data], ["data"]);

	return $flattened;
}

################
# this will provide you with a data structure created from a flattend string (i.e. $self->data)

sub parse_session_data
{
	my ($self) = @_;

        my $data;

        eval($self->data);

	return $data;
}

1;
