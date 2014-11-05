package Webkit::Date;

# this is a test

####################
# Webkit::Date overides Webkit::BaseDate giving it just the date portion
# of a datetime
	
use strict;

use Webkit::BaseDate ();

@Webkit::Date::ISA = qw(Webkit::BaseDate);

my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

####################
# Parse To SQL - this will return the MySQL representation of this date object

sub parse_to_sql
{
	my ($classname, $value) = @_;

	if(!$value)
	{
		return '0000-00-00';
	}

	if(ref($value)!~/\w/)
	{
		return $value;
	}

	my $year = $value->Year;
	my $month = Webkit::BaseDate->get_twodp_value($value->Month);
	my $day = Webkit::BaseDate->get_twodp_value($value->Day);

	my $sql_value = "$year-$month-$day";

	return $sql_value;
}

####################
# Parse From SQL - this will return the date object parsed from the given sql
# representation.

sub parse_from_sql
{
	my ($classname, $value) = @_;

	my $null_values = {
		'0000-00-00' => 1,
		'2000-00-00' => 1 };

	if($null_values->{$value})
	{
		return undef;
	}

	if($value=~/^(\d{4})-(\d{2})-(\d{2})/)
	{
		my $day = $3;
		my $month = $2;
		my $year = $1;

		my $date = Webkit::Date->new($month.'/'.$day.'/'.$year);

		return $date;
	}
	else
	{
		return undef;
	}
}

############
# Get Full String
# Will return the string with full=1 and delim = ' '

sub get_full_string
{
	my ($self) = @_;

	return $self->get_string({
		delimeter => ' ',
		full => 1 });
}

##################
# get_string - overidden to append date info

sub get_string
{
	my ($self, $attr) = @_;

	if(!$attr->{delimeter})
	{
		$attr->{delimeter} = '/';
	}

	my $day = 1;

	if($attr->{no_day})
	{
		$day = undef;
	}

	$attr->{day} = $day;
	$attr->{month} = 1;
	$attr->{year} = 1;

	my $string = $self->SUPER::get_string($attr);

	return $string;
}

############################
# Clone - this will create a new copy of this date
# using the Epoch as the next contructor

sub clone
{
	my ($self) = @_;

	return Webkit::Date->new($self->{'epoch second'});
}

sub params_constructor
{
	my ($classname, $id, $params) = @_;

	my $day = $params->{$id.'_date'};
	my $month = $params->{$id.'_month'};
	my $year = $params->{$id.'_year'};

	my $st = $month.'/'.$day.'/'.$year;

	return Webkit::Date->new($st);
}

sub simple_gui
{
        my ($self, $id) = @_;

        my $date_data;

        for(my $i=1; $i<=31; $i++)
        {
                push(@$date_data, { id => $i, name => $i });
        }

        my $month_data;

        for(my $i=1; $i<=12; $i++)
        {
                push(@$month_data, { id => $i, name => $months[$i-1] });
        }

        my $year_data;

        for(my $i=2000; $i<=2020; $i++)
        {
                push(@$year_data, { id => $i, name => $i });
        }



        my $date_attr = {        name => $id.'_date',
                                class => 'select_input',
                                key_field => 'id',
                                no_width => 1,
                                null_title => '--',
				selected => $self->Day,
                                value_field => 'name' };

	my $month = $self->Month;

	$month =~ s/^0(\d)$/$1/;

        my $month_attr = {        name => $id.'_month',
                                class => 'select_input',
                                key_field => 'id',
                                no_width => 1,
                                null_title => '--',
				selected => $month,
                                value_field => 'name' };

        my $year_attr = {        name => $id.'_year',
                                class => 'select_input',
                                key_field => 'id',
                                no_width => 1,
                                null_title => '--',
				selected => $self->Year,
                                value_field => 'name' };

        my $date_select = Webkit::AppTools->get_select($date_data, $date_attr);
        my $month_select = Webkit::AppTools->get_select($month_data, $month_attr);
        my $year_select = Webkit::AppTools->get_select($year_data, $year_attr);

        my $gui=<<"+++";
<table width=100% border=0 cellspacing=0 cellpadding=0>
<tr>
<td align=center width=25%>
$date_select
</td>
<td align=center width=5%>
-
</td>
<td align=center width=25%>
$month_select
</td>
<td align=center width=5%>
-
</td>
<td align=center width=25%>
$year_select
</td>
</tr>
</table>
+++

        return $gui;
}

package Webkit::Date::Tie;

use strict;
use vars qw(@ISA);
@ISA = ('Date::EzDate::Tie');

1;
