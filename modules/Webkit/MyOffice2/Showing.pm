package Webkit::MyOffice2::Showing;

use strict;

@Webkit::MyOffice2::Showing::ISA = qw(Webkit::DBObject);

my $schema = {	 org_id => {	type => 'id',
				required => 1},

		tour_id => {	type => 'id',
				required => 1 },

                deal_id => {	type => 'id',
				required => 1 },

                users_id => {	type => 'id',
				required => 1 },

                venue_id => {	type => 'id',
				required => 1 },

                booking_id => {	type => 'id',
				required => 1 },

                technical_rider_date => {	type => 'string' },

                technical_rider_date_rcvd => {	type => 'string' },

                created => {	type => 'datetime',
				required => 1 },

                sp => {		type => 'datetime' },

                epk => {	type => 'datetime' },

                flattened => {	type => 'datetime' },

                settled => {	type => 'date' },

                pl_flatten_mode => {	type => 'string' },
                
                tickets_url => {	type => 'string' },
                tickets_region => {	type => 'string' },
                tickets_country => {	type => 'string' },
                
                onsale => {	type => 'string' },
                
                onsale_date => {	type => 'date' },

                show_report => {	type => 'date' } };

sub table
{
        return 'myoffice2.showing';
}

sub schema
{
        return $schema;
}

sub load_print_reqs
{
	my ($self) = @_;

	if($self->{_print_reqs_loaded}) { return; }
	$self->{_print_reqs_loaded} = 1;

	$self->load_children('Webkit::MyOffice2::Print');

	foreach my $print_req (@{$self->ensure_child_array('print_req')})
	{
		$self->{_print_run_ids}->{$print_req->print_run_id} = $print_req;
	}
}

sub load_tourdates
{
	my ($self) = @_;

	if($self->{_tourdates_loaded}) { return; }
	$self->{_tourdates_loaded} = 1;

	$self->load_children('Webkit::MyOffice2::Tourdate', {
		order => 'date, time' });
}

sub load_booking
{
	my ($self) = @_;

	if($self->{_booking_loaded}) { return $self->{_booking}; }
	$self->{_booking_loaded} = 1;

	my $booking = Webkit::MyOffice2::Booking->load($self->{db}, {
		id => $self->booking_id });

	$self->{_booking} = $booking;
	return $self->{_booking};
}

sub load_venue
{
	my ($self) = @_;

	if($self->{_venue_loaded}) { return $self->{_venue}; }
	$self->{_venue_loaded} = 1;

	my $venue = Webkit::MyOffice2::Venue->load($self->{db}, {
		id => $self->venue_id });

	$self->{_venue} = $venue;
	return $self->{_venue};
}

sub load_sales_figures_entries
{
	my ($self) = @_;

	if($self->{_sales_figures_entries_loaded}) { return; }
	$self->{_sales_figures_entries_loaded} = 1;

	my $clause=<<"+++";
tourdate.showing_id = ?
and sales_figures_entry.tourdate_id = tourdate.id
+++

	$self->add_children('Webkit::MyOffice2::SalesFiguresEntry', {
		table => 'myoffice2.sales_figures_entry, myoffice2.tourdate',
		cols => 'sales_figures_entry.*',
		clause => $clause,
		binds => [$self->get_id],
		group => 'sales_figures_entry.id' });
}

sub load_sales_figures
{
	my ($self) = @_;

	if($self->{_sales_figures_loaded}) { return; }
	$self->{_sales_figures_loaded} = 1;

	my $clause=<<"+++";
tourdate.showing_id = ?
and sales_figures_entry.tourdate_id = tourdate.id
and sales_figures.sales_figures_entry_id = sales_figures_entry.id
+++

	$self->add_children('Webkit::MyOffice2::SalesFiguresEntry', {
		table => 'myoffice2.sales_figures_entry, myoffice2.sales_figures, myoffice2.tourdate',
		cols => 'sales_figures.*',
		clause => $clause,
		binds => [$self->get_id],
		group => 'sales_figures.id' });
}

