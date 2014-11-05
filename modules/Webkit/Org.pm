package Webkit::Org;

use strict qw(vars);

@Webkit::Org::ISA = qw(Webkit::DBObject);

my $schema = {	name => {	type => 'string',
				required => 1 },

		debug => { 	type => 'string',
				required => 1 },

		parent_org_id => {	type => 'id',
					required => 1 },

		resourceshare_org_id => {	type => 'id' },

		address => {	type => 'string' },

		website => {	type => 'string' },

		phone => {	type => 'string' },

		fax => {	type => 'string' },

		resourceshare_url => {	type => 'string' } };

sub table
{
        return 'webkit.org';
}

sub schema
{
        return $schema;
}

##############
# Load users, this will load all users for an organisation within the context of an application.
# This is done by matching the users load with a privilage belonging the to application
# specified by $props->{appname}.  If a $props->{datatable} and $props->{dataclass} exists,
# then it will also load and assign the data objects belonging to the particular application.
# This should be used by an Inherited Org, but can be used in default which will then only
# load the users with their privilages.  The users active property is given to it by the privilage.
# If appname is not supplied, it will check $self->{appname} (which should be set at $app->_init)
# -----------
# datatable, dataclass - information about any data object to associate with users
# clause - any extra parts to the clause whilst loading ALL objects (must only include users and privilage)
# userclass - the class for the users to be loaded into
# appname - the name of the application to find privilages for
# order - how to order the users
# all - if specified, the active = 'y' part of the clause will be omitted

sub load_users
{
	my ($self, $props) = @_;

	my $attr = {
		table => 'webkit.users',
		clause => " users.org_id = ? and users.deleted = ? ",
		binds => [$self->get_id, 'n'],
		cols => 'users.*',
		group => 'users.id',
		order => 'firstname, surname' };

	my $userclass = 'Webkit::User';

	if($props->{userclass}=~/\w/)
	{
		$userclass = $props->{userclass};
	}

	$self->add_children($userclass, $attr);

	$attr->{table} .= ',webkit.privilage';

	$attr->{clause}.=<<"+++";
and privilage.users_id = users.id
and privilage.application_id = ?
+++

	if($props->{appname}!~/\w/)
	{
		$props->{appname} = $self->{application_id};
	}

	push(@{$attr->{binds}}, $props->{appname});

	$attr->{cols} = 'privilage.*';
	$attr->{group} = 'privilage.id';

	$self->add_children('Webkit::Privilage', $attr);

	my $users_hash = $self->ensure_child_hash('users');

	foreach my $privilage (@{$self->ensure_child_array('privilage')})
	{
		my $user = $users_hash->{$privilage->get_value('users_id')};

		if($user)
		{
			$user->assign_privilage_to_map($privilage);
		}
	}

	if($props->{user_data_class}=~/\w/)
	{
		$self->load_children($props->{user_data_class});

		foreach my $userdata (@{$self->ensure_child_array('user_data')})
		{
			my $user = $users_hash->{$userdata->get_value('users_id')};

			if($user)
			{
				$user->assign_data_obj($userdata);
			}
		}
	}

	my $users_array;

	if($props->{privilage}!~/\w/)
	{
		$props->{privilage} = 'all';
	}

	foreach my $user (@{$self->ensure_child_array('users')})
	{
		if($props->{user_data_class} =~ /\w/)
		{
			$user->ensure_data_obj;
		}

		if($props->{privilage} eq 'all')
		{
			push(@$users_array, $user);
		}
		elsif($props->{privilage} eq 'exists')
		{
			if($user->get_privilage($props->{appname}))
			{
				push(@$users_array, $user);
			}
		}
		elsif($props->{privilage} eq 'active')
		{
			if($user->is_privilaged($props->{appname}))
			{
				push(@$users_array, $user);
			}
		}

		$self->{_all_users}->{$user->get_id} = $user;
	}

	$self->replace_children_from_array('users', $users_array);
}

sub load_active_users
{
	my ($self, $props) = @_;

	$props->{privilage} = 'active';

	$self->load_users($props);
}

sub load_existing_users
{
	my ($self, $props) = @_;

	$props->{privilage} = 'exists';

	$self->load_users($props);
}

sub load_all_users
{
	my ($self, $props) = @_;

	$props->{privilage} = 'all';

	$self->load_users($props);
}

sub load_admin_users
{
	my ($self) = @_;

	$self->load_children('Webkit::User', {
		clause => ' type = ? ',
		order => 'firstname, surname',
		binds => ['admin'] });
}

