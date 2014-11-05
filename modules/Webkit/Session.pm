package Webkit::Session;

use strict;

my $no_save = {
	created => 1,
	modified => 1,
	user => 1,
	params => 1,
	has_changed => 1,
	db => 1 };

###############
# Simple Constructor
# Assigns the database object and params

sub new
{
        my ($classname, $app) = @_;

	if(!$app)
	{
		Webkit::Error->wkerror("You must give an APP to create a new session");
	}

        my $self = {};

        bless($self, $classname);

	$self->{db} = $app->{db};
	$self->{params} = $app->{params};

	return $self;
}

sub login
{
	my ($self) = @_;

	if($self->{params}->{session_id}!~/\w/)
	{
		if(($self->{params}->{username}!~/\w/)||($self->{params}->{password}!~/\w/))
		{
			return undef;
		}

		my $user = Webkit::User->load($self->{db}, {
			clause => " username = ? and password = ? ",
			binds => [lc($self->{params}->{username}), lc($self->{params}->{password})] });

		if(!$user)
		{
			return undef;
		}

		my $org = Webkit::Org->load($self->{db}, {
			id => $user->get_value('org_id') });

		my $privs = Webkit::Privilage->load_objects($self->{db}, {
			clause => 'users_id = ?',
			binds => [$user->get_id] });

		my $priv_map;
		
		foreach my $priv (@$privs)
		{
			my $sub = $priv->sub_application;
			my $app = $priv->application;
			my $active = $priv->get_value('active');

			my $priv_hash = {
				id => $priv->get_id,
				active => $active };

			if($sub=~/\w/)
			{
				$priv_map->{$app.'_subs'}->{$sub} = $priv_hash;
			}
			else
			{
				$priv_map->{$app} = $priv_hash;
			}
		}

		$self->set('user_data', $user->{data});
		$self->set('org_data', $org->{data});
		$self->set('privilage_map', $priv_map);

		$self->create;
	}
	else
	{
		if(!$self->load)
		{
			return undef;
		}
	}

	return 1;
}

sub is_privilaged
{
	my ($self, $base_id, $sub_id) = @_;

	return $self->check_privilages($base_id, $sub_id);
}

