package Webkit::MyOffice2::Tour;

use strict qw(vars);

@Webkit::MyOffice2::Tour::ISA = qw(Webkit::DBObject);

my $schema = {        	org_id => {	type => 'id',
					required => 1 },

			name => {	required => 1,
					type => 'string' },

                	country_id => {	required => 1,
                                        type => 'id' },

                	type => {	type => 'string',
					required => 1 },

			combined_ids => {	type => 'string' },

			default_mode => {	type => 'string',
						required => 1 } };

my $type_options = [	{	title => 'Normal Tour',
				key => 'normal' },
			{	title => 'Combined Tour',
				key => 'combined' }];

my $types;

foreach my $option (@$type_options)
{
	$types->{$option->{key}} = $option;
}

sub table
{
        return 'myoffice2.tour';
}

sub schema
{
        return $schema;
}

##########################################
#
#
#
# MAIN METHODS
#
#
#
##########################################

sub constructor
{
	my ($classname, $db) = @_;

	my $ret = &Webkit::DBObject::constructor($classname, $db);

	$ret->default_mode('n');

	return $ret;
}

sub assign_data
{
	my ($self, $data) = @_;

	$self->SUPER::assign_data($data);

	my @tour_ids = split(/:/, $self->combined_ids);

	foreach my $tour_id (@tour_ids)
	{
		$self->{_tour_ids}->{$tour_id} = 1;
	}

	$self->{_tour_id_array} = \@tour_ids;
}

sub save_form_params
{
	my ($self, $params) = @_;

	$self->name($params->{name});
	$self->type($params->{type});

	if($self->is_normal)
	{
		$self->country_id($params->{country_id});
		$self->combined_ids('');
	}
	else
	{
		$self->country_id(0);
		my $ids = [];

		foreach my $key (keys %$params)
		{
			if($key=~/^tour_(\d+)$/)
			{
				push(@$ids, $1);
			}
		}

		my $id_string = join(':', @$ids);

		$self->combined_ids($id_string);
	}
}

sub get_children_clause
{
	my ($self, $original_clause, $table_match, $include_self) = @_;

	if($table_match=~/\w/) { $table_match .= '.'; }

	my $clause;

	if($self->is_all_tours)
	{
		$clause = $table_match.'org_id = '.$self->org_id;
	}
	elsif($self->is_normal)
	{
		$clause = $table_match.$self->single_table.'_id = '.$self->get_id;
	}
	else
	{
		my $clause_parts;

		my $ids = $self->get_tour_id_array;

		if($include_self)
		{
			push(@$ids, $self->get_id);
		}

		foreach my $id (@$ids)
		{
			push(@$clause_parts, "\t".$table_match.$self->single_table.'_id = '.$id);
		}

		$clause = join("\n or \n", @$clause_parts);
	}

	$clause = "\n(\n".$clause."\n)\n";

	if($original_clause=~/\w/)
	{
		$clause = $clause."and \n(\n".$original_clause."\n)\n";
	}

	return $clause;
}

sub load_children
{
	my ($self, $childclass, $attr) = @_;

	$attr->{table} = &{$childclass.'::table'};

	$attr->{clause} = $self->get_children_clause($attr->{clause}, '', $attr->{include_self});

	return &Webkit::DBObject::load_objects($childclass, $self->{db}, $attr, $self);
}

sub load_child_tours
{
	my ($self) = @_;

	if($self->{_child_tours_loaded}) { return; }
	$self->{_child_tours_loaded} = 1;

	if($self->is_all_tours)
	{
		$self->add_children('Webkit::MyOffice::Tour', {
			table => 'myoffice2.tour',
			cols => 'tour.*',
			order => 'name' });
	}
	elsif($self->is_combined)
	{
		my $clause_parts;
		my $binds;

		foreach my $id (@{$self->get_tour_id_array})
		{
			push(@$clause_parts, ' id = ? ');
			push(@$binds, $id);
		}

		my $clause = join(' or ', @$clause_parts);

		$self->add_children('Webkit::MyOffice2::Tour', {
			table => 'myoffice2.tour',
			cols => 'tour.*',
			clause => $clause,
			binds => $binds,
			order => 'name' });
	}
}

##########################################
#
#
#
# PROPS
#
#
#
##########################################

sub get_tour_id_array
{
	my ($self) = @_;

	return $self->{_tour_id_array};
}

sub contains_tour
{
	my ($self, $tour_id) = @_;

	return $self->{_tour_ids}->{$tour_id};
}

sub is_combined
{
	my ($self) = @_;

	if($self->type eq 'combined') { return 1; }
	else { return undef; }
}

sub is_all_tours
{
	my ($self) = @_;

	if($self->combined_ids eq 'all') { return 1; }
	else { return undef; }
}

sub is_normal
{
	my ($self) = @_;

	if($self->type eq 'normal') { return 1; }
	else { return undef; }
}

sub is_default
{
	my ($self) = @_;

	if($self->default_mode eq 'y') { return 1; }
	else { return undef; }
}

sub get_type_options
{
	my ($self) = @_;

	return Webkit::AppTools->get_select_options($type_options, {
		key_field => 'key',
		value_field => 'title',
		selected => $self->type });
}

sub get_type_title
{
	my ($self) = @_;

	my $option = $types->{$self->type};

	return $option->{title};
}


####Homepage

sub load_homepage_confirmed_objects
{
	my ($self) = @_;

	my $booking_clause=<<"+++";
penciled IS NOT NULL
and agreed IS NOT NULL
+++

	my $showing_clause=<<"+++";
$booking_clause
and showing.booking_id = booking.id
+++

	my $tourdate_clause=<<"+++";
$booking_clause
and tourdate.booking_id = booking.id
+++

	$self->add_children('Webkit::MyOffice2::Booking', {
		table => 'myoffice2.booking',
		cols => 'booking.*',
		clause => $self->get_children_clause($booking_clause, 'booking'),
		order => 'booking.agreed DESC',
		group => 'booking.id',
		limit => 10 });

	$self->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.booking, myoffice2.showing',
		cols => 'showing.*',
		clause => $self->get_children_clause($showing_clause, 'showing'),
		order => 'booking.agreed DESC',
		group => 'showing.id' });

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.venue',
		cols => 'venue.*',
		group => 'venue.id' });

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.booking, myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($tourdate_clause, 'tourdate'),
		order => 'booking.created DESC',
		group => 'tourdate.id'});

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $booking = $self->get_child('booking', $tourdate->booking_id);

		if(!$booking) { next; }

		$booking->add_child($tourdate);
	}

	foreach my $showing (@{$self->ensure_child_array('showing')})
	{
		my $booking = $self->get_child('booking', $showing->booking_id);

		if(!$booking) { next; }

		$booking->{_showing} = $showing;
	}
}

sub load_homepage_objects
{
	my ($self) = @_;

	my $booking_clause=<<"+++";
penciled IS NOT NULL
and agreed IS NULL
+++

	my $tourdate_clause=<<"+++";
$booking_clause
and tourdate.booking_id = booking.id
+++

	$self->add_children('Webkit::MyOffice2::Booking', {
		table => 'myoffice2.booking',
		cols => 'booking.*',
		clause => $self->get_children_clause($booking_clause, 'booking'),
		order => 'booking.penciled DESC',
		group => 'booking.id',
		limit => 10 });

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.venue',
		cols => 'venue.*',
		group => 'venue.id' });

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.booking, myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($tourdate_clause, 'tourdate'),
		order => 'booking.created DESC',
		group => 'tourdate.id'});

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $booking = $self->get_child('booking', $tourdate->booking_id);

		if(!$booking) { next; }

		$booking->add_child($tourdate);
	}
}

##########################################
#
#
#
# VENUE
#
#
#
##########################################

sub count_venues
{
	my ($self) = @_;

	if($self->{_venues_counted}) { return $self->{_venue_count}; }
	$self->{_venues_counted} = 1;

	my $clause = $self->get_children_clause;

	my $ref = $self->{db}->get_select_ref({
		table => 'myoffice2.venue',
		cols => 'count(*) as count',
		clause => $clause });

	$self->{_venue_count} = $ref->{count};

	return $self->{_venue_count};
}

sub load_all_venues
{
	my ($self) = @_;

	if($self->{_venues_loaded}) { return; }

	$self->{_venues_loaded} = 1;

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.venue',
		cols => 'venue.*',
		order => 'city, name' });
}

sub load_venues
{
	my ($self, $params) = @_;

	if($self->{_venues_loaded}) { return; }

	$self->{_venues_loaded} = 1;

	my $clause = '';
	my $binds;

	if($params->{search}=~/\w/)
	{
		my $search = $params->{search};

		if($search=~/\%/)
		{
			$clause=<<"+++";
city like ?
+++

			$binds = [$search];
		}
		else
		{
			$search = '%'.$search.'%';

			$clause=<<"+++";
name like ?
or city like ?
+++

			$binds = [$search, $search];
		}
	}
	elsif($params->{start_letter}=~/\w/)
	{
		my $start = $params->{start_letter};
		my $end = $params->{end_letter};

		$clause=<<"+++";
LOWER(SUBSTRING(city, 1, 1)) >= ?
and LOWER(SUBSTRING(city, 1, 1)) <= ?
+++

		$binds = [$start, $end];
	}

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.venue',
		cols => 'venue.*',
		clause => $clause,
		binds => $binds,
		order => 'city, name' });
}



##########################################
#
#
#
# COUNTRY
#
#
#
##########################################

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

sub load_country
{
	my ($self, $country) = @_;

	if($self->{_country_loaded}) { return $self->{_country}; }
	$self->{_country_loaded} = 1;

	if($country)
	{
		$self->{_country} = $country;
	}
	elsif($self->country_id>0)
	{
		$self->{_country} = Webkit::MyOffice2::Country->load($self->{db}, {
			id => $self->country_id });
	}

	return $self->{_country};
}

