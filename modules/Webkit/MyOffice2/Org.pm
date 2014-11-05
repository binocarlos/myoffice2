package Webkit::MyOffice2::Org;

use vars qw(@ISA);

use strict;

@ISA = qw(Webkit::Org);

sub load_venues
{
	my ($self, $params) = @_;

	if($self->{_venues_loaded}) { return; }

	$self->{_venues_loaded} = 1;

	my $clause = '';
	my $binds;

	if($params->{search}=~/\w/)
	{
		$clause=<<"+++";
name like ?
or city like ?
+++

		$binds = ['%'.$params->{search}.'%', '%'.$params->{search}.'%'];
	}

	$self->load_children('Webkit::MyOffice2::Venue', {
		clause => $clause,
		binds => $binds,
		order => 'city, name' });
}

sub load_tours_with_countries
{
	my ($self) = @_;

	$self->load_tours;
	$self->load_countries;

	foreach my $tour (@{$self->ensure_child_array('tour')})
	{
		if($tour->country_id>0)
		{
			my $country = $self->get_child('country', $tour->country_id);
			$tour->load_country($country);
		}
	}
}

sub load_countries
{
	my ($self) = @_;

	if($self->{_countries_loaded}) { return; }
	$self->{_countries_loaded} = 1;

	$self->add_children('Webkit::MyOffice2::Country', {
		table => 'myoffice2.country',
		cols => 'country.*',
		order => 'name' });
}

sub load_tours
{
	my ($self) = @_;

	if($self->{_tours_loaded}) { return; }

	$self->{_tours_loaded} = 1;

	$self->add_children('Webkit::MyOffice2::Tour', {
		order => 'name' });
}

sub get_tour_options
{
	my ($self, $selected) = @_;

	if((!$selected)&&($self->{tour}))
	{
		$selected = $self->{tour}->get_id;
	}

	$self->load_tours;

	return Webkit::AppTools->get_object_select_options($self->ensure_child_array('tour'), {
		value_field => 'name',
		selected => $selected });
}

sub get_normal_tour_options
{
	my ($self, $selected) = @_;

	$self->load_tours;

	return Webkit::AppTools->get_object_select_options($self->get_normal_tours, {
		value_field => 'name',
		selected => $selected });
}	

sub load_default_tour
{
	my ($self) = @_;

	if($self->{_default_tour_loaded}) { return $self->{_default_tour}; }
	$self->{_default_tour_loaded} = 1;

	my $tour = Webkit::MyOffice2::Tour->load($self->{db}, {
		clause => ' default_mode = ? and org_id = ? ',
		binds => ['y', $self->get_id] });

	$self->{_default_tour} = $tour;

	return $tour;
}

sub get_combined_tours
{
	my ($self) = @_;

	$self->load_tours;

	my $ret;

	foreach my $tour (@{$self->ensure_child_array('tour')})
	{
		if($tour->is_combined)
		{
			push(@$ret, $tour);
		}
	}

	return $ret;
}

sub get_normal_tours
{
	my ($self) = @_;

	$self->load_tours;

	my $ret;

	foreach my $tour (@{$self->ensure_child_array('tour')})
	{
		if($tour->is_normal)
		{
			push(@$ret, $tour);
		}
	}

	return $ret;
}


sub load_print_runs_with_req_count
{
	my ($self, $tour) = @_;

	if(!$tour) { die "You need a tour to call org->load_print_runs_with_req_count"; }

	if($self->{_print_runs_with_req_count_loaded}) { return; }
	$self->{_print_runs_with_req_count_loaded} = 1;

	my $clause=<<"+++";
print_req.print_run_id = print_run.id
+++

	$self->load_tours;

	$self->add_children('Webkit::MyOffice2::PrintRun', {
		table => 'myoffice2.print_run, myoffice2.print_req',
		cols => 'print_run.*, count(*) as print_req_count',
		clause => $clause,
		order => 'start_date DESC',
		group => 'print_run.id' });

	my $ret;

	foreach my $print_run (@{$self->ensure_child_array('print_run')})
	{
		if($print_run->tour_id==$tour->get_id)
		{
			push(@$ret, $print_run);
		}
		else
		{
			my $print_run_tour = $self->get_child('tour', $print_run->tour_id);

			if($print_run_tour->is_combined)
			{
				if($print_run_tour->contains_tour($tour->get_id))
				{
					push(@$ret, $print_run);
				}
			}	
		}
	}

	$self->{print_run_array} = $ret;

	return $ret;
}

sub get_note_entry_month_options
{
	my ($self, $selected) = @_;

	if($self->{_note_entries_months_loaded}) { return; }
	$self->{_note_entries_months_loaded} = 1;

	my $refs = $self->{db}->get_select_refs({
		table => 'myoffice2.note_entry',
		cols => 'MONTH(created) as month, YEAR(created) as year',
		clause => "org_id = ?",
		binds => [$self->get_id],
		group => 'MONTH(created), YEAR(created)',
		order => 'created DESC' });

	my $options;

	foreach my $ref (@$refs)
	{
		my $month_name = Webkit::BaseDate->get_monthname($ref->{month});

		push(@$options, {
			key => $ref->{month}.'_'.$ref->{year},
			value => $month_name.' '.$ref->{year} });
	}

	return Webkit::AppTools->get_select_options($options, {
		null_title => 'Choose month...',
		key_field => 'key',
		value_field => 'value',
		selected => $selected });
}	

sub load_note_entries
{
	my ($self, $params) = @_;

	if($self->{_note_entries_loaded}) { return; }
	$self->{_note_entries_loaded} = 1;

	my $month_entry = $params->{archive_month};

	my $month;
	my $year;

	if($month_entry=~/^(\d+)_(\d+)$/)
	{
		$month = $1;
		$year = $2;
	}

	my $clause=<<"+++";
note_entry.users_id = users.id
and note_entry.org_id = ?
+++

	my $binds = [$self->get_id];

	my $limit = 10;

	if($month>0)
	{
		$clause.=<<"+++";
and MONTH(created) = ?
and YEAR(created) = ?
+++

		push(@$binds, $month);
		push(@$binds, $year);

		$limit = undef;
	}

	$self->add_children('Webkit::MyOffice2::NoteEntry', {
		table => 'myoffice2.note_entry, webkit.users',
		cols => "note_entry.*, users.firstname as users_name",
		clause => $clause,
		binds => $binds,
		group => 'note_entry.id',
		order => 'note_entry.created DESC',
		limit => $limit });
}

1;