sub load_deal
{
	my ($self) = @_;

	if($self->{_deal_loaded}) { return $self->{_deal}; }
	$self->{_deal_loaded} = 1;

	my $deal = Webkit::MyOffice2::Deal->load($self->{db}, {
		id => $self->deal_id });

	$self->{_deal} = $deal;
	return $self->{_deal};
}

sub add_venue_status_entry
{
	my ($self, $entry) = @_;

	$self->add_child($entry);

	$self->{_venue_status_entries}->{$entry->field} = $entry;
}

sub get_venue_status_value
{
	my ($self, $field) = @_;

	my $entry = $self->get_venue_status_entry($field);

	if(!$entry) { return; }

	return $entry->value;
}

sub assign_venue_status_entries
{
	my ($self) = @_;

	

}

sub get_venue_status_entry
{
	my ($self, $field, $construct) = @_;

	my $ret = $self->{_venue_status_entries}->{$field};

	if((!$ret)&&($construct))
	{
		$self->{_new_venue_status_id}++;

		$ret = Webkit::MyOffice2::VenueStatusEntry->constructor($self->{db});
		$ret->{data}->{id} = $self->get_id.'.'.$self->{_new_venue_status_id};

		$ret->org_id($self->org_id);
		$ret->tour_id($self->tour_id);
		$ret->showing_id($self->get_id);
		$ret->booking_id($self->booking_id);
		$ret->created(Webkit::DateTime->now);
		$ret->field($field);

		$self->{_venue_status_entries}->{$field} = $ret;
	}

	return $ret;
}

sub get_technical_rider_rcvd_title
{
	my ($self, $delim, $notestyle) = @_;

	my $ret = '';

	if($self->technical_rider_date_rcvd)
	{
		$ret = Webkit::AppTools->get_multidate_note_title($self->technical_rider_date_rcvd, $delim, $notestyle);
	}

	return $ret;
}

sub get_technical_rider_title
{
	my ($self, $delim, $notestyle) = @_;

	my $ret = '';

	if($self->technical_rider_date)
	{
		$ret = Webkit::AppTools->get_multidate_note_title($self->technical_rider_date, $delim, $notestyle);
	}

	return $ret;
}

sub get_first_tourdate
{
	my ($self) = @_;

	my $arr = $self->ensure_child_array('tourdate');

	return $arr->[0];
}

sub get_first_tourdate_epoch
{
	my ($self) = @_;

	my $tourdate = $self->get_first_tourdate;

	if(!$tourdate) { return 0; }

	if(!$tourdate->date) { return 0; }
	
	return $tourdate->date->Epoch;
}

sub get_first_tourdate_title
{
	my ($self) = @_;

	my $tourdate = $self->get_first_tourdate;

	if(!$tourdate) { return ''; }

	return $tourdate->get_date_title;
}


sub get_datetime_title
{
	my ($self, $delim) = @_;

	if(!$delim) { $delim = '<br>'; }

	my $parts;

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		push(@$parts, $tourdate->get_datetime_title);
	}

	if(!$parts) { return ''; }

	my $ret = join($delim, @$parts);

	return $ret;
}

sub get_epk_title
{
	my ($self) = @_;

	my $ret = '';

	if($self->epk)
	{
		$ret = &Webkit::Date::get_string($self->epk);
	}

	return $ret;
}