sub get_country_options
{
	my ($self) = @_;

	$self->load_countries;

	my $selected = $self->country_id;

	if($selected!~/\w/)
	{
		$selected = 1;
	}

	return Webkit::AppTools->get_object_select_options($self->ensure_child_array('country'), {
		value_field => 'name',
		selected => $selected });	
}

sub get_country_name
{
	my ($self) = @_;

	$self->load_country;

	my $name = '';

	if($self->{_country})
	{
		$name = $self->{_country}->name;
	}

	return $name;
}

##########################################
#
#
#
# TIMELINE
#
#
#
##########################################

sub load_modal_timeline_not_booked_objects
{
	my ($self, $params) = @_;

	if($self->{_modal_timeline_not_booked_loaded}) { return; }
	$self->{_modal_timeline_not_booked_loaded} = 1;

	my $from_date = Webkit::Date->from_calendar($params->{from});
	my $to_date = Webkit::Date->from_calendar($params->{to});

	$self->{_timeline_from_date} = $from_date;
	$self->{_timeline_to_date} = $to_date;

	my $from_sql_date = Webkit::Date->parse_to_sql($from_date);
	my $to_sql_date = Webkit::Date->parse_to_sql($to_date);

	my $clause=<<"+++";
tourdate.booking_id = booking.id
and booking.failed IS NULL
and tourdate.date >= ?
and tourdate.date <= ?
+++

	my $binds = [$from_sql_date, $to_sql_date];

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.tourdate, myoffice2.booking',
		cols => 'tourdate.*, booking.venue_id as venue_id',
		clause => $self->get_children_clause($clause, 'tourdate'),
		binds => $binds,
		group => 'tourdate.id',
		order => 'date, time' });

	$self->load_all_venues;

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $venue = $self->get_child('venue', $tourdate->{data}->{venue_id});

		$venue->{_is_booked} = 1;
	}

	foreach my $venue (@{$self->ensure_child_array('venue')})
	{
		if(!$venue->{_is_booked})
		{
			push(@{$self->{_not_booked_venues}}, $venue);
		}
	}
}

sub load_modal_timeline_booked_objects
{
	my ($self, $params) = @_;

	if($self->{_modal_timeline_booked_loaded}) { return; }
	$self->{_modal_timeline_booked_loaded} = 1;

	my $from_date = Webkit::Date->from_calendar($params->{from});
	my $to_date = Webkit::Date->from_calendar($params->{to});

	$self->{_timeline_from_date} = $from_date;
	$self->{_timeline_to_date} = $to_date;

	my $from_sql_date = Webkit::Date->parse_to_sql($from_date);
	my $to_sql_date = Webkit::Date->parse_to_sql($to_date);

	my $clause=<<"+++";
tourdate.booking_id = booking.id
and booking.failed IS NULL
and booking.penciled IS NOT NULL
and tourdate.date >= ?
and tourdate.date <= ?
+++

	my $binds = [$from_sql_date, $to_sql_date];

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.tourdate, myoffice2.booking',
		cols => 'tourdate.*, booking.venue_id as venue_id',
		clause => $self->get_children_clause($clause, 'tourdate'),
		binds => $binds,
		group => 'tourdate.id',
		order => 'date, time' });

	my $venue_clause=<<"+++";
tourdate.venue_id = venue.id
and $clause
+++

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.tourdate, myoffice2.venue, myoffice2.booking',
		cols => 'venue.*',
		clause => $self->get_children_clause($clause, 'tourdate'),
		binds => $binds,
		group => 'venue.id' });

	if($params->{load_with_bookings})
	{
		$self->add_children('Webkit::MyOffice2::Booking', {
			table => 'myoffice2.tourdate, myoffice2.venue, myoffice2.booking',
			cols => 'booking.*',
			clause => $self->get_children_clause($clause, 'tourdate'),
			binds => $binds,
			group => 'booking.id' });
	}

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		push(@{$self->{_timeline_map}->{$tourdate->date->epoch_days}}, $tourdate);
	}
}



##########################################
#
#
#
# TOURLIST
#
#
#
##########################################

sub load_tourlist_objects
{
	my ($self, $params) = @_;

	if($self->{_tourlist_loaded}) { return; }
	$self->{_tourlist_loaded} = 1;

	my $from_date = Webkit::Date->from_calendar($params->{from});
	my $to_date = Webkit::Date->from_calendar($params->{to});
	my $from_sql_date = Webkit::Date->parse_to_sql($from_date);
	my $to_sql_date = Webkit::Date->parse_to_sql($to_date);

	$self->{_tourlist_from_date} = $from_date;
	$self->{_tourlist_to_date} = $to_date;

	my $clause=<<"+++";
tourdate.booking_id = booking.id
and tourdate.date >= ?
and tourdate.date <= ?
+++

	my $binds = [$from_sql_date, $to_sql_date];

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.tourdate, myoffice2.booking',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($clause, 'tourdate'),
		binds => $binds,
		group => 'tourdate.id' });
	
	$self->add_children('Webkit::MyOffice2::Booking', {
		table => 'myoffice2.tourdate, myoffice2.booking',
		cols => 'booking.*',
		clause => $self->get_children_clause($clause, 'tourdate'),
		binds => $binds,
		group => 'booking.id' });

	my $showing_clause=<<"+++";
tourdate.showing_id = showing.id
and $clause
+++

	$self->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.tourdate, myoffice2.booking, myoffice2.showing',
		cols => 'showing.*',
		clause => $self->get_children_clause($showing_clause, 'tourdate'),
		binds => $binds,
		group => 'showing.id' });

	my $venue_clause=<<"+++";
booking.venue_id = venue.id
and $clause
+++

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.tourdate, myoffice2.booking, myoffice2.venue',
		cols => 'venue.*',
		clause => $self->get_children_clause($venue_clause, 'tourdate'),
		binds => $binds,
		group => 'venue.id' });

	my $deal_clause=<<"+++";
showing.deal_id = deal.id
and $showing_clause
+++

	$self->add_children('Webkit::MyOffice2::Deal', {
		table => 'myoffice2.tourdate, myoffice2.booking, myoffice2.showing, myoffice2.deal',
		cols => 'deal.*',
		clause => $self->get_children_clause($deal_clause, 'tourdate'),
		binds => $binds,
		group => 'deal.id' });

	my $print_clause=<<"+++";
print_req.showing_id = showing.id
and $showing_clause
+++

	$self->add_children('Webkit::MyOffice2::Print', {
		table => 'myoffice2.tourdate, myoffice2.booking, myoffice2.showing, myoffice2.print_req',
		cols => 'print_req.*',
		clause => $self->get_children_clause($print_clause, 'tourdate'),
		binds => $binds,
		group => 'print_req.id' });

	my $st = '';

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		push(@{$self->{_tourlist_map}->{$tourdate->date->epoch_days}}, $tourdate);
	}

	foreach my $print_req (@{$self->ensure_child_array('print_req')})
	{
		my $showing = $self->get_child('showing', $print_req->showing_id);

		$showing->add_child($print_req);
	}
}

sub load_website_push_objects
{
	my ($self, $params) = @_;

	if($self->{_website_push_loaded}) { return; }
	$self->{_website_push_loaded} = 1;

	if($params->{from}!~/\w/)
	{
		$params->{from} = '01/01/2000';
	}
	
	if($params->{to}!~/\w/)
	{
		$params->{to} = '01/01/2020';
	}
	
	my $from_date = Webkit::Date->from_calendar($params->{from});
	my $to_date = Webkit::Date->from_calendar($params->{to});
	my $from_sql_date = Webkit::Date->parse_to_sql($from_date);
	my $to_sql_date = Webkit::Date->parse_to_sql($to_date);

	#$self->{_tourlist_from_date} = $from_date;
	#$self->{_tourlist_to_date} = $to_date;

	my $clause=<<"+++";
tourdate.showing_id = showing.id
and tourdate.date >= ?
and tourdate.date <= ?
+++

	my $binds = [$from_sql_date, $to_sql_date];

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.tourdate, myoffice2.showing',
		cols => 'tourdate.*',
		#clause => $self->get_children_clause($clause, 'tourdate'),
		clause => $clause,
		binds => $binds,
		order => 'tourdate.date, tourdate.time',
		group => 'tourdate.id' });
		
	$self->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.tourdate, myoffice2.showing',
		cols => 'showing.*',
		#clause => $self->get_children_clause($clause, 'tourdate'),
		clause => $clause,
		binds => $binds,
		group => 'showing.id' });		
	
#	$self->add_children('Webkit::MyOffice2::Booking', {
#		table => 'myoffice2.tourdate, myoffice2.booking',
#		cols => 'booking.*',
#		clause => #$self->get_children_clause($clause, 'tourdate'),
#		clause => $clause,
#		binds => $binds,
#		group => 'booking.id' });

#	my $showing_clause=<<"+++";
#tourdate.showing_id = showing.id
#and $clause
#+++

#	$self->add_children('Webkit::MyOffice2::Showing', {
#		table => 'myoffice2.tourdate, myoffice2.booking, myoffice2.showing',
#		cols => 'showing.*',
#		#clause => $self->get_children_clause($showing_clause, 'tourdate'),
#		clause => $showing_clause,
#		binds => $binds,
#		group => 'showing.id' });

	my $venue_clause=<<"+++";
showing.venue_id = venue.id
and $clause
+++

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.tourdate, myoffice2.showing, myoffice2.venue',
		cols => 'venue.*',
		#clause => $self->get_children_clause($venue_clause, 'tourdate'),
		clause => $venue_clause,
		binds => $binds,
		group => 'venue.id' });

