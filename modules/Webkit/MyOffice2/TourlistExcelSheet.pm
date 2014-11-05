package Webkit::MyOffice2::TourlistExcelSheet;

use vars qw(@ISA);

use strict;

@ISA = qw(Webkit::ExcelSheet);

my @letters = qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);

my $formats = {
	normal_text => {
		valign => 'top',
		size => 12,
		num_format => '@',
		text_wrap => 1,
		font => 'Tahoma',
		color => 'black' },

	greencell => {
		bold => 1,
		border => 1,
		border_color => 'grey',
		formats => ['normal_text'],
		color => 'green',
		bg_color => '#ccffcc' },

	redcell => {
		bold => 1,
		border => 1,
		border_color => 'grey',
		formats => ['normal_text'],
		color => 'red',
		bg_color => '#ffcccc' },

	tourdate_row => {
		border => 1,
		border_color => 'grey',
		formats => ['normal_text'] },

	tourdate_row_green => {
		border => 1,
		border_color => 'grey',
		formats => ['normal_text'],
		color => 'green'},

	tourdate_row_blue => {
		border => 1,
		border_color => 'grey',
		formats => ['normal_text'],
		color => 'blue' },

	tourdate_row_venue => {
		border => 1,
		border_color => 'grey',
		formats => ['normal_text'],
		color => '#000088' },

	non_booked_tourdate_row => {
		formats => ['normal_text'],
		bg_color => '#ffe5e5' },

	non_booked_tourdate_row_green => {
		formats => ['normal_text'],
		color => 'green',
		bg_color => '#ffe5e5' },

	non_booked_tourdate_row_blue => {
		formats => ['normal_text'],
		color => 'blue',
		bg_color => '#ffe5e5' },

	non_booked_tourdate_row_venue => {
		formats => ['normal_text'],
		color => '#000088',
		bg_color => '#ffe5e5' },

	normaldate => {
		formats => ['normal_text'],	
		bg_color => '#e5e5e5',
		color => '#888888' },

	visitdate => {
		border => 1,
		border_color => 'grey',
		formats => ['normal_text'],	
		color => 'red' },

	red => {
		formats => ['normal_text'],	
		color => 'red' },

	month_title => {
		bold => 1,
		formats => ['normal_text'],	
		color => 'red',
		size => 16 },

	grey => {
		color => '#888888' },

	date_text => {
		formats => ['base_text'],
		color => 'green',
		text_wrap => 1 },

	address => {
		formats => ['normal_text'],
		text_wrap => 1 },

	venue_text => {
		formats => ['normal_text'],	
		color => 'blue' },

	

	float => {
		formats => ['base_text2'],
		num_format => '0.00' },

	percentage => {
		formats => ['base_text'],
		num_format => '0%' },

	integer_text => {
		num_format => '0',
		formats => ['base_text'] },

	data_text => {
		num_format => '@',
		formats => ['base_text'] },

	number_text => {
		num_format => '0.00',
		formats => ['base_text'] },

	base_text2 => {
		valign => 'top',
		size => 12,
		font => 'Tahoma',
		color => 'black',
		align => 'right' },

	base_text => {
		valign => 'top',
		size => 11,
		font => 'Tahoma',
		color => 'black',
		align => 'right' },

	blank_data => {
		formats => ['normal_text'] },

	sub_total_title => {
		formats => ['normal_text'],
		color => 'red' },

	nic_title => {
		formats => ['sub_total_title'] },

	number_title => {
		bold => 1,
		formats => ['grey', 'normal_text'],
		align => 'right' },

	col_title => {
		formats => ['normal_text'],
		bold => 1,
		bg_color => '#CCCCCC',
		align => 'center' },

	sheet_header => {
		formats => ['normal_text'],
		bold => 1,
		size => 18 },

	department_header => {
		formats => ['normal_text'],
		size => 12,
		bold => 1 },

	main_department_header => {
		formats => ['normal_text'],
		size => 14,
		bold => 1 },

	blue_border => {
		border => 1,
		border_color => 'blue' } };

