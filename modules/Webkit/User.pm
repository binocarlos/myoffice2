package Webkit::User;

###########
# Webkit::User
# This represents the base class for all users within the engine.
# You can subclass this adding methods or you can create application
# specific data subclassing by adding a data object.

use strict qw(vars);

@Webkit::User::ISA = qw(Webkit::DBObject);

my $schema = {		org_id => {	type => 'id',
					required => 1 },

			username => {	type => 'string',
					required => 1 },

			password => {	type => 'string',
					required => 1 },

			firstname => {	type => 'string',
					required => 1 },

			surname => {	type => 'string',
					required => 1 },

			department_id => {	type => 'id' },

			general_type => {	type => 'string',
						required => 1 },

			type => {	type => 'string',
					required => 1 },

			phone => {	type => 'string' },

			mobile => {	type => 'string' },

			position => {	type => 'string' },

			deleted => {	type => 'string',
					required => 1 },

			homephone => {	type => 'string' },

			sex => {	type => 'string' },

			address => {	type => 'string' },

			email_addresses => { 	type => 'string' } };

my $general_type_titles = {
	admin => 'Account Holder',
	webkit => 'Webkit Administrator',
	normal => 'Normal User' };

my $type_titles = {
	admin => 'Administrator',
	normal => 'Employee' };			

sub table
{
        return 'webkit.users';
}

sub schema
{
        return $schema;
}

##########
# initialise
# Call this to initialse the general properties

sub initialise
{
	my ($self) = @_;

	$self->{_general_type_title} = $general_type_titles->{$self->{type}};
	$self->{_type_title} = $type_titles->{$self->{type}};
}

##################
# This is overidden to check if this user has a data object
# and if so, whether the $key belongs to it.

sub get_value
{
	my ($self, $key) = @_;

	if($self->{data_obj})
	{
		if(($self->{data_obj}->has_property($key))&&($key ne 'id'))
		{
			return $self->{data_obj}->get_value($key);
		}
	}

	return $self->SUPER::get_value($key);
}

##################
# This is overidden to check if this user has a data object
# and if so, whether the $key belongs to it.

sub set_value
{
	my ($self, $key, $value) = @_;

	if($key eq 'active')
	{
		$self->set_active($value);

		return;
	}

	if($self->{data_obj})
	{
		if($self->{data_obj}->has_property($key))
		{
			return $self->{data_obj}->set_value($key, $value);
		}
	}

	return $self->SUPER::set_value($key, $value);
}

##################
# This is overidden to check if this user has a data object
# and if so, whether the $key belongs to it.

sub get_parsed_value
{
	my ($self, $key) = @_;

	if($self->{data_obj})
	{
		if($self->{data_obj}->has_property($key))
		{
			return $self->{data_obj}->get_parsed_value($key);
		}
	}

	return $self->SUPER::get_parsed_value($key);
}

############
# If there is a data object, then calls its error method
# If no errors, then call DBObject->error

sub error
{
	my ($self, $ignore) = @_;

	if($self->{data_obj})
	{
		my $ret = $self->{data_obj}->error($ignore);

		if($ret)
		{
			$self->{error_text} = $self->{data_obj}->{error_text};

			return 1;
		}
	}

	my $existing_ref;

	if($self->exists)
	{
		$existing_ref = $self->{db}->get_select_ref({
			table => 'webkit.users',
			clause => 'username = ? and id != ?',
			binds => [$self->get_value('username'), $self->get_id] });
	}
	else
	{
		$existing_ref = $self->{db}->get_select_ref({
			table => 'webkit.users',
			clause => 'username = ?',
			binds => [$self->get_value('username')] });
	}

	if($existing_ref)
	{
		my $username = $self->get_value('username');

		$self->{error_text} = "The username $username already exists";

		return 1;
	}
	else
	{
		return $self->SUPER::error($ignore);
	}
}