#	my $deal_clause=<<"+++";
#showing.deal_id = deal.id
#and $showing_clause
#+++

#	$self->add_children('Webkit::MyOffice2::Deal', {
#		table => 'myoffice2.tourdate, myoffice2.booking, myoffice2.showing, myoffice2.deal',
#		cols => 'deal.*',
#		#clause => $self->get_children_clause($deal_clause, 'tourdate'),
#		clause => $deal_clause,
#		binds => $binds,
#		group => 'deal.id' });
}

##########################################
#
#
#
# BOOKING
#
#
#
##########################################

sub load_booking_progress_objects
{
	my ($self, $params) = @_;

	if($self->{_booking_progress_tree_loaded}) { return; }
	$self->{_booking_progress_tree_loaded} = 1;

	my $clause="";

	my $binds;

	if($params->{filter} eq 'failed')
	{
		$clause.=<<"+++";
booking.failed IS NOT NULL
+++
	}
	elsif($params->{filter} eq 'penciled')
	{
		$clause.=<<"+++";
booking.penciled IS NOT NULL
and booking.agreed IS NULL
and booking.failed IS NULL
+++
	}
	elsif($params->{filter} eq 'all')
	{
		$clause.=<<"+++";
booking.agreed IS NULL
+++
	}
	else
	{
		$clause.=<<"+++";
booking.failed IS NULL
and booking.agreed IS NULL
+++
	}

	if($params->{venue_id}>0)
	{
		$clause.=<<"+++";
and booking.venue_id = ?
+++

		push(@$binds, $params->{venue_id});
	}

	if($params->{booking_id}>0)
	{
		$clause.=<<"+++";
and booking.id = ?
+++

		push(@$binds, $params->{booking_id});
	}

	my $venue_clause=<<"+++";
booking.venue_id = venue.id
and $clause
+++

	my $tourdate_clause=<<"+++";
tourdate.booking_id = booking.id
and $clause
+++

	my $booking_notes_clause=<<"+++";
booking_notes.venue_id = booking.venue_id
and booking_notes.tour_id = booking.tour_id
and $clause
+++

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.booking, myoffice2.venue',
		cols => 'venue.*',
		clause => $self->get_children_clause($venue_clause, 'booking'),
		binds => $binds,
		group => 'venue.id',
		order => 'city, name' });

	$self->add_children('Webkit::MyOffice2::Booking', {
		table => 'myoffice2.booking',
		cols => 'booking.*',
		clause => $self->get_children_clause($clause, 'booking'),
		binds => $binds,
		order => 'created DESC',
		group => 'booking.id' });

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.booking, myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($tourdate_clause, 'booking'),
		binds => $binds,
		order => 'date, time',
		group => 'tourdate.id' });

	$self->add_children('Webkit::MyOffice2::BookingNotes', {
		table => 'myoffice2.booking_notes, myoffice2.booking',
		cols => 'booking_notes.*',
		clause => $self->get_children_clause($booking_notes_clause, 'booking_notes'),
		binds => $binds,
		group => 'booking_notes.id' });

	foreach my $note (@{$self->ensure_child_array('booking_notes')})
	{
		$self->{_booking_notes}->{$note->venue_id}->{$note->tour_id} = $note;
	}

	foreach my $booking (@{$self->ensure_child_array('booking')})
	{
		my $venue = $self->get_child('venue', $booking->venue_id);

		if(!$venue) { next; }

		$venue->add_child($booking);

		my $note = $self->{_booking_notes}->{$booking->venue_id}->{$booking->tour_id};

		if($note)
		{
			$booking->{data}->{booking_note} = $note->notes;
		}
	}

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $booking = $self->get_child('booking', $tourdate->booking_id);

		if(!$booking) { next; }

		$booking->add_child($tourdate);
	}
}



sub load_booking_penciled_objects
{
	my ($self, $params) = @_;

	if($self->{_booking_penciled_tree_loaded}) { return; }
	$self->{_booking_penciled_tree_loaded} = 1;

	my $clause;
	my $binds;

	$clause=<<"+++";
booking.failed IS NULL
and booking.agreed IS NULL
and booking.penciled IS not NULL
+++

	if($params->{venue_id}>0)
	{
		$clause.=<<"+++";
and booking.venue_id = ?
+++

		push(@$binds, $params->{venue_id});
	}

	if($params->{booking_id}>0)
	{
		$clause.=<<"+++";
and booking.id = ?
+++

		push(@$binds, $params->{booking_id});
	}

	my $venue_clause=<<"+++";
booking.venue_id = venue.id
and $clause
+++

	my $tourdate_clause=<<"+++";
tourdate.booking_id = booking.id
and $clause
+++

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.booking, myoffice2.venue',
		cols => 'venue.*',
		clause => $self->get_children_clause($venue_clause, 'booking'),
		binds => $binds,
		group => 'venue.id',
		order => 'city, name' });

	$self->add_children('Webkit::MyOffice2::Booking', {
		table => 'myoffice2.booking',
		cols => 'booking.*',
		clause => $self->get_children_clause($clause, 'booking'),
		binds => $binds,
		order => 'created DESC',
		group => 'booking.id' });

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.booking,  myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($tourdate_clause, 'booking'),
		binds => $binds,
		order => 'date, time',
		group => 'tourdate.id' });

	foreach my $booking (@{$self->ensure_child_array('booking')})
	{
		my $venue = $self->get_child('venue', $booking->venue_id);

		if(!$venue) { next; }

		$venue->add_child($booking);
	}

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $booking = $self->get_child('booking', $tourdate->booking_id);

		if(!$booking) { next; }

		$booking->add_child($tourdate);
	}
}

##########################################
#
#
#
# PRINT
#
#
#
##########################################

sub load_print_runs
{
	my ($self) = @_;

	if($self->{_print_runs_loaded}) { return; }
	$self->{_print_runs_loaded} = 1;

	$self->load_children('Webkit::MyOffice2::PrintRun', {
		include_self => 1,
		order => 'start_date DESC' });
}

sub load_print_runs_with_req_count
{
	my ($self) = @_;

	if($self->{_print_runs_with_req_count_loaded}) { return; }
	$self->{_print_runs_with_req_count_loaded} = 1;

	my $clause=<<"+++";
print_req.print_run_id = print_run.id
+++

	$self->add_children('Webkit::MyOffice2::PrintRun', {
		table => 'myoffice2.print_run, myoffice2.print_req',
		cols => 'print_run.*, count(*) as print_req_count',
		clause => $self->get_children_clause($clause, 'print_run', 1),
		order => 'start_date DESC',
		group => 'print_run.id' });
}

sub load_print_run_objects
{
	my ($self, $print_run) = @_;

	if(!$print_run) { return; }

	$print_run->load_print_reqs;

	my $showing_clause=<<"+++";
print_req.print_run_id = ?
and print_req.showing_id = showing.id
+++

	$print_run->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.print_req, myoffice2.showing',
		cols => 'showing.*',
		clause => $showing_clause,
		binds => [$print_run->get_id],
		group => 'showing.id' });

	my $venue_clause=<<"+++";
$showing_clause
and showing.venue_id = venue.id
+++

	$print_run->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.print_req, myoffice2.showing, myoffice2.venue',
		cols => 'venue.*',
		clause => $venue_clause,
		binds => [$print_run->get_id],
		group => 'venue.id' });

	my $tourdate_clause=<<"+++";
$showing_clause
and tourdate.showing_id = showing.id
+++

	$print_run->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.print_req, myoffice2.showing, myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $tourdate_clause,
		binds => [$print_run->get_id],
		order => 'date, time',
		group => 'tourdate.id' });

	foreach my $tourdate (@{$print_run->ensure_child_array('tourdate')})
	{
		my $showing = $print_run->get_child('showing', $tourdate->showing_id);

		$showing->add_child($tourdate);
	}

	foreach my $print_req (@{$print_run->ensure_child_array('print_req')})
	{
		if($print_req->showing_id==0)
		{
			$print_run->{_central_print_req} = $print_req;
		}
		else
		{
			my $showing = $print_run->get_child('showing', $print_req->showing_id);

			$showing->{_print_req_obj} = $print_req;
		}
	}

	foreach my $showing (@{$print_run->ensure_child_array('showing')})
	{
		my $venue = $print_run->get_child('venue', $showing->venue_id);

		$showing->{_venue_obj} = $venue;
		$showing->{_venue_title} = $venue->get_city_title;
	}

	my $arr = $print_run->ensure_child_array('showing');

	@$arr = sort { $a->{_venue_title} cmp $b->{_venue_title} } @$arr;

	$print_run->{showing_array} = $arr;
}

sub load_print_not_assigned_objectsOLD
{
	my ($self) = @_;

	if($self->{_print_not_assigned_loaded}) { return; }
	$self->{_print_not_assigned_loaded} = 1;

	my $clause=<<"+++";
tourdate.showing_id = showing.id
and print_req.showing_id = showing.id
and print_req.print_run_id IS NULL
+++

	$self->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.tourdate, myoffice2.showing, myoffice2.print_req',
		cols => 'showing.*, print_req.id as print_req_id',
		clause => $self->get_children_clause($clause, 'showing'),
		order => 'tourdate.date DESC, tourdate.time DESC',
		group => 'showing.id' });

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.showing, myoffice2.print_req, myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($clause, 'showing'),
		order => 'tourdate.date DESC, tourdate.time DESC',
		group => 'tourdate.id' });

	my $venue_clause=<<"+++";
print_req.showing_id = showing.id
and showing.venue_id = venue.id
and print_req.print_run_id IS NULL
+++

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.showing, myoffice2.print_req, myoffice2.venue',
		cols => 'venue.*',
		clause => $self->get_children_clause($venue_clause, 'showing'),
		group => 'venue.id' });
	
	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $showing = $self->get_child('showing', $tourdate->showing_id);

		$showing->add_child($tourdate);
	}
}