sub new
{
	my ($classname, $org, $tour) = @_;

	if(!$org)
	{
		die "You must pass an org to create a new tourlist Excel Sheet";
	}

	if(!$tour)
	{
		die "You must pass a tour to create a new tourlist Excel Sheet";
	}

	my $self = &Webkit::ExcelSheet::new($classname);

	$self->{org} = $org;
	$self->{tour} = $tour;

	return $self;
}

sub generate
{
	my ($self) = @_;

	my $worksheet_name = $self->{tour}->name;

	$worksheet_name =~ s/\// - /g;

	$worksheet_name =~ /^(.{1,30})/;

	$worksheet_name = $1;

	$self->generate_worksheet('tourlist', $worksheet_name);

	my $sheet = $self->worksheet('tourlist');

	$self->current_worksheet($sheet);

	$sheet->freeze_panes(1,4);
	$sheet->set_zoom(70);

	my $widths = {
		col0 => 20,
		col3 => 60,
		col5 => 30,
		col8 => 50,
		col9 => 30,
		default => 14 };

	for(my $i=0; $i<10; $i++)
	{
		my $width = $widths->{default};

		if($widths->{'col'.$i}>0)
		{
			$width = $widths->{'col'.$i};
		}

		$sheet->set_column($i, $i, $width, 'blank_data');
	}

	$self->row(0);

	$self->write_title_row;
	$self->write_dates;

	$self->{workbook}->close();
}

sub write_month
{
	my ($self, $props) = @_;

	$self->row(1);
	$self->reset_col;

	my $sheet = $self->current_worksheet;

	$sheet->set_row($self->row, 25, 'month_title');

	$self->write({
		format => 'month_title',
		value => $props->{month_title} });
}

sub write_date
{
	my ($self, $props) = @_;

	$self->row(1);
	$self->reset_col;

	my $sheet = $self->current_worksheet;

	$sheet->set_row($self->row, undef, $props->{format});

	$self->write({
		format => $props->{format},
		value => $props->{day_title} });

	$self->col(1);

	$self->write({
		format => $props->{format},
		value => $props->{date_title} });
}

sub write_non_booked_tourdate
{
	my ($self, $props) = @_;

	$self->row(1);
	$self->set_col(1);

	my $sheet = $self->current_worksheet;

	$sheet->set_row($self->row, undef, 'non_booked_tourdate_row');
	
	$self->write({
		format => 'non_booked_tourdate_row_blue',
		value => $props->{tour_title} });

	$self->col(1);

	$self->write({
		format => 'non_booked_tourdate_row_green',
		value => $props->{time_title} });

	$self->col(1);

	$self->write({
		format => 'non_booked_tourdate_row_venue',
		value => $props->{venue_title} });
}

sub write_tourdate
{
	my ($self, $props) = @_;

	$self->row(1);
	$self->set_col(1);

	my $sheet = $self->current_worksheet;

	$sheet->set_row($self->row, 55, 'tourdate_row');
	
	$self->write({
		format => 'tourdate_row_blue',
		value => $props->{tour_title} });

	$self->col(1);

	$self->write({
		format => 'tourdate_row_green',
		value => $props->{time_title} });

	$self->col(1);

	$self->write({
		format => 'tourdate_row_venue',
		value => $props->{venue_title} });

	$self->col(1);

	$self->write({
		format => 'tourdate_row',
		value => $props->{deal_sheet_date} });

	my $tr=<<"+++";
Sent: $props->{technical_rider_date}

Rcvd: $props->{technical_rider_date_rcvd}
+++

	$self->col(1);

	$self->write({
		format => 'tourdate_row',
		value => $tr });

	$self->col(1);

	$self->write({
		format => $props->{print_style},
		value => $props->{print_value} });

	$self->col(1);

	$self->write({
		format => $props->{projector_style},
		value => $props->{projector_value} });

	$self->col(1);

	$self->write({
		format => 'tourdate_row',
		value => $props->{staff_string} });

	$self->col(1);

	$self->write({
		format => 'tourdate_row',
		value => $props->{notes} });
}

