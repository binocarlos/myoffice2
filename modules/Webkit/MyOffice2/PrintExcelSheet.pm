package Webkit::MyOffice2::PrintExcelSheet;

use vars qw(@ISA);

use strict;

@ISA = qw(Webkit::ExcelSheet);

my @letters = qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);

my $formats = {
	normal_text => {
		valign => 'top',
		size => 12,
		num_format => '@',
		font => 'Tahoma',
		color => 'black' },

	red => {
		formats => ['normal_text'],	
		color => 'red' },

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
	my ($classname, $print_run) = @_;

	if(!$print_run)
	{
		die "You must pass a print run to create a new print Excel Sheet";
	}

	my $self = &Webkit::ExcelSheet::new($classname);

	$print_run->calculate;

	$self->{print_run} = $print_run;

	return $self;
}

sub generate
{
	my ($self) = @_;

	my $worksheet_name = $self->{print_run}->name;

	$worksheet_name =~ s/\// - /g;

	$worksheet_name =~ /^(.{1,30})/;

	$worksheet_name = $1;

	$self->generate_worksheet('print', $worksheet_name);

	my $sheet = $self->worksheet('print');

	$self->current_worksheet($sheet);

	$sheet->freeze_panes(9,3);
	$sheet->set_zoom(70);

	my $widths = {
		default => 14,
		col0 => 20,
		col1 => 40,
		col2 => 20,
		col15 => 30,
		col16 => 30 };

	for(my $i=0; $i<17; $i++)
	{
		my $width = $widths->{default};

		if($widths->{'col'.$i}>0)
		{
			$width = $widths->{'col'.$i};
		}

		$sheet->set_column($i, $i, $width, 'blank_data');
	}

	$self->write_titles($sheet);

	my $print_run = $self->{print_run};

	my $central_showing = {
		_print_req_obj => $print_run->{_central_print_req} };

	$self->row(2);
	$self->write_showing($central_showing);

	$self->row(2);

	foreach my $showing (@{$print_run->{showing_array}})
	{
		$self->write_showing($showing);
		$self->row(1);
	}

	$self->{workbook}->close();
}

sub write_titles
{
	my ($self, $sheet) = @_;

	my $name = $self->{print_run}->name;

	$name =~ s/\// - /g;

	$self->write({
		format => 'sheet_header',
		value => 'Print Sheet - '.$name });

	return;

	$self->row(2);
	$self->reset_col;

	$self->write({
		format => 'red',
		value => 'Unit Print Costs' });

	my $arr = [	{	key => 'leaflet_cost',
				title => 'Leaflets' },
			{	key => 'a3_cost',
				title => 'A3s' },
			{	key => 'dc_cost',
				title => 'DCs' },
			{	key => 'foursheet_cost',
				title => 'Foursheets' } ];

	$self->set_col(2);

	foreach my $block (@$arr)
	{
		my $title = $block->{title};
		my $value = $self->{print_run}->get_value($block->{key});

		$self->col(1);

		$self->write({
			format => 'red',
			value => $title });

		$self->col(1);

		$self->write({
			format => 'float',
			value => $value });
	}

	$self->row(2);
	$self->reset_col;

	$self->write({
		format => 'normal_text',
		value => 'Remember that the grand total is calculated from the total of each visit - not by the main totals shown just below...' });

	$self->row(2);
	$self->reset_col;

	$self->reset_col;

	$self->write({
		format => 'red',
		value => 'Totals' });

	my $print_run = $self->{print_run};

	my $leaflet_total = $print_run->get_print_run_value('leaflet_total', $print_run->{_totals}->{leaflets});
	my $a3_total = $print_run->get_print_run_value('a3_total', $print_run->{_totals}->{a3s});
	my $dc_total = $print_run->get_print_run_value('dc_total', $print_run->{_totals}->{dcs});
	my $foursheet_total = $print_run->get_print_run_value('foursheet_total', $print_run->{_totals}->{foursheets});
	my $delivery_total = $print_run->get_print_run_value('delivery_total', $print_run->{_totals}->{delivery});
	my $total = $print_run->get_print_run_value('total_cost', $print_run->{_totals}->{total});

	$self->set_col(4);

	$self->write({
		format => 'float',
		value => $leaflet_total });

	$self->col(2);

	$self->write({
		format => 'float',
		value => $a3_total });

	$self->col(2);

	$self->write({
		format => 'float',
		value => $dc_total });

	$self->col(2);

	$self->write({
		format => 'float',
		value => $foursheet_total });

	$self->col(1);

	$self->write({
		format => 'float',
		value => $delivery_total });

	$self->col(1);

	$self->write({
		format => 'float',
		value => $total });

	$self->row(2);
	$self->reset_col;

	$self->write_title_row;

}

sub write_title_row
{
	my ($self) = @_;

	my @titles = ("Date", "Venue", "B.O Number", "No.Lfts", "", "No A3s", "", "No DCs", "", "No 4Shts", "", "D Cost", "T Cost", "Despatched", "Received", "Address", "Notes");

	$self->reset_col;

	foreach my $title (@titles)
	{
		$self->write({
			format => 'col_title',
			value => $title });

		$self->col(1);
	}
}

sub write_showing
{
	my ($self, $showing) = @_;

	my $venue = $showing->{_venue_obj};
	my $print_req = $showing->{_print_req_obj};

	my $venue_title = 'Central Showing';
	my $box_office_number = '';
	my $date = 'n/a';
	my $address = '';

	if($venue)
	{
		$venue_title = $venue->get_city_title;
		$box_office_number = $venue->box_office_number;
		$date = $showing->get_datetime_title;
		$address = $venue->get_full_address;

		$date =~ s/<br>/ /g;
	}

	$self->reset_col;

	$self->write({
		format => 'date_text',
		value => $date });

	$self->col(1);

	$self->write({
		format => 'venue_text',
		value => $venue_title });

	$self->col(1);

	$self->write({
		format => 'normal_text',
		value => $box_office_number });

	$self->col(1);

	my @values = ($print_req->leaflets, $print_req->{_leaflets_total}, $print_req->a3s, $print_req->{_a3s_total}, $print_req->dcs, $print_req->{_dcs_total}, $print_req->foursheets, $print_req->{_foursheets_total}, $print_req->{_delivery_total}, $print_req->{_total});

	foreach my $value (@values)
	{
		$self->write({
			format => 'float',
			value => $value });

		$self->col(1);
	}

	my @data_values = ($print_req->print_despatched_title, $print_req->print_received_title, $address, $print_req->notes);

	foreach my $value (@data_values)
	{
		$self->write({
			format => 'address',
			value => $value });

		$self->col(1);
	}
}

sub get_filename
{
	my ($self) = @_;

	my $name = $self->{print_run}->name;

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
