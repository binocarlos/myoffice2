package Webkit::MyOffice2::SalesFigures;

use strict;

@Webkit::MyOffice2::SalesFigures::ISA = qw(Webkit::DBObject);

my $schema = {	org_id => 	{	type => 'id',
					required => 1 },

		sales_figures_entry_id => {	type => 'id',
						required => 1 },

                tour_id => {	type => 'id',
                                required => 1 },

                week_start => {	type => 'date',
				required => 1 },

                sold_seats => {	type => 'integer',
				required => 1 },

                reserved_seats => {	type => 'integer',
					required => 1 },

                sold_gross => {	type => 'float',
				required => 1 },

                reserved_gross => {	type => 'float',
                                        required => 1 },

		tourdate_id => {	type => 'id',
					required => 1 } };

sub table
{
        return 'myoffice2.sales_figures';
}

sub schema
{
        return $schema;
}

sub calculate
{
	my ($self, $tickets, $last_week_sold) = @_;

	$self->{_percent_sold} = 0;

	if($tickets>0)
	{
		$self->{_percent_sold} = sprintf("%.2f", ($self->sold_seats / $tickets) * 100);
	}

	$self->{_sold_in_week} = $self->sold_seats - $last_week_sold;
}

sub percent_sold
{
	my ($self) = @_;

	return $self->{_percent_sold};
}

sub sold_in_week
{
	my ($self) = @_;

	return $self->{_sold_in_week};
}

1;
