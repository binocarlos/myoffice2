package Webkit::OrgAdmin::Admin;

use vars qw(@ISA);

use strict qw(vars);

use Webkit::Application;
use Webkit::Error;

use Webkit::Org;
use Webkit::User;
use Webkit::Privilage;

@ISA = qw(Webkit::Application);

my $app_name = 'orgadmin';
my $app_title = 'Org Manager';

my $manual_page_methods = {
	generate_window => 1,
	home_frameset => 1 };

########################################################################################
########################################################################################
######################
# Boot
######################
########################################################################################
########################################################################################

sub app_name
{
	my ($self) = @_;

	return 'orgadmin';
}

sub get_sqldb
{
	my ($self) = @_;

	return 'webkit';
}

sub app_title
{
	my ($self) = @_;

	return $app_title;
}



sub manual_page_methods
{
	my ($self) = @_;

	return $manual_page_methods;
}

sub check_privilages
{
	my ($self) = @_;

	if($self->{user}->get_value('general_type') eq 'webkit')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub initialise_user_objects
{
	my ($self) = @_;

	if($self->{session}->{edit_org_id}>0)
	{
		$self->{org} = Webkit::Org->load($self->{db}, {
			id => $self->{session}->{edit_org_id} });
	}
	else
	{
		$self->SUPER::initialise_user_objects;
	}
}

########################################################################################
########################################################################################
######################
# LOGIN
######################
########################################################################################
########################################################################################

sub home_frameset
{
	my ($self) = @_;

	my $href = $self->href;

	$self->{page}->{manual_page}=<<"+++";
<HTML>
  <FRAMESET COLS="160,*" ID="sidebar_frameset" FRAMEBORDER="YES" BORDER="5">
  <FRAME NAME="sidebar" SRC="$href&method=home_sidebar" MARGINWIDTH="5" MARGINHEIGHT="5" STYLE="border:1px; border-style:inset;" SCROLLING="AUTO" FRAMEBORDER="NO">
  <FRAME NAME="page" SRC="$href&method=home_mainpage" FRAMEBORDER="NO" MARGINWIDTH="5" MARGINHEIGHT="5" STYLE="border:1px; border-style:inset;" SCROLLING="AUTO"> </FRAMESET>
</HTML>
+++
}


sub home_sidebar
{
	my ($self) = @_;

	my $orgs = Webkit::Org->load_all_orgs_and_users($self->{db});

	$self->{page}->add_template('sidemenu', {
		orgs => $orgs });
}

sub home_mainpage
{
        my ($self) = @_;

	$self->{page}->ab("This is the home_mainpage page");
}


sub edit_user_details
{
	my ($self) = @_;

	my $user_id = $self->{params}->{users_id};

	if(!$user_id>0)
	{
		$user_id = $self->{session}->{edit_users_id};
	}

	my $user = Webkit::User->load($self->{db}, {
		id => $user_id });

	$self->{session}->set('edit_org_id', $user->get_value('org_id'));
	$self->{session}->set('view_method', 'edit_user_details');
	$self->{session}->set('edit_users_id', $user->get_id);

	$self->{session}->set('post_user_hash', {
		method => 'edit_user_details',
		users_id => $user->get_id });

	$self->{org}->load_all_applications;

	$user->load_all_privilages;

	$self->{page}->add_template('users_details', {
		users_id => $user->get_id,
		application_array => $self->{org}->get_standalone_applications,
		application_hash => $self->{org}->get_child_hash('application'),
		edituser => $user });
}

sub edit_user_details_submit
{
	my ($self) = @_;

	my $user = Webkit::User->load($self->{db}, {
		id => $self->{params}->{users_id} });

	$self->{org}->load_all_applications;

	$user->load_all_privilages;

	my $app_arr = $self->{org}->get_standalone_applications;
	my $app_hash = $self->{org}->get_child_hash('application');

	$self->{db}->begin_transaction;

	foreach my $application (@$app_arr)
	{
		my $existing = $user->get_privilage($application->get_id);

		$self->save_privilage_from_params($user, $existing, $application);

		my $subapps = $application->get_subapplication_ids;

		foreach my $sub_app_id (@$subapps)
		{
			my $sub_application = $app_hash->{$sub_app_id};

			my $sub_existing = $user->get_privilage($application->get_id, $sub_application->get_id);

			$self->save_privilage_from_params($user, $sub_existing, $application, $sub_application);
		}
	}

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'edit_user_details',
		users_id => $user->get_id });
}

