package Webkit::MyOffice2::Admin;

use vars qw(@ISA);

use strict qw(vars);

use Webkit::Application;
use Webkit::Error;

@ISA = qw(Webkit::Application);

my $app_name = 'myoffice2';
my $app_title = 'MyOffice V2.0';

my $manual_page_methods = {
	tourlist_excel_sheet => 'header',
	showing_push_website_data => 'header',
	print_excel_sheet => 'header',
	sales_figures_toolbar => 1,
	print_toolbar => 1,
	venue_status_toolbar => 1,
	tourlist_toolbar => 1,
	booking_report_toolbar => 1,
	booking_penciled_sheet_toolbar => 1,
	booking_progress_sheet_toolbar => 1 };

my $sql_update=<<"+++";
CREATE TABLE `note_entry` 
(
	`id` INT UNSIGNED DEFAULT '0' NOT NULL AUTO_INCREMENT, 
	`org_id` INT UNSIGNED DEFAULT '0' NOT NULL, 
	`users_id` INT UNSIGNED DEFAULT '0' NOT NULL, 
	`created` DATE DEFAULT '''' NOT NULL, 
	`content` TEXT, PRIMARY KEY(`id`), 
	INDEX(`id`,`org_id`,`users_id`,`created`)
)  TYPE = InnoDB;
+++

########################################################################################
########################################################################################
######################
# Boot
######################
########################################################################################
########################################################################################

sub app_name
{
	my ($self) = @_;

	return $app_name;
}

sub app_title
{
	my ($self) = @_;

	return $app_title;
}

sub manual_page_methods
{
	my ($self) = @_;

	return $manual_page_methods;
}

sub check_access
{
	my ($self, $attr) = @_;
	
	if($self->{params}->{method} eq 'showing_push_website_data')
	{
		my $session = Webkit::Session->new($self);
		
		$self->{session} = $session;
		$self->{org} = Webkit::MyOffice2::Org->constructor($self->{db});
		
		return 1;
	}
	else
	{
		return $self->SUPER::check_access($attr);
	}
}

########################################################################################
########################################################################################
######################
# USER ORG Inheritance
######################
########################################################################################
########################################################################################

sub load_org
{
	my ($self, $attr) = @_;

	return Webkit::MyOffice2::Org->load($self->{db}, $attr);
}

sub bless_org
{
	my ($self, $org) = @_;

	bless($org, 'Webkit::MyOffice2::Org');
}

sub bless_user
{
	my ($self, $user) = @_;

	bless($user, 'Webkit::MyOffice2::User');
}

sub get_org_classname
{
	return 'Webkit::MyOffice2::Org';
}

sub assign_objects
{
	my ($self) = @_;

	$self->SUPER::assign_objects;

	$self->load_tour;
}

sub load_tour
{
	my ($self) = @_;

	my $tour_id = $self->{session}->{tour_id};

	if($self->{params}->{switch_tour_id}>0)
	{
		$tour_id = $self->{params}->{switch_tour_id};

		$self->{session}->set('tour_id', $tour_id);
	}

	my $tour;

	if($tour_id!~/\d/)
	{
		$tour = $self->{org}->load_default_tour;
	}
	else
	{
		$tour = Webkit::MyOffice2::Tour->load($self->{db}, {
			id => $tour_id });
	}

	$self->{tour} = $tour;
	$self->{page}->add_static('tour', $tour);
	$self->{org}->{tour} = $tour;
}

########################################################################################
########################################################################################
######################
# LOGIN
######################
########################################################################################
########################################################################################

sub generate_window
{
	my ($self, $attr) = @_;

	my $href = $self->href;

	my $packet = $self->{page}->get_template('menu');

	my $jsmenu = Webkit::JSMenu->browser_new_with_content($packet, Webkit::Browser->new);

	my $props = {
		menu => $jsmenu->{text},
		href => $href };

	foreach my $key (keys %$attr)
	{
		$props->{$key} = $attr->{$key};
	}

	$props->{tour_options} = $self->{org}->get_tour_options;

	my $template_code = $self->{page}->get_template('window', $props);

	$self->{page}->{manual_page} = $template_code;
}

sub homepage_tree
{
	my ($self) = @_;

	$self->{page}->add_template('main_homepage_tree');
}

sub homepage_screen
{
	my ($self) = @_;

	$self->{org}->load_tours;
	$self->{org}->load_note_entries($self->{params});
	$self->{tour}->load_homepage_objects($self->{params});
	$self->{tour}->load_homepage_confirmed_objects($self->{params});

	$self->{page}->add_template('main_homepage');
}

sub homepage_screen_save_notes
{
	my ($self) = @_;

	my $note_entry = Webkit::MyOffice2::NoteEntry->constructor($self->{db});

	if($self->{params}->{note_entry_id}>0)
	{
		$note_entry = Webkit::MyOffice2::NoteEntry->load($self->{db}, {
			id => $self->{params}->{note_entry_id} });
	}
	else
	{
		$note_entry->org_id($self->{org}->get_id);
		$note_entry->users_id($self->{user}->get_id);
		$note_entry->created(Webkit::DateTime->now);
	}

	if($self->{params}->{date_value} =~ /\w/)
	{
		$note_entry->created(Webkit::DateTime->from_calendar($self->{params}->{date_value}));
	}

	$note_entry->content($self->{params}->{note_content});

	$self->{db}->begin_transaction;

	$note_entry->save_or_create;

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'homepage_screen' });
}

sub delete_note_entry
{
	my ($self) = @_;

	my $note = Webkit::MyOffice2::NoteEntry->load($self->{db}, {
		id => $self->{params}->{note_entry_id} });

	$self->{db}->begin_transaction;

	$note->delete;

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'homepage_screen' });
}

########################################################################################
########################################################################################
######################
# EDITORS
######################
########################################################################################
########################################################################################

sub editors_notes
{
	my ($self) = @_;

	my $value = $self->{params}->{value};

	if($self->{params}->{class}=~/\w/)
	{
		my $class = 'Webkit::MyOffice2::'.$self->{params}->{class};

		my $obj = &Webkit::DBObject::load($class, $self->{db}, {
			id => $self->{params}->{id} });

		$value = $obj->get_value($self->{params}->{field});
	}

	$self->{page}->add_template('editors_notes', {
		value => $value });
}

sub editors_notes_date
{
	my ($self) = @_;

	$self->{page}->add_template('editors_notes_date', {
		calendar => $self->{page}->get_template('calendar') });
}

sub editors_date
{
	my ($self) = @_;

	$self->{page}->add_template('editors_date', {
		calendar => $self->{page}->get_template('calendar') });
}

sub editors_daterange
{
	my ($self) = @_;

	$self->{page}->add_template('editors_daterange', {
		calendar => $self->{page}->get_template('calendar') });
}

sub editors_multidate
{
	my ($self) = @_;

	my $value = $self->{params}->{value};

	if($self->{params}->{class}=~/\w/)
	{
		my $class = 'Webkit::MyOffice2::'.$self->{params}->{class};

		my $obj = &Webkit::DBObject::load($class, $self->{db}, {
			id => $self->{params}->{id} });

		$value = $obj->get_value($self->{params}->{field});
	}

	$self->{page}->add_template('editors_multidate', {
		calendar => $self->{page}->get_template('calendar'),
		value => $value });
}

sub editors_multidate_submit
{
	my ($self) = @_;

	my @date_sts = split(/:/, $self->{params}->{date_string});
	my $dates;
	my $titles;
	my $epochs;

	foreach my $date_st (@date_sts)
	{
		my $date = Webkit::Date->from_calendar($date_st);
		push(@$dates, $date);
		push(@$titles, $date->get_string);
		push(@$epochs, $date->Epoch);
	}

	my $value = join(':', @$epochs);
	my $title = join(', <br>', @$titles);

	$self->{page}->ab(<<"+++");
<script>
var returnObj = new Object();

returnObj.value = '$value';
returnObj.title = '$title';

top.returnValue = returnObj;
top.close();
</script>
+++
}

sub editors_multidatenote_js_value
{
	my ($classname, $string) = @_;

	my @parts = split(/\+\+\+/, $string);
	my @refs;

	foreach my $part (@parts)
	{
		if($part!~/^[\w \/]{2,16}=/)
		{
			$part = 'na='.$part;
		}

		my ($date, $note) = split(/=/, $part);

		$note = Webkit::AppTools->js_quote($note);

		my $ref="{date:'$date',note:'$note'}";

		push(@refs, $ref);
	}

	my $joined = join(', ', @refs);

	my $ret="new Array($joined)";

	return $ret;
}

sub editors_number_text
{
	my ($self) = @_;

	$self->{page}->add_template('editors_numbertext');
}

sub editors_multidatenote
{
	my ($self) = @_;

	$self->{page}->add_template('editors_multidatenote', {
		calendar => $self->{page}->get_template('calendar') });
}

sub editors_multiprice
{
	my ($self) = @_;

	my $value = $self->{params}->{value};

	if($self->{params}->{class}=~/\w/)
	{
		my $class = 'Webkit::MyOffice2::'.$self->{params}->{class};

		my $obj = &Webkit::DBObject::load($class, $self->{db}, {
			id => $self->{params}->{id} });

		$value = $obj->get_value($self->{params}->{field});
	}

	$self->{page}->add_template('editors_multiprice', {
		value => $value });
}

sub editors_datetime
{
	my ($self) = @_;

	my $value = $self->{params}->{value};

	if($self->{params}->{class}=~/\w/)
	{
		my $class = 'Webkit::MyOffice2::'.$self->{params}->{class};

		my $obj = &Webkit::DBObject::load($class, $self->{db}, {
			id => $self->{params}->{id} });

		if($self->{params}->{field}=~/\w/)
		{
			$value = $obj->get_value($self->{params}->{field});
			$value = $value->Epoch;
		}
		elsif($self->{params}->{obj_method}=~/\w/)
		{
			my $method = $self->{params}->{obj_method};

			$value = $obj->$method;
		}

		if($value)
		{
			$value = $value->Epoch;
		}
		else
		{
			$value = Webkit::DateTime->now->Epoch;
		}
	}

	$self->{page}->add_template('editors_datetime', {
		calendar => $self->{page}->get_template('calendar'),
		value => $value });
}

########################################################################################
########################################################################################
######################
# MODAL WINDOWS
######################
########################################################################################
########################################################################################

sub modal_timeline_frame
{
	my ($self, $from_date, $to_date) = @_;

	my $from_st;
	my $to_st;

	if(!$from_date)
	{
		if($self->{session}->{booking_timeline_from}=~/\w/)
		{
			$from_st = $self->{session}->{booking_timeline_from};
			$to_st = $self->{session}->{booking_timeline_to};
		}
		else
		{
			$from_date = Webkit::Date->now;
			$to_date = Webkit::Date->now;

			$from_date->epoch_days();
			$to_date->epoch_days(90);

			$from_st = $from_date->get_string;
			$to_st = $to_date->get_string;
		}
	}
	else
	{
		$from_st = $from_date->get_string;
		$to_st = $to_date->get_string;
	}

	$self->{page}->add_template('modal_timeline_frame', {
		tour_options => $self->{org}->get_tour_options($self->{tour}->get_id),
		from => $from_st,
		to => $to_st,
		calendar => $self->{page}->get_template('calendar') });
}

sub modal_timeline_page
{
	my ($self) = @_;

	my $tour = $self->{tour};

	if($self->{params}->{tour_id}>0)
	{
		$tour = Webkit::MyOffice2::Tour->load($self->{db}, {
			id => $self->{params}->{tour_id} });

		$self->{page}->add_static('tour', $tour);
	}

	$self->{session}->set('booking_timeline_from', $self->{params}->{from});
	$self->{session}->set('booking_timeline_to', $self->{params}->{to});

	if($self->{params}->{view} eq 'not_booked')
	{
		$tour->load_modal_timeline_not_booked_objects($self->{params});

		$self->{page}->add_template('modal_timeline_not_booked');
	}
	else
	{
		$tour->load_modal_timeline_booked_objects($self->{params});
		$self->{org}->load_tours;

		$self->{page}->add_template('modal_timeline_page');
	}
}

sub modal_venue_status_reset_search
{
	my ($self) = @_;

	$self->{session}->delete('venue_status_search_params');

	$self->{page}->add_redir({
		method => 'modal_venue_status_search' });
}

sub modal_venue_status_search
{
	my ($self) = @_;

	my $params = $self->{session}->{venue_status_search_params};

	$self->{params} = $params;
	$self->{page}->add_static('params', $params);

	$self->{page}->add_template('modal_venue_status_search', {
		calendar => $self->{page}->get_template('calendar') });
}

sub modal_venue_status_search_results
{
	my ($self) = @_;

	if($self->{params}->{from_session}=~/\w/)
	{
		my $params = $self->{session}->{venue_status_search_params};

		$self->{params} = $params;
		$self->{page}->add_static('params', $params);
	}
	else
	{
		$self->{session}->set('venue_status_search_params', $self->{params});
	}

	$self->{tour}->load_venue_status_search($self->{params});

	$self->{org}->load_tours;

	$self->{page}->add_template('modal_venue_status_search_results');
}

sub modal_search_venues_frame
{
	my ($self) = @_;

	$self->{page}->add_template('modal_search_venues_frame');
}

sub modal_search_venues_page
{
	my ($self) = @_;

	if($self->{params}->{no_search}!~/\w/)
	{
		$self->{org}->load_venues($self->{params});
	}

	$self->{page}->add_template('modal_search_venues_page');
}

sub modal_find_showing_frame
{
	my ($self) = @_;

	$self->{params}->{submit_method} = 'modal_find_showing_frame_submit';

	$self->{page}->add_template('modal_search_venues_frame', {
		no_tour => 1 });
}

sub modal_find_showing_frame_submit
{
	my ($self) = @_;

	my $venue = $self->venue_get_venue;

	$venue->load_showings_and_tourdates;
	$self->{org}->load_tours;

	$self->{page}->add_template('modal_find_showing_page', {
		venue => $venue });
}

########################################################################################
########################################################################################
######################
# TOUR
######################
########################################################################################
########################################################################################

sub tour_home
{
	my ($self) = @_;

	my $defs = [
		{	title => 'Name',
			prop => 'name',
			width => '*' },

		{	title => 'Country',
			method => 'get_country_name',
			width => '140' },

		{	title => 'Type',
			method => 'get_type_title',
			width => '100' } ];

	my $buttons = [
		{	key => 'add',
			title => 'Add Tour',
			normal_method => 'tour_form' },
		{	key => 'edit',
			title => 'Edit Tour',
			method => 'tour_form' },
		{	key => 'delete',
			title => 'Delete Tour',
			method => 'tour_delete_tour' } ];

	$self->{org}->load_tours_with_countries;

	$self->{page}->add_template('object_list', {
		title => 'Current Tours',
		defs => $defs,
		object_tag => 'tour',
		objects => $self->{org}->get_child_array('tour'),
		button_refs => $buttons });

}

sub tour_get_tour
{
	my ($self) = @_;

	my $tour;

	if($self->{params}->{tour_id}>0)
	{
		$tour = Webkit::MyOffice2::Tour->load($self->{db}, {
			id => $self->{params}->{tour_id} });
	}
	else
	{
		$tour = Webkit::MyOffice2::Tour->constructor($self->{db});
		$tour->org_id($self->{org}->get_id);
	}

	return $tour;
}

sub tour_form
{
	my ($self, $tour) = @_;

	if(!$tour)
	{
		$tour = $self->tour_get_tour;
	}

	$self->{page}->add_static('tour', $tour);

	$self->{page}->add_template('tour_form', {
		tour => $tour });
}

sub tour_form_submit
{
	my ($self) = @_;

	my $tour = $self->tour_get_tour;

	$tour->save_form_params($self->{params});

	if($tour->error)
	{
		$self->tour_form($tour);
		return;
	}
	else
	{
		$self->{db}->begin_transaction;

		$tour->save_or_create;

		$self->{db}->commit;

		$self->{page}->add_redir({
			method => 'tour_home' });
	}
}

sub tour_delete_tour
{
	my ($self) = @_;

	my $tour = $self->tour_get_tour;

	my $message=<<"+++";
<span style="font-size:18pt;">Are you sure you want to delete this tour?</span><p>
This will remove the following objects that are linked to it:<br><br>
Bookings<br>
Tourdates<br>
Showings<br>
Deals<br>
Print<br>
Sales Figures<br>
<br>

<b style="color:red;">Are you absolutely sure?</b>
+++

	$self->{page}->add_template('general_confirm', {
		title => 'Delete '.$tour->name,
		message => $message,
		object_id => $tour->get_id,
		confirm_method => 'tour_delete_tour_submit',
		cancel_method => 'tour_home' });
}

sub tour_delete_tour_submit
{
	my ($self) = @_;

	my $tour = Webkit::MyOffice2::Tour->load($self->{db}, {
		id => $self->{params}->{object_id} });

	$self->{db}->begin_transaction;

	$tour->delete_children('Webkit::MyOffice2::Booking');
	$tour->delete_children('Webkit::MyOffice2::Tourdate');
	$tour->delete_children('Webkit::MyOffice2::Showing');
	$tour->delete_children('Webkit::MyOffice2::Deal');
	$tour->delete_children('Webkit::MyOffice2::Print');
	$tour->delete_children('Webkit::MyOffice2::PrintRun');
	$tour->delete_children('Webkit::MyOffice2::SalesFiguresEntry');
	$tour->delete_children('Webkit::MyOffice2::SalesFigures');

	$tour->delete;

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'tour_home' });
}

########################################################################################
########################################################################################
######################
# VENUE
######################
########################################################################################
########################################################################################

sub venue_home
{
	my ($self) = @_;

	my $defs = [
		{	title => 'Capacity',
			prop => 'capacity',
			align => 'right',
			width => '70' },

		{	title => 'City',
			prop => 'city',
			width => '140' },

		{	title => 'Name',
			prop => 'name',
			width => '*' },

		{	title => 'Admin Number',
			prop => 'admin_number',
			width => '160' },

		{	title => 'Box Office Number',
			prop => 'box_office_number',
			width => '160' } ];

	my $buttons = [
		{	key => 'edit',
			title => 'Edit Venue',
			method => 'venue_form' },
		{	key => 'delete',
			title => 'Delete Venue',
			method => 'venue_delete_venue' },
		{	key => 'add',
					title => 'Add Venue',
					normal_method => 'venue_form' } ];

	$self->{tour}->load_venues($self->{params});

	my $extra_table = $self->{page}->get_template('venue_home');

	$self->{page}->add_template('object_list', {
		extra_table => $extra_table,
		title => 'Current Venues',
		search_submit_method => 'venue_home',
		defs => $defs,
		object_tag => 'venue',
		objects => $self->{tour}->get_child_array('venue'),
		button_refs => $buttons });

}

sub venue_get_venue
{
	my ($self, $id) = @_;

	if($id!~/\d/)
	{
		$id = $self->{params}->{venue_id};
	}

	my $venue;

	if($id>0)
	{
		$venue = Webkit::MyOffice2::Venue->load($self->{db}, {
			id => $id });
	}
	else
	{
		$venue = Webkit::MyOffice2::Venue->constructor($self->{db});
		$venue->org_id($self->{org}->get_id);
	}

	return $venue;
}

sub venue_form
{
	my ($self, $venue) = @_;

	if(!$venue)
	{
		$venue = $self->venue_get_venue;
	}

	if($venue->exists)
	{
		$venue->load_contacts;
		$venue->load_booking_notes;
		$venue->load_last_booking_per_tour;
		$venue->load_showings_and_tourdates_by_tour;
	}

	$self->{org}->load_tours;

	$self->{page}->add_template('venue_form', {
		modal => $self->{params}->{modal},
		venue => $venue });
}

sub venue_form_submit
{
	my ($self) = @_;

	my $venue = $self->venue_get_venue;

	$venue->tour_id(1);

	$venue->save_form_params($self->{params});

	if($venue->error)
	{
		$self->venue_form($venue);
	}
	else
	{
		$self->{db}->begin_transaction;

		$venue->save_or_create;

		$self->{db}->commit;

		if($self->{params}->{modal}=~/\w/)
		{
			$self->{page}->ab(<<"+++");
<script>
top.close();
</script>
+++
		}
		else
		{
			my $search = $venue->get_city_first_letter.'%';

			$self->{page}->add_redir({
				search => $search,
				method => 'venue_home' });
		}
	}
}

sub venue_delete_venue
{
	my ($self) = @_;

	my $venue = $self->venue_get_venue;

	my $message=<<"+++";
WARNING - do not remove this venue if there are other things (like bookings & showings linked to it!!!!)<p>

<b style="color:red;">Are you absolutely sure?</b>
+++

	$self->{page}->add_template('general_confirm', {
		title => 'Delete '.$venue->get_city_title,
		message => $message,
		object_id => $venue->get_id,
		confirm_method => 'venue_delete_venue_submit',
		cancel_method => 'venue_home' });
}

sub venue_delete_venue_submit
{
	my ($self) = @_;

	my $venue = $self->venue_get_venue($self->{params}->{object_id});

	$self->{db}->begin_transaction;

	$venue->delete_children('Webkit::MyOffice2::Contact');

	$venue->delete;

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'venue_home' });
}

sub venue_info_window
{
	my ($self) = @_;

	$self->{params}->{modal} = 1;

	$self->venue_form;
}

########################################################################################
########################################################################################
######################
# BOOKING REPORT
######################
########################################################################################
########################################################################################

sub booking_report_tree
{
	my ($self) = @_;

	if(($self->{params}->{search}=~/\w/)||($self->{params}->{start_letter}=~/\w/))
	{
		$self->{params}->{only_venues} = 1;
		$self->{tour}->load_booking_report($self->{params});
	}

	$self->{page}->add_template('booking_report_tree');
}

sub booking_report_toolbar
{
	my ($self) = @_;

	$self->{page}->{manual_page} = $self->{page}->get_template('booking_report_toolbar');
}

sub booking_report_sheet
{
	my ($self) = @_;

	$self->{tour}->load_booking_report($self->{params});
	$self->{org}->load_tours;

	$self->{page}->add_template('booking_report_sheet');
}

sub booking_report_toolbar_save
{
	my ($self) = @_;

	my $data = $self->{params}->{data};

	my $formparams;

	while($data =~ /<field name="(.*?)">(.*?)<\/field>/gsi)
	{
		$formparams->{$1} = $2;

		$data =~ s/<field name="(.*?)">(.*?)<\/field>//si;
	}

	$self->{db}->begin_transaction;

	foreach my $key (keys %$formparams)
	{
		if($key =~ /^booking_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};
			my $field = $2;

			my $booking = Webkit::MyOffice2::Booking->load($self->{db}, {
				id => $1 });

			if($field eq 'notes')
			{
				my $notes = Webkit::MyOffice2::BookingNotes->load($self->{db}, {
					clause => "venue_id = ? and tour_id = ?",
					binds => [$booking->venue_id, $booking->tour_id] });

				if(!$notes)
				{
					$notes = Webkit::MyOffice2::BookingNotes->constructor($self->{db});
					$notes->org_id($booking->org_id);
					$notes->tour_id($booking->tour_id);
					$notes->venue_id($booking->venue_id);
				}

				$notes->notes($value);

				$notes->save_or_create;
			}
			else
			{
				$booking->set_value($field, $value);
				$booking->save;
			}
		}
	}

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => $self->{params}->{redirect} });
}
########################################################################################
########################################################################################
######################
# BOOKING
######################
########################################################################################
########################################################################################

sub booking_get_booking
{
	my ($self, $id) = @_;

	if($id!~/\d/)
	{
		$id = $self->{params}->{booking_id};
	}

	my $booking;

	if($id>0)
	{
		$booking = Webkit::MyOffice2::Booking->load($self->{db}, {
			id => $id });
	}
	else
	{
		$booking = Webkit::MyOffice2::Booking->constructor($self->{db});
		$booking->org_id($self->{org}->get_id);
		$booking->created(Webkit::DateTime->now);
		
	}

	return $booking;
}

sub booking_progress_tree
{
	my ($self) = @_;

	$self->{tour}->load_booking_progress_objects;

	$self->{page}->add_template('booking_progress_tree');
}

sub booking_progress_sheet_toolbar
{
	my ($self) = @_;

	$self->{page}->{manual_page} = $self->{page}->get_template('booking_progress_sheet_toolbar');
}

sub booking_progress_sheet
{
	my ($self) = @_;

	$self->{tour}->load_booking_progress_objects($self->{params});
	$self->{org}->load_tours;

	$self->{page}->add_template('booking_progress_sheet');
}

sub booking_sheet_toolbar_save
{
	my ($self) = @_;

	my $data = $self->{params}->{data};

	my $formparams;

	while($data =~ /<field name="(\w+)">(.*?)<\/field>/gsi)
	{
		$formparams->{$1} = $2;

		$data =~ s/<field name="(\w+)">(.*?)<\/field>//si;
	}

	$self->{db}->begin_transaction;

	foreach my $key (keys %$formparams)
	{
		if($key =~ /^booking_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};
			my $field = $2;

			my $booking = Webkit::MyOffice2::Booking->load($self->{db}, {
				id => $1 });

			if($field eq 'notes')
			{
				my $notes = Webkit::MyOffice2::BookingNotes->load($self->{db}, {
					clause => "venue_id = ? and tour_id = ?",
					binds => [$booking->venue_id, $booking->tour_id] });

				if(!$notes)
				{
					$notes = Webkit::MyOffice2::BookingNotes->constructor($self->{db});
					$notes->org_id($booking->org_id);
					$notes->tour_id($booking->tour_id);
					$notes->venue_id($booking->venue_id);
				}

				$notes->notes($value);

				$notes->save_or_create;
			}
			else
			{
				$booking->set_value($field, $value);
				$booking->save;
			}
		}

		if($key =~ /^venue_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $venue = Webkit::MyOffice2::Venue->load($self->{db}, {
				id => $1 });

			$venue->set_value($2, $value);
			$venue->save;
		}
	}

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => $self->{params}->{redirect} });
}

sub booking_penciled_tree
{
	my ($self) = @_;

	$self->{tour}->load_booking_penciled_objects;

	$self->{page}->add_template('booking_penciled_tree');
}

sub booking_penciled_sheet_toolbar
{
	my ($self) = @_;

	$self->{page}->{manual_page} = $self->{page}->get_template('booking_penciled_sheet_toolbar');
}

sub booking_penciled_sheet
{
	my ($self) = @_;

	$self->{tour}->load_booking_penciled_objects($self->{params});
	$self->{org}->load_tours;

	$self->{page}->add_template('booking_penciled_sheet');

	#$self->{page}->ab($self->{db}->get_log);
}

sub booking_fail_pencil_booking_submit
{
	my ($self) = @_;

	my $booking = $self->booking_get_booking($self->{params}->{object_id});

	$booking->load_tourdates;
	
	my $failed_date = Webkit::Date->now;

	my $failed_date_st = $failed_date->get_calendar_string;

	$self->{db}->begin_transaction;

	my $notes_obj = $booking->ensure_booking_notes;

	my $notes = $notes_obj->notes;

	$notes.=<<"+++";
------------
Pencil Booking FAILED On - $failed_date_st
------------

+++

	$notes_obj->notes($notes);
	$notes_obj->save;

	$booking->set_value('notes', $notes);

	$booking->set_value('penciled', '');
	$booking->add_date_called_entry($failed_date_st, 'Pencil Booking Failed');

	$booking->save;
	
	foreach my $tourdate (@{$booking->ensure_child_array('tourdate')})
	{
		$tourdate->delete;
	}

	$self->{db}->commit;
	
	$self->{page}->ab(<<"+++");
<script>
	alert('The booking has been failed - now moving to booking progress where the booking has been placed');
	top.get_double_frameset('myoffice2_booking_progress&filter=all');
</script>
+++
}

### This is no longer used!!!

sub booking_fail_booking_submit
{
	my ($self) = @_;

	return;

	my $booking = $self->booking_get_booking($self->{params}->{object_id});

	$self->{db}->begin_transaction;

	$booking->failed(Webkit::DateTime->now);
	$booking->save;
	
	$self->{db}->commit;

	my $method = 'booking_progress_sheet';
	my $venue_id = $booking->venue_id;

	if($self->{params}->{redirect}=~/\w/)
	{
		$method = $self->{params}->{redirect};
	}

	if($self->{params}->{no_venue}=~/\w/)
	{
		$venue_id = undef;
	}

	$self->{page}->ab(<<"+++");
<script>
	alert('The booking has been failed - now moving to booking progress where the booking has been placed');
	top.get_double_frameset('myoffice2_booking_progress&filter=failed');
</script>
+++

#	$self->{page}->add_redir({
#		method => $method,
#		filter => 'all',
#		venue_id => $self->{params}->{venue_id},
#		booking_id => $self->{params}->{booking_id} });	
}

sub booking_delete_booking_submit
{
	my ($self) = @_;

	my $booking = $self->booking_get_booking($self->{params}->{object_id});

	$self->{db}->begin_transaction;

	$booking->delete_children('Webkit::MyOffice2::Tourdate');
	$booking->delete;
	
	$self->{db}->commit;

	my $method = 'booking_progress_sheet';
	my $venue_id = $booking->venue_id;

	if($self->{params}->{redirect}=~/\w/)
	{
		$method = $self->{params}->{redirect};
	}

	if($self->{params}->{no_venue}=~/\w/)
	{
		$venue_id = undef;
	}

	$self->{page}->ab(<<"+++");
<script>
	top.appContent.sidebar.frames[1].document.location.reload();
</script>
+++

	$self->{page}->add_redir({
		venue_id => $self->{params}->{venue_id},
		booking_id => $self->{params}->{booking_id},
		filter => 'all',
		method => $method });	
}

sub booking_add_booking
{
	my ($self) = @_;

	my $options;

	if(!$self->{tour}->is_normal)
	{
		$options->{tour_options} = $self->{org}->get_normal_tour_options;
	}

	$self->{params}->{submit_method} = 'booking_add_booking_submit';

	$self->{page}->add_template('modal_search_venues_frame', $options);
}

sub booking_add_booking_submit
{
	my ($self) = @_;

	my $venue = $self->venue_get_venue;
	my $venue_id = $venue->get_id;

	my $booking = Webkit::MyOffice2::Booking->constructor($self->{db});
	$booking->org_id($self->{org}->get_id);
	$booking->created(Webkit::DateTime->now);
	$booking->venue_id($venue->get_id);
	$booking->tour_id($self->{params}->{tour_id});
#	$booking->notes($venue->booking_notes);

	$self->{db}->begin_transaction;

	$booking->create;

	$self->{db}->commit;

	$self->{page}->ab(<<"+++")
<script>
	top.returnValue = $venue_id;
	top.close();
</script>
+++
}

sub booking_add_tourdate_timeline
{
	my ($self) = @_;

	my $tourdate = Webkit::Date->new($self->{params}->{tourdate_epoch});

	my $from_date = $tourdate->clone;
	my $to_date = $tourdate->clone;

	$from_date->epoch_days(-7);
	$to_date->epoch_days(7);

	my $date_st = $tourdate->get_string;

	my $message=<<"+++";
Click OK if you want to add the date to $date_st
+++

	$self->{params}->{confirmMessage} = $message;

	$self->modal_timeline_frame($from_date, $to_date);
}

sub booking_delete_tourdate_submit
{
	my ($self) = @_;

	my $tourdate = Webkit::MyOffice2::Tourdate->load($self->{db}, {
		id => $self->{params}->{tourdate_id}});

	my $booking = Webkit::MyOffice2::Booking->load($self->{db}, {
		id => $tourdate->booking_id });

	$self->{db}->begin_transaction;

	$tourdate->delete;

	$self->{db}->commit;

	$self->{page}->add_redir({
		venue_id => $self->{params}->{venue_id},
		method => 'booking_penciled_sheet' });
}

sub booking_edit_tourdate_submit
{
	my ($self) = @_;

	my $date = Webkit::Date->from_calendar($self->{params}->{tourdate_date});

	my ($hour, $min) = split(/:/, $self->{params}->{tourdate_time});

	my $time = Webkit::Time->new;

	$time->Hour($hour);
	$time->Min($min);

	my $tourdate = Webkit::MyOffice2::Tourdate->load($self->{db}, {
		id => $self->{params}->{tourdate_id} });

	my $booking = Webkit::MyOffice2::Booking->load($self->{db}, {
		id => $tourdate->booking_id });

	$tourdate->date($date);
	$tourdate->time($time);

	$self->{db}->begin_transaction;

	$tourdate->save;

	$self->{db}->commit;

	$self->{page}->add_redir({
		venue_id => $self->{params}->{venue_id},
		method => 'booking_penciled_sheet' });
}

sub booking_add_tourdate_submit
{
	my ($self) = @_;

	my $date = Webkit::Date->from_calendar($self->{params}->{tourdate_date});

	my ($hour, $min) = split(/:/, $self->{params}->{tourdate_time});

	my $time = Webkit::Time->new;

	$time->Hour($hour);
	$time->Min($min);

	my $booking = $self->booking_get_booking;

	my $tourdate = Webkit::MyOffice2::Tourdate->constructor($self->{db});
	$tourdate->org_id($self->{org}->get_id);
	$tourdate->booking_id($booking->get_id);
	$tourdate->showing_id(0);
	$tourdate->tour_id($booking->tour_id);
	$tourdate->date($date);
	$tourdate->time($time);

	$self->{db}->begin_transaction;

	$tourdate->create;

	$self->{db}->commit;

	$self->{session}->set('booking_add_tourdate_epoch', $self->{params}->{tourdate_epoch});

	$self->{page}->add_redir({
		venue_id => $self->{params}->{venue_id},
		method => 'booking_penciled_sheet' });
}

sub booking_add_pencil_date_submit
{
	my ($self) = @_;

	my $date = Webkit::Date->from_calendar($self->{params}->{tourdate_date});

	my ($hour, $min) = split(/:/, $self->{params}->{tourdate_time});

	my $time = Webkit::Time->new;

	$time->Hour($hour);
	$time->Min($min);

	my $booking = $self->booking_get_booking;

	my $tourdate = Webkit::MyOffice2::Tourdate->constructor($self->{db});
	$tourdate->org_id($self->{org}->get_id);
	$tourdate->booking_id($booking->get_id);
	$tourdate->showing_id(0);
	$tourdate->tour_id($booking->tour_id);
	$tourdate->date($date);
	$tourdate->time($time);

	$booking->penciled(Webkit::DateTime->now);

	my $deal = $booking->construct_deal;

	$self->{db}->begin_transaction;

	$tourdate->create;
	$booking->save;

	$self->{db}->commit;

	$self->{session}->set('booking_add_tourdate_epoch', $self->{params}->{tourdate_epoch});

	$self->{page}->add_redir({
		venue_id => $self->{params}->{venue_id},
		method => 'booking_penciled_sheet' });
}

sub booking_view_dealsheet_redirect
{
	my ($self) = @_;

	my $showing = $self->showing_get_showing;
	$showing->load_tourdates;

	my $showing_id = $showing->get_id;

	my $tourdate = $showing->get_first_tourdate;
	my $date = $tourdate->date;

	my $from = $date->clone;
	my $to = $date->clone;

	$from->epoch_days(-15);
	$to->epoch_days(15);

	my $from_st = $from->get_string;
	my $to_st = $to->get_string;

	my $session_id = $self->session_id;

	$self->{session}->set('tour_id', $showing->tour_id);

	my $url = "/htmlhub/frames_double?session_id=$session_id&frameset_key=myoffice2_tourlist&page_method=deal_form&showing_id=$showing_id&from=$from_st&to=$to_st";

	$self->{page}->ab(<<"+++");
Re-directing...
<script>
	document.location = '$url';
</script>
+++
}

sub booking_deal_summary
{
	my ($self) = @_;

	my $showing = $self->showing_get_showing;
	my $booking = $showing->load_booking;
	my $deal = $showing->load_deal;

	$self->{params}->{summary_mode} = 1;

	$self->booking_create_dealsheet($booking, $deal);
}

sub booking_create_dealsheet
{
	my ($self, $booking, $deal) = @_;

	if(!$booking)
	{
		$booking = $self->booking_get_booking;
	}

	if(!$deal)
	{
		$deal = $booking->construct_deal;
	}

	$booking->load_tourdates;
	my $venue = $booking->load_venue;

	$deal->calculate($booking, $venue);

	my $booking_tour = Webkit::MyOffice2::Tour->load($self->{db}, {
		id => $booking->tour_id });

	$self->{page}->add_template('deal_form', {
		booking_tour => $booking_tour,
		calendar => $self->{page}->get_template('calendar'),
		venue => $venue,
		booking => $booking,
		deal => $deal });
}

sub booking_create_dealsheet_submit
{
	my ($self) = @_;

	my $booking = $self->booking_get_booking;
	$booking->load_tourdates;
	$booking->load_venue_status_entries;

	my $deal;

	if($self->{params}->{deal_id}>0)
	{
		$deal = Webkit::MyOffice2::Deal->load($self->{db}, {
			id => $self->{params}->{deal_id} });
	}
	else
	{
		$deal = $booking->construct_deal;
	}

	$deal->save_form_params($booking, $self->{params});

	if($deal->error)
	{
		$self->booking_create_dealsheet($booking, $deal);
	}
	elsif($booking->error)
	{
		$deal->{error_text} = $booking->{error_text};

		$self->booking_create_dealsheet($booking, $deal);
	}
	else
	{
		$self->{db}->begin_transaction;

		if(!$deal->exists)
		{
			$deal->create;

			my $showing = $self->showing_get_showing;

			$showing->tour_id($booking->tour_id);
			$showing->booking_id($booking->get_id);
			$showing->venue_id($booking->venue_id);
			$showing->deal_id($deal->get_id);

			$showing->create;

			$booking->agreed(Webkit::DateTime->now);

			$booking->save;

			foreach my $entry (@{$booking->ensure_child_array('venue_status_entry')})
			{
				$entry->showing_id($showing->get_id);
				$entry->save;
			}

			foreach my $tourdate (@{$booking->ensure_child_array('tourdate')})
			{
				$tourdate->showing_id($showing->get_id);
				$tourdate->save;

				my $sales_entry = Webkit::MyOffice2::SalesFiguresEntry->constructor($self->{db});
				$sales_entry->org_id($booking->org_id);
				$sales_entry->tour_id($booking->tour_id);
				$sales_entry->tourdate_id($tourdate->get_id);

				$sales_entry->create;
			}
		}
		else
		{
			$deal->save;
			$booking->save;
		}

		$self->{db}->commit;

		if($self->{params}->{modal}=~/\w/)
		{
			$self->{page}->ab(<<"+++");
Closing window...
<script>
	top.close();
</script>
+++
		}
		elsif($self->{params}->{summary_mode}=~/\w/)
		{
			$self->{page}->ab(<<"+++");
Re-directing
<script>
	document.location = href + '&method=tourlist_sheet';
</script>
+++
		}
		else
		{
			my $tourdate = $booking->get_first_tourdate;

			my $date = $tourdate->date;
			my $from = $date->clone;
			my $to = $date->clone;

			$from->epoch_days(-7);
			$to->epoch_days(7);

			my $from_st = $from->get_string;
			my $to_st = $to->get_string;

			$self->{page}->ab(<<"+++");
Re-directing
<script>
top.get_double_frameset('myoffice2_tourlist&from=$from_st&to=$to_st');
</script>
+++
		}
	}
}

########################################################################################
########################################################################################
######################
# TOURLIST
######################
########################################################################################
########################################################################################

sub tourlist_frameset_proxy
{
	my ($self) = @_;

	my $page_method = $self->{params}->{page_method};

	if($page_method eq 'deal_form')
	{
		$self->booking_deal_summary;
	}
	else
	{
		$self->tourlist_sheet;
	}
}

sub tourlist_toolbar
{
	my ($self) = @_;

	if($self->{params}->{from}!~/\w/)
	{
		if($self->{session}->{tourlist_from})
		{
			$self->{params}->{from} = $self->{session}->{tourlist_from};
			$self->{params}->{to} = $self->{session}->{tourlist_to};
		}
		else
		{
			my $from = Webkit::Date->now;
			my $to = Webkit::Date->now;

			$to->epoch_days(90);

			$self->{params}->{from} = $from->get_string;
			$self->{params}->{to} = $to->get_string;
		}
	}

	$self->{page}->{manual_page} = $self->{page}->get_template('tourlist_toolbar', {
		from => $self->{params}->{from},
		to => $self->{params}->{to} });
}

sub tourlist_tree
{
	my ($self) = @_;

	if($self->{params}->{from}!~/\w/)
	{
		if($self->{session}->{tourlist_from})
		{
			$self->{params}->{from} = $self->{session}->{tourlist_from};
			$self->{params}->{to} = $self->{session}->{tourlist_to};
		}
		else
		{
			my $from = Webkit::Date->now;
			my $to = Webkit::Date->now;

			$to->epoch_days(90);

			$self->{params}->{from} = $from->get_string;
			$self->{params}->{to} = $to->get_string;
		}
	}

	my $tour = $self->{tour};

	$self->{params}->{load_with_bookings} = 1;

	$tour->load_modal_timeline_booked_objects($self->{params});
	$self->{org}->load_tours;

	$self->{page}->add_template('tourlist_tree');

	#$self->{page}->ab($self->{db}->get_log);
}

sub tourlist_sheet
{
	my ($self) = @_;

	if($self->{params}->{from}!~/\w/)
	{
		if($self->{session}->{tourlist_from})
		{
			$self->{params}->{from} = $self->{session}->{tourlist_from};
			$self->{params}->{to} = $self->{session}->{tourlist_to};
		}
		else
		{
			my $from = Webkit::Date->now;
			my $to = Webkit::Date->now;

			$to->epoch_days(90);

			$self->{params}->{from} = $from->get_string;
			$self->{params}->{to} = $to->get_string;
		}
	}
	else
	{
		$self->{session}->set('tourlist_from', $self->{params}->{from});
		$self->{session}->set('tourlist_to', $self->{params}->{to});
	}

	$self->{tour}->load_tourlist_objects($self->{params});
	$self->{org}->load_tours;

	$self->{page}->add_template('tourlist_sheet');

	#$self->{page}->ab($self->{db}->get_log);
}

sub tourlist_toolbar_save
{
	my ($self) = @_;

	$self->{db}->begin_transaction;

	my $data = $self->{params}->{data};

	my $formparams;

	while($data =~ /<field name="(\w+)">(.*?)<\/field>/gsi)
	{
		$formparams->{$1} = $2;

		$data =~ s/<field name="(\w+)">(.*?)<\/field>//si;
	}

	foreach my $key (keys %$formparams)
	{
		if($key =~ /^booking_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $booking = Webkit::MyOffice2::Booking->load($self->{db}, {
				id => $1 });

			$booking->set_value($2, $value);
			$booking->save;
		}

		if($key =~ /^tourdate_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $tourdate = Webkit::MyOffice2::Tourdate->load($self->{db}, {
				id => $1 });

			$tourdate->set_value($2, $value);
			$tourdate->save;
		}

		if($key =~ /^showing_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $showing = Webkit::MyOffice2::Showing->load($self->{db}, {
				id => $1 });

			my $field = $2;

			if($field eq 'technical_rider_dates')
			{
				my ($from, $to) = split(/:/, $value);

				$showing->set_calendar_value('technical_rider_date', $from);
				$showing->set_calendar_value('technical_rider_date_rcvd', $to);
			}
			else
			{
				$showing->set_value($field, $value);
			}

			$showing->save;
		}
	}

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'tourlist_toolbar' });
}

sub tourlist_excel_sheet
{
	my ($self) = @_;

	if($self->{params}->{from}!~/\w/)
	{
		if($self->{session}->{tourlist_from})
		{
			$self->{params}->{from} = $self->{session}->{tourlist_from};
			$self->{params}->{to} = $self->{session}->{tourlist_to};
		}
		else
		{
			my $from = Webkit::Date->now;
			my $to = Webkit::Date->now;

			$to->epoch_days(90);

			$self->{params}->{from} = $from->get_string;
			$self->{params}->{to} = $to->get_string;
		}
	}

	$self->{tour}->load_tourlist_objects($self->{params});
	$self->{org}->load_tours;

	my $spreadsheet = Webkit::MyOffice2::TourlistExcelSheet->new($self->{org}, $self->{tour});

	$spreadsheet->generate;

	my $filecontent = $spreadsheet->get_file_contents;
	my $length = length($filecontent);
	my $filename = $spreadsheet->get_filename;
	my $mime = $spreadsheet->get_mime_type;

	my $header=<<"+++";
Content-type: $mime
Content-length: $length
Content-Disposition: attachment;filename="$filename"

+++

	print $header;

	print $filecontent;
}

sub tourlist_assign_staff
{
	my ($self) = @_;

	my $tourdate = Webkit::MyOffice2::Tourdate->load($self->{db}, {
		id => $self->{params}->{tourdate_id} });

	my $tour = Webkit::MyOffice2::Tour->load($self->{db}, {
		id => $tourdate->tour_id });

	my $showing = $tourdate->load_showing;
	my $venue = $showing->load_venue;

	$self->{page}->add_template('modal_assign_tourdate_staff', {
		venue => $venue,
		pagetour => $tour,
		showing => $showing,
		tourdate => $tourdate });
}

sub tourlist_assign_staff_submit
{
	my ($self) = @_;

	my $tourdate = Webkit::MyOffice2::Tourdate->load($self->{db}, {
		id => $self->{params}->{tourdate_id} });

	$tourdate->save_staff_params($self->{params});

	$self->{db}->begin_transaction;

	$tourdate->save;

	$self->{db}->commit;

	my $ret = $tourdate->get_staff_string($self->{tour}->get_staff_hash);

	$ret = Webkit::AppTools->js_quote($ret);

	$self->{page}->ab(<<"+++");
<script>
	top.returnValue = '$ret';
	top.close();
</script>
+++
}

sub tourlist_add_staff_submit
{
	my ($self) = @_;

	my $name = $self->{params}->{staffname};

	if($name=~/\w/)
	{
		my $firstname = ' ';
		my $surname = ' ';

		if($name =~ /^(\w+) (.*?)$/)
		{
			$firstname = $1;
			$surname = $2;
		}
		
		if($firstname!~/\w/)
		{
			$firstname = $self->{params}->{staffname};
		}
		
		
		my $user = Webkit::MyOffice2::MyOfficeUser->constructor($self->{db});

		my $username = lc($name);
		$username =~ s/\W//g;

		$user->org_id($self->{org}->get_id);
		$user->username($username);
		$user->password_id(0);
		$user->tour_id(1);
		$user->active('y');
		$user->default_tour_id(1);
		$user->type('event_manager');
		$user->firstname($firstname);
		$user->surname($surname);

		$self->{db}->begin_transaction;

		$user->create;

		$self->{db}->commit;
	}

	$self->{page}->add_redir({
		method => 'tourlist_assign_staff',
		tourdate_id => $self->{params}->{tourdate_id} });
}


########################################################################################
########################################################################################
######################
# SHOWING
######################
########################################################################################
########################################################################################

sub showing_get_showing
{
	my ($self, $id) = @_;

	if($id!~/\d/)
	{
		$id = $self->{params}->{showing_id};
	}

	my $showing;

	if($id>0)
	{
		$showing = Webkit::MyOffice2::Showing->load($self->{db}, {
			id => $id });
	}
	else
	{
		$showing = Webkit::MyOffice2::Showing->constructor($self->{db});
		$showing->org_id($self->{org}->get_id);
		$showing->users_id($self->{user}->get_id);
		$showing->created(Webkit::DateTime->now);
	}

	return $showing;
}

########################################################################################
########################################################################################
######################
# PRINT
######################
########################################################################################
########################################################################################

sub print_get_print_run
{
	my ($self, $id) = @_;

	if($id!~/\d/)
	{
		$id = $self->{params}->{print_run_id};
	}

	my $print_run;

	if($id>0)
	{
		$print_run = Webkit::MyOffice2::PrintRun->load($self->{db}, {
			id => $id });
	}
	else
	{
		$print_run = Webkit::MyOffice2::PrintRun->constructor($self->{db});
		$print_run->org_id($self->{org}->get_id);
	}

	return $print_run;
}

sub print_frameset_proxy
{
	my ($self) = @_;

	my $page_method = $self->{params}->{page_method};

	if($page_method eq 'print_form')
	{
		$self->print_form;
	}
	elsif($page_method eq 'non_assigned')
	{
		$self->print_non_assigned;
	}
	elsif($page_method eq 'print_sheet')
	{
		$self->print_sheet;
	}
	else
	{
		$self->print_home;
	}
}

sub print_tree
{
	my ($self) = @_;

	$self->{tour}->load_print_runs;

	$self->{page}->add_template('print_tree');
}

sub print_toolbar
{
	my ($self) = @_;

	$self->{page}->{manual_page} = $self->{page}->get_template('print_toolbar');
}

sub print_toolbar_save
{
	my ($self) = @_;

	$self->{db}->begin_transaction;

	my $data = $self->{params}->{data};

	my $formparams;

	while($data =~ /<field name="(\w+)">(.*?)<\/field>/gsi)
	{
		$formparams->{$1} = $2;

		$data =~ s/<field name="(\w+)">(.*?)<\/field>//si;
	}

	my $objs;

	foreach my $key (keys %$formparams)
	{
		if($key =~ /^print_run_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $print_run = $objs->{'print_run_'.$1};

			if(!$print_run)
			{
				$print_run = Webkit::MyOffice2::PrintRun->load($self->{db}, {
					id => $1 });
			}

			$objs->{'print_run_'.$print_run->get_id} = $print_run;

			$print_run->set_value($2, $value);
		}

		if($key =~ /^print_req_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $print_req = $objs->{'print_req_'.$1};

			if(!$print_req)
			{
				$print_req = Webkit::MyOffice2::Print->load($self->{db}, {
					id => $1 });
			}

			$objs->{'print_req_'.$print_req->get_id} = $print_req;

			if(($2 eq 'print_despatched')||($2 eq 'print_received'))
			{
				$value = Webkit::Date->from_calendar($value);
			}

			$print_req->set_value($2, $value);
		}

		if($key =~ /^venue_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $venue = $objs->{'venue_'.$1};

			if(!$venue)
			{
				$venue = Webkit::MyOffice2::Venue->load($self->{db}, {
					id => $1 });
			}

			$objs->{'venue_'.$venue->get_id} = $venue;

			$venue->set_value($2, $value);
		}
	}

	foreach my $key (keys %$objs)
	{
		my $obj = $objs->{$key};

		$obj->save;
	}

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'print_toolbar' });
}


sub print_home
{
	my ($self) = @_;

	my $defs = [
		{	title => 'Name',
			prop => 'name',
			width => '*' },

		{	title => 'Count',
			align => 'right',
			method => 'print_req_count',
			width => '60' },

		{	title => 'Tour',
			method => 'tour_name_blue_span',
			width => '120' },

		{	title => 'Dates',
			method => 'get_dates_title',
			width => '140' },

		{	title => 'Notes',
			no_overflow => 1,
			method => 'get_html_notes',
			width => '300' } ];

	my $buttons = [
		{	key => 'edit',
			title => 'View Print Sheet',
			width => '120px',
			method => 'print_sheet' },
		{	key => 'edit_run',
			title => 'Edit Print Run',
			method => 'print_form' },
		{	key => 'delete',
			width => '120px',
			title => 'Delete Print Run',
			method => 'print_delete_print' },
		{
			key => 'add',
			title => 'Add Print Run',
			normal_method => 'print_form' } ];

	$self->{tour}->load_print_runs_with_req_count;
	$self->{org}->load_tours;

	foreach my $print_run (@{$self->{tour}->ensure_child_array('print_run')})
	{
		my $tour = $self->{org}->get_child('tour', $print_run->tour_id);

		$print_run->tour_name($tour->name);
	}

	$self->{page}->add_template('object_list', {
		title => 'Current Print Runs',
		defs => $defs,
		object_tag => 'print_run',
		objects => $self->{tour}->ensure_child_array('print_run'),
		button_refs => $buttons });
}

sub print_not_assigned
{
	my ($self) = @_;

	$self->{tour}->load_print_not_assigned_objects;

	$self->{page}->add_template('print_not_assigned');
}

sub print_excel_sheet
{
	my ($self) = @_;

	my $print_run = $self->print_get_print_run;

	$self->{tour}->load_print_run_objects($print_run);

	my $spreadsheet = Webkit::MyOffice2::PrintExcelSheet->new($print_run);

	$spreadsheet->generate;

	my $filecontent = $spreadsheet->get_file_contents;
	my $length = length($filecontent);
	my $filename = $spreadsheet->get_filename;
	my $mime = $spreadsheet->get_mime_type;

	my $header=<<"+++";
Content-type: $mime
Content-length: $length
Content-Disposition: attachment;filename="$filename"

+++

	print $header;

	print $filecontent;
}


sub print_sheet
{
	my ($self) = @_;

	my $print_run = $self->print_get_print_run;

	$self->{tour}->load_print_run_objects($print_run);

	$self->{page}->add_template('print_sheet', {
		central_print => $print_run->{_central_print_req},
		print_run => $print_run });
}

sub print_form
{
	my ($self, $print_run) = @_;

	if(!$print_run)
	{
		$print_run = $self->print_get_print_run;
	}

	$self->{page}->add_template('print_form', {
		calendar => $self->{page}->get_template('calendar'),
		print_run => $print_run });
}

sub print_form_submit
{
	my ($self) = @_;

	my $print_run = $self->print_get_print_run;

	if(!$print_run->exists)
	{
		$print_run->tour_id($self->{tour}->get_id);
	}

	$print_run->save_form_params($self->{params});

	if($print_run->error)
	{
		$self->print_form($print_run);
		return;
	}
	else
	{
		$self->{db}->begin_transaction;

		my $create_central;

		if(!$print_run->exists)
		{
			$create_central = 1;
		}

		$print_run->save_or_create;

		if($create_central)
		{
			$print_run->create_central_print_req;
		}		

		$self->{db}->commit;

		my $href = $self->href;

		$self->{page}->ab(<<"+++");
<script>
	top.appContent.sidebar.frames[1].document.location = '$href&method=print_tree';
</script>
+++

		$self->{page}->add_redir({
			method => 'print_home' });
	}
}

sub print_assign_print_run
{
	my ($self) = @_;

	my $showing = Webkit::MyOffice2::Showing->load($self->{db}, {
		id => $self->{params}->{showing_id} });

	my $venue = $showing->load_venue;
	$showing->load_tourdates;
	$showing->load_print_reqs;

	my $tour = Webkit::MyOffice2::Tour->load($self->{db}, {
		id => $showing->tour_id });

	$self->{tour} = $tour;
	$self->{page}->add_static("tour", $tour);

	$self->{org}->load_print_runs_with_req_count($self->{tour});

	$self->{page}->add_template('modal_assign_print_run', {
		showing => $showing,
		venue => $venue });
}

sub print_assign_print_run_submit
{
	my ($self) = @_;

	my $showing = Webkit::MyOffice2::Showing->load($self->{db}, {
		id => $self->{params}->{showing_id} });

	$showing->load_print_reqs;

	$self->{org}->load_children('Webkit::MyOffice2::PrintRun');

	$self->{db}->begin_transaction;

	my $count = 0;

	foreach my $key (keys %{$self->{params}})
	{
		if($key=~/^print_run_(\d+)$/)
		{
			my $print_run_id = $1;
			my $existing = $showing->{_print_run_ids}->{$print_run_id};

			if($existing)
			{
				$existing->{_selected} = 1;
			}
			else
			{
				my $print_req = Webkit::MyOffice2::Print->constructor($self->{db});
				my $print_run = $self->{org}->get_child('print_run', $print_run_id);

				$print_req->org_id($self->{org}->get_id);
				$print_req->tour_id($print_run->tour_id);
				$print_req->showing_id($showing->get_id);
				$print_req->print_run_id($print_run->get_id);

				$print_req->create;
			}

			$count++;
		}
	}

	foreach my $print_req (@{$showing->ensure_child_array('print_req')})
	{
		if(!$print_req->{_selected})
		{
			$print_req->delete;
		}
	}

	$self->{db}->commit;

	$self->{page}->ab(<<"+++");
<script>
	top.returnValue = new Object({
		mode:'assigned',
		count:$count });

	top.close();
</script>
+++
}

########################################################################################
########################################################################################
######################
# SALES FIGURES
######################
########################################################################################
########################################################################################

sub sales_figures_tree
{
	my ($self) = @_;

	if($self->{params}->{month}=~/\w/)
	{
		$self->{session}->set('sales_figures_month', $self->{params}->{month});
		$self->{session}->set('sales_figures_year', $self->{params}->{year});
		$self->{session}->set('sales_figures_lookahead', $self->{params}->{lookahead});
	}
	else
	{
		$self->{params}->{month} = $self->{session}->{sales_figures_month};
		$self->{params}->{year} = $self->{session}->{sales_figures_year};
		$self->{params}->{lookahead} = $self->{session}->{sales_figures_lookahead};

		if($self->{params}->{month}!~/\w/)
		{
			my $now = Webkit::Date->now;
			$self->{params}->{month} = $now->Month;
			$self->{params}->{year} = $now->Year;
			$self->{params}->{lookahead} = 8;
		}
	}

	$self->{tour}->parse_sales_figures_dates($self->{params});

	$self->{page}->add_template('sales_figures_tree');
}

sub sales_figures_toolbar
{
	my ($self) = @_;

	my $now = Webkit::Date->now;

	my $month = $now->Month;
	my $year = $now->Year;
	my $lookahead = 8;

	if($self->{session}->{sales_figures_month}=~/\w/)
	{
		$month = $self->{session}->{sales_figures_month};
		$year = $self->{session}->{sales_figures_year};
		$lookahead = $self->{session}->{sales_figures_lookahead};
	}

	$self->{page}->{manual_page} = $self->{page}->get_template('sales_figures_toolbar', {
		lookahead => $lookahead,
		month => $month,
		year => $year });
}


sub sales_figures_toolbar_save
{
	my ($self) = @_;

	my $st = '';

	my $data = $self->{params}->{data};

	my $formparams;

	while($data =~ /<field name="([\.\w]+)">(.*?)<\/field>/gsi)
	{
		$formparams->{$1} = $2;

		$data =~ s/<field name="([\.\w]+)">(.*?)<\/field>//si;
	}

	$self->{db}->begin_transaction;

	foreach my $key (keys %$formparams)
	{
		if($key =~ /^booking_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $booking = Webkit::MyOffice2::Booking->load($self->{db}, {
				id => $1 });

			$booking->set_value($2, $value);
			$booking->save;
		}

		if($key =~ /^venue_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $venue = Webkit::MyOffice2::Venue->load($self->{db}, {
				id => $1 });

			$venue->set_value($2, $value);
			$venue->save;
		}

		if($key =~ /^deal_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $deal = Webkit::MyOffice2::Deal->load($self->{db}, {
				id => $1 });

			$deal->set_value($2, $value);
			$deal->save;
		}

		if($key =~ /^sales_figures_entry_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $sales_figures_entry = Webkit::MyOffice2::SalesFiguresEntry->load($self->{db}, {
				id => $1 });

			$sales_figures_entry->set_value($2, $value);
			$sales_figures_entry->save;
		}

		if($key =~ /^sales_figures_([\d\.]+)$/)
		{
			my $id = $1;

			my $value = $formparams->{$key};
			my $sales_figures;

			my @parts = split(/&/, $value);

			my $figs_ref;

			foreach my $part (@parts)
			{
				my ($key, $value) = split(/=/, $part);

				$figs_ref->{$key} = $value;
			}

			if($id=~/^(\d+)\.\d+$/)
			{
				my $entry = Webkit::MyOffice2::SalesFiguresEntry->load($self->{db}, {
					id => $figs_ref->{sales_figures_entry_id} });

				$sales_figures = Webkit::MyOffice2::SalesFigures->constructor($self->{db});
				$sales_figures->org_id($entry->org_id);
				$sales_figures->tour_id($entry->tour_id);
				$sales_figures->tourdate_id($entry->tourdate_id);
				$sales_figures->sales_figures_entry_id($entry->get_id);
				
				my $week_start = Webkit::Date->from_calendar($figs_ref->{week_start});

				$sales_figures->week_start($week_start);
			}
			else
			{
				$sales_figures = Webkit::MyOffice2::SalesFigures->load($self->{db}, {
					id => $id });
			}

			$sales_figures->sold_seats($figs_ref->{sold_seats});
			$sales_figures->sold_gross($figs_ref->{sold_gross});
			$sales_figures->reserved_seats($figs_ref->{reserved_seats});
			$sales_figures->reserved_gross($figs_ref->{reserved_gross});

			$sales_figures->save_or_create;
		}
	}

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'sales_figures_toolbar' });
}


sub sales_figures_sheet
{
	my ($self) = @_;

	if($self->{params}->{month}=~/\w/)
	{
		$self->{session}->set('sales_figures_month', $self->{params}->{month});
		$self->{session}->set('sales_figures_year', $self->{params}->{year});
		$self->{session}->set('sales_figures_lookahead', $self->{params}->{lookahead});
	}
	else
	{
		$self->{params}->{month} = $self->{session}->{sales_figures_month};
		$self->{params}->{year} = $self->{session}->{sales_figures_year};
		$self->{params}->{lookahead} = $self->{session}->{sales_figures_lookahead};

		if($self->{params}->{month}!~/\w/)
		{
			my $now = Webkit::Date->now;
			$self->{params}->{month} = $now->Month;
			$self->{params}->{year} = $now->Year;
			$self->{params}->{lookahead} = 8;
		}
	}

	$self->{tour}->load_sales_figures_objects($self->{params});
	$self->{org}->load_tours;
	
	$self->{page}->add_template('sales_figures_sheet');
}


########################################################################################
########################################################################################
######################
# TIMELINE
######################
########################################################################################
########################################################################################

sub timeline_tree
{
	my ($self) = @_;

	if($self->{params}->{from}!~/\w/)
	{
		if($self->{session}->{tourlist_from})
		{
			$self->{params}->{from} = $self->{session}->{tourlist_from};
			$self->{params}->{to} = $self->{session}->{tourlist_to};
		}
		else
		{
			my $from = Webkit::Date->now;
			my $to = Webkit::Date->now;

			$to->epoch_days(240);

			$self->{params}->{from} = $from->get_string;
			$self->{params}->{to} = $to->get_string;
		}
	}
	else
	{
		$self->{session}->set('tourlist_from', $self->{params}->{from});
		$self->{session}->set('tourlist_to', $self->{params}->{to});
	}	

	$self->{tour}->load_modal_timeline_booked_objects($self->{params});
	$self->{org}->load_tours;

	$self->{page}->add_template('timeline_tree');
}

sub timeline_home
{
	my ($self) = @_;

	$self->{page}->ab("Click on a showing in the tree");
}

########################################################################################
########################################################################################
######################
# VENUE STATUS
######################
########################################################################################
########################################################################################

sub venue_status_tree
{
	my ($self) = @_;

	my $venue = $self->venue_get_venue;

	$self->{tour}->load_bookings_and_tourdates_for_venue($venue);
	$self->{org}->load_tours;

	$self->{page}->add_template('venue_status_tree', {
		venue => $venue });
}

sub venue_status_toolbar
{
	my ($self) = @_;

	my $venue;

	if($self->{params}->{venue_id}>0)
	{
		$venue = $self->venue_get_venue;
	}

	$self->{page}->{manual_page} = $self->{page}->get_template('venue_status_toolbar', {
		venue => $venue });
}

sub venue_status_toolbar_save
{
	my ($self) = @_;

	my $data = $self->{params}->{data};

	my $formparams;

	while($data =~ /<field name="(.*?)">(.*?)<\/field>/gsi)
	{
		$formparams->{$1} = $2;

		$data =~ s/<field name="(.*?)">(.*?)<\/field>//si;
	}
	
	$self->{db}->begin_transaction;
	
	my $st = '';

	foreach my $key (keys %$formparams)
	{
		if($key =~ /^booking_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $booking = Webkit::MyOffice2::Booking->load($self->{db}, {
				id => $1 });

			my $field = $2;

			$booking->set_value($field, $value);
				
			$booking->save;
		}

		if($key =~ /^showing_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $showing = Webkit::MyOffice2::Showing->load($self->{db}, {
				id => $1 });

			my $field = $2;

			my $date_fields = {
				onsale_date => 1 };

			if($date_fields->{$field})
			{
				$showing->set_calendar_value($field, $value);
			}
			else
			{
				$showing->set_value($field, $value);
			}
			
			$showing->save;
			
			$st .= $key.':'.$showing->get_value($field).' --- '.$field.'='.$value;
		}

		if($key =~ /^deal_(\d+)_(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $deal = Webkit::MyOffice2::Deal->load($self->{db}, {
				id => $1 });

			my $field = $2;
			
			my $date_fields = {
				print_deadline => 1 };

			if($date_fields->{$field})
			{
				$deal->set_calendar_value($field, $value);
			}
			else
			{
				$deal->set_value($field, $value);
			}			

			$deal->save;
		}

		if($key =~ /^venue_status_entry:(\w+):(\w+)$/)
		{
			my $value = $formparams->{$key};

			my $id = $1;
			my $field = $2;

			my $entry;

			if($id=~/^new_(\d+)/)
			{
				my $showing = Webkit::MyOffice2::Showing->load($self->{db}, {
					id => $1 });

				$entry = $showing->get_venue_status_entry($field, 1);
			}
			elsif($id=~/^new_booking_(\d+)/)
			{
				my $booking = Webkit::MyOffice2::Booking->load($self->{db}, {
					id => $1 });

				$entry = $booking->get_venue_status_entry($field, 1);
			}
			else
			{
				$entry = Webkit::MyOffice2::VenueStatusEntry->load($self->{db}, {
					id => $id });
			}

			$entry->value($value);
			$entry->save_or_create;
		}
	}

	$self->{db}->commit;
	
	#$self->{page}->add_body($st);
	#return;
	

	$self->{page}->add_redir({
		venue_id => $self->{params}->{venue_id},
		method => 'venue_status_toolbar' });
}

sub venue_status_sheet
{
	my ($self) = @_;

	$self->{tour}->load_venue_status_sheet($self->{params});
	$self->{org}->load_tours;

	$self->{page}->add_template('venue_status_sheet', {
		calendar => $self->{page}->get_template('calendar') });
}

sub venue_status_show_venue
{
	my ($self) = @_;

	my $venue = $self->venue_get_venue;

	$self->{tour}->load_showings_and_tourdates_for_venue($venue);
	$self->{org}->load_tours;

	$self->{page}->add_template('modal_find_showing_page', {
		show_all_button => 1,
		venue => $venue });
}

########################################################################################
########################################################################################
######################
# SHOWING (i.e. visit admin)
######################
########################################################################################
########################################################################################

sub showing_form
{
	my ($self) = @_;

	my $showing = $self->showing_get_showing;

	$showing->load_tourdates;

	$self->{page}->add_template('showing_form', {
		calendar => $self->{page}->get_template('calendar'),
		venue => $showing->load_venue,
		showing => $showing });
}

sub showing_form_submit
{
	my ($self) = @_;

	my $showing = $self->showing_get_showing;

	$showing->load_tourdates;

	foreach my $tourdate (@{$showing->ensure_child_array('tourdate')})
	{
		my $date = Webkit::Date->from_calendar($self->{params}->{'date'.$tourdate->get_id});
		my $hour = $self->{params}->{'hour'.$tourdate->get_id};
		my $min = $self->{params}->{'min'.$tourdate->get_id};

		my $time = Webkit::Time->now;

		$tourdate->date($date);

		$time->Hour($hour);
		$time->Min($min);
		$time->Sec(0);

		$tourdate->time($time);
	}

	my $tour_id = $self->{params}->{tour_id};

	$self->{db}->begin_transaction;

	if($tour_id!=$showing->tour_id)
	{
		my $deal = $showing->load_deal;
		my $booking = $showing->load_booking;
		$showing->load_print_reqs;
		$showing->load_children('Webkit::MyOffice2::VenueStatusEntry');
		$showing->load_sales_figures;
		$showing->load_sales_figures_entries;

		$showing->tour_id($tour_id);
		$showing->save;
		$deal->tour_id($tour_id);
		$deal->save;
		$booking->tour_id($tour_id);
		$booking->save;
		
		foreach my $print_req (@{$showing->ensure_child_array('print_req')})
		{
			$print_req->delete;
		}

		foreach my $venue_status_entry (@{$showing->ensure_child_array('venue_status_entry')})
		{
			$venue_status_entry->tour_id($tour_id);
			$venue_status_entry->save;
		}

		foreach my $sales_figures (@{$showing->ensure_child_array('sales_figures')})
		{
			$sales_figures->tour_id($tour_id);
			$sales_figures->save;
		}

		foreach my $sales_figures_entry (@{$showing->ensure_child_array('sales_figures_entry')})
		{
			$sales_figures_entry->tour_id($tour_id);
			$sales_figures_entry->save;
		}

		foreach my $tourdate (@{$showing->ensure_child_array('tourdate')})
		{
			$tourdate->tour_id($tour_id);
			$tourdate->save;
		}
	}

	foreach my $tourdate (@{$showing->ensure_child_array('tourdate')})
	{
		$tourdate->save;
	}
	
	$showing->tickets_url($self->{params}->{tickets_url});
	$showing->onsale($self->{params}->{onsale}eq'y'?'y':'n');
	$showing->onsale_date(Webkit::DateTime->from_calendar($self->{params}->{onsale_date}));
	
	$showing->save;

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'showing_form',
		showing_id => $showing->get_id });
}

sub quick_xml_process
{
	my ($self, $text) = @_;
	
	$text =~ s/&/&amp;/g;
	
	return $text;	
}

sub showing_push_website_data
{
	my ($self) = @_;
	
	my $today = Webkit::DateTime->new;
	my $till = Webkit::DateTime->new;

	$today->epoch_days(-1);
	$till->epoch_days(1000);
	
	#$self->{params}->{from} = '01/01/2011';
	#$self->{params}->{to} = '01/01/2012';
	
	$self->{params}->{from} = $today->get_string;
	$self->{params}->{to} = $till->get_string;
	
	my $alltour = Webkit::MyOffice2::Tour->constructor($self->{db});

	$alltour->combined_ids('all');
	
	$alltour->load_website_push_objects($self->{params});
	
	$self->{org}->load_tours;
	
	my $id = 12;
	
	my $xml=<<"+++";
<?xml version="1.0" encoding="UTF-8"?>
<tourdates>
+++

	foreach my $tourdate (@{$alltour->ensure_child_array('tourdate')})
	{
		my $showing = $alltour->get_child('showing', $tourdate->showing_id);
		my $venue = $alltour->get_child('venue', $showing->venue_id);
		
		my $tour = $self->{org}->get_child('tour', $tourdate->tour_id);

		if($showing)
		{				
#				my $tourdate_js_hash = Webkit::AppTools->js_hash({
#					staff_string => $staff_string,
#					projector_image => $projector_image,
#					onsale_image => $onsale_image,
#					print_style => $print_style,
#					_technical_rider_date => $technical_rider_date,
#					_technical_rider_date_rcvd => $technical_rider_date_rcvd,
#					technical_rider_title => $showing->get_technical_rider_title('<br>', 'color:blue'),
#					technical_rider_rcvd_title => $showing->get_technical_rider_rcvd_title('<br>', 'color:blue'),
#					js_notes => $tourdate->get_js_value('general_notes'),
#					notes => $tourdate->get_html_value('general_notes'),
#					epk_date => $showing->get_epk_title,
#					tour_title => $tour->name,
#					deal_sheet_date => $deal->created_title,
#					time_title => $tourdate->get_time_title,
#					pack_sent => $booking->pack_sent,
#					pack_sent_title => $booking->get_multidate_title('pack_sent', ',<br>'),
#					_tourdate_id => $tourdate->get_id,
#					_showing_id => $showing->get_id,
#					_booking_id => $booking->get_id,
#					_deal_id => $deal->get_id,
#					_venue_id => $venue->get_id,
#					sponsorship_checked => $sponsorship_checked,
#					venue_title => $venue->get_city_title
#});

				my $t = {
					
					id => $tourdate->get_id,
					
					show => $tour->name,
					
					date => $tourdate->date ? $tourdate->date->get_string : '',
					
					time => $tourdate->time ? $tourdate->time->get_string : '',
					
					venue => $venue ? $self->quick_xml_process($venue->name) : '',
					
					phone => $venue ? $self->quick_xml_process($venue->box_office_number) : '',
					
					city => $venue ? $self->quick_xml_process($venue->city) : '',
					
					postcode => $venue ? $self->quick_xml_process($venue->postcode) : '',
					
					onsale => $showing->onsale eq 'y' ? 'y' : 'n',
					
					onsale_date => $showing->onsale_date ? $showing->onsale_date->get_string : '',
					
					tickets_url => $self->quick_xml_process($showing->tickets_url),
					
					tickets_region => $self->quick_xml_process($showing->tickets_region),
					
					tickets_country => $self->quick_xml_process($showing->parse_tickets_country)
					
				};
		
			$xml.=<<"+++";
	<tourdate id="$t->{id}">
		<show>$t->{show}</show>
		<date>$t->{date}</date>
		<time>$t->{time}</time>
		<venue>$t->{venue}</venue>
		<phone>$t->{phone}</phone>
		<city>$t->{city}</city>
		<postcode>$t->{postcode}</postcode>
		<onsale>$t->{onsale}</onsale>
		<onsale_date>$t->{onsale_date}</onsale_date>
		<tickets_url>$t->{tickets_url}</tickets_url>
		<tickets_region>$t->{tickets_region}</tickets_region>
		<tickets_country>$t->{tickets_country}</tickets_country>
	</tourdate>
+++
			}
		}
	
	$xml.=<<"+++";	
</tourdates>	
+++

	my $length = length($xml);
	
my $header=<<"+++";
Content-type: text/xml
Content-length: $length

+++

	print $header;

	print $xml;
}

sub showing_delete_tourdate_submit
{
	my ($self) = @_;

	my $tourdate = Webkit::MyOffice2::Tourdate->load($self->{db}, {
		id => $self->{params}->{tourdate_id} });

	$self->{db}->begin_transaction;

	$tourdate->delete_children('Webkit::MyOffice2::SalesFigures');
	$tourdate->delete_children('Webkit::MyOffice2::SalesFiguresEntry');

	$tourdate->delete;

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'showing_form',
		showing_id => $tourdate->showing_id });
}

sub showing_delete_showing_submit
{
	my ($self) = @_;

	my $showing = $self->showing_get_showing;

	$showing->load_sales_figures;
	$showing->load_sales_figures_entries;
	my $deal = $showing->load_deal;
	my $booking = $showing->load_booking;

	$self->{db}->begin_transaction;

	$showing->delete_children('Webkit::MyOffice2::VenueStatusEntry');
	$showing->delete_children('Webkit::MyOffice2::Tourdate');
	$showing->delete_children('Webkit::MyOffice2::Print');

	foreach my $sales_figures (@{$showing->ensure_child_array('sales_figures')})
	{
		$sales_figures->delete;
	}

	foreach my $sales_figures_entry (@{$showing->ensure_child_array('sales_figures_entry')})
	{
		$sales_figures_entry->delete;
	}

	$deal->delete;
	$booking->delete;
	$showing->delete;

	$self->{db}->commit;

	$self->{page}->ab(<<"+++");
You have deleted this visit - please use the menu-bars to navigate from here...
+++
}

sub showing_fail_showing_submit
{
	my ($self) = @_;

	my $showing = $self->showing_get_showing;

	$showing->load_sales_figures;
	$showing->load_sales_figures_entries;
	$showing->load_tourdates;

	my $deal = $showing->load_deal;
	my $booking = $showing->load_booking;

	$self->{db}->begin_transaction;

	$showing->delete_children('Webkit::MyOffice2::VenueStatusEntry');
	$showing->delete_children('Webkit::MyOffice2::Print');

	foreach my $sales_figures (@{$showing->ensure_child_array('sales_figures')})
	{
		$sales_figures->delete;
	}

	foreach my $sales_figures_entry (@{$showing->ensure_child_array('sales_figures_entry')})
	{
		$sales_figures_entry->delete;
	}

	foreach my $tourdate (@{$showing->ensure_child_array('tourdate')})
	{
		$tourdate->set_value('showing_id', 0);
		$tourdate->save;
	}

	$deal->delete;
	$showing->delete;

	###$booking->failed(Webkit::DateTime->now);

	my $failed_date = Webkit::DateTime->now;
	my $failed_date_st = $failed_date->get_calendar_string;

	my $notes_obj = $booking->ensure_booking_notes;

	my $notes = $notes_obj->notes;

	$notes.=<<"+++";
------------
Pencil Booking FAILED On - $failed_date_st
------------

+++

	$notes_obj->notes($notes);
	$notes_obj->save;

	$booking->set_value('notes', $notes);
	$booking->set_value('penciled', '');
	$booking->set_value('agreed', '');
	$booking->add_date_called_entry($failed_date_st, 'Pencil Booking Failed');

	$booking->save;

	$self->{db}->commit;

	$self->{page}->ab(<<"+++");
<script>
	alert('The booking has been failed - now moving to booking progress where the booking has been placed');
	top.get_double_frameset('myoffice2_booking_progress&filter=all');
</script>
+++
}

1;