package Webkit::MyOffice2::Booking;

use strict;

@Webkit::MyOffice2::Booking::ISA = qw(Webkit::DBObject);

my $schema = {	org_id => 	{	type => 'id',
					required => 1},

		tour_id =>        {	type => 'id',
                                        required => 1 },

                created =>        {        type => 'datetime',
                                        required => 1 },

                penciled =>        {        type => 'datetime' },

                failed =>        {        type => 'datetime' },

                venue_id =>        {        type => 'id',
                                        required => 1 },

                pack_sent =>         {  type => 'string' },

                date_called =>         {      type => 'string' },

                notes =>         {       type => 'string' },

                ticket_price => {       type => 'string' },

		gross_box_office => {	type => 'float' },

		tickets_on_sale => {	type => 'integer' },

		tickets_on_sale_reason => {	type => 'string' },

                guarantee =>         {        type => 'string' },

                deal =>         {       type => 'float' },

                agreed =>         {        type => 'datetime' },

                tech_issues =>         {       type => 'string' },

		venue_target => 	{	type => 'string' },

		deal_notes => {		type => 'string' },

		brochure_copy_deadline => {	type => 'string' },

		brochure_mailing_dates => {	type => 'string' } };

sub table
{
        return 'myoffice2.booking';
}

sub schema
{
        return $schema;
}

sub assign_data
{
	my ($self, $data) = @_;

	$self->SUPER::assign_data($data);

	my @ticket_price_parts = split(/:/, $self->ticket_price);

	my $total_percent = 0;
	my $no_percent_count = 0;

	foreach my $part (@ticket_price_parts)
	{
		my ($price, $note, $percent) = split(/=/, $part);

		if(!$percent)
		{
			$percent = 0;
		}

		$total_percent += $percent;

		my $ref = {
			price => $price,
			percent => $percent,
			note => $note };

		push(@{$self->{_ticket_price_refs}}, $ref);

		if($percent<=0)
		{
			$no_percent_count++;
		}
	}

	my $remaining_percent = 100 - $total_percent;

	if($no_percent_count>0)
	{
		my $divided_percent = $remaining_percent / $no_percent_count;

		foreach my $ref (@{$self->{_ticket_price_refs}})
		{
			if($ref->{percent}<=0)
			{
				$ref->{percent} = sprintf("%.0f", $divided_percent);
			}
		}
	}
}

sub load_venue_status_entries
{
	my ($self) = @_;

	if($self->{_venue_status_entries_loaded}) { return; }
	$self->{_venue_status_entries_loaded} = 1;

	$self->load_children('Webkit::MyOffice2::VenueStatusEntry');
}

sub load_tourdates
{
	my ($self) = @_;

	if($self->{_tourdates_loaded}) { return; }
	$self->{_tourdates_loaded} = 1;

	$self->load_children('Webkit::MyOffice2::Tourdate', {
		order => 'date, time' });
}

sub load_venue
{
	my ($self, $venue) = @_;

	if($self->{_venue_loaded}) { return $self->{_venue}; }
	$self->{_venue_loaded} = 1;

	if(!$venue)
	{
		$venue = Webkit::MyOffice2::Venue->load($self->{db}, {
			id => $self->venue_id });
	}

	$self->{_venue} = $venue;
	return $venue;
}

sub construct_deal
{
	my ($self) = @_;

	my $deal = Webkit::MyOffice2::Deal->constructor($self->{db});
	$deal->org_id($self->org_id);
	$deal->tour_id($self->tour_id);
	$deal->created(Webkit::DateTime->now);
	$deal->deal($self->deal || 0);
	$deal->guarantee($self->guarantee || 0);
	$deal->ticket_price($self->ticket_price);
	$deal->tickets_on_sale($self->tickets_on_sale);
	$deal->gross_box_office($self->gross_box_office);
	$deal->notes($self->deal_notes);
	$deal->brochure_copy_deadline($self->brochure_copy_deadline);
	$deal->brochure_mailing_dates($self->brochure_mailing_dates);

	return $deal;
}

sub get_first_tourdate_epoch
{
	my ($self) = @_;

	my $tourdate = $self->get_first_tourdate;

	if(!$tourdate) { return 0; }

	return $tourdate->date->Epoch;
}

sub get_first_tourdate
{
	my ($self) = @_;

	my $arr = $self->ensure_child_array('tourdate');

	return $arr->[0];
}

sub get_first_tourdate_title
{
	my ($self) = @_;

	my $tourdate = $self->get_first_tourdate;

	if(!$tourdate) { return ''; }

	return $tourdate->get_date_title;
}

sub get_tourdatetime_titles
{
	my ($self, $delim) = @_;

	if(!$delim) { $delim = '<br>'; }

	my @parts;

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		push(@parts, $tourdate->get_datetime_title);
	}

	my $ret = join($delim, @parts);

	return $ret;
}

sub get_tourdate_titles
{
	my ($self, $delim) = @_;

	if(!$delim) { $delim = '<br>'; }

	my @parts;

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		push(@parts, $tourdate->get_date_title);
	}

	my $ret = join($delim, @parts);

	return $ret;
}