sub calculate_venue_status_sheet
{
	my ($self) = @_;

	if($self->{_venue_status_calculated}) { return; }
	$self->{_venue_status_calculated} = 1;

	my $tourdate_count = 0;

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $entry = $tourdate->sales_figures_entry;
		
		$self->{_current_sold_gross} += $entry->current_sold_gross;
		$self->{_current_attendance} += $entry->current_attendance;
#		$self->{_sales_figures_tickets} += $entry->tickets_avail;
		$self->{_current_sold_in_week} += $entry->current_sold_in_week;
		$self->{_current_reserved} += $entry->current_reserved;

		$tourdate_count++;
	}

	if($self->{_tickets_on_sale}>0)
	{
		my $total_sale_tickets = $self->{_tickets_on_sale};

		if($tourdate_count>0) { $total_sale_tickets *= $tourdate_count; }

		$self->{_attendance_capacity} = ($self->{_current_attendance} / $total_sale_tickets) * 100;
		$self->{_percent_reserved} = ($self->{_current_reserved} / $total_sale_tickets) * 100;
	}

	$self->{_percent_to_sell} = 100 - $self->{_attendance_capacity} - $self->{_percent_reserved};

	my $gross_bo = $self->get_venue_status_value('actual_gross_box_office') || 0;
	my $net_bo = $self->get_venue_status_value('actual_net_box_office') || 0;

	if($self->{_current_attendance}>0)
	{
		$self->{_average_gross_ticket_price} = $self->{_current_sold_gross} / $self->{_current_attendance};
		$self->{_average_net_ticket_price} = $self->{_average_gross_ticket_price} * 0.825;
	}
}

sub no_weeks_left
{
	my ($self) = @_;

	my $tourdate = $self->get_first_tourdate;

	if(!$tourdate) { return 0; }

	my $now = Webkit::Date->now;
	my $date = $tourdate->date;

	my $days_gap = $date->epoch_days - $now->epoch_days;

	if($days_gap<=0) { return 0; }

	my $weeks = $days_gap / 7;

	my $rounded = sprintf("%.1f", $weeks);

	return $rounded;
}

sub get_percent_to_sell
{
	my ($self) = @_;

	$self->calculate_venue_status_sheet;
	return $self->{_percent_to_sell} || 0;
}

sub get_percent_reserved
{
	my ($self) = @_;

	$self->calculate_venue_status_sheet;
	return $self->{_percent_reserved} || 0;
}

sub get_current_sold_gross
{
	my ($self) = @_;

	$self->calculate_venue_status_sheet;
	return $self->{_current_sold_gross} || 0;
}

sub get_current_sold_in_week
{
	my ($self) = @_;

	$self->calculate_venue_status_sheet;
	return $self->{_current_sold_in_week} || 0;
}

sub get_current_attendance
{
	my ($self) = @_;

	$self->calculate_venue_status_sheet;
	return $self->{_current_attendance} || 0;
}

sub get_attendance_capacity
{
	my ($self) = @_;

	$self->calculate_venue_status_sheet;
	return $self->{_attendance_capacity} || 0;
}

sub get_average_sales_gross_ticket_price
{
	my ($self) = @_;

	$self->calculate_venue_status_sheet;
	return $self->{_average_sales_gross_ticket_price} || 0;
}

sub get_average_gross_ticket_price
{
	my ($self) = @_;

	$self->calculate_venue_status_sheet;
	return $self->{_average_gross_ticket_price} || 0;
}

sub get_average_net_ticket_price
{
	my ($self) = @_;

	$self->calculate_venue_status_sheet;
	return $self->{_average_net_ticket_price} || 0;
}

sub parse_tickets_url
{
	my ($self) = @_;

	my $ret = $self->tickets_url;
	
	#if($ret !~ /^http:\/\//i)
	#{
	#	$ret = 'http://'.$ret;
	#}
	
	return $ret;
}

sub parse_tickets_country
{
	my ($self) = @_;

	my $ret = $self->tickets_country;
	
	if($ret !~ /\w/)
	{
		$ret = 'UK';
	}
	
	return $ret;
}

sub parse_tickets_region
{
	my ($self) = @_;

	my $ret = $self->tickets_region;
	
	#if($ret !~ /^http:\/\//i)
	#{
	#	$ret = 'http://'.$ret;
	#}
	
	return $ret;
}

sub is_onsale
{
	my ($self) = @_;

	return $self->onsale eq 'y';
}

sub ensure_onsale_date_string
{
	my ($self) = @_;
	
	if($self->onsale_date)
	{
		return $self->onsale_date->get_string;
	}
	else
	{
		return '';
	}	
}

1;