sub check_privilages
{
	my ($self, $base_id, $sub_id) = @_;

	my $mode = 'n';

	if($sub_id=~/\w/)
	{
		$mode = $self->{privilage_map}->{$base_id.'_subs'}->{$sub_id}->{active};
	}
	else
	{
		$mode = $self->{privilage_map}->{$base_id}->{active};
	}

	if($mode eq 'y')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

#######
# Delete the following on finish
# db
# params

sub DESTROY
{
	my ($self) = @_;

	$self->{db} = undef;
	$self->{params} = undef;
	$self = undef;
}


#########
# This returns the session id comrising of the session_id and
# the hit_count

sub get_session_id
{
        my ($self) = @_;

        my $id = $self->{_session_id};

        return $id;

}

sub session_id
{
	my ($self) = @_;

	return $self->get_session_id;
}


#############
# Create will insert the session into the database

sub create
{
        my ($self) = @_;

       #$self->{_session_id} = Apache::Session::Generate::MD5::generate();
        
    use CGI::Session;

    my $cgisession = new CGI::Session("driver:File", undef, {Directory=>'/tmp'});
    
    $self->{_session_id} = $cgisession->id();

	my $nowstring = Webkit::DateTime->parse_to_sql(Webkit::DateTime->now);

        my $data = { 	id => "\'$self->{_session_id}\'",
			created => "\'$nowstring\'",
			modified => "\'$nowstring\'" };

	if($self->{user_obj})
	{
		$data->{users_id} = $self->{user_obj}->get_id;
	}

	if($self->{org_obj})
	{
		$data->{org_id} = $self->{org_obj}->get_id;
	}

	my $committed = undef;
	my $loop_count = 0;

	while(!$committed)
	{
		$loop_count++;

		eval
		{
			$self->{db}->begin_transaction;

		        $self->{db}->insert({ table => 'webkit.sessions' }, $data);

			$self->{db}->commit;
		};

		if ($@)
		{
			if (($DBI::err == 1213)&&($loop_count<20))
			{
				print "Deadlock! Retrying ...\n";
				next;
			}
			else
			{
				die "Error! ($DBI::errstr) Exiting ...\n";
				return;
			}
		}
		else
		{
			$committed = 1;
		}
	}	

	return 1;
}

#############
# This will flatten the current values to the associated text file
# The text file is formed by getting the sessions_dir from Webkit::Application
# and using the session_id.wks

sub save
{
        my ($self) = @_;

	if(!$self->{has_changed})
	{
		return;
	}

	my $nowstring = Webkit::DateTime->parse_to_sql(Webkit::DateTime->now);

        my $data = { 	modified => "\'$nowstring\'",
			content => $self->{db}->quote($self->get_flattened_string) };

	my $committed = undef;
	my $loop_count = 0;

	while(!$committed)
	{
		$loop_count++;

		eval
		{
			$self->{db}->begin_transaction;

		        $self->{db}->update({ 	table => 'webkit.sessions',
						clause => " id = '$self->{_session_id}'" }, $data);

			$self->{db}->commit;
		};

		if ($@)
		{
			if (($DBI::err == 1213)&&($loop_count<20))
			{
				print "Deadlock! Retrying ...\n";
				next;
			}
			else
			{
				die "Error! ($DBI::errstr) Exiting ...\n";
				return;
			}
		}
		else
		{
			$committed = 1;
		}		
	}

	return 1;
}

#########################
# save_file - this will output the flattened value of the session to the relating file

sub get_flattened_string
{
	my ($self) = @_;

	my $data;

	foreach my $prop (keys %$self)
	{
		if($self->should_save($prop))
		{
			$data->{$prop} = $self->{$prop};
		}
	}

        my $flattened = Data::Dumper->Dump([$data], ["data"]);

	return $flattened;
}

################
# This will load in the session given by the params session_id

sub load
{
        my ($self) = @_;

        my $session_id = $self->{params}->{session_id};

	$self->{_session_id} = $session_id;

        my $session_hash = $self->{db}->get_select_ref({	table => 'webkit.sessions',
								binds => [$session_id],
								clause => " id = ? " });

        if(!$session_hash) { return undef; }

	$self->{created} = Webkit::DateTime->parse_from_sql($session_hash->{created});
	$self->{modified} = Webkit::DateTime->parse_from_sql($session_hash->{modified});

	#### Lets check that the last activity was less than 1 hour ago

	my $now = Webkit::DateTime->now;
	my $gap = $now->Epoch - $self->{modified}->Epoch;

	if($gap>(60*60*24))
	{
		return undef;
	}

	$self->load_flattened_string($session_hash->{content});

	return 1;
}

sub set
{
	my ($self, $key, $value) = @_;

	$self->{$key} = $value;

	$self->{has_changed} = 1;
}

sub delete
{
	my ($self, $key) = @_;

	delete($self->{$key});

	$self->{has_changed} = 1;
}

################
# load_file
# This will read the dumped file and re-insert the values into self

sub load_flattened_string
{
	my ($self, $flattened) = @_;

        my $data;

        eval($flattened);

	foreach my $prop (keys %$data)
	{
		$self->{$prop} = $data->{$prop};
	}

        return 1;
}

sub get_duration
{
	my ($self) = @_;

	if(!$self->{created})
	{
		return 0;
	}

	my $now_date = Webkit::DateTime->now;

	my $secs = $now_date->Epoch - $self->{created}->Epoch;

	if($secs<0)
	{
		$secs = 0;
	}

	return $secs;
}

sub get_duration_title
{
	my ($self) = @_;

	my $duration = $self->get_duration;

	my $mins = $duration / 60;
	my $secs = 0;

	if($mins=~/\.(\d+)$/)
	{
		my $secs_percentage = '0.'.$1;

		$secs = $secs_percentage*60;

		$secs = Webkit::AppTools->round_number($secs);

		$mins=~s/\.\d+$//;
	}

	my $title = "$mins Mins, $secs Secs";

	return $title;
}

sub get_logged_in_title
{
	my ($self) = @_;

	return $self->{created}->get_string;
}

sub get_modified_title
{
	my ($self) = @_;

	return $self->{modified}->get_string;
}

sub should_save
{
	my ($self, $key) = @_;

	if($no_save->{$key})
	{
		return undef;
	}
	else
	{
		return 1;
	}
}

1;
