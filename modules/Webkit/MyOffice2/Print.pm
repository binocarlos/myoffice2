package Webkit::MyOffice2::Print;

use strict;

@Webkit::MyOffice2::Print::ISA = qw(Webkit::DBObject);

my $schema = {	org_id => 	{	type => 'id',
					required => 1 },

		showing_id =>	{	type => 'id',
					required => 1 },

		tour_id =>	{	type => 'id',
					required => 1 },

		addressee_id =>	{	type => 'id' },

		print_run_id => {	type => 'id' },

		total_cost => {		type => 'float' },

		leaflets =>	{	type => 'integer' },

		leaflet_cost => {	type => 'float' },

		a3s =>		{	type => 'integer' },

		a3_cost => {		type => 'float' },
		
		dcs =>		{	type => 'integer' },

		dc_cost => {	type => 'float' },

		foursheets =>	{	type => 'integer' },

		foursheet_cost => {	type => 'float' },

		print_despatched => {	type => 'datetime' },

		print_received => {	type => 'datetime' },

		delivery_cost => {	type => 'float' },

		delivery_address => {	type => 'string' },

		notes => 	{	type => 'string' } };

sub table
{
        return 'myoffice2.print_req';
}

sub schema
{
        return $schema;
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

sub assign_data
{
	my ($self, $data) = @_;

	$self->SUPER::assign_data($data);

	my @non_zero_fields = qw(leaflets a3s dcs foursheets delivery_cost);

	foreach my $field (@non_zero_fields)
	{
		my $value = $self->get_value($field);

		if($value!~/\w/)
		{
			$self->set_value($field, 0);
		}
	}
}

sub print_despatched_title
{
	my ($self) = @_;

	my $ret = '';

	if($self->print_despatched)
	{
		$ret = &Webkit::Date::get_string($self->print_despatched);
	}

	return $ret;
}

sub print_received_title
{
	my ($self) = @_;

	my $ret = '';

	if($self->print_received)
	{
		$ret = &Webkit::Date::get_string($self->print_received);
	}

	return $ret;
}

sub get_print_value
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
	my ($self, $print_run) = @_;

	my $leaflets_total = $self->get_print_value('leaflet_cost', $print_run->leaflet_cost * $self->leaflets);
	my $a3s_total = $self->get_print_value('a3_cost', $print_run->a3_cost * $self->a3s);
	my $dcs_total = $self->get_print_value('dc_cost', $print_run->dc_cost * $self->dcs);
	my $foursheets_total = $self->get_print_value('foursheet_cost', $print_run->foursheet_cost * $self->foursheets);
	my $delivery_cost = $self->delivery_cost || 0;
	my $calculated_total = $leaflets_total + $a3s_total + $dcs_total + $foursheets_total + $delivery_cost;
	my $total = $self->get_print_value('total_cost', $calculated_total);

	$self->{_leaflets_total} = $leaflets_total;
	$self->{_a3s_total} = $a3s_total;
	$self->{_dcs_total} = $dcs_total;
	$self->{_foursheets_total} = $foursheets_total;
	$self->{_delivery_total} = $delivery_cost;
	$self->{_total} = $total;
}

1;
