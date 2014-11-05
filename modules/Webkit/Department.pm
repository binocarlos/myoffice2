package Webkit::Department;

use strict;

@Webkit::Department::ISA = qw(Webkit::DBObject);

my $schema = {		org_id => {	type => 'id',
					required => 1 },

			name => {	type => 'string',
					required => 1 } };

sub table
{
        return 'webkit.department';
}

sub schema
{
        return $schema;
}

sub get_department_options
{
	my ($classname, $org, $user) = @_;

	if((!$user)||(!$org))
	{
		return '';
	}

	$org->load_children('Webkit::Department', {
		order => 'name' });

	my $options = Webkit::AppTools->get_object_select_options($org->get_child_array('department'), {
		key_field => 'id',
		value_field => "name",
		null_title => 'None or enter new ...',
		selected => $user->get_value('department_id') });

	return $options;	
}

sub delete_unused_departments
{
	my ($classname, $org, $appname) = @_;

	if(!$org)
	{
		return;
	}

	my $departments = $org->load_children('Webkit::Department');
	my $users = $org->load_children('Webkit::User');

	my $department_hash = Webkit::AppTools->get_id_hash($departments);

	my $department_counts;

	foreach my $department (@$departments)
	{
		$department_counts->{$department->get_id} = 0;
	}

	foreach my $user (@$users)
	{
		my $dept_id = $user->get_value('department_id');

		$department_counts->{$dept_id}++;
	}

	foreach my $department (@$departments)
	{
		my $count = $department_counts->{$department->get_id};

		if(!$count>0)
		{
			$department->delete;
		}
	}
}

1;
