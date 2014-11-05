package Webkit::MyOffice2::Tourdate;

use strict;

@Webkit::MyOffice2::Tourdate::ISA = qw(Webkit::DBObject);

my $schema = {	org_id => 	{	type => 'id',
					required => 1},

		showing_id =>	{	type => 'id',
					required => 1 },

		booking_id => 	{	type => 'id',
					required => 1 },

		company_manager_id => 	{	type => 'id' },

		company_manager_confirmed => {	type => 'string' },

		backup_company_manager_id => {	type => 'id' },

		backup_company_manager_confirmed => {	type => 'string' },

		projectionist_id => {	type => 'id' },

		projectionist_confirmed => {	type => 'string' },

		backup_projectionist_id => {	type => 'id' },

		backup_projectionist_confirmed => {	type => 'string' },

		host_id => 	{	type => 'id' },

		host_confirmed => {	type => 'string' },

		backup_host_id => {	type => 'id' },

		backup_host_confirmed => {	type => 'string' },

		tour_id => 	{	type => 'id',
					required => 1 },

		date => 	{	type => 'date',
					required => 1 },

		time => 	{	type => 'time',
					required => 1 },

		general_notes => {	type => 'string' },

		sponsorship => {	type => 'string' },

		sales_figures_flattened => {	type => 'datetime' }  };

sub table
{
        return 'myoffice2.tourdate';
}

sub schema
{
        return $schema;
}

sub save_staff_params
{
	my ($self, $params) = @_;

	my @fields = qw(company_manager projectionist host backup_company_manager backup_projectionist backup_host);

	foreach my $field (@fields)
	{
		my $id = $params->{$field.'_id'};
		my $confirmed = $params->{$field.'_confirmed'};

		$self->set_value($field.'_id', $id);

		if($confirmed=~/\w/)
		{
			$self->set_value($field.'_confirmed', 'yes');
		}
		else
		{
			$self->set_value($field.'_confirmed', '');
		}
	}
}

sub get_date_title
{
	my ($self) = @_;

	return $self->date->week_day_title.' '.$self->date->get_string;
}

sub get_datetime_title
{
	my ($self, $day_of_week) = @_;

	my $time_st = $self->get_time_title;
	
	if(!$self->date)
	{
		return '';
	}

	my $ret = $self->date->get_string.' - '.$time_st;

	$ret = $self->date->week_day_title.' '.$ret;

	return $ret;
}

sub get_time_title
{
	my ($self) = @_;

	my $time_st = &Webkit::BaseDate::get_string($self->time, {
		hour => 1,
		min => 1,
		delimeter => ':' });

	return $time_st;
}

sub get_datetime
{
	my ($self) = @_;

	my $ret = Webkit::DateTime->new($self->date->Epoch);

	$ret->Hour($self->time->Hour);
	$ret->Min($self->time->Min);

	return $ret;
}

sub is_sponsored
{
	my ($self) = @_;

	if($self->sponsorship eq 'yes')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub get_staff_options
{
	my ($self, $field) = @_;

	$self->load_staff;

	my $options;

	foreach my $staff (@{$self->ensure_child_array('users')})
	{
		push(@$options, {
			id => $staff->get_id,
			title => $staff->get_fullname });
	}

	return Webkit::AppTools->get_select_options($options, {
		null_title => 'Choose...',
		key_field => 'id',
		value_field => 'title',
		selected => $self->get_value($field) });
}

sub get_confirmed_checkbox
{
	my ($self, $field) = @_;

	my $checked = '';

	if($self->get_value($field) eq 'yes')
	{
		$checked = ' CHECKED';
	}

	my $ret=<<"+++";
<input type="checkbox" value="yes" name="$field"$checked>
+++

	return $ret;
}

sub load_showing
{
	my ($self) = @_;

	if($self->{_showing_loaded}) { return $self->{_showing}; }
	$self->{_showing_loaded} = 1;

	my $showing = Webkit::MyOffice2::Showing->load($self->{db}, {
		id => $self->showing_id });

	$self->{_showing} = $showing;
	return $self->{_showing};
}

sub get_staff_string
{
	my ($self, $hash, $delim) = @_;

	my $keys = [
		{	field => 'company_manager',
			title => 'CM' },
		{	field => 'projectionist',
			title => 'PJ' },
		{	field => 'host',
			title => 'HS' },
		{	field => 'backup_company_manager',
			title => 'CM2' },
		{	field => 'backup_projectionist',
			title => 'PJ2' },
		{	field => 'backup_host',
			title => 'HS2' } ];

	my $parts;

	foreach my $ref (@$keys)
	{
		my $value = $self->get_value($ref->{field}.'_id');

		if($value>0)
		{
			my $user_name = $hash->{$value};
			my $conf = ' (NOT Confirmed)';

			if($self->get_value($ref->{field}.'_confirmed') eq 'yes')
			{
				$conf = ' (Conf)';
			}

			push(@$parts, $ref->{title}.': '.$user_name.$conf);
		}
	}

	my $ret;
	if(!defined($delim))
	{
		$delim = "<br>";
	}

	if($parts)
	{
		$ret = join(','.$delim, @$parts);
	}

	return $ret;
}

sub load_staff
{
	my ($self) = @_;

	if($self->{_users_loaded}) { return; }
	$self->{_users_loaded} = 1;

	my $clause=<<"+++";
org_id = ?
and active = ?
and
(
	type = ?
or
	type = ?
or
	type = ?
)
+++

	$self->add_children('Webkit::MyOffice2::MyOfficeUser', {
		table => 'myoffice2.users',
		clause => $clause,
		binds => [$self->org_id, 'y', 'event_manager', 'compere', 'projectionist'],
		order => 'firstname, surname' });
}

sub sales_figures_entry
{
	my ($self, $new) = @_;

	if($new)
	{
		$self->{_sales_figures_entry} = $new;
	}

	return $self->{_sales_figures_entry};
}

1;