#################
# The following methods are all hooks so the data_obj is
# loaded, created and saved in sync.
# ---------
# Constructor calls SUPER::constructor then load_data_obj
# Load calls SUPER::load and then load_data_obj

sub constructor
{
	my ($classname, $db) = @_;

	my $self = &Webkit::DBObject::constructor($classname, $db);

	$self->load_data_obj;

	return $self;
}


sub load
{
	my ($classname, $db, $attr) = @_;

	my $self = &Webkit::DBObject::load($classname, $db, $attr);
	
	if(!$self)
	{
		return undef;
	}

	$self->load_data_obj;

	return $self;
}

################
# create checks to see if this user exists elsewhere
# within the system (i.e. has other privilages)
# if so, the existing user if given the data_obj
# to create and creates a new privilage.
# If there is no other user, the data_obj is
# saved after the current user being saved


sub create
{
	my ($self) = @_;

	my $existing = Webkit::User->load($self->{db}, {
		clause => " username = ? ",
		binds => [$self->get_value('username')] });

	if($existing)
	{
		$existing->{data_obj} = $self->{data_obj};

		$existing->save_data_obj;
	}
	else
	{
		$self->SUPER::create;

		$self->save_data_obj;
	}
}

#############
# Save
# This simply catches the save and calls save_data_obj

sub save
{
	my ($self) = @_;

	$self->SUPER::save;

	$self->save_data_obj;
}

#################
# Delete
# This will check if the data object exists and deletes it if yes.
# If then gets the current users privilage count, deletes the current
# privilage and if that takes the privilage count to 0, will also delete
# the user.

sub delete_old
{
	my ($self, $app_name) = @_;

	$self->set_value('deleted', 'y');

	$self->save;
}

sub save_department_info
{
	my ($self, $params) = @_;

	if(!defined($params->{department_id}))
	{
		return;
	}

	if($params->{department_id}<0)
	{
		$params->{department_id} = 0;
	}

	$self->set_value('department_id', $params->{department_id});
	$self->{otherdepartment} = $params->{otherdepartment};
}

sub commit_department_info
{
	my ($self) = @_;

	if($self->{otherdepartment}=~/\w/)
	{
		$self->create_new_department($self->{otherdepartment});
	}

	if($self->{_old_department_id}>0)
	{	
		if($self->{_old_department_id}!=$self->department_id)
		{
			my $department = Webkit::Department->load($self->{db}, {
				id => $self->{_old_department_id} });

			$department->load_children('Webkit::User');

			my $child_count = 0;

			foreach my $user (@{$department->ensure_child_array('users')})
			{
				if($user->get_id!=$self->get_id)
				{
					$child_count++;
				}
			}

			if($child_count<=0)
			{
				$department->delete;
			}
		}
	}
}

#########
# Create New Department
# If called with a $name, this will create a new Department pointed to
# by this user

sub create_new_department
{
	my ($self, $name) = @_;

	if($name=~/\w/)
	{
		my $department = Webkit::Department->constructor($self->{db});

		$department->set_value('org_id', $self->get_value('org_id'));
		$department->set_value('name', $name);

		$department->create;

		$self->set_value('department_id', $department->get_id);
	}
}

sub ensure_department_id
{
	my ($self) = @_;

	my $id = $self->get_value('department_id');

	if($id>0)
	{
		return $id;
	}
	else
	{
		return 0;
	}
}

###########
# Load Department
# This will load this Users department Object

sub load_department
{
	my ($self) = @_;

	if((!$self->{department})&&($self->get_value('department_id')>0))
	{
		my $department = Webkit::Department->load($self->{db}, {
			id => $self->get_value('department_id') });

		$self->{department} = $department;

		return $department;
	}
	else
	{
		if($self->{department})
		{
			return undef;
		}
		else
		{
			my $dept = Webkit::Department->blank;

			$dept->set_value('name', 'No Group');

			$self->{department} = $dept;
		}
	}
}

##############
# Load Org
# This will load this users Org Object