sub load_print_not_assigned_objects
{
	my ($self) = @_;

	if($self->{_print_not_assigned_loaded}) { return; }
	$self->{_print_not_assigned_loaded} = 1;

	my $clause=<<"+++";
tourdate.showing_id = showing.id
and print_req.id IS NULL
and YEAR(tourdate.date) >= 2011
+++

	$self->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.tourdate, myoffice2.showing LEFT JOIN myoffice2.print_req on print_req.showing_id = showing.id',
		cols => 'showing.*, print_req.id as print_req_id',
		clause => $self->get_children_clause($clause, 'showing'),
		order => 'tourdate.date DESC, tourdate.time DESC',
		group => 'showing.id' });

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.tourdate, myoffice2.showing LEFT JOIN myoffice2.print_req on print_req.showing_id = showing.id',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($clause, 'showing'),
		order => 'tourdate.date DESC, tourdate.time DESC',
		group => 'tourdate.id' });

	my $venue_clause=<<"+++";
showing.venue_id = venue.id
and print_req.id IS NULL
+++

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.showing, myoffice2.venue LEFT JOIN myoffice2.print_req on print_req.showing_id = showing.id',
		cols => 'venue.*',
		clause => $self->get_children_clause($venue_clause, 'showing'),
		group => 'venue.id' });
	
	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $showing = $self->get_child('showing', $tourdate->showing_id);

		$showing->add_child($tourdate);
	}
}

##########################################
#
#
#
# STAFF
#
#
#
##########################################

sub get_staff_hash
{
	my ($self) = @_;

	if($self->{_staff_hash_loaded}) { return $self->{_staff_hash}; }
	$self->{_staff_hash_loaded} = 1;

	$self->load_staff;

	my $hash;

	foreach my $user (@{$self->ensure_child_array('users')})
	{
		$hash->{$user->get_id} = $user->get_fullname;
	}

	$self->{_staff_hash} = $hash;

	return $self->{_staff_hash};
}

sub load_staff
{
	my ($self) = @_;

	if($self->{_users_loaded}) { return; }
	$self->{_users_loaded} = 1;

	my $clause=<<"+++";
org_id = ?
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
		binds => [$self->org_id, 'event_manager', 'compere', 'projectionist'],
		order => 'firstname, surname' });
}

##########################################
#
#
#
# SALES FIGURES
#
#
#
##########################################

sub get_month_boundary_date
{
	my ($self, $date) = @_;

	my $copy = $date->clone;

	while($copy->WeekDay!=1)
	{
		$copy->epoch_days(-1);
	}

	return $copy;
}

sub parse_sales_figures_dates
{
	my ($self, $params) = @_;

	if($params->{lookahead}!~/\d/)
	{
		$params->{lookahead} = 8;
	}

	if($params->{month}!~/\w/) 
	{
		my $now = Webkit::Date->now;

		$params->{month} = $now->Month;
		$params->{year} = $now->Year;
	}

	my $month = $params->{month};
	my $year = $params->{year};

	my $start_date = Webkit::Date->now;

	$start_date->Month($month);
	$start_date->Year($year);
	$start_date->Day(1);

	my $next_month = $month + 1;
	my $next_year = $year;

	if($next_month>12)
	{
		$next_month = 1;
		$next_year++;
	}

	my $end_date = $start_date->clone;
	$end_date->Month($next_month);
	$end_date->Year($next_year);
	$end_date->Day(1);

	my $boundary_start_date = $self->get_month_boundary_date($start_date);
	my $boundary_end_date = $self->get_month_boundary_date($end_date);

	$self->{sheet_start_date} = $boundary_start_date;
	$self->{sheet_end_date} = $boundary_end_date;

	my $lookahead_date = $boundary_start_date->clone;
	$lookahead_date->epoch_days($params->{lookahead} * 7);

	my $sql_start = Webkit::Date->parse_to_sql($boundary_start_date);
	my $sql_end = Webkit::Date->parse_to_sql($lookahead_date);

	$self->{sheet_sql_start} = $sql_start;
	$self->{sheet_sql_end} = $sql_end;	

	my $week_date = $self->{sheet_start_date}->clone;

	while($week_date->epoch_days<=$self->{sheet_end_date}->epoch_days)
	{
		push(@{$self->{_week_dates}}, $week_date->clone);

		$week_date->epoch_days(7);
	}
}

sub load_sales_figures_objects
{
	my ($self, $params) = @_;

	$self->parse_sales_figures_dates($params);

	my $sql_start = $self->{sheet_sql_start};
	my $sql_end = $self->{sheet_sql_end};

	my $tourdate_clause=<<"+++";
tourdate.showing_id > 0
and tourdate.date >= ?
and tourdate.date <= ?
+++

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($tourdate_clause, 'tourdate'),
		binds => [$sql_start, $sql_end],
		group => 'tourdate.id',
		order => 'date, time' });

	my $figures_clause=<<"+++";
$tourdate_clause
and sales_figures.tourdate_id = tourdate.id
+++

	$self->add_children('Webkit::MyOffice2::SalesFigures', {
		table => 'myoffice2.tourdate, myoffice2.sales_figures',
		cols => 'sales_figures.*',
		clause => $self->get_children_clause($figures_clause, 'tourdate'),
		binds => [$sql_start, $sql_end],
		order => 'sales_figures.week_start',
		group => 'sales_figures.id' });

	my $figures_entry_clause=<<"+++";
$tourdate_clause
and sales_figures_entry.tourdate_id = tourdate.id
+++

	$self->add_children('Webkit::MyOffice2::SalesFiguresEntry', {
		table => 'myoffice2.tourdate, myoffice2.sales_figures_entry',
		cols => 'sales_figures_entry.*',
		clause => $self->get_children_clause($figures_entry_clause, 'tourdate'),
		binds => [$sql_start, $sql_end],
		group => 'sales_figures_entry.id' });

	my $showing_clause=<<"+++";
$tourdate_clause
and tourdate.showing_id = showing.id
+++

	$self->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.tourdate, myoffice2.showing',
		cols => 'showing.*',
		clause => $self->get_children_clause($showing_clause, 'tourdate'),
		binds => [$sql_start, $sql_end],
		group => 'showing.id' });

	my $booking_clause=<<"+++";
$showing_clause
and showing.booking_id = booking.id
+++

	$self->add_children('Webkit::MyOffice2::Booking', {
		table => 'myoffice2.tourdate, myoffice2.showing, myoffice2.booking',
		cols => 'booking.*',
		clause => $self->get_children_clause($booking_clause, 'tourdate'),
		binds => [$sql_start, $sql_end],
		group => 'booking.id' });

	my $deal_clause=<<"+++";
$showing_clause
and showing.deal_id = deal.id
+++

	$self->add_children('Webkit::MyOffice2::Deal', {
		table => 'myoffice2.tourdate, myoffice2.showing, myoffice2.deal',
		cols => 'deal.*',
		clause => $self->get_children_clause($deal_clause, 'tourdate'),
		binds => [$sql_start, $sql_end],
		group => 'deal.id' });

	my $venue_clause=<<"+++";
$showing_clause
and showing.venue_id = venue.id
+++

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.tourdate, myoffice2.showing, myoffice2.venue',
		cols => 'venue.*',
		clause => $self->get_children_clause($venue_clause, 'tourdate'),
		binds => [$sql_start, $sql_end],
		group => 'venue.id' });

	my $venue_status_clause=<<"+++";
$showing_clause
and venue_status_entry.showing_id = showing.id
and venue_status_entry.field = ?
+++

	$self->add_children('Webkit::MyOffice2::VenueStatusEntry', {
		table => 'myoffice2.tourdate, myoffice2.showing, myoffice2.venue_status_entry',
		cols => 'venue_status_entry.*',
		clause => $self->get_children_clause($venue_status_clause, 'tourdate'),
		binds => [$sql_start, $sql_end, 'som_target'],
		group => 'venue_status_entry.id' });

	foreach my $entry (@{$self->ensure_child_array('venue_status_entry')})
	{
		my $showing = $self->get_child('showing', $entry->showing_id);

		$showing->{_som_target} = $entry->value;
	}

	foreach my $entry (@{$self->ensure_child_array('sales_figures_entry')})
	{
		my $tourdate = $self->get_child('tourdate', $entry->tourdate_id);
		my $showing = $self->get_child('showing', $tourdate->showing_id);
		my $venue = $self->get_child('venue', $showing->venue_id);
		my $deal = $self->get_child('deal', $showing->deal_id);

		if(!$deal->tickets_on_sale>0)
		{
			$deal->tickets_on_sale($venue->capacity);
		}

		$tourdate->sales_figures_entry($entry);
	}

	foreach my $figures (@{$self->ensure_child_array('sales_figures')})
	{
		my $entry = $self->get_child('sales_figures_entry', $figures->sales_figures_entry_id);
		my $tourdate = $self->get_child('tourdate', $figures->tourdate_id);

		$entry->add_sales_figures($figures);
	}

	$self->{_new_figures_id} = 1;

	my $include_figures_start = $self->{sheet_start_date}->clone;
	$include_figures_start->epoch_days(-7);

	my @include_week_dates = ($include_figures_start, @{$self->{_week_dates}});

	$self->{_include_week_dates} = \@include_week_dates;

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $entry = $tourdate->sales_figures_entry;
		my $showing = $self->get_child('showing', $tourdate->showing_id);
		my $venue = $self->get_child('venue', $showing->venue_id);

		my $venue_title = $venue->get_city_title;
		my $showing_title = $tourdate->get_datetime_title;

		foreach my $weekdate (@{$self->get_sales_figures_include_date_array})
		{
			my $week_epoch_days = $weekdate->epoch_days;

			my $figs = $entry->get_sales_figures($week_epoch_days);

			if(!$figs)
			{
				$figs = $entry->construct_sales_figures($self->{_new_figures_id}, $week_epoch_days, $tourdate);
				$self->{_new_figures_id}++;
			}
		}
	}
}