#############
# Load departments will load all departments for this Org

sub load_departments
{
	my ($self, $assign) = @_;

	if(!$self->get_child_array('department'))
	{
		$self->load_children('Webkit::Department', {
			order => 'name' });

		if($assign)
		{
			my $arr = $self->get_child_array('users');
			my $dept_hash = $self->get_child_hash('department');

			my $blank_department = Webkit::Department->blank;

			$blank_department->set_value('name', 'No Group');
			$blank_department->{data}->{id} = 0;

			foreach my $user (@$arr)
			{
				if($user->get_value('department_id')>0)
				{
					my $department = $dept_hash->{$user->get_value('department_id')};
		
					if(!$department)
					{
						next;
					}

					$department->add_child($user);

					$user->{department} = $department;
				}
				else
				{
					$blank_department->{_has_users} = 1;

					$blank_department->add_child($user);

					$user->{department} = $blank_department;
				}
			}

			if($blank_department->{_has_users})
			{
				$self->add_child($blank_department);
				#$self->{_no_group} = $blank_department;
			}
		}
	}
}

##############
# This will call load users and load departments (load users will be passed the args)

sub load_departments_and_users
{
	my ($self, $attr) = @_;

	$self->load_users($attr);

	$self->load_departments(1);
}

sub load_all_orgs_and_users
{
	my ($classname, $db) = @_;

	my $orgs = Webkit::Org->load_objects($db, {
		table => 'webkit.org',
		clause => 'parent_org_id = 0',
		order => 'name' });

	my $org_hash = Webkit::AppTools->get_id_hash($orgs);

	my $users = Webkit::User->load_objects($db, {
		table => 'webkit.users',
		clause => "deleted = ?",
		binds => ['n'],
		order => 'firstname, surname' });

	foreach my $user (@$users)
	{
		my $org = $org_hash->{$user->get_value('org_id')};

		if($org)
		{
			$org->add_child($user);
		}
	}

	return $orgs;
}

sub get_users_options_data
{
	my ($self) = @_;

	my $data;

	$self->load_users;

	foreach my $user (@{$self->get_child_array('users')})
	{
		push(@$data, {
			title => $user->get_fullname,
			id => $user->get_id });
	}

	return $data;
}

sub get_users_options
{
	my ($self, $user_id) = @_;

	my $data = $self->get_users_options_data;

	my $attr;

	$attr->{key_field} = 'id';
	$attr->{value_field} = 'title';

	if($user_id)
	{
		$attr->{selected} = $user_id;
	}

	return Webkit::AppTools->get_select_options($data, $attr);
}

sub load_orgs_for_app
{
	my ($classname, $db, $appname) = @_;

	if($appname !~ /\w/)
	{
		return undef;
	}

	my $select_clause=<<"+++";
webkit.privilage.users_id = webkit.users.id
and webkit.users.org_id = webkit.org.id
and privilage.application_id = ?
+++

	my $select_attr = {
		table => 'webkit.org, webkit.users, webkit.privilage',
		cols => 'webkit.org.*',
		group => 'webkit.org.id',
		binds => ["'$appname'"],
		clause => $select_clause };

	my $orgs = Webkit::Org->load_objects($db, $select_attr);

	return $orgs;
}