sub load_org
{
	my ($self) = @_;

	if((!$self->{org})&&($self->get_value('org_id')>0))
	{
		my $org = Webkit::Org->load($self->{db}, {
			 id => $self->get_value('org_id') });

		$self->{org} = $org;

		return $org;
	}
	else
	{
		return undef;
	}
}

#############
# ABSTRACT
# This returns no data object for the base user class

sub get_data_obj
{
	my ($self) = @_;

	return undef;
}

###############
# This will call the users get_data_obj method
# which checks if the user exists and returns an existing
# or constructed data object.  If the user has not overidden the get_data_obj
# method, then this user will have no data_obj functionality.

sub ensure_data_obj
{
	my ($self) = @_;

}

sub assign_data_obj
{
	my ($self, $obj) = @_;

	$self->{data_obj} = $obj;
}

sub has_data_obj
{
	my ($self) = @_;

	if($self->{data_obj})
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub load_data_obj
{
	my ($self) = @_;

	my $data_obj = $self->get_data_obj;

	if(!$data_obj)
	{
		$self->ensure_data_obj;

		return;
	}

	$self->{data_obj} = $data_obj;
}

###############
# This will save the users data_obj.
# It will assign the users_id and org_id 
# if the data_obj does not exist.
	
sub save_data_obj
{
	my ($self) = @_;

	if(!$self->{data_obj})
	{
		return;
	}

	if($self->{data_obj}->exists)
	{
		$self->{data_obj}->save;
	}
	else
	{
		$self->{data_obj}->set_value('users_id', $self->get_id);
		$self->{data_obj}->set_value('org_id', $self->get_value('org_id'));

		$self->{data_obj}->create;
	}
}

############
# Returns the current number of privilages belonging to this user

sub get_privilage_count
{
	my ($self) = @_;

	my $count_attr = {
		cols => 'count(*) as count',
		table => 'webkit.privilage',
		binds => [$self->get_id],
		clause => "users_id = ?" };

	my $ref = $self->{db}->get_select_ref($count_attr);

	if(!$ref)
	{
		return 0;
	}
	else
	{
		return $ref->{count};
	}
}



sub get_privilage
{
	my ($self, $app_id, $sub_app_id) = @_;

	if($sub_app_id=~/\w/)
	{
		return $self->{_privilage_map}->{$app_id}->{$sub_app_id};
	}
	else
	{
		return $self->{_privilage_map}->{$app_id};
	}
}

sub get_priv_checkbox
{
	my ($self, $app_id, $sub_app_id, $params) = @_;

	my $id = 'privilage_'.$app_id;

	if($sub_app_id=~/\w/)
	{
		$id.='_'.$sub_app_id;
	}

	my $checked = '';

	if(($self->is_privilaged($app_id, $sub_app_id))||(!$self->exists))
	{
		$checked = ' CHECKED';
	}

	if($params->{username}=~/\w/)
	{
		my $pcheck = $params->{$id};

		if($pcheck eq 'y')
		{
			$checked = ' CHECKED';
		}
		else
		{
			$checked = '';
		}
	}

	my $cbox=<<"+++";
<input type="checkbox" name="$id" value="y"$checked>
+++

	return $cbox;
}

sub is_privilaged
{
	my ($self, $app_id, $sub_app_id) = @_;

	my $priv = $self->get_privilage($app_id, $sub_app_id);

	if(!$priv)
	{
		return undef;
	}
	else
	{
		return $priv->is_active;
	}
}

sub set_all_privilages_inactive
{
	my ($self) = @_;

	my $id = $self->get_id;

	$self->{db}->update(	{
		table => 'webkit.privilage',
		clause => "users_id = $id" },
				{
		active => "'n'" });

}

sub set_privilage_active
{
	my ($self, $params, $main_app, $sub_app) = @_;

	my $priv = $self->get_privilage($main_app, $sub_app);

	my $active = $self->is_params_privilage_ticked($params, $main_app, $sub_app);

	my $active_value = 'n';

	if($active)
	{
		$active_value = 'y';
	}

	if(!$priv)
	{
		$priv = Webkit::Privilage->constructor($self->{db});

		$priv->set_value('users_id', $self->get_id);
		$priv->set_value('application_id', $main_app);
		$priv->set_value('sub_application_id', $sub_app);
		$priv->set_value('active', $active_value);

		push(@{$self->{changed_privilages}}, $priv);
	}
	else
	{
		if($priv->get_value('active') ne $active_value)
		{
			$priv->set_value('active', $active_value);

			push(@{$self->{changed_privilages}}, $priv);
		}
	}
}

sub delete_all_privilages
{
	my ($self) = @_;

	my $id = $self->get_id;

	my $clause=<<"+++";
users_id = $id
+++

	Webkit::Privilage->delete_with_clause($self->{db}, {
		clause => $clause });
}

sub delete_application_privilages
{
	my ($self, $application_id) = @_;

	my $id = $self->get_id;

	my $clause=<<"+++";
application_id = '$application_id'
and users_id = $id
+++

	Webkit::Privilage->delete_with_clause($self->{db}, {
		clause => $clause });
}

sub save_all_privilages
{
	my ($self, $params) = @_;

	my $main_application_id = $params->{main_application_id};
	my $sub_application_ids_st = $params->{sub_application_ids};

### There cannot be a privilage with orgadmin

	if(($main_application_id!~/\w/)||($main_application_id eq 'orgadmin'))
	{
		return;
	}

	my @sub_app_ids = split(/:/, $sub_application_ids_st);

	$self->set_privilage_active($params, $main_application_id);

	foreach my $sub_app_id (@sub_app_ids)
	{
		if($sub_app_id ne 'orgadmin')
		{
			$self->set_privilage_active($params, $main_application_id, $sub_app_id);
		}
	}
}

sub commit_changed_privilages
{
	my ($self) = @_;

	my $arr = $self->{changed_privilages};

	foreach my $priv (@$arr)
	{
		$priv->save_or_create;
	}
}

sub is_params_privilage_ticked
{
	my ($self, $params, $main_app, $sub_app) = @_;

	my $id = 'privilage_'.$main_app;

	if($sub_app=~/\w/)
	{
		$id.='_'.$sub_app;
	}

	my $value = $params->{$id};

	if($value eq 'y')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub has_multi_standalone_applications
{
	my ($self) = @_;

	my $count = 0;

	my $priv_array = $self->get_child_array('privilage');

	foreach my $priv (@$priv_array)
	{
		my $app = $priv->get_application_obj;

		if(($priv->is_active)&&($app->is_standalone)&&(!$priv->sub_application))
		{
			$count++;
		}
	}

	if($count>1)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub assign_privilage_to_map
{
	my ($self, $priv) = @_;

	if($priv->sub_application=~/\w/)
	{
		$self->{_privilage_map}->{$priv->application}->{$priv->sub_application} = $priv;
	}
	else
	{
		$self->{_privilage_map}->{$priv->application} = $priv;

		if($priv->is_standalone_and_active)
		{
			$self->{_standalone_privialge_map}->{$priv->application} = $priv;
		}
	}
}


sub load_all_privilages
{
	my ($self) = @_;

	if(!$self->exists)
	{
		return;
	}

	$self->load_children('Webkit::Privilage');

	my $arr = $self->get_child_array('privilage');

	foreach my $priv (@$arr)
	{
		$self->assign_privilage_to_map($priv);
	}
}

sub load_privilage_obj
{
	my ($self, $app_name, $sub_app_name) = @_;

	if($self->get_privilage($app_name, $sub_app_name))
	{
		return;
	}

	my $clause=<<"+++";
users_id = ?
and application_id = ?
+++

	my $binds = [$self->get_id, $app_name];

	if($sub_app_name=~/\w/)
	{
		$clause.=<<"+++";
and sub_application_id = ?
+++

		push(@$binds, $sub_app_name);
	}

	my $priv = Webkit::Privilage->load($self->{db}, {
		clause => $clause,
		binds => $binds });

	if($priv)
	{
		$self->assign_privilage_to_map($priv);

		return 1;
	}
	else
	{
		return undef;
	}
}

##############
# Admin
# Returns the admin property, if type is admin, then they can usually
# add edit users etc.  However, this is up to the individual application,
# admin will have no effect to the user in its own right.

sub admin
{
	my ($self) = @_;

	if($self->get_value('type') eq 'admin')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

#########################
# Active - checks $self->{active}

sub active
{
	my ($self) = @_;

	if($self->get_active eq 'y')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

########################
# Set Active - 
# this will assign the given value to the privilage object

sub set_active
{
	my ($self, $value) = @_;

	if(($value =~ /\w/)&&($self->{privilage}))
	{
		$self->{privilage}->set_value('active', $value);
	}

	$self->{active} = $value;
}

########################
# Get Active - 
# this will return the active property of the privilage object

sub get_active
{
	my ($self) = @_;

	if($self->{privilage})
	{
		return $self->{privilage}->get_value('active');
	}
	else
	{
		return $self->{active};
	}
}

##############
# New From Login
#
# This method takes a username and a password and authenticated the user against
# the database values
#
# Returns user/false

sub new_from_login
{
        my ($classname, $db, $username, $password) = @_;

	if(($username!~/\w/)||($password!~/\w/))
	{
		return undef;
	}

	my $user = &load($classname, $db, {
		clause =>  " username = ? ",
		binds => [$username] });

        if($user)
        {
                if(lc($user->get_value('password')) eq lc($password))
                {
                        return $user;
                }
                else
                {
                        return undef;
                }
        }
        else
        {
                return undef;
        }
}

##############
# New From Login
#
# This method takes a username authenticated the user against
# the database values
#
# Returns user/false

sub load_with_email
{
        my ($classname, $db, $email) = @_;

	if($email!~/\w/)
	{
		return undef;
	}

	my $user = &load($classname, $db, {
		clause =>  " username = ? ",
		binds => [$email] });

	return $user;
}

################
# Returns the appendation of firstname and surname

sub fullname
{
	my ($self) = @_;

	return $self->get_fullname;
}

sub get_fullname
{
        my ($self) = @_;

	if($self->get_value('surname') eq 'null')
	{
		return $self->get_value('firstname');
	}

        return $self->get_value('firstname').' '.$self->get_value('surname');
}

################
# Returns the first letters of firstname and surname

sub get_initials
{
	my ($self) = @_;

	my @parts = split(/ /, $self->get_fullname);

	my $initials;

	foreach my $part (@parts)
	{
		my $letter = substr($part, 0, 1);

		$initials .= $letter;
	}

	$initials = uc($initials);
	
	return $initials;
}

#################
# Will save the form data given a params hash	

sub save_form_data
{
	my ($self, $params) = @_;

	if($params->{is_webkit_set} eq 'y')
	{
		if($params->{is_webkit} eq 'y')
		{
			$self->general_type('webkit');
		}
		else
		{
			$self->general_type('normal');
		}
	}

	my $email1name = $params->{email1name};
	my $email1 = $params->{email1};
	my $email2name = $params->{email2name};
	my $email2 = $params->{email2};

	$email1name =~ s/[,=]//g;
	$email1 =~ s/[,=]//g;
	$email2name =~ s/[,=]//g;
	$email2 =~ s/[,=]//g;

	my $email_addresses="$email1name=$email1,$email2name=$email2";

	$params->{email_addresses} = $email_addresses;

	my @save_props = qw(firstname surname username password type phone mobile position homephone sex address email_addresses);

	foreach my $prop (@save_props)
	{
		if($params->{$prop}=~/\w/)
		{
			$self->set_value($prop, $params->{$prop});
		}
	}

	if($params->{department_id}=~/\d/)
	{
		$self->set_value('department_id', $params->{department_id});
	}

	if($self->get_value('department_id')==-1)
	{
		$self->set_value('department_id', 0);
	}

	if($self->get_value('type')!~/\w/)
	{
		$self->set_value('type', 'normal');
	}

	if($self->get_value('general_type')!~/\w/)
	{
		$self->set_value('general_type', 'normal');
	}
}

############
# Sets default values for a new user

sub set_form_defaults
{
	my ($self) = @_;

	$self->set_value('type', 'normal');
	$self->set_value('active', 'y');
}

sub get_type_title
{
	my ($self) = @_;

	return $type_titles->{$self->get_value('type')};
}

sub get_app_exists_image
{
	my ($self, $appname) = @_;

	my $src = "/images/holiday/cross.gif";

	if($self->get_privilage($appname))
	{
		$src = "/images/holiday/tick.gif";
	}

	my $ret=<<"+++";
<img width="14" height="14" align="absmiddle" src="$src">
+++

	return $ret;
}

sub get_active_image
{
	my ($self, $appname) = @_;

	my $src = "/images/holiday/cross.gif";

	if($self->is_privilaged($appname))
	{
		$src = "/images/holiday/tick.gif";
	}

	my $ret=<<"+++";
<img width="14" height="14" align="absmiddle" src="$src">
+++

	return $ret;
}

###############
# This will return options for the different types a user can be

sub get_type_options
{
	my ($self) = @_;

	my $data;

	foreach my $type (keys %$type_titles)
	{
		push(@$data, {
			title => $type_titles->{$type},
			key => $type });
	}

	my $options = Webkit::AppTools->get_select_options($data, {
		key_field => 'key',
		value_field => 'title',
		selected => $self->get_value('type') });

	return $options;
}

################
# Will return ' CHECKED' if the given prop eq 'y'

sub get_checkbox_value
{
	my ($self, $prop) = @_;

	my $value = '';

	if($self->get_value($prop) eq 'y')
	{
		$value = ' CHECKED';
	}

	return $value;
}

sub get_department_name
{
	my ($self) = @_;

	if(!$self->{department})
	{
		return '';
	}

	return $self->{department}->get_value('name');
}

sub is_user_active
{
	my ($self) = @_;

	
}

sub is_webkit
{
	my ($self) = @_;

	if($self->get_value('general_type') eq 'webkit')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub get_sex_check
{
	my ($self, $mode) = @_;

	my $value = $self->get_value('sex');

	if($value!~/\w/)
	{
		$value = 'm';
	}

	if($value eq $mode)
	{
		return ' CHECKED';
	}
	else
	{
		return '';
	}
}

sub is_webkit_checked
{
	my ($self) = @_;

	if($self->is_webkit)
	{
		return ' CHECKED';
	}
	else
	{
		return '';
	}
}

sub parse_email_addresses
{
	my ($self) = @_;

	if($self->{email_addresses_parsed}) { return; }

	my @parts = split(/,/, $self->email_addresses);

	my @parts1 = split(/=/, $parts[0]);
	my @parts2 = split(/=/, $parts[1]);

	$self->{email1name} = $parts1[0];
	$self->{email1} = $parts1[1];
	$self->{email2name} = $parts2[0];
	$self->{email2} = $parts2[1];

	$self->{email_addresses_parsed} = 1;
}

sub email1name
{
	my ($self) = @_;

	$self->parse_email_addresses;

	return $self->{email1name};
}

sub email1
{
	my ($self) = @_;

	$self->parse_email_addresses;

	return $self->{email1};
}

sub email2name
{
	my ($self) = @_;

	$self->parse_email_addresses;

	return $self->{email2name};
}

sub email2
{
	my ($self) = @_;

	$self->parse_email_addresses;

	return $self->{email2};
}

1;
