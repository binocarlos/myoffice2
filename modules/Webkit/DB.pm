package Webkit::DB;

use strict qw(vars);

use DBI ();
use DBD::mysql ();

sub new
{
	my ($classname, $config) = @_;

	my $self = {};

	bless($self, $classname);

	unless($self->_init($config))
	{
		return undef;
	}
}

#######
# Connects to the Database using the args supplied
# args are
# -----
# sqldb
# sqluser
# sqlpassword
#

sub _init
{
	my ($self, $config) = @_;

	my $reqs = [qw/sqldb sqluser sqlpassword/];

	my $ensure = Webkit::AppTools->ensure_args($reqs, $config);

	if($ensure=~/[a-z]/i)
	{
		$self->throw_error("The DB Connect $ensure field is Required");

		return undef;
	}

	$config->{sqldb} = 'webkit';

	my $dsn = "dbi:mysql:$config->{sqldb}:localhost";	

	my $sqlattr = {	PrintError => 0,
			AutoCommit => 1,
			RaiseError => 1 };

	my $dbh = DBI->connect($dsn, $config->{sqluser}, $config->{sqlpassword}, $sqlattr);

	$self->{dbh} = $dbh;

	$self->{log} = undef;
	$self->{dev} = $config->{dev};

	return $self;
}

#######
# Checks if the module has a dbh and if so, calls disconnect and rollback
# if in_transaciton returns true.

sub cleanup
{
	my ($self) = @_;

	if($self->{dbh})
	{
		if($self->in_transaction)
		{
			$self->{dbh}->rollback;
		}

		my $status = $self->{dbh}->disconnect;
	}

	$self->{log} = undef;
	$self->{dbh} = undef;
	$self = undef;
}

sub DESTROY
{
	my ($self) = @_;

	$self->cleanup;
}

#########
# get_select_ref - this calls get_select_refs after adding $attr->{limit} = 1;

sub get_select_ref
{
	my ($self, $attr) = @_;

	$attr->{limit} = 1;

	my $refs = $self->get_select_refs($attr);

	if($refs)
	{
		return $refs->[0];
	}
	else
	{
		return undef;
	}
}

#######
# Creates the sql statement for a SELECT based on the following args:
# All args must be minimal (i.e. don't include where, group words etc).
# ------
# table - the full database table
# clause - the clause, the question mark count MUST match the element count within the binds array
# group - the group
# order - the order of the returned rows
# limit - the number (or slice if start,end) of the returned rows
# binds - the array of actual values to substitute for ?'s

sub get_select_refs
{
	my ($self, $attr) = @_;

	my $reqs = [qw/table/];

	my $ensure = Webkit::AppTools->ensure_args($reqs, $attr);

	if($ensure=~/[a-z]/i)
	{
		$self->throw_error("The get select string $ensure field is required");

		return undef;
	}

	my $qmarkcount = 0;

	while($attr->{clause}=~/\?/g)
	{
		$qmarkcount++;
	}

	my $bindcount = @{$attr->{binds}};

	if($qmarkcount!=$bindcount)
	{
		$self->throw_error("The clause  ---- $attr->{clause} ---- is matched by $bindcount bind values - they do not match");

		return undef;
	}

	if($attr->{cols}!~/\w/o)
	{
		$attr->{cols} = '*';
	}

	my $statement=<<"+++";
select $attr->{cols}
from $attr->{table}
+++

	if($attr->{clause}=~/\w/)
	{
		$statement.=<<"+++";
where $attr->{clause}
+++
	}

	if($attr->{group}=~/\w/)
	{
		$statement.=<<"+++";
group by $attr->{group}
+++
	}

	if($attr->{order}=~/\w/)
	{
		$statement.=<<"+++";
order by $attr->{order}
+++
	}

	if($attr->{limit}=~/\w/)
	{
		$statement.=<<"+++";
limit $attr->{limit}
+++
	}

	$self->add_log($statement, $attr->{binds});
	
	if($attr->{die})
	{
		die $self->get_last_log();
	}

	my $sth = $self->{dbh}->prepare($statement);

	my $bindcounter = 1;

	foreach my $bind (@{$attr->{binds}})
	{
		$sth->bind_param($bindcounter, $bind);

		$bindcounter++;
	}
	
	eval
	{
		$sth->execute;
	};

	if($@)
	{
		die $@.' --- '.$statement;
	}

	my $rows;

	while(my $row = $sth->fetchrow_hashref())		
	{
		if($row)
		{
			push(@$rows, $row);
		}
	}

	$sth->finish();

	return $rows;
}

