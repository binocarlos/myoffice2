package Webkit::RootServer;

use Expect ();

use XML::DOM;

# these variables should really be set in a central configuration file
my $useraddex    = "/usr/sbin/useradd";  # location of useradd executable
my $groupaddex = "/usr/sbin/groupadd";   # location of groupadd executable
my $passwdex     = "/usr/bin/passwd";        # location of passwd executable
my $homedir = "/dev/null";               # home directory root dir
my $userdelex 	 = "/usr/sbin/userdel";  # location of userdel executable
my $passwdfile = "/etc/passwd";
my $groupfile = "/etc/group";
my $virtusertable = "/etc/mail/virtusertable";
my $lastsystemuser = "admin";
my $lastsystemgroup = "admin";

my $host = '127.0.0.1';
my $port = 1082;

### Sendmail Stuff

use strict;

sub new
{
	my ($classname) = @_;

	my $self = {};

	bless($self, $classname);

	return $self;
}

sub host
{
	my ($classname) = @_;

	return $host;
}

sub port
{
	my ($classname) = @_;

	return $port;
}

sub error_packet
{
	my ($self) = @_;

	my $packet=<<"+++";
<error>$self->{error}</error>
+++

	return $packet;
}

sub ok_packet
{
	my ($self) = @_;

	return '<ok>';
}

sub execute_instructions
{
	my ($self) = @_;

	foreach my $instruction (@{$self->{instructions}})
	{
		my $method = $instruction->{action};
		my $props = $instruction->{properties};

		my $status = $self->$method($props);

		if(!$status)
		{
			return undef;
		}
	}

	return 1;
}

sub get_password
{
	return 'lllIu89KKDjkjsdMSDoISsd2DSDisdksOksOKlmkSM0ok0SKD03lskd';
}

sub parse_message
{
	my ($self, $message) = @_;

	if($message !~ /\w/)
	{
		return undef;
	}

        my $parser = new XML::DOM::Parser;

	my $doc;

	eval {
	        $doc = $parser->parse($message);
	};

	if(@!)
	{
		$self->{error} = "XML Parser Failed - @!";

		return undef;
	}

	for my $password_node ($doc->getElementsByTagName("password"))
	{
		if(!$self->check_password_node($password_node))
		{
			$self->{error} = "The password is wrong";

			return undef;
		}
	}

	for my $instruction ($doc->getElementsByTagName("instruction"))
	{
		if(!$self->add_instruction($instruction))
		{
			return undef;
		}
	}

	return 1;
}

sub add_instruction
{
	my ($self, $node) = @_;

	my $action = $node->getAttribute("action");

	if($action!~/\w/)
	{
		$self->{error} = "One of the instructions does not have an action";

		return undef;
	}

	my $instruction = {
		action => $action };

	for my $property ($node->getElementsByTagName("property"))
	{
		my $key = $property->getAttribute("key");
		my $value = $property->getAttribute("value");

		if(($key!~/\w/)||($value!~/\w/))
		{
			$self->{error} = "One of the instructions does not have a good property";

			return undef;
		}

		$instruction->{properties}->{$key} = $value;
	}

	push(@{$self->{instructions}}, $instruction);

	return 1;
}