sub get_sales_figures_include_date_array
{
	my ($self) = @_;

	return $self->{_include_week_dates};
}

sub get_sales_figures_date_array
{
	my ($self) = @_;

	return $self->{_week_dates};
}

##########################################
#
#
#
# Booking Report
#
#
#
##########################################

sub load_booking_report
{
	my ($self, $params) = @_;

	if($self->{_booking_report_loaded}) { return; }
	$self->{_booking_report_loaded} = 1;

	if(($params->{search}!~/\w/)&&($params->{start_letter}!~/\w/))
	{
		return;
	}

	my $clause=<<"+++";
showing.venue_id = venue.id
+++

	my $booking_clause=<<"+++";
booking.venue_id = venue.id
+++

	my $add_clause = '';

	my $binds;

	if($params->{search}=~/\w/)
	{
		my $search = $params->{search};

		if($search=~/\%/)
		{
			$add_clause.=<<"+++";
and venue.city like ?
+++

			$binds = [$search];
		}
		else
		{
			$search = '%'.$search.'%';

			$add_clause.=<<"+++";
and
(
	venue.name like ?
	or
	venue.city like ?
)
+++

			$binds = [$search, $search];
		}
	}
	elsif($params->{start_letter}=~/\w/)
	{
		my $start = $params->{start_letter};
		my $end = $params->{end_letter};

		$add_clause.=<<"+++";
and LOWER(SUBSTRING(venue.city, 1, 1)) >= ?
and LOWER(SUBSTRING(venue.city, 1, 1)) <= ?
+++

		$binds = [$start, $end];
	}

	$clause .= $add_clause;
	$booking_clause .= $add_clause;

	$self->add_children('Webkit::MyOffice2::Venue', {
		table => 'myoffice2.venue, myoffice2.showing',
		cols => 'venue.*',
		clause => $self->get_children_clause($clause, 'showing'),
		binds => $binds,
		group => 'venue.id',
		order => 'venue.city, venue.name' });

	if($params->{only_venues}=~/\w/)
	{
		return;
	}

	$self->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.venue, myoffice2.showing',
		cols => 'showing.*',
		clause => $self->get_children_clause($clause, 'showing'),
		binds => $binds,
		group => 'showing.id',
		order => 'venue.city, venue.name' });

	$self->add_children('Webkit::MyOffice2::Booking', {
		table => 'myoffice2.venue, myoffice2.booking',
		cols => 'booking.*',
		clause => $self->get_children_clause($booking_clause, 'booking'),
		binds => $binds,
		group => 'booking.id' });

	my $booking_notes_clause=<<"+++";
$booking_clause
and booking_notes.venue_id = booking.venue_id
and booking_notes.tour_id = booking.tour_id
+++

	$self->add_children('Webkit::MyOffice2::BookingNotes', {
		table => 'myoffice2.venue, myoffice2.booking, myoffice2.booking_notes',
		cols => 'booking_notes.*',
		clause => $self->get_children_clause($booking_notes_clause, 'booking'),
		binds => $binds,
		group => 'booking_notes.id' });	

	my $deal_clause=<<"+++";
$clause
and showing.deal_id = deal.id
+++

	$self->add_children('Webkit::MyOffice2::Deal', {
		table => 'myoffice2.venue, myoffice2.showing, myoffice2.deal',
		cols => 'deal.*',
		clause => $self->get_children_clause($deal_clause, 'showing'),
		binds => $binds,
		group => 'deal.id' });

	my $tourdate_clause=<<"+++";
$clause
and tourdate.showing_id = showing.id
+++

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.venue, myoffice2.showing, myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($tourdate_clause, 'showing'),
		binds => $binds,
		group => 'tourdate.id' });

	my $sales_entry_clause=<<"+++";
$tourdate_clause
and sales_figures_entry.tourdate_id = tourdate.id
+++

	$self->add_children('Webkit::MyOffice2::SalesFiguresEntry', {
		table => 'myoffice2.venue, myoffice2.showing, myoffice2.tourdate, myoffice2.sales_figures_entry',
		cols => 'sales_figures_entry.*',
		clause => $self->get_children_clause($sales_entry_clause, 'showing'),
		binds => $binds,
		group => 'sales_figures_entry.id' });

	my $sales_figs_clause=<<"+++";
$tourdate_clause
and sales_figures.tourdate_id = tourdate.id
+++

	$self->add_children('Webkit::MyOffice2::SalesFigures', {
		table => 'myoffice2.venue, myoffice2.showing, myoffice2.tourdate, myoffice2.sales_figures',
		cols => 'sales_figures.*',
		clause => $self->get_children_clause($sales_figs_clause, 'showing'),
		binds => $binds,
		group => 'sales_figures.id' });

	my $venue_status_clause=<<"+++";
$clause
and venue_status_entry.showing_id = showing.id
+++

	$self->add_children('Webkit::MyOffice2::VenueStatusEntry', {
		table => 'myoffice2.venue, myoffice2.showing, myoffice2.venue_status_entry',
		cols => 'venue_status_entry.*',
		clause => $self->get_children_clause($venue_status_clause, 'showing'),
		binds => $binds,
		group => 'venue_status_entry.id' });

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $showing = $self->get_child('showing', $tourdate->showing_id);
		my $booking = $self->get_child('booking', $tourdate->booking_id);

		$showing->add_child($tourdate);
	}

	foreach my $entry (@{$self->ensure_child_array('venue_status_entry')})
	{
		my $showing = $self->get_child('showing', $entry->showing_id);

		$showing->add_venue_status_entry($entry);
	}

	foreach my $sales_figures (@{$self->ensure_child_array('sales_figures')})
	{
		if($sales_figures->sold_seats<=0)
		{
			next;
		}

		my $sales_entry = $self->get_child('sales_figures_entry', $sales_figures->sales_figures_entry_id);

		$sales_entry->add_child($sales_figures);
	}

	foreach my $sales_entry (@{$self->ensure_child_array('sales_figures_entry')})
	{
		my $tourdate = $self->get_child('tourdate', $sales_entry->tourdate_id);
		my $showing = $self->get_child('showing', $tourdate->showing_id);
		my $deal = $self->get_child('deal', $showing->deal_id);
		my $venue = $self->get_child('venue', $showing->venue_id);

		if(!$deal->tickets_on_sale>0)
		{
			$deal->tickets_on_sale($venue->capacity);
		}

		$tourdate->sales_figures_entry($sales_entry);

		$sales_entry->calculate($deal->tickets_on_sale);
	}

	my $showing_array = $self->ensure_child_array('showing');
	@$showing_array = sort { $a->get_first_tourdate_epoch <=> $b->get_first_tourdate_epoch } @$showing_array;

	$self->{showing_array} = $showing_array;

	foreach my $showing (@{$self->ensure_child_array('showing')})
	{
		my $booking = $self->get_child('booking', $showing->booking_id);
		my $deal = $self->get_child('deal', $showing->deal_id);
		my $venue = $self->get_child('venue', $showing->venue_id);

		if(!$booking)
		{
			next;
		}

		$booking->{_showing_obj} = $showing;

		$deal->calculate($booking, $venue);

		$showing->{_tickets_on_sale} = $booking->tickets_on_sale;

		$venue->add_child($showing);
	}

	foreach my $note (@{$self->ensure_child_array('booking_notes')})
	{
		$self->{_booking_notes}->{$note->venue_id}->{$note->tour_id} = $note;
	}

	foreach my $booking (@{$self->ensure_child_array('booking')})
	{
		if(!$booking->penciled)
		{
			$self->{_date_called_map}->{$booking->venue_id}->{$booking->tour_id} = $booking->date_called;
		}

		my $note = $self->{_booking_notes}->{$booking->venue_id}->{$booking->tour_id};

		if($note)
		{
			$booking->{data}->{booking_note} = $note->notes;
		}
	}
}

my $venue_checkbox_fields = {
	venues_at_risk => 'at_risk',
	projector => 'projector',
	projectionist => 'projectionist',
	screen => 'screen' };

my $rangefields = {
	brochure_deadline => 'brochure_copy_deadline',
	brochure_hit_date => 'brochure_mailing_dates',
	brochure_proof_date => 'brochure_proof_date',
	proof_requested => 'proof_requested',
	proof_seen => 'proof_seen',
	tech_rider_sent => 'technical_rider_date',
	tech_rider_rcvd => 'technical_rider_date_rcvd' };