sub is_debug
{
	my ($self) = @_;

	if($self->get_value('debug') eq 'y')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub is_client
{
	my ($self) = @_;

	my $ret = undef;

	if($self->get_value('parent_org_id')>0)
	{
		$ret = 1;
	}

	return $ret;
}



sub get_key
{
	my ($self) = @_;

	my $key = lc($self->get_value('name'));

	$key =~ s/[^\w]//g;

	return $key;
}

sub get_unix_group
{
	my ($self) = @_;

	my $group = $self->get_key;

	$group = substr($group, 0, 10);

	return $group;
}

sub get_position_options
{
	my ($self, $attr) = @_;

	if(!$attr->{obj})
	{
		return;
	}

	if(!$attr->{field})
	{
		$attr->{field} = 'field_order';
	}

	my $field = $attr->{field};
	my $obj = $attr->{obj};

	my $table = $obj->table;

	my $clause = " org_id = ? ";

	if($attr->{clause}=~/\w/)
	{
		$clause.=$attr->{clause};
	}

	my $ref = $self->{db}->get_select_ref({
		table => $table,
		cols => "MAX($field) as highest",
		clause => $clause,
		binds => [$self->get_id] });

	my $highest = 0;

	if($ref)
	{
		$highest = $ref->{highest};
	}

	my $extra = 0;

	if(!$obj->exists)
	{
		$extra = 1;
	}

	my $options;

	for(my $i=1; $i<=$highest + $extra; $i++)
	{
		my $option = {
			id => $i,
			value => $i };

		push(@$options, $option);
	}

	my $selected = 1;

	if($obj->get_value($field)>0)
	{
		$selected = $obj->get_value($field);
	}

	my $optionst = Webkit::AppTools->get_select_options($options, {
		key_field => 'id',
		value_field => 'value',
		selected => $selected });

	return $optionst;
}

sub sort_add_field_orders
{
	my ($self, $attr) = @_;

	if(!$attr->{obj})
	{
		return;
	}

	if(!$attr->{load_method})
	{
		return;
	}

	if(!$attr->{field})
	{
		$attr->{field} = 'field_order';
	}

	my $obj = $attr->{obj};
	my $load_method = $attr->{load_method};
	my $field = $attr->{field};

	my $table = $obj->table;

	my $single_table = $obj->single_table;

	$self->$load_method;

	my $arr = $self->get_child_array($single_table);

	my $tosave;

	foreach my $other (@$arr)
	{
		if($other->get_value($field)>=$obj->get_value($field))
		{
			my $value = $other->get_value($field);

			$value++;

			$other->set_value($field, $value);

			push(@$tosave, $other);
		}
	}

	return $tosave;
}

sub sort_delete_field_orders
{
	my ($self, $attr) = @_;

	if(!$attr->{obj})
	{
		return;
	}

	if(!$attr->{load_method})
	{
		return;
	}

	if(!$attr->{field})
	{
		$attr->{field} = 'field_order';
	}

	my $obj = $attr->{obj};
	my $load_method = $attr->{load_method};
	my $field = $attr->{field};

	my $table = $obj->table;

	my $single_table = $obj->single_table;

	$self->$load_method;

	my $arr = $self->get_child_array($single_table);

	my $tosave;

	foreach my $other (@$arr)
	{
		if($other->get_value($field)>$obj->get_value($field))
		{
			my $value = $other->get_value($field);

			$value--;

			$other->set_value($field, $value);

			push(@$tosave, $other);
		}
	}

	return $tosave;
}

sub sort_edit_field_orders
{
	my ($self, $attr) = @_;

	if(!$attr->{obj})
	{
		return;
	}

	if(!$attr->{load_method})
	{
		return;
	}

	if(!$attr->{field})
	{
		$attr->{field} = 'field_order';
	}

	my $obj = $attr->{obj};
	my $load_method = $attr->{load_method};
	my $field = $attr->{field};

	my $table = $obj->table;

	my $single_table = $obj->single_table;

	$self->$load_method;

	my $old_position = $obj->{'_old_'.$field};

	my $new_position = $obj->get_value($field);

	my $arr = $self->get_child_array($single_table);

	my $tosave_hash;

	foreach my $other (@$arr)
	{
		if(($other->get_value($field)>$old_position)&&($other->get_id!=$obj->get_id))
		{
			my $value = $other->get_value($field);

			$value--;

			$other->set_value($field, $value);

			$tosave_hash->{$other->get_id} = $other;
		}
	}

	foreach my $other (@$arr)
	{
		if(($other->get_value($field)>=$new_position)&&($other->get_id!=$obj->get_id))
		{
			my $value = $other->get_value($field);

			$value++;

			$other->set_value($field, $value);

			$tosave_hash->{$other->get_id} = $other;
		}
	}

	my @ret = values %$tosave_hash;

	return \@ret;
}

sub load_clients_and_users
{
	my ($self) = @_;

	$self->load_clients(1);
}

sub load_clients_and_users_and_groups
{
	my ($self) = @_;

	&Webkit::Org::load_clients($self, 1);

	my $department_attr = {
		cols => 'department.*',
		table => 'webkit.department, webkit.org',
		clause => " ( org.parent_org_id = ? or org.resourceshare_org_id = ? ) and department.org_id = org.id ",
		binds => [$self->get_id, $self->get_id],
		order => 'name' };

	$self->add_children('Webkit::Department', $department_attr);

	if($self->{_load_users_array})
	{
		foreach my $user (@{$self->{_load_users_array}})
		{
			my $has_added = undef;

			if($user->department_id>0)
			{
				my $department = $self->get_child('department', $user->department_id);

				if($department)
				{
					$department->add_child($user);
					$has_added = 1;
				}
			}

			if(!$has_added)
			{	
				my $org = $self->get_child('org', $user->org_id);
	
				if($org)
				{
					push(@{$org->{_no_group}}, $user);
				}
			}
		}
	}

	foreach my $department (@{$self->ensure_child_array('department')})
	{
		my $org = $self->get_child('org', $department->org_id);

		if($org)
		{
			$org->add_child($department);
		}
	}
}

sub load_clients
{
	my ($self, $with_users) = @_;

	if(!$self->{_clients_loaded})
	{
		my $client_attr = {
			cols => 'org.*',
			table => 'webkit.org',
			clause => " ( org.parent_org_id = ? or org.resourceshare_org_id = ? ) ",
			binds => [$self->get_id, $self->get_id],
			order => 'name' };

		$self->add_children('Webkit::ClientMS::Client', $client_attr);

		$self->{_clients_loaded} = 1;

		if($with_users)
		{
			my $users_attr = {
				table => 'webkit.org, webkit.users',
				cols => 'users.*',
				clause => " ( org.parent_org_id = ? or org.resourceshare_org_id = ? ) and users.org_id = org.id ",
				binds => [$self->get_id, $self->get_id],
				order => 'firstname, surname' };

			my $users = Webkit::User->load_objects($self->{db}, $users_attr);

			$self->{_load_users_array} = $users;

			my $orghash = $self->get_child_hash('org');

			foreach my $user (@$users)
			{
				my $org = $orghash->{$user->get_value('org_id')};

				if($org)
				{
					$org->add_child($user);
				}

				$self->{_all_users}->{$user->get_id} = $user;
			}
		}
	}
}

sub get_client_array
{
	my ($self) = @_;

	$self->load_clients;

	return $self->get_child_array('org');
}

sub get_client_options
{
	my ($self, $selected) = @_;

	$self->load_clients;

	return Webkit::AppTools->get_object_select_options($self->get_child_array('org'), {
		value_field => 'name',
		selected => $selected,
		null_title => 'Any' });
}

sub get_standalone_applications
{
	my ($self) = @_;

	$self->load_all_applications;

	my $ret;

	my $arr = $self->get_child_array('application');

	foreach my $app (@$arr)
	{
		if($app->get_value('standalone') eq 'y')
		{
			push(@$ret, $app);
		}
	}

	return $ret;
}

sub load_all_applications
{
	my ($self) = @_;

	my $array = Webkit::Apache::ApplicationHub->get_application_array;
	my $hash = Webkit::Apache::ApplicationHub->get_application_hash;

	$self->{application_array} = $array;
	$self->{application_hash} = $hash;
}

sub get_logo_tag
{
	my ($self) = @_;

	my $details = Webkit::Apache::TemplateHub->get_org_logo_details($self);

	my $tag=<<"+++";
<img src="$details->{src}" width="$details->{width}" height="$details->{height}" border=0>
+++

	$tag =~ s/\n//g;

	return $tag;
}

sub set_application_id
{
	my ($self, $app_id) = @_;

	$self->{application_id} = $app_id;
}

sub load_or_create_variable
{
	my ($self, $varname, $default) = @_;

	my $variable = $self->load_variable($varname);

	if(!$variable->exists)
	{
		$variable->set_value('value', $default);
		$variable->set_value('modified', Webkit::DateTime->now);

		$self->{db}->begin_transaction;

		$variable->create;

		$self->{db}->commit;
	}

	return $variable;
}

sub load_variable
{
	my ($self, $varname, $org_id) = @_;

	if($self->{_variables}->{$varname})
	{
		return $self->{_variables}->{$varname};
	}

	my $clause=<<"+++";
org_id = ?
and field = ?
+++

	if(!$org_id) { $org_id = $self->get_id; }

	my $variable = Webkit::Variable->load($self->{db}, {
		clause => $clause,
		binds => [$org_id, $varname] });

	if(!$variable)
	{
		$variable = Webkit::Variable->constructor($self->{db});
		$variable->set_value('org_id', $org_id);
		$variable->set_value('field', $varname);
	}

	$self->{_variables}->{$varname} = $variable;

	return $variable;
}

sub child_org_title
{
	my ($self) = @_;

	return 'Child Org';
}

sub parent_org_field
{
	my ($self) = @_;

	return 'parent_org_id';
}

1;