sub write_dates
{
	my ($self) = @_;

	my $from_date = $self->{tour}->{_tourlist_from_date};
	my $to_date = $self->{tour}->{_tourlist_to_date};

	my $current_month;
	my $current_date = $from_date->clone;
	
	while($current_date->epoch_days<=$to_date->epoch_days)
	{
		my $month = $current_date->Month;
		
		if($month!=$current_month)
		{
			$current_month = $month;
			my $month_name = Webkit::Date->get_monthname($month);
			my $year = $current_date->Year;
			
			my $month_js_hash = {
				month_title => $month_name.' '.$year };

			$self->write_month($month_js_hash);
		}
		
		my $date_title = $current_date->get_string;
		my $day_title = $current_date->week_day_title;
		
		my $tourdates = $self->{tour}->{_tourlist_map}->{$current_date->epoch_days};
		
		my $format = 'normaldate';
		
		if($tourdates)
		{
			$format = 'visitdate';
		}
		else
		{
			$current_date->epoch_days(1);
			next;
		}

		
		my $date_js_hash = {
				format => $format,
				date_title => $date_title,
				day_title => $day_title };

		$self->write_date($date_js_hash);

		foreach my $tourdate (@$tourdates)
		{
			my $showing = $self->{tour}->get_child('showing', $tourdate->showing_id);
			my $booking = $self->{tour}->get_child('booking', $tourdate->booking_id);			
			my $venue = $self->{tour}->get_child('venue', $booking->venue_id);

			my $tour = $self->{org}->get_child('tour', $tourdate->tour_id);

			if($booking->date_called =~ /=Pencil Booking Failed/)
			{
				#next;
			}
			
			if(!$showing)
			{
				my $tourdate_js_hash = {
					tour_title => $tour->name,
					time_title => $tourdate->get_time_title,
					venue_title => $venue->get_full_address };

				$self->write_non_booked_tourdate($tourdate_js_hash);
			}
			else
			{
				my $deal = $self->{tour}->get_child('deal', $showing->deal_id);
			
				my $print_style = 'redcell';
				my $print_value = 'NO';

				my $projector_style = 'redcell';
				my $projector_value = 'NO';
			
				if($showing->get_child_count('print_req')>0)
				{
					$print_style = 'greencell';
					$print_value = 'YES';
				}
			
				if($deal->has_projector)
				{
					$projector_style = 'greencell';
					$projector_value = 'YES';
				}
			
				my $staff_string = $tourdate->get_staff_string($self->{tour}->get_staff_hash, "\n");
			
				my $tourdate_js_hash = {
					staff_string => $staff_string,
					projector_style => $projector_style,
					projector_value => $projector_value,
					print_style => $print_style,
					print_value => $print_value,
					technical_rider_date => $showing->get_technical_rider_title("\n"),
					technical_rider_date_rcvd => $showing->get_technical_rider_rcvd_title("\n"),
					notes => $tourdate->general_notes,
					tour_title => $tour->name,
					deal_sheet_date => $deal->created_title,
					time_title => $tourdate->get_time_title,
					venue_title => $venue->get_full_address };
		
				$self->write_tourdate($tourdate_js_hash);
			}
		}
		
		$current_date->epoch_days(1);
	}
}


sub write_title_row
{
	my ($self) = @_;

	my @titles = ("", "Tour", "Time", "Venue", "Deal Sheet", "Rider", "Print", "Own Proj", "Staff", "Notes");

	$self->reset_col;

	foreach my $title (@titles)
	{
		$self->write({
			format => 'col_title',
			value => $title });

		$self->col(1);
	}
}

sub write_date_row
{
	my ($self, $date) = @_;

}

sub write_showing_row
{
	my ($self, $showing) = @_;


}

sub get_filename
{
	my ($self) = @_;

	my $name = $self->{tour}->name;

	$name =~ s/\W//g;

	$name.='.xls';

	return $name;
}


sub get_format_props
{
	my ($self) = @_;

	return $formats;
}


1;
