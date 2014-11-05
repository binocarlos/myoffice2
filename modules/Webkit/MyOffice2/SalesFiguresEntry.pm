package Webkit::MyOffice2::SalesFiguresEntry;

use strict;

@Webkit::MyOffice2::SalesFiguresEntry::ISA = qw(Webkit::DBObject);

my $schema = {	org_id => 	{	type => 'id',
					required => 1 },

		tourdate_id =>	{	type => 'id',
					required => 1 },

		surf_held =>	{	type => 'integer',
					required => 1 },

		tickets_avail => {	type => 'integer',
					required => 1 },

		figures_number => {	type => 'string' },

		tour_id => {	type => 'id',
				required => 1 },

		notes => {	type => 'string' } };

sub table
{
        return 'myoffice2.sales_figures_entry';
}

sub schema
{
        return $schema;
}

sub constructor
{
	my ($classname, $db) = @_;

	my $ret = &Webkit::DBObject::constructor($classname, $db);

	$ret->surf_held(0);
	$ret->tickets_avail(0);

	return $ret;
}

sub add_sales_figures
{
	my ($self, $figures) = @_;

	$self->add_child($figures);
	$self->{_figures_map}->{$figures->week_start->epoch_days} = $figures;
}

sub get_previous_sales_figures
{
	my ($self, $week_epoch_days) = @_;

	$week_epoch_days -= 7;

	return $self->{_figures_map}->{$week_epoch_days};
}

sub get_sales_figures
{
	my ($self, $week_epoch_days) = @_;

	return $self->{_figures_map}->{$week_epoch_days};
}

sub construct_sales_figures
{
	my ($self, $next_id, $week_start_epoch_days, $tourdate) = @_;

	my $week_start = Webkit::Date->now;
	$week_start->{'epoch day'} = $week_start_epoch_days;

	my $figures = Webkit::MyOffice2::SalesFigures->constructor($self->{db});
	$figures->org_id($self->org_id);
	$figures->tour_id($self->tour_id);
	$figures->sales_figures_entry_id($self->get_id);
	$figures->tourdate_id($tourdate->get_id);
	$figures->week_start($week_start);
	$figures->sold_seats(0);
	$figures->reserved_seats(0);
	$figures->sold_gross(0);
	$figures->reserved_gross(0);

	$figures->{data}->{id} = $self->get_id.'.'.$next_id;

	$self->add_sales_figures($figures);
}

sub calculate
{
	my ($self, $tickets_on_sale) = @_;

	if($tickets_on_sale!~/\d/)
	{
		return;
	}

	my $last_week = 0;

	foreach my $sales_figures (@{$self->ensure_child_array('sales_figures')})
	{
		$sales_figures->calculate($tickets_on_sale, $last_week);

		$last_week = $sales_figures->sold_seats;
	}
}

sub get_last_sales_figures
{
	my ($self) = @_;

	my $arr = $self->ensure_child_array('sales_figures');

	return $arr->[-1];
}

sub current_reserved
{
	my ($self) = @_;

	my $figs = $self->get_last_sales_figures;

	if($figs) { return $figs->reserved_seats; }
	else { return 0; }
}

sub current_sold_gross
{
	my ($self) = @_;

	my $figs = $self->get_last_sales_figures;

	if($figs) { return $figs->sold_gross; }
	else { return 0; }
}

sub current_sold_in_week
{
	my ($self) = @_;

	my $figs = $self->get_last_sales_figures;

	if($figs) { return $figs->sold_in_week; }
	else { return 0; }
}

sub current_attendance
{
	my ($self) = @_;

	my $figs = $self->get_last_sales_figures;

	if($figs) { return $figs->sold_seats; }
	else { return 0; }
}

1;