sub save_privilage_from_params
{
	my ($self, $user, $existing, $application, $sub_application) = @_;

	my $del = $self->{params}->{'delete_'.$application->get_id};

	if(($existing)&&($del eq 'y'))
	{
		$existing->delete;

		return;
	}

	my $param_key = 'active_'.$application->get_id;

	if($sub_application)
	{
		$param_key.='_'.$sub_application->get_id;
	}

	my $old_active = 'n';

	if($existing)
	{
		$old_active = $existing->get_value('active');
	}

	my $new_active = $self->{params}->{$param_key};

	if($new_active!~/\w/)
	{
		$new_active = 'n';
	}

	if($new_active ne $old_active)
	{
		if($existing)
		{
			$existing->set_value('active', $new_active);

			$existing->save;
		}
		else
		{
			my $priv = Webkit::Privilage->constructor($self->{db});

			$priv->set_value('users_id', $user->get_id);
			$priv->set_value('application_id', $application->get_id);

			if($sub_application)
			{
				$priv->set_value('sub_application_id', $sub_application->get_id);
			}

			$priv->set_value('active', 'y');

			$priv->create;
		}

		if($new_active eq 'y')
		{

			my $appclass = $application->get_value('module');

			my $app = {};

			bless($app, $appclass);

			if($app->can('create_default_user_data'))
			{
				$app->create_default_user_data($user);
			}
		}
	}
}

sub edit_org_details
{
	my ($self) = @_;

	$self->{session}->set('edit_org_id', $self->{params}->{org_id});
	$self->{session}->set('users_home_no_active', 'y');
	$self->{session}->set('users_home_app_name', '');
	$self->{session}->set('users_home_add_method', 'add_user');

	$self->{session}->delete('view_method');
	$self->{session}->delete('edit_users_id');
	$self->{session}->delete('post_user_hash');

	$self->{page}->add_redir({
		method => 'users_home' });
}

sub edit_user
{
	my ($self) = @_;

	$self->SUPER::edit_user(undef, {
		form_config => {
			privilages => -1 }});
}

sub edit_user_submit
{
	my ($self) = @_;

	my $href = $self->href;

	$self->{page}->ab(<<"+++");
<script>
parent.sidebar.document.location = '$href&method=home_sidebar';
</script>
+++

	$self->SUPER::edit_user_submit({
		no_privilages => 1 });
}

sub add_user
{
	my ($self) = @_;

	$self->SUPER::add_user(undef, {
		form_config => {
			privilages => 'admin_only' }});
}

sub add_user_submit
{
	my ($self) = @_;

	my $href = $self->href;

	$self->{page}->ab(<<"+++");
<script>
parent.sidebar.document.location = '$href&method=home_sidebar';
</script>
+++

	$self->SUPER::add_user_submit({
		no_privilages => 1 });
}

sub delete_user_submit
{
	my ($self) = @_;

	my $user = $self->load_user({
		id => $self->{params}->{object_id} });

	$self->{db}->begin_transaction;

	$user->delete_children('Webkit::Privilage');

	my $id = $user->get_id;

	$user->delete;

	$self->{db}->commit;

	my $href = $self->href;

	$self->{page}->ab(<<"+++");
<script>
parent.sidebar.document.location = '$href&method=home_sidebar';
</script>
+++

	$self->{page}->add_redir({
		method => 'users_home' });
}

1;