## will execute raw sql and return hashrefs
sub do_sql
{
	my ($self, $statement) = @_;

	my $sth = $self->{dbh}->prepare($statement);

	$sth->execute;

	my $rows;

	while(my $row = $sth->fetchrow_hashref())		
	{
		if($row)
		{
			push(@$rows, $row);
		}
	}

	$sth->finish();

	return $rows;
}

############
# This will get the last insert id for the object
# to assign a new id.

sub get_last_insert_id
{
	my ($self) = @_;

	my $statement=<<"+++";
select LAST_INSERT_ID() as id
+++

	$self->add_log($statement);

	my $sth = $self->{dbh}->prepare($statement);

	$sth->execute;

	my $row = $sth->fetchrow_hashref();

	$sth->finish();

	return $row->{id};
}

#########
# Adds a create statement to the current transaction
# If there is no transaction, will throw an error
# Args are the attr for the update (table, clause)
# and the properties to update

sub update
{
	my ($self, $updateattr, $updatedata) = @_;

	if((!$self->in_transaction)&&(!$self->{no_transaction_check}))
	{
		$self->throw_error("You cannot call update when not in a transaction");

		return;
	}

	my $reqs = [qw/table clause/];

	my $ensure = Webkit::AppTools->ensure_args($reqs, $updateattr);

	if($ensure=~/[a-z]/i)
	{
		$self->throw_error("The DB::add_update $ensure field is required");

		return undef;
	}

	my @pairs;

	foreach my $key (sort keys %$updatedata)
	{
		if($key=~/\w/)
		{
			my $value = $updatedata->{$key};

			if($value!~/\w/)
			{
				$value = 'NULL';
			}

			push(@pairs, "$key=$value");
		}
	}

	my $data_st = join(', ', @pairs);

	my $statement=<<"+++";
update $updateattr->{table}
set $data_st 
where $updateattr->{clause}
+++

	$self->add_log($statement);

	$self->{dbh}->do($statement);

	return 1;	
}

#########
# Adds an insert statement to the current transaction
# If there is no transaction, will throw an error
# Args are the attr for the insert (table)
# and the properties to insert

sub insert
{
	my ($self, $insertattr, $insertdata) = @_;

	if((!$self->in_transaction)&&(!$self->{no_transaction_check}))
	{
		$self->throw_error("You cannot call insert when not in a transaction");

		return;
	}

	my $reqs = [qw/table/];

	my $ensure = Webkit::AppTools->ensure_args($reqs, $insertattr);

	if($ensure=~/[a-z]/i)
	{
		$self->throw_error("The DB::add_insert $ensure field is required");

		return undef;
	}

	my @keys;
	my @values;

	foreach my $key (sort keys %$insertdata)
	{
		my $value = $insertdata->{$key};

		if($value!~/\w/)
		{
			$value = 'NULL';
		}

		push(@keys, $key);
		push(@values, $value);
	}

	my $key_st = join(', ', @keys);

	my $value_st = join(', ', @values);

	my $statement=<<"+++";
insert into $insertattr->{table}
($key_st)
values
($value_st)
+++

	$self->add_log($statement);

	eval
	{
		$self->{dbh}->do($statement);
	};

	if($@)
	{
		#die Webkit::Error->get_caller_info;
		die $@.' - '.$statement;
	}

	return 1;	
}

#########
# Adds a delete statement to the current transaction
# If there is no transaction, will throw an error
# Args are the attr for the delete (table, clause)

