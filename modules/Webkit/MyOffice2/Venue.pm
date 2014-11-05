package Webkit::MyOffice2::Venue;

use strict;

@Webkit::MyOffice2::Venue::ISA = qw(Webkit::DBObject);

my $schema = {
		org_id => {	type => 'id',
				required => 1 },

		name => {	required => 1,
				type => 'string' },

                address1 => {	required => 1,
				type => 'string' },

                address2 => {	type => 'string' },

                city => {	required => 1,
				type => 'string' },

                postcode => {	type => 'string' },

                website => {	type => 'string' },

                county => {	type => 'string' },

                capacity => {	type => 'integer' },

                tour_id => {	type => 'id',
				required => 1 },

                main_contact_id => {	type => 'id' },

                tech_contact_id => {	type => 'id' },

                marketing_contact_id =>	{	type => 'id' },

                boxoffice_contact_id => {	type => 'id' },

		booking_contact_id => {	type => 'id' },

		box_office_number => {	type => 'string' },

		figures_number => {	type => 'string' },

		admin_number => {	type => 'string' },

		fax_number => {		type => 'string' },

		brochure_date => {	type => 'string' },

		brochures_per_year => {	type => 'string' },

		brochures_produced => {	type => 'string' },

		brochures_mailed => {	type => 'string' },

		space_allocated => {	type => 'string' },

		contra_charges => {	type => 'string' },

		booking_notes => {	type => 'string' } };

sub table
{
        return 'myoffice2.venue';
}

sub schema
{
        return $schema;
}

sub save_form_params
{
	my ($self, $params) = @_;

	$self->load_contacts;

	my @save_fields = qw(name capacity website box_office_number figures_number admin_number fax_number address1 address2 city postcode county brochure_date brochures_per_year brochures_produced brochures_mailed space_allocated contra_charges booking_notes);
	my @contact_types = qw(main tech marketing boxoffice booking);
	my @contact_fields = qw(name phone email);

	foreach my $save_field (@save_fields)
	{
		$self->set_value($save_field, $params->{$save_field});
	}

	foreach my $contact_type (@contact_types)
	{
		my $contact = $self->get_contact($contact_type);
		my $prefix = 'contact_'.$contact_type;
		my $contact_ref;

		foreach my $contact_field (@contact_fields)
		{
			my $value = $params->{$prefix.'_'.$contact_field};

			if($value=~/\w/)
			{
				$contact_ref->{$contact_field} = $value;
			}
		}

		if($contact_ref)
		{
			if(!$contact)
			{
				$contact = Webkit::MyOffice2::Contact->constructor($self->{db});
				$contact->org_id($self->org_id);
				$contact->tour_id($self->tour_id);
				$contact->type('venue');

				$self->{_contacts}->{$contact_type} = $contact;
			}

			$contact->name($contact_ref->{name});
			$contact->phone($contact_ref->{phone});
			$contact->email($contact_ref->{email});

			$contact->{_contact_type} = $contact_type;

			push(@{$self->{_save_contacts}}, $contact);
		}
		else
		{
			if($contact)
			{
				push(@{$self->{_delete_contacts}}, $contact);
			}

			$self->set_value($contact_type.'_contact_id', 0);
		}
	}
}

sub save_or_create
{
	my ($self) = @_;

	$self->SUPER::save_or_create;

	foreach my $contact (@{$self->{_delete_contacts}})
	{
		$contact->delete;
	}

	foreach my $contact (@{$self->{_save_contacts}})
	{
		$contact->venue_id($self->get_id);

		$contact->save_or_create;

		$self->set_value($contact->{_contact_type}.'_contact_id', $contact->get_id);
	}

	$self->SUPER::save;
}

sub get_contact
{
	my ($self, $type) = @_;

	$self->load_contacts;

	return $self->{_contacts}->{$type};
}

sub get_contact_field
{
	my ($self, $type, $field) = @_;

	$self->load_contacts;

	my $contact = $self->get_contact($type);

	if(!$contact) { return ''; }

	return $contact->get_value($field);
}

sub load_bookings
{
	my ($self) = @_;

	if($self->{_bookings_loaded}) { return; }
	$self->{_bookings_loaded} = 1;

	my $clause;
	my $binds;

	$self->load_children('Webkit::MyOffice2::Booking', {
		order => 'created DESC' });
}

sub load_showings
{
	my ($self) = @_;

	if($self->{_showings_loaded}) { return; }
	$self->{_showings_loaded} = 1;

	my $clause;
	my $binds;

	$self->load_children('Webkit::MyOffice2::Showing');
}

