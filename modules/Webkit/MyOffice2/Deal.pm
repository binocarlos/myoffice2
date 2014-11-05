package Webkit::MyOffice2::Deal;

use strict;

@Webkit::MyOffice2::Deal::ISA = qw(Webkit::DBObject);

my $schema = {	 org_id => 	{	type => 'id',
					required => 1},

		tour_id =>         {        type => 'id',
                                        required => 1 },

                created =>        {        type => 'datetime',
                                        required => 1 },

                get_in =>        {        type => 'string' },

                running =>        {        type => 'string' },

                get_out =>        {        type => 'string' },

                staff_level =>        {        type => 'string' },

                projector =>        {        type => 'string' },

                deal =>         {        type => 'float' },

                projectionist =>{        type => 'string' },

                screen =>        {        type => 'string' },

                merchandising =>{        type => 'string' },

                print_required =>{        type => 'string' },

                in_brochure =>        {        type => 'string' },

                brochure_mailing =>{        type => 'datetime' },

		brochure_mailing_dates => {	type => 'string' },

                print_deadline =>{        type => 'datetime' },

                brochure_deadline =>{        type => 'datetime' },

                brochure_copy_deadline =>{        type => 'string' },

                ticket_price =>        {        type => 'string',
						required => 1 },

		tickets_on_sale => {	type => 'integer' },

		tickets_on_sale_reason => {	type => 'string' },

		gross_box_office => {	type => 'float' },

                terms =>        {        type => 'string' },

                guarantee =>        {        type => 'string' },

                notes => {      type => 'string' },

                paying_under_over =>{        type => 'string' } };

sub table
{
        return 'myoffice2.deal';
}

sub schema
{
        return $schema;
}

sub save_form_params
{
	my ($self, $booking, $params) = @_;

        my @simple_fields = qw(staff_level projector projectionist screen print_required in_brochure terms paying_under_over);
        my @date_fields = qw(print_deadline brochure_deadline);

	foreach my $simple_field (@simple_fields)
	{
		$self->set_value($simple_field, $params->{$simple_field});
	}

	foreach my $date_field (@date_fields)
	{
		my $date = Webkit::Date->from_calendar($params->{$date_field});

		$self->set_value($date_field, $date);
	}

	$booking->brochure_mailing_dates($params->{brochure_mailing_dates});
	$booking->brochure_copy_deadline($params->{brochure_copy_deadline});

	$self->brochure_mailing_dates($params->{brochure_mailing_dates});
	$self->brochure_copy_deadline($params->{brochure_copy_deadline});

	$booking->guarantee($params->{guarantee});
	$self->guarantee($params->{guarantee});

	$booking->ticket_price($params->{ticket_price});
	$self->ticket_price($params->{ticket_price});

	$booking->tickets_on_sale($params->{tickets_on_sale});
	$self->tickets_on_sale($params->{tickets_on_sale});

	$booking->tickets_on_sale_reason($params->{tickets_on_sale_reason});
	$self->tickets_on_sale_reason($params->{tickets_on_sale_reason});

	$booking->venue_target($params->{venue_target});

	$booking->gross_box_office($params->{gross_box_office});
	$self->gross_box_office($params->{gross_box_office});

	$booking->deal($params->{deal});
	$self->deal($params->{deal});	

	$booking->deal_notes($params->{notes});
	$self->notes($params->{notes});	
}

sub calculate
{
	my ($self, $booking, $venue) = @_;

	if((!$booking)||(!$venue)) { die "You must give a booking and venue @ Deal->calculate"; }

	my $tourdate_count = $booking->get_child_count('tourdate');

	$self->{_per_show_gross} = sprintf("%.2f", $booking->calculate_gross($venue->capacity));
	$self->{_total_gross} = sprintf("%.2f", $self->{_per_show_gross} * $tourdate_count);

	$self->{_som_gross} = sprintf("%.2f", $self->{_total_gross} * $self->deal_factor);
	$self->{_som_vat} = sprintf("%.2f", $self->{_som_gross} * Webkit::Constants->get_constant('vat'));
	$self->{_som_net} = sprintf("%.2f", $self->{_som_gross} - $self->{_som_vat});

	$self->{_venue_gross} = sprintf("%.2f", $self->{_total_gross} * $self->venue_deal_factor);
	$self->{_venue_vat} = sprintf("%.2f", $self->{_venue_gross} * Webkit::Constants->get_constant('vat'));
	$self->{_venue_net} = sprintf("%.2f", $self->{_venue_gross} - $self->{_venue_vat});

	if($booking->tickets_on_sale<=0)
	{
		$booking->tickets_on_sale($venue->capacity);
		$self->tickets_on_sale($venue->capacity);
	}
}

sub get_staff_options
{
	my ($self, $field) = @_;

	return Webkit::AppTools->get_number_select_options({
		min => 1,
		max => 8,
		gap => 1,
		selected => $self->get_value($field) });
}

sub get_merchandising_options
{
	my ($self) = @_;

	return Webkit::AppTools->get_number_select_options({
		min => 10,
		max => 50,
		gap => 5,
		selected => $self->merchandising });
}

sub yes_no_gui
{
	my ($self, $field) = @_;

	my $value = $self->get_value($field);

	if($value!~/\w/) { $value = 'no'; }

	my $yes_checked = '';
	my $no_checked = '';

	if($value eq 'yes') { $yes_checked = ' CHECKED'; }
	else { $no_checked = ' CHECKED'; }

	my $ret=<<"+++";
<input type="radio" name="$field" value="yes"$yes_checked> Yes
&nbsp;&nbsp;&nbsp;
<input type="radio" name="$field" value="no"$no_checked> No 
+++

	return $ret;
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

sub created_title
{
	my ($self) = @_;

	return &Webkit::Date::get_string($self->created);
}

sub has_projector
{
	my ($self) = @_;

	if($self->projector eq 'yes')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub date_title
{
	my ($self, $field) = @_;

	my $value = $self->get_value($field);

	if(!$value) { return; }

	return &Webkit::Date::get_string($value);
}

sub calendar_value
{
	my ($self, $field) = @_;

	my $date = $self->get_value($field);

	if(!$date) { return ''; }

	return &Webkit::Date::get_string($date);
}

sub get_created_st
{
	my ($self) = @_;

	if($self->exists)
	{
		return &Webkit::Date::get_string($self->created);
	}
	else
	{
		return Webkit::Date->now->get_string;
	}
}

1;