sub check_password_node
{
	my ($self, $password_node) = @_;

	my $password = $password_node->getAttribute("value");

	if($password eq $self->get_password)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

################################
# REMOTE METHODS
################################

sub create_email_address
{
	my ($self, $props) = @_;

	return $self->create_alias($props);
}

sub edit_email_address
{
	my ($self, $props) = @_;

	return $self->update_alias($props);
}

sub delete_email_address
{
	my ($self, $props) = @_;

	return $self->delete_alias($props);
}
		
sub edit_pop_account
{
	my ($self, $props) = @_;

	if($props->{password}=~/\w/)
	{
		my $status = $self->init_unix_password($props);

		if(!$status)
		{
			return undef;
		}
	}

	if($props->{new_address}=~/\w/)
	{
		my $alias_props = {
			address => $props->{address},
			new_address => $props->{new_address},
			alias => $props->{account} };

		my $alias_status = $self->update_alias($alias_props);

		return $alias_status;
	}
	else
	{
		return 1;
	}
}

sub create_pop_account
{
	my ($self, $props) = @_;

	my $status = $self->create_unix_account($props);

	if(!$status)
	{
		return undef;
	}

	my $alias_props = {
		address => $props->{address},
		alias => $props->{account} };

	my $alias_status = $self->create_alias($alias_props);

	return $alias_status;
}

sub delete_pop_account
{
	my ($self, $props) = @_;

	my $status = $self->delete_unix_account($props);

	if(!$status)
	{
		return undef;
	}

	my $alias_props = {
		address => $props->{address} };

	my $alias_status = $self->delete_alias($alias_props);

	return $alias_status;
}

################################
# UNIX TOOLS
################################

sub does_group_exist
{
	my ($self, $group) = @_;

	my $found = undef;

	open(GROUP, $groupfile);

	while(<GROUP>)
	{
		if($_=~/^$group:/)
		{
			$found = 1;
		}
	}

	close(GROUP);

	return $found;
}

sub does_user_exist
{
	my ($self, $user) = @_;

	my $found = undef;

	open(PASSWD, $passwdfile);

	while(<PASSWD>)
	{
		if($_=~/^$user:/)
		{
			$found = 1;
		}
	}

	close(PASSWD);

	return $found;
}

sub create_unix_group
{
	my ($self, $group) = @_;

	if($self->does_group_exist($group))
	{
		$self->{error} = "The group $group already exists";

		return undef;
	}

	my @cmd = ($groupaddex, $group);

	my $result = 0xff & system @cmd;

	if($result)
	{
		$self->{error} = "The Add Group Command Failed";

		return undef;
	}
	else
	{
		return 1;
	}
}

sub create_unix_account
{
	my ($self, $record) = @_;

	if($self->does_user_exist($record->{account}))
	{
		$self->{error} = "That username $record->{account} already exists";

		return undef;
	}

	if(!$self->does_group_exist($record->{group}))
	{
		my $status = $self->create_unix_group($record->{group});

		if(!$status)
		{
			return undef;
		}
	}

	my @cmd = ($useraddex, 
		"-c", $record->{"fullname"},
		"-d", "$homedir",
		"-g", $record->{"group"},
		$record->{"account"} );

	my $result = 0xff & system @cmd;

	if($result)
	{
		$self->{error} = "The Add User Command Failed";

		return undef;
	}

	my $password_status = $self->init_unix_password($record);

	if(!$password_status)
	{
		return undef;
	}
	else
	{
		return 1;
	}
}

sub delete_unix_account
{    
	my ($self, $record) = @_;

	my @cmd = ($userdelex, $record->{"account"});
    
	my $result = 0xffff & system @cmd;

	# the return code is 0 for success, non-0 for failure, so we invert

	if(!$result)
	{
		return 1;
	}
	else 
	{
		$self->{error} = "The Delete User Command Failed";

		return undef;
	}
}

sub init_unix_password 
{
	my ($self, $record) = @_;

	# return a process object

	my $pobj = Expect->spawn($passwdex, $record->{"account"});

	if(!defined($pobj))
	{
		$self->{error} = "Creating A New Expect Object Failed";

		return undef;
	}

	# do not log to stdout (i.e. be silent)
	$pobj->log_stdout(0);

	# wait for password & password re-enter prompts, 
	# answering appropriately
	$pobj->expect(10,"New password: ");

	# Linux sometimes prompts before it is ready for input, so we pause
	sleep 1;
	print $pobj "$record->{password}\r";

	$pobj->expect(10, "Re-enter new password: ");
	print $pobj "$record->{password}\r";

	# did it work?
	my $result = (defined ($pobj->expect(10, "passwd: all authentication tokens updated successfully")) ? 1 : undef);

	# close the process object, waiting up to 15 secs for 
	# the process to exit
	$pobj->soft_close(  );

	if(!$result)
	{
		$self->{error} = "The set password method failed";

		return undef;
	}
	else
	{
		return 1;
	}
}

################################
# VIRTUSERTABLE Tools
################################

sub delete_alias
{
	my ($self, $record) = @_;

	if($record->{address}!~/\w/)
	{
		$self->{error} = "You must give an address to delete an alias";

		return undef;
	}	

	my $address = $record->{address};

	my $addresses = $self->get_virtusertable_addresses;

	delete($addresses->{$address});

	return $self->save_virtusertable_addresses($addresses);
}

sub update_alias
{
	my ($self, $record) = @_;

	if($record->{address}!~/\w/)
	{
		$self->{error} = "You must give an address to create an alias";

		return undef;
	}

	my $addresses = $self->get_virtusertable_addresses;

	my $address = $record->{address};
	my $alias = $record->{alias};

	my $new_address = $record->{new_address};

	if($new_address=~/\w/)
	{
		delete($addresses->{$address});

		$addresses->{$new_address} = $alias;
	}
	else
	{
		$addresses->{$address} = $alias;
	}

	return $self->save_virtusertable_addresses($addresses);
}

sub create_alias
{
	my ($self, $record) = @_;

	if($record->{address}!~/\w/)
	{
		$self->{error} = "You must give an address to create an alias";

		return undef;
	}

	if($record->{alias}!~/\w/)
	{
		$self->{error} = "You must give an alias to create an alias";

		return undef;
	}

	my $address = $record->{address};
	my $alias = $record->{alias};

	my $addresses = $self->get_virtusertable_addresses;

	$addresses->{$address} = $alias;

	return $self->save_virtusertable_addresses($addresses);
}

sub save_virtusertable_addresses
{
	my ($self, $addresses) = @_;

	if(!$addresses)
	{
		$self->{error} = "You cannot call save_virtusertable_addresses without passing the addresses";

		return undef;
	}

	my $backup = $virtusertable.'_bk';

	system "cp $virtusertable $backup";

	my $table;

	foreach my $address (sort keys %$addresses)
	{
		my $alias = $addresses->{$address};

		$table.=<<"+++";
$address	$alias
+++
	}

	open(VIRTUSERTABLE, ">$virtusertable");

	print VIRTUSERTABLE $table;

	close(VIRTUSERTABLE);

	system "makemap hash $virtusertable < $virtusertable";

	return 1;	
}

sub get_virtusertable_addresses
{
	my ($self) = @_;

	my $addresses;

	open(VIRTUSER, $virtusertable);

	while(<VIRTUSER>)
	{
		chomp($_);

		if($_=~/^([^\s]+)\s+([^\s]+)$/)
		{
			my $email = $1;
			my $alias = $2;

			$addresses->{$email} = $alias;
		}
	}

	close(VIRTUSER);

	return $addresses;
}

################################
# EASEMAIL Methods
################################

sub send_easemail_queue
{
	my ($self, $props) = @_;

	my $id = $props->{email_id};

	if($id>0)
	{
		system "perl /home/webkit/scripts/send_easemail_queue.pl $id";
	}

	return 1;
}

1;