sub load_tourdates
{
	my ($self) = @_;

	if($self->{_tourdates_loaded}) { return; }
	$self->{_tourdates_loaded} = 1;

	my $clause=<<"+++";
tourdate.showing_id = showing.id
and showing.venue_id = ?
+++

	$self->add_children('Webkit::MyOffice2::Tourdate', {
		table => 'myoffice2.showing, myoffice2.tourdate',
		cols => 'tourdate.*',
		clause => $clause,
		binds => [$self->get_id],
		group => 'tourdate.id',
		order => 'tourdate.date, tourdate.time' });
}

sub load_showings_and_tourdates
{
	my ($self) = @_;

	if($self->{_showings_and_tourdates_loaded}) { return; }
	$self->{_showings_and_tourdates_loaded} = 1;

	$self->load_showings;
	$self->load_tourdates;

	foreach my $tourdate (@{$self->ensure_child_array('tourdate')})
	{
		my $showing = $self->get_child('showing', $tourdate->showing_id);
		$showing->add_child($tourdate);
	}
}

sub load_contacts
{
	my ($self) = @_;

	if($self->{_contacts_loaded}) { return; }

	$self->{_contacts_loaded} = 1;

	my @fields = qw(main tech marketing boxoffice booking);
	my $clause_parts;
	my $binds;

	foreach my $field (@fields)
	{
		my $value = $self->get_value($field.'_contact_id');

		if($value!~/\d/) { next; }

		push(@$clause_parts, 'id = ?');
		push(@$binds, $value);

		$self->{_contact_id_map}->{$self->get_value($field.'_contact_id')} = $field;
	}

	if(!$clause_parts) { return; }

	my $clause = join(' or ', @$clause_parts);

	$self->add_children('Webkit::MyOffice2::Contact', {
		table => 'myoffice2.contact',
		cols => 'contact.*',
		clause => $clause,
		binds => $binds });

	foreach my $contact (@{$self->ensure_child_array('contact')})
	{
		my $type = $self->{_contact_id_map}->{$contact->get_id};

		$self->{_contacts}->{$type} = $contact;
	}
}

sub get_city_title
{
	my ($self) = @_;

	return $self->city.' - '.$self->name;
}

sub load_showings_and_tourdates_by_tour
{
	my ($self) = @_;

	if($self->{_showings_and_tourdates_by_tour_loaded}) { return; }
	$self->{_showings_and_tourdates_by_tour_loaded} = 1;

	$self->load_showings_and_tourdates;

	my $showing_arr = $self->ensure_child_array('showing');

	@$showing_arr = sort { $a->get_first_tourdate_epoch <=> $b->get_first_tourdate_epoch } @$showing_arr;

	$self->{showing_array} = $showing_arr;

	foreach my $showing (@{$self->ensure_child_array('showing')})
	{
		if($showing->get_child_count('tourdate')<=0)
		{
			next;
		}

		push(@{$self->{_showing_map}->{$showing->tour_id}}, $showing);
	}
}

sub load_booking_notes
{
	my ($self) = @_;

	if($self->{_booking_notes_loaded}) { return; }
	$self->{_booking_notes_loaded} = 1;

	$self->load_children('Webkit::MyOffice2::BookingNotes');

	foreach my $notes (@{$self->ensure_child_array('booking_notes')})
	{
		$self->{_booking_notes}->{$notes->tour_id} = $notes;
	}
}

sub load_last_booking_per_tour
{
	my ($self) = @_;

	if($self->{_last_booking_per_tour_loaded}) { return; }
	$self->{_last_booking_per_tour_loaded} = 1;

	$self->load_bookings;

	foreach my $booking (@{$self->ensure_child_array('booking')})
	{
		if(!$self->{_booking_map}->{$booking->tour_id})
		{
			$self->{_booking_map}->{$booking->tour_id} = $booking;
		}
	}	
}

sub load_active_bookings_for_tour
{
	my ($self, $tour) = @_;

	if(!$tour) { return; }

	if($self->{_active_bookings_for_tour_loaded}) { return; }
	$self->{_active_bookings_for_tour_loaded} = 1;

	my $clause=<<"+++";
failed IS NULL
and agreed IS NULL
and penciled IS NULL
+++

	$self->load_children('Webkit::MyOffice2::Booking', {
		clause => $tour->get_children_clause($clause),
		group => 'booking.id' });
}

sub get_full_address
{
	my ($self, $delim) = @_;

	if(!$delim) { $delim = ",\n"; }

	my @fields = qw(name address1 address2 city postcode county);
	my $parts;

	foreach my $field (@fields)
	{
		my $value = $self->get_value($field);

		if($value=~/\w/)
		{
			push(@$parts, $value);
		}
	}

	my $address = join($delim, @$parts);

	return $address;
}

sub get_city_first_letter
{
	my ($self) = @_;

	$self->city =~ /^(\w)/i;

	return $1;
}

1;