sub delete
{
	my ($self, $deleteattr) = @_;

	if((!$self->in_transaction)&&(!$self->{no_transaction_check}))
	{
		$self->throw_error("You cannot call delete when not in a transaction");

		return;
	}

	my $reqs = [qw/table clause/];

	my $ensure = Webkit::AppTools->ensure_args($reqs, $deleteattr);

	if($ensure=~/[a-z]/i)
	{
		$self->throw_error("The DB::add_delete $ensure field is required");

		return undef;
	}

	my $statement=<<"+++";
delete from $deleteattr->{table}
where $deleteattr->{clause}
+++

	$self->add_log($statement);

	$self->{dbh}->do($statement);

	return 1;	
}

#########
# begin_transaction - Starts the handle in a transaction
# Sets Autocommit to off
#

sub begin_transaction
{
	my ($self) = @_;

	if($self->in_transaction)
	{
		$self->rollback;

		$self->throw_error("You cannot begin a transaction when you are already within one.");

		return;
	}

	$self->{dbh}->{AutoCommit} = 0;
}

#########
# commit - Commits the current transaction
# Does this within an eval, and if there is an error
# it will rollback and then print the error page.

sub commit
{
	my ($self) = @_;

	if(!$self->in_transaction)
	{
		$self->throw_error("You cannot commit when not in a transaction");

		return undef;
	}

	$self->{dbh}->commit;

	$self->{dbh}->{AutoCommit} = 1;

	return 1;
}

#########
# rollback - rollbacks the current transaction
# Does this within an eval, and if there is an error
# it will disconnect and print the error page.

sub rollback
{
	my ($self) = @_;

	$self->{dbh}->rollback;

	$self->{dbh}->{AutoCommit} = 1;

	return 1;
}

#########
# Returns true or false i.e.
# whether within transaction

sub in_transaction
{
	my ($self) = @_;

	my $autocommit = $self->{dbh}->{AutoCommit};

	if($autocommit==1)
	{
		return undef;
	}
	else
	{
		return 1;
	}
}

########
# quote - returns dbh->quote for string values

sub quote
{
	my ($self, $value) = @_;

	return $self->{dbh}->quote($value);
}

#########
# Add Log - adds a statement to the current SQL Log only if $self->{dev}
#

sub no_transaction_check
{
	my ($self) = @_;

	$self->{no_transaction_check} = 1;
}



sub no_log
{
	my ($self) = @_;

	$self->{no_log} = 1;
}

sub clear_log
{
	my ($self) = @_;

	delete($self->{logs});
}

sub get_last_log
{
	my ($self) = @_;

	return $self->{last_log};
}

sub add_log
{
	my ($self, $statement, $binds) = @_;

	if($self->{no_log})
	{
		return;
	}

	my $counter = 0;

	while($statement=~/\?/g)
	{
		my $value = $binds->[$counter];

		if($value=~/[^\d\.]/)
		{
			$value = "'$value'";
		}

		$statement =~ s/\?/$value/;

		$counter++;
	}

	if($self->{dev})
	{
		$self->{last_log} = $statement;

		push(@{$self->{logs}}, $statement);
	}
}


#########
# Get Log - returns a dump of the current store of statements
# - if html is set, then it will have tags

sub get_log
{
	my ($self, $plain) = @_;

	my $br = '<br>';
	my $hr = '<hr>';

	if($plain)
	{
		$br = "\n";
		$hr = "\n-----------------------------\n";
	}

	my $ret=<<"+++";
Current SQL Log:$br$br
+++

	foreach my $statement (@{$self->{logs}})
	{
		$ret.=<<"+++";
$statement $hr
+++
	}

	return $ret;
}

#########
# throw_error - will call Webkit::Error->wkerror appending the log

sub throw_error
{
	my ($self, $message) = @_;

	die $message;

#	$message.='<hr>'.$self->get_log;

#	Webkit::Error->wkerror($message);
}

1;