sub parse_epoch_string
{
	my ($self, $string) = @_;

	my @epochs = split(/:/, $string);

	my $dates;

	foreach my $epoch (@epochs)
	{
		my $date = Webkit::Date->new($epoch);

		push(@$dates, $date);
	}

	return $dates;
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

sub get_date_title
{
	my ($self, $field) = @_;

	return &Webkit::Date::get_string($self->get_value($field));
}

sub get_multidate_title
{
	my ($self, $field, $delim) = @_;

	if(!$delim)
	{
		$delim = ', ';
	}

	my $dates = $self->{'_'.$field.'_dates'};
	my $date_sts;

	foreach my $date (@$dates)
	{
		push(@$date_sts, $date->get_string);
	}

	if($date_sts)
	{
		return join($delim, @$date_sts);
	}
	else
	{
		return '';
	}
}

sub get_ticket_price_title
{
	my ($self) = @_;

	my $parts;

	foreach my $ref (@{$self->{_ticket_price_refs}})
	{
		my $title = $ref->{price};

		if($ref->{percent}=~/\w/)
		{
			$title .= ' @ '.$ref->{percent}.'%';
		}

		if($ref->{note}=~/\w/)
		{
			$title .= ' ('.$ref->{note}.')';
		}

		push(@$parts, $title);
	}

	if(!$parts) { return ''; }

	return join(',<br>', @$parts);
}

sub calculate_average_ticket_price
{
	my ($self) = @_;

	if($self->{_average_ticket_price_calculated}) { return $self->{_average_ticket_price}; }
	$self->{_average_ticket_price_calculated} = 1;

	my $count = 0;
	my $total = 0;

	foreach my $ref (@{$self->{_ticket_price_refs}})
	{
		my $price = $ref->{price};
		my $percent = $ref->{percent};

		$total+= ($price * $percent);
		$count++;
	}

	my $ret = 0;

	if($count>0)
	{
		$ret = sprintf("%.2f", $total/100);
	}

	$self->{_average_ticket_price} = $ret;

	return $ret;
}

sub calculate_gross
{
	my ($self, $capacity) = @_;

	if($self->gross_box_office>0)
	{
		return $self->gross_box_office;
	}

	my $ticket_price = $self->calculate_average_ticket_price;

	my $real_capacity = $self->tickets_on_sale;

	if($real_capacity<=0)
	{
		$real_capacity = $capacity;
	}

	return $ticket_price * $real_capacity;
}

sub add_date_called_entry
{
	my ($self, $date, $text) = @_;

	my @parts = split(/\+\+\+/, $self->date_called);

	push(@parts, $date.'='.$text);

	my $new_date_called = join('+++', @parts);

	$self->date_called($new_date_called);
}

sub get_last_date_called_ref
{
	my ($self) = @_;

	my @parts = split(/\+\+\+/, $self->date_called);

	my $last_note;
	my $last_date;

	foreach my $part (@parts)
	{
		my ($date, $note) = split(/=/, $part);

		$last_note = $note;
		$last_date = $date;
	}

	my $ret = {
		notes => $last_note,
		date => $last_date };

	return $ret;
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

sub deal_title
{
	my ($self) = @_;

	return $self->deal.' / '.$self->venue_deal;
}

sub venue_deal
{
	my ($self) = @_;

	return 100 - $self->deal;
}

sub venue_deal_factor
{
	my ($self) = @_;

	return $self->venue_deal/100;
}

sub deal_factor
{
	my ($self) = @_;

	return $self->deal/100;
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

sub get_venue_status_entry
{
	my ($self, $field, $construct) = @_;

	if($self->{_showing_obj})
	{
		return $self->{_showing_obj}->get_venue_status_entry($field, $construct);
	}
	else
	{
		my $ret = $self->{_venue_status_entries}->{$field};

		if((!$ret)&&($construct))
		{
			$self->{_new_venue_status_id}++;

			$ret = Webkit::MyOffice2::VenueStatusEntry->constructor($self->{db});
			$ret->{data}->{id} = $self->get_id.'.'.$self->{_new_venue_status_id};

			$ret->org_id($self->org_id);
			$ret->tour_id($self->tour_id);
			$ret->showing_id(0);
			$ret->booking_id($self->get_id);
			$ret->created(Webkit::DateTime->now);
			$ret->field($field);

			$self->{_venue_status_entries}->{$field} = $ret;
		}

		return $ret;
	}
}

sub ensure_booking_notes
{
	my ($self) = @_;

	if(!$self->{db}->in_transaction) { die "booking->ensure_booking_notes requires a transaction..."; }

	my $notes = $self->load_booking_notes;

	if(!$notes)
	{
		$notes = Webkit::MyOffice2::BookingNotes->constructor($self->{db});
		$notes->org_id($self->org_id);
		$notes->tour_id($self->tour_id);
		$notes->venue_id($self->venue_id);

		$notes->create;
	}

	return $notes;
}

sub load_booking_notes
{
	my ($self) = @_;

	my $notes = Webkit::MyOffice2::BookingNotes->load($self->{db}, {
		clause => "tour_id = ? and venue_id = ?",
		binds => [$self->tour_id, $self->venue_id] });

	return $notes;
}

1;