sub assign_ref_query_title
{
	my ($self, $ref, $params) = @_;

	if(($params->{from}=~/\w/)||($params->{to}=~/\w/))
	{
		my $tourdate_ref = $ref->{_tourdate_refs}->[0];
		my $date = Webkit::Date->parse_from_sql($tourdate_ref->{date});

		push(@{$ref->{query_titles}->{visit}}, 'Visit On:'.$date->get_string);
	}

	if($params->{no_shows}>0)
	{
		push(@{$ref->{query_titles}->{visit}}, 'No. Shows per Visit:'.$ref->{tourdate_count});
	}

	if($params->{no_visits}>0)
	{
		push(@{$ref->{query_titles}->{visit}}, 'No. Seperate Visits:'.$params->{no_visits});
	}

	if(($params->{capacity_more}>0)||($params->{capacity_less}>0))
	{
		push(@{$ref->{query_titles}->{venue}}, 'Capacity:'.$ref->{venue_capacity});
	}

	foreach my $field (keys %$venue_checkbox_fields)
	{
		if($params->{$field} ne 'y')
		{
			next;
		}

		my $datafield = $venue_checkbox_fields->{$field};

		my $title = $self->get_venuestatus_search_field_title($datafield);

		push(@{$ref->{query_titles}->{venue}}, $title);
	}

	if(($params->{attendance_more}>0)||($params->{attendance_less}>0))
	{
		push(@{$ref->{query_titles}->{attendance}}, 'Attendance:'.$ref->{attendance_capacity});
	}
	
	if($params->{top_ticket_price}>0)
	{
		push(@{$ref->{query_titles}->{attendance}}, 'Ticket Price:'.$ref->{highest_price});
	}		

	foreach my $rangefield (keys %$rangefields)
	{
		if($params->{$rangefield} ne 'y') { next; }

		my $datafield = $rangefields->{$rangefield};

		my $title = $self->get_venuestatus_search_field_title($datafield);

		push(@{$ref->{query_titles}->{daterange}}, $title.':'.$ref->{$datafield});
	}

	$ref->{visit_query} = join('<br>', @{$ref->{query_titles}->{visit}});
	$ref->{venue_query} = join('<br>', @{$ref->{query_titles}->{venue}});
	$ref->{attendance_query} = join('<br>', @{$ref->{query_titles}->{attendance}});
	$ref->{daterange_query} = join('<br>', @{$ref->{query_titles}->{daterange}});
}

sub assign_query_title
{
	my ($self, $params) = @_;

	if($params->{from}=~/\w/)
	{
		my $from = $params->{parsed_from};

		if(!$from)
		{
			$from = Webkit::Date->from_calendar($params->{from});
			$params->{parsed_from} = $from;
		}

		push(@{$self->{query_titles}->{visit}}, 'From:'.$from->get_string);
	}

	if($params->{to}=~/\w/)
	{
		my $to = $params->{parsed_to};

		if(!$to)
		{
			$to = Webkit::Date->from_calendar($params->{to});
			$params->{parsed_to} = $to;
		}

		push(@{$self->{query_titles}->{visit}}, 'To:'.$to->get_string);
	}

	if($params->{no_shows}>0)
	{
		push(@{$self->{query_titles}->{visit}}, 'No. Shows:'.$params->{no_shows});
	}

	if($params->{capacity_more}>0)
	{
		push(@{$self->{query_titles}->{venue}}, 'Capacity > '.$params->{capacity_more});
	}

	if($params->{capacity_less}>0)
	{
		push(@{$self->{query_titles}->{venue}}, 'Capacity < '.$params->{capacity_less});
	}

	foreach my $field (keys %$venue_checkbox_fields)
	{
		if($params->{$field} ne 'y')
		{
			next;
		}

		my $datafield = $venue_checkbox_fields->{$field};

		my $title = $self->get_venuestatus_search_field_title($datafield);

		push(@{$self->{query_titles}->{venue}}, $title);
	}

	if($params->{attendance_more}>0)
	{
		push(@{$self->{query_titles}->{attendance}}, 'Attendance > '.$params->{attendance_more});
	}

	if($params->{attendance_less}>0)
	{
		push(@{$self->{query_titles}->{attendance}}, 'Attendance < '.$params->{attendance_less});
	}
	
	if($params->{top_ticket_price}>0)
	{
		push(@{$self->{query_titles}->{attendance}}, 'Top Ticket Price:'.$params->{top_ticket_price});
	}	

	if($params->{rangefrom}=~/\w/)
	{
		my $from = $params->{parsed_rangefrom};

		if(!$from)
		{
			$from = Webkit::Date->from_calendar($params->{rangefrom});
			
			$params->{parsed_rangefrom} = $from;
		}

		foreach my $rangefield (keys %$rangefields)
		{
			if($params->{$rangefield} ne 'y') { next; }

			my $datafield = $rangefields->{$rangefield};

			my $title = $self->get_venuestatus_search_field_title($datafield);

			push(@{$self->{query_titles}->{daterange}}, $title.' > '.$from->get_string);
		}
	}

	if($params->{rangeto}=~/\w/)
	{
		my $to = $params->{parsed_rangeto};

		if(!$to)
		{
			$to = Webkit::Date->from_calendar($params->{rangeto});
			$params->{parsed_rangeto} = $to;
		}

		foreach my $rangefield (keys %$rangefields)
		{
			if($params->{$rangefield} ne 'y') { next; }

			my $datafield = $rangefields->{$rangefield};

			my $title = $self->get_venuestatus_search_field_title($datafield);

			push(@{$self->{query_titles}->{daterange}}, $title.' < '.$to->get_string);
		}
	}

	if(($params->{rangefrom}!~/\w/)&&($params->{rangeto}!~/\w/))
	{
		foreach my $rangefield (keys %$rangefields)
		{
			if($params->{$rangefield} ne 'y') { next; }

			my $datafield = $rangefields->{$rangefield};

			my $title = $self->get_venuestatus_search_field_title($datafield);

			push(@{$self->{query_titles}->{daterange}}, 'NO '.$title);
		}
	}

	$self->{visit_query} = join('<br>', @{$self->{query_titles}->{visit}});
	$self->{venue_query} = join('<br>', @{$self->{query_titles}->{venue}});
	$self->{attendance_query} = join('<br>', @{$self->{query_titles}->{attendance}});
	$self->{daterange_query} = join('<br>', @{$self->{query_titles}->{daterange}});
}


sub filter_venue_status_search
{
	my ($self, $ref, $params) = @_;

	if($params->{from}=~/\w/)
	{
		my $from = $params->{parsed_from};

		if(!$from)
		{
			$from = Webkit::Date->from_calendar($params->{from});
			$params->{parsed_from} = $from;
		}

		my $found = undef;

		foreach my $tourdate_ref (@{$ref->{_tourdate_refs}})
		{
			my $date = $tourdate_ref->{parsed_date};

			if(!$date)
			{
				$date = Webkit::Date->parse_from_sql($tourdate_ref->{date});
				$tourdate_ref->{parsed_date} = $date;
			}

			if($date)
			{
				if($date->epoch_days>=$from->epoch_days)
				{
					$found = $date;
				}
			}
		}

		if(!$found) { return undef; }
	}

	if($params->{to}=~/\w/)
	{
		my $to = $params->{parsed_to};

		if(!$to)
		{
			$to = Webkit::Date->from_calendar($params->{to});
			$params->{parsed_to} = $to;
		}

		my $found = undef;

		foreach my $tourdate_ref (@{$ref->{_tourdate_refs}})
		{
			my $date = $tourdate_ref->{parsed_date};

			if(!$date)
			{
				$date = Webkit::Date->parse_from_sql($tourdate_ref->{date});
				$tourdate_ref->{parsed_date} = $date;
			}

			if($date->epoch_days<=$to->epoch_days)
			{
				$found = $date;
			}
		}

		if(!$found) { return undef; }
	}

	if($params->{no_shows}>0)
	{
		if($ref->{tourdate_count}!=$params->{no_shows})
		{
			return undef;
		}
	}

	if($params->{capacity_more}>0)
	{
		if($ref->{venue_capacity}<$params->{capacity_more})
		{
			return undef;
		}
	}

	if($params->{capacity_less}>0)
	{
		if($ref->{venue_capacity}>$params->{capacity_less})
		{
			return undef;
		}
	}

	foreach my $field (keys %$venue_checkbox_fields)
	{
		if($params->{$field} ne 'y')
		{
			next;
		}

		my $datafield = $venue_checkbox_fields->{$field};

		my $value = $ref->{$datafield};

		if($value !~ /^y/i)
		{
			return undef;
		}
	}

	if($params->{attendance_more}>0)
	{
		if($ref->{attendance_capacity}<$params->{attendance_more})
		{
			return undef;
		}
	}

	if($params->{attendance_less}>0)
	{
		if($ref->{attendance_capacity}>$params->{attendance_less})
		{
			return undef;
		}
	}
	
	if($params->{top_ticket_price}>0)
	{
		my @ticket_price_parts = split(/:/, $ref->{ticket_price});

		my $highest_price = 0;

		foreach my $part (@ticket_price_parts)
		{
			my ($price, $note, $percent) = split(/=/, $part);

			if($price>$highest_price)
			{
				$highest_price = $price;
			}
		}

		$ref->{highest_price} = $highest_price;

		if($highest_price>$params->{top_ticket_price})
		{
			return undef;
		}
	}

	if($params->{rangefrom}=~/\w/)
	{
		my $from = $params->{parsed_rangefrom};

		if(!$from)
		{
			$from = Webkit::Date->from_calendar($params->{rangefrom});
			$params->{parsed_rangefrom} = $from;
		}

		foreach my $rangefield (keys %$rangefields)
		{
			if($params->{$rangefield} ne 'y') { next; }

			my $datafield = $rangefields->{$rangefield};

			my $mode = '>=';

			if(!$self->filter_venuestatus_daterange($mode, $ref->{$datafield}, $from, $ref->{showing_id}))
			{
				return undef;
			}

		}
	}

	if($params->{rangeto}=~/\w/)
	{
		my $to = $params->{parsed_rangeto};

		if(!$to)
		{
			$to = Webkit::Date->from_calendar($params->{rangeto});
			$params->{parsed_rangeto} = $to;
		}

		foreach my $rangefield (keys %$rangefields)
		{
			my $datafield = $rangefields->{$rangefield};

			if($params->{$rangefield} ne 'y') { next; }

			my $mode = '<=';

			if(!$self->filter_venuestatus_daterange($mode, $ref->{$datafield}, $to, $ref->{showing_id}))
			{
				return undef;
			}

		}
	}

	if(($params->{rangefrom}!~/\w/)&&($params->{rangeto}!~/\w/))
	{
		foreach my $rangefield (keys %$rangefields)
		{
			my $datafield = $rangefields->{$rangefield};

			if($params->{$rangefield} ne 'y') { next; }

			my $mode = 'not';

			if(!$self->filter_venuestatus_daterange($mode, $ref->{$datafield}))
			{
				return undef;
			}
		}
	}
		
	return 1;
}

