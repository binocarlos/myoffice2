package Webkit::MyOffice2::PrintRun;

use strict;

@Webkit::MyOffice2::PrintRun::ISA = qw(Webkit::DBObject);

my $schema = {	org_id => 	{	type => 'id',
					required => 1 },

		tour_id =>	{	type => 'id',
					required => 1 },

		name =>		{	type => 'string',
					required => 1 },

		start_date =>	{	type => 'date',
					required => 1 },

		end_date =>	{	type => 'date',
					required => 1 },

		created =>	{	type => 'datetime',
					required => 1 },

		notes =>	{	type => 'string' },

		leaflet_cost => {	type => 'float' },

		a3_cost => {		type => 'float' },

		dc_cost => {		type => 'float' },

		foursheet_cost => {	type => 'float' },

		leaflet_total => {	type => 'float' },

		a3_total => {		type => 'float' },

		dc_total => {		type => 'float' },

		foursheet_total => {	type => 'float' },

		delivery_total => {	type => 'float' },

		total_cost => {		type => 'float' }
 };

sub table
{
        return 'myoffice2.print_run';
}

sub schema
{
        return $schema;
}

sub assign_data
{
	my ($self, $data) = @_;

	$self->SUPER::assign_data($data);

	my @non_zero_fields = qw(leaflet_cost a3_cost dc_cost foursheet_cost);

	foreach my $field (@non_zero_fields)
	{
		my $value = $self->get_value($field);

		if($value!~/\w/)
		{
			$self->set_value($field, 0);
		}
	}
}

sub save_form_params
{
	my ($self, $params) = @_;

	if(!$self->exists)
	{
		$self->created(Webkit::DateTime->now);
	}

	$self->name($params->{name});
	
	my $start_date = Webkit::Date->from_calendar($params->{start_date});
	my $end_date = Webkit::Date->from_calendar($params->{end_date});

	$self->start_date($start_date);
	$self->end_date($end_date);

	$self->notes($params->{notes});
}

sub create_central_print_req
{
	my ($self) = @_;

	if(!$self->{db}->in_transaction) { die "PrintRun->create_central_print_req requires a transaction"; }

	my $print = Webkit::MyOffice2::Print->constructor($self->{db});

	$print->org_id($self->org_id);
	$print->tour_id($self->tour_id);
	$print->print_run_id($self->get_id);
	$print->showing_id(0);

	$print->create;
}

sub load_print_reqs
{
	my ($self) = @_;

	if($self->{_print_reqs_loaded}) { return; }
	$self->{_print_reqs_loaded} = 1;

	$self->load_children('Webkit::MyOffice2::Print');
}

sub qtr_title
{
	my ($self) = @_;

	my $year = $self->start_date->Year;
	my $month = $self->start_date->Month;

	my $qtr = sprintf("%.0f", $month/4) + 1;

	return "Qtr $qtr - $year";
}

sub tour_name_blue_span
{
	my ($self) = @_;

	my $value = $self->tour_name;

	my $ret=<<"+++";
<span style="color:blue;">$value</span>
+++

	return $ret;
}

sub tour_name
{
	my ($self, $value) = @_;

	if($value=~/\w/)
	{
		$self->{_tour_name} = $value;
	}

	return $self->{_tour_name};
}

sub print_req_count
{
	my ($self, $value) = @_;

	if($value=~/\w/)
	{
		$self->{data}->{print_req_count} = $value;
	}

	return $self->{data}->{print_req_count};
}

sub get_dates_title
{
	my ($self) = @_;

	return $self->start_date->get_string.' to '.$self->end_date->get_string;
}

sub get_html_notes
{
	my ($self) = @_;

	return $self->get_html_value('notes');
}

sub start_date_title
{
	my ($self) = @_;

	my $ret = '';

	if($self->start_date)
	{
		$ret = $self->start_date->get_string;
	}

	return $ret;
}

sub end_date_title
{
	my ($self) = @_;

	my $ret = '';

	if($self->end_date)
	{
		$ret = $self->end_date->get_string;
	}

	return $ret;
}

sub get_print_run_value
{
	my ($self, $field, $calculated) = @_;

	my $ret = $self->get_value($field);

	if($ret>0)
	{
		return $ret;
	}
	else
	{
		return $calculated;
	}
}

sub calculate
{
	my ($self) = @_;

	my $print_array;
	my $central_req = $self->{_central_print_req};

	if($central_req)
	{
		$central_req->calculate($self);
		push(@$print_array, $central_req);
	}

	foreach my $showing (@{$self->{showing_array}})
	{
		my $print_req = $showing->{_print_req_obj};

		$print_req->calculate($self);
		push(@$print_array, $print_req);
	}

	foreach my $print_req (@$print_array)
	{
		$self->{_totals}->{leaflets} += $print_req->{_leaflets_total};
		$self->{_totals}->{a3s} += $print_req->{_a3s_total};
		$self->{_totals}->{dcs} += $print_req->{_dcs_total};
		$self->{_totals}->{foursheets} += $print_req->{_foursheets_total};
		$self->{_totals}->{delivery} += $print_req->{_delivery_total};
		$self->{_totals}->{total} += $print_req->{total};
	}
}

1;