sub filter_venuestatus_daterange
{
	my ($self, $mode, $value, $compare_date, $showing_id) = @_;

	
	
	$value = ''.$value;
	
	$value =~ s/^(\d+\/\d+\/\d+).*$/$1/;
	
	
	if($mode eq 'not')
	{
		if($value=~/\w/)
		{
			return undef;
		}
		else
		{
			return 1;
		}
	}
	else
	{
		if(($value!~/\w/)||($value=~/^00/))
		{
			return undef;
		}

		if($value!~/\d\d/) { return undef; }

		my $dates;

		if($value =~ /=/)
		{
			$value =~ s/[^\d\/=]//g;

			while($value =~ /(\d{1,2}\/\d{1,2}\/\d{4})/gsi)
			{
				my $real_date = Webkit::Date->from_calendar($1);

				if($real_date)
				{
					push(@$dates, $real_date);
				}

				$value =~ s/(\d{1,2}\/\d{1,2}\/\d{4})//si;
			}
		}
		else
		{
			my $date_value;

			if($value =~ /\d+\/\d+\/\d+/)
			{
				$date_value = Webkit::Date->from_calendar($value);
			}
			else
			{
				$date_value = Webkit::Date->parse_from_sql($value);
			}

			if($date_value!~/\d/) { return undef; }

			$dates = [$date_value];
		}

		my $compare_days = $compare_date->epoch_days;

		foreach my $date (@$dates)
		{
			my $check = undef;
			
			if(ref($date)!~/\w/)
			{
				die $date;
			}
			
			my $date_days = $date->epoch_days;
			
			my $eval_st=<<"+++";
if($date_days $mode $compare_days)
{
	\$check = 1;
}
+++

			eval($eval_st);

			if($check)
			{
				return 1;
			}
		}

		return undef;
	}
}

sub get_venuestatus_search_field_title
{
	my ($self, $field) = @_;

	my @parts = split(/_/, $field);

	$parts[0]=~s/^(\w)/uc($1)/e;

	return join(' ', @parts);
}

sub load_venue_status_search
{
	my ($self, $params) = @_;

	if($self->{_venue_status_search_loaded}) { return; }
	$self->{_venue_status_search_loaded} = 1;

	my $showing_table=<<"+++";
myoffice2.showing,
myoffice2.venue,
myoffice2.deal
+++

	my $showing_clause=<<"+++";
showing.venue_id = venue.id
and showing.deal_id = deal.id
+++

	my $showing_cols=<<"+++";
showing.id as showing_id,
showing.tour_id as tour_id,
venue.id as venue_id,
CONCAT(venue.city,', ',venue.name) as venue_name,
venue.capacity as venue_capacity,
deal.ticket_price as ticket_price,
deal.tickets_on_sale as tickets_on_sale,
deal.projector as projector,
deal.projectionist as projectionist,
deal.screen as screen,
deal.brochure_copy_deadline as brochure_copy_deadline,
deal.brochure_mailing_dates as brochure_mailing_dates,
showing.technical_rider_date as tech_rider_sent,
showing.technical_rider_date_rcvd as tech_rider_rcvd
+++


	my $showing_refs = $self->{db}->get_select_refs({
		table => $showing_table,
		cols => $showing_cols,
		clause => $self->get_children_clause($showing_clause, 'showing'),
		group => 'showing.id',
		order => 'venue_name' });

	my $tourdate_table=<<"+++";
myoffice2.tourdate
+++

	my $tourdate_clause=<<"+++";
tourdate.showing_id>0
+++

	my $sales_figures_table=<<"+++";
myoffice2.tourdate,
myoffice2.sales_figures
+++

	my $tourdate_cols=<<"+++";
tourdate.showing_id as showing_id,
tourdate.id as tourdate_id,
tourdate.date as date
+++

	my $sales_figures_cols=<<"+++";
tourdate.showing_id as showing_id,
tourdate.id as tourdate_id,
MAX(sales_figures.sold_seats) as sold_seats
+++

	my $sales_figures_clause=<<"+++";
sales_figures.tourdate_id = tourdate.id
+++

	my $tourdate_refs = $self->{db}->get_select_refs({
		table => $tourdate_table,
		cols => $tourdate_cols,
		clause => $self->get_children_clause($tourdate_clause, 'tourdate'),
		group => 'tourdate.id' });

	my $sales_figures_refs = $self->{db}->get_select_refs({
		table => $sales_figures_table,
		cols => $sales_figures_cols,
		clause => $self->get_children_clause($sales_figures_clause, 'tourdate'),
		group => 'tourdate.id' });

	my $venue_status_cols=<<"+++";
venue_status_entry.showing_id as showing_id,
venue_status_entry.field as field,
venue_status_entry.value as value
+++

	my $venue_status_table=<<"+++";
myoffice2.venue_status_entry
+++

	my $venue_status_clause=<<"+++";
venue_status_entry.field = ?
or venue_status_entry.field = ?
or venue_status_entry.field = ?
or venue_status_entry.field = ?
+++

	my $venue_status_refs = $self->{db}->get_select_refs({
		table => $venue_status_table,
		cols => $venue_status_cols,
		clause => $self->get_children_clause($venue_status_clause, 'venue_status_entry'),
		binds => ['brochure_proof_date', 'proof_requested', 'proof_seen', 'at_risk'],
		group => 'venue_status_entry.id' });
		
		

	my $showing_map;
	my $venue_map;

	foreach my $ref (@$showing_refs)
	{
		$showing_map->{$ref->{showing_id}} = $ref;
	}

	foreach my $ref (@$tourdate_refs)
	{
		my $showing_ref = $showing_map->{$ref->{showing_id}};

		push(@{$showing_ref->{_tourdate_refs}}, $ref);
	}

	foreach my $ref (@$sales_figures_refs)
	{
		my $showing_ref = $showing_map->{$ref->{showing_id}};

		foreach my $tourdate_ref (@{$showing_ref->{_tourdate_refs}})
		{
			if($tourdate_ref->{tourdate_id}==$ref->{tourdate_id})
			{
				$tourdate_ref->{sold_seats} = $ref->{sold_seats};
			}
		}
	}

	foreach my $ref (@$venue_status_refs)
	{
		my $showing_ref = $showing_map->{$ref->{showing_id}};

		$showing_ref->{$ref->{field}} = $ref->{value};
	}

	my $results;

	foreach my $ref (@$showing_refs)
	{
		my $capacity = $ref->{tickets_on_sale};

		if($capacity<=0)
		{
			$capacity = $ref->{venue_capacity};
		}

		my $total_attendance = 0;

		my $tourdate_count = 0;

		foreach my $tourdate_ref (@{$ref->{_tourdate_refs}})
		{
			$total_attendance += $tourdate_ref->{sold_seats};
			$tourdate_count++;
		}

		if($tourdate_count<=0)
		{
			$self->{ntd}++;
			next;
		}

		if($capacity<=0)
		{
			$self->{zcp}++;
			next;
		}

		my $average_total_attendance = $total_attendance / $tourdate_count;
		my $attendance_capacity = ($average_total_attendance / $capacity) * 100;

		$ref->{attendance_capacity} = sprintf("%.0f", $attendance_capacity);
		$ref->{tourdate_count} = $tourdate_count;

		$ref->{visit_count} = $venue_map->{$ref->{venue_id}};

		my $temp_results;



		if($self->filter_venue_status_search($ref, $params))
		{
			$venue_map->{$ref->{venue_id}}->{$ref->{showing_id}} = $ref;

			push(@$results, $ref);
		}
		
	}

	if($params->{no_visits}>0)
	{
		my $latest_results;

		my $st = '';

		foreach my $result (@$results)
		{
			
			my @showing_refs = keys %{$venue_map->{$result->{venue_id}}};
			my $count = @showing_refs;

			$st .= $result->{venue_name}.' --- '.$count.'<p>';

			if($count==$params->{no_visits})
			{
				if(!$latest_results->{$result->{venue_id}})
				{
					$latest_results->{$result->{venue_id}} = $result;
				}
				else
				{
					my $existing = $latest_results->{$result->{venue_id}};

					my $existing_date = $existing->{_tourdate_refs}->[0]->{date};
					my $result_date = $result->{_tourdate_refs}->[0]->{date};

					if($result_date>$existing_date)
					{
						$latest_results->{$result->{venue_id}} = $result;
					}
				}
			}
		}

		my $new_results;

		foreach my $venue_id (keys %$latest_results)
		{
			my $result = $latest_results->{$venue_id};

			push(@$new_results, $result);
		}

		$results = $new_results;
	}

	

	if($params->{order} eq 'date')
	{
		@$results = sort { $self->get_date_sort_number($b) <=> $self->get_date_sort_number($a) } @$results;
	}
	else
	{
		@$results = sort { $a->{venue_name} cmp $b->{venue_name} } @$results;
	}

	foreach my $result (@$results)
	{
		$self->assign_ref_query_title($result, $params);
	}

	$self->assign_query_title($params);

	$self->{search_results} = $results;

	$self->{result_count} = @$results;
}

sub get_date_sort_number
{
	my ($self, $ref) = @_;

	my $highest_epoch = 0;

	foreach my $tourdate_ref (@{$ref->{_tourdate_refs}})
	{
		#my $date = $tourdate_ref->{parsed_date};
		
		my $date = Webkit::Date->parse_from_sql($tourdate_ref->{date});

		if($date)
		{
			if($date->epoch_days>=$highest_epoch)
			{
				$highest_epoch = $date->epoch_days;
			}
		}
		
#		if(!$date)
#		{
#			$date = Webkit::Date->parse_from_sql($tourdate_ref->{date});
#			$tourdate_ref->{parsed_date} = $date;
#		}
#		else
#		{
#			if($date->epoch_days>=$highest_epoch)
#			{
#				$highest_epoch = $date->epoch_days;
#			}
#		}
	}

	return $highest_epoch;
}


sub load_venue_status_sheet
{
	my ($self, $params) = @_;

	if($params->{venue_id}!~/\w/) { return; }

	my $venue = Webkit::MyOffice2::Venue->load($self->{db}, {
		id => $params->{venue_id} });

	$self->{venue} = $venue;

	my $clause=<<"+++";
booking.venue_id = ?
and booking.penciled IS NOT NULL
+++

	my $showing_clause=<<"+++";
showing.venue_id = ?
+++

	my $booking_table = 'myoffice2.booking';
	my $tourdate_table = 'myoffice2.booking, myoffice2.tourdate';
	my $venue_status_entry_table = 'myoffice2.booking, myoffice2.venue_status_entry';

	my $binds = [$venue->get_id];

	if($params->{booking_id}>0)
	{
		$clause.=<<"+++";
and booking.id = ?
+++

		$showing_clause.=<<"+++";
and showing.booking_id = ?
+++

		push(@$binds, $params->{booking_id});
	}
	elsif($params->{showing_id}>0)
	{
		$showing_clause.=<<"+++";
and showing.id = ?
+++

		$clause.=<<"+++";
and showing.booking_id = booking.id
and showing.id = ?
+++

		$booking_table .= ', myoffice2.showing';
		$tourdate_table .= ', myoffice2.showing';
		$venue_status_entry_table .= ', myoffice2.showing';

		push(@$binds, $params->{showing_id});
	}

#	if($params->{showing_id}>0)
#	{
#		$clause.=<<"+++";
#showing.booking_id = booking.id
#and showing.id = ?
#+++
#
#		push(@$binds, $params->{showing_id});
#	}

	$self->add_children('Webkit::MyOffice2::Booking', {
		table => $booking_table,
		cols => 'booking.*',
		clause => $self->get_children_clause($clause, 'booking'),
		binds => $binds,
		group => 'booking.id' });

my $tourdate_clause=<<"+++";
$clause
and tourdate.booking_id = booking.id
+++

my $showing_tourdate_clause=<<"+++";
$showing_clause
and tourdate.showing_id = showing.id
+++

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => $tourdate_table,
		cols => 'tourdate.*',
		clause => $self->get_children_clause($tourdate_clause, 'booking'),
		binds => $binds,
		group => 'tourdate.id',
		order => 'tourdate.date, tourdate.time' });

	my $venue_status_clause=<<"+++";
$clause
and venue_status_entry.booking_id = booking.id
+++

	$self->add_children('Webkit::MyOffice2::VenueStatusEntry', {
		table => $venue_status_entry_table,
		cols => 'venue_status_entry.*',
		clause => $self->get_children_clause($venue_status_clause, 'booking'),
		binds => $binds,
		group => 'venue_status_entry.id' });


	$self->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.showing',
		cols => 'showing.*',
		clause => $self->get_children_clause($showing_clause, 'showing'),
		binds => $binds,
		group => 'showing.id' });


	my $sales_entry_clause=<<"+++";
$showing_tourdate_clause
and sales_figures_entry.tourdate_id = tourdate.id
+++

	$self->add_children('Webkit::MyOffice2::SalesFiguresEntry', {
		table => 'myoffice2.showing, myoffice2.tourdate, myoffice2.sales_figures_entry',
		cols => 'sales_figures_entry.*',
		clause => $self->get_children_clause($sales_entry_clause, 'showing'),
		binds => $binds,
		group => 'sales_figures_entry.id' });

	my $sales_figures_clause=<<"+++";
$showing_tourdate_clause
and sales_figures.tourdate_id = tourdate.id
+++

	$self->add_children('Webkit::MyOffice2::SalesFigures', {
		table => 'myoffice2.showing, myoffice2.tourdate, myoffice2.sales_figures',
		cols => 'sales_figures.*',
		clause => $self->get_children_clause($sales_figures_clause, 'showing'),
		binds => $binds,
		group => 'sales_figures.id',
		order => 'sales_figures.week_start' });

	my $deal_clause=<<"+++";
$showing_clause
and showing.deal_id = deal.id
+++

	$self->add_children('Webkit::MyOffice2::Deal', {
		table => 'myoffice2.showing, myoffice2.deal',
		cols => 'deal.*',
		clause => $self->get_children_clause($deal_clause, 'showing'),
		binds => $binds,
		group => 'deal.id' });

	my $print_req_clause=<<"+++";
$showing_clause
and print_req.showing_id = showing.id
+++

	$self->add_children('Webkit::MyOffice2::Print', {
		table => 'myoffice2.showing, myoffice2.print_req',
		cols => 'print_req.*',
		clause => $self->get_children_clause($print_req_clause, 'showing'),
		binds => $binds,
		group => 'print_req.id' });

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $booking = $self->get_child('booking', $tourdate->booking_id);
		$booking->add_child($tourdate);

		if($tourdate->showing_id>0)
		{
			my $showing = $self->get_child('showing', $tourdate->showing_id);

			if(!$showing) { next; }

			$showing->add_child($tourdate);
		}
	}

	foreach my $sales_figures (@{$self->ensure_child_array('sales_figures')})
	{
		if($sales_figures->sold_seats<=0)
		{
			next;
		}

		my $sales_entry = $self->get_child('sales_figures_entry', $sales_figures->sales_figures_entry_id);

		$sales_entry->add_child($sales_figures);
	}

	foreach my $sales_entry (@{$self->ensure_child_array('sales_figures_entry')})
	{
		my $tourdate = $self->get_child('tourdate', $sales_entry->tourdate_id);

		if(!$tourdate) { next; }
		my $showing = $self->get_child('showing', $tourdate->showing_id);
		my $deal = $self->get_child('deal', $showing->deal_id);

		if(!$deal->tickets_on_sale>0)
		{
			$deal->tickets_on_sale($venue->capacity);
		}

		$tourdate->sales_figures_entry($sales_entry);

		$sales_entry->calculate($deal->tickets_on_sale);
	}

	foreach my $showing (@{$self->ensure_child_array('showing')})
	{
		my $booking = $self->get_child('booking', $showing->booking_id);
		my $deal = $self->get_child('deal', $showing->deal_id);

		if((!$booking)||(!$deal)) { next; }

		$booking->{_showing_obj} = $showing;

		$deal->calculate($booking, $venue);

		$showing->{_tickets_on_sale} = $booking->tickets_on_sale;
	}

	foreach my $print_req (@{$self->ensure_child_array('print_req')})
	{
		my $showing = $self->get_child('showing', $print_req->showing_id);
		$showing->add_child($print_req);
	}

	foreach my $venue_status_entry (@{$self->ensure_child_array('venue_status_entry')})
	{
		my $booking = $self->get_child('booking', $venue_status_entry->booking_id);
		$booking->add_venue_status_entry($venue_status_entry);

		if($venue_status_entry->showing_id>0)
		{
			my $showing = $self->get_child('showing', $venue_status_entry->showing_id);

			if(!$showing)
			{
				next;
			}

			$showing->add_venue_status_entry($venue_status_entry);
		}
	}

	my $booking_arr = $self->get_child_array('booking');

	@$booking_arr = sort { $a->get_first_tourdate_epoch <=> $b->get_first_tourdate_epoch } @$booking_arr;

	$self->{booking_array} = $booking_arr;
}

sub load_bookings_and_tourdates_for_venue
{
	my ($self, $venue) = @_;

	if(!$venue) { return; }

	my $clause=<<"+++";
booking.venue_id = ?
and booking.penciled IS NOT NULL
and tourdate.booking_id = booking.id
+++

	$venue->add_children('Webkit::MyOffice2::Booking', {
		table => 'myoffice2.booking, myoffice2.tourdate',
		cols => 'booking.*',
		clause => $self->get_children_clause($clause, 'booking'),
		binds => [$venue->get_id],
		group => 'booking.id' });

	$venue->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.booking, myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($clause, 'booking'),
		binds => [$venue->get_id],
		group => 'tourdate.id',
		order => 'date, time' });

	foreach my $tourdate (@{$venue->ensure_child_array('tourdate')})
	{
		my $booking = $venue->get_child('booking', $tourdate->booking_id);

		$booking->add_child($tourdate);
	}
}

sub load_showings_and_tourdates_for_venue
{
	my ($self, $venue) = @_;

	if(!$venue) { return; }

	my $clause=<<"+++";
showing.venue_id = ?
+++

	$venue->add_children('Webkit::MyOffice2::Showing', {
		table => 'myoffice2.showing',
		cols => 'showing.*',
		clause => $self->get_children_clause($clause, 'showing'),
		binds => [$venue->get_id],
		group => 'showing.id' });

	my $tourdate_clause=<<"+++";
$clause
and tourdate.showing_id = showing.id
+++

	$venue->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.showing, myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $self->get_children_clause($tourdate_clause, 'showing'),
		binds => [$venue->get_id],
		group => 'tourdate.id',
		order => 'date, time' });

	foreach my $tourdate (@{$venue->ensure_child_array('tourdate')})
	{
		my $showing = $venue->get_child('showing', $tourdate->showing_id);

		$showing->add_child($tourdate);
	}
}

1;
