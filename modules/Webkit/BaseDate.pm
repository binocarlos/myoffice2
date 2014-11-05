package Webkit::BaseDate;

####################
# This module is used for Date Manipulation routines
# It overides Date::EZDate to provide default functionality.
# There are then three overidden modules from this, date, datetime and time
# For these modules, the parse_to_sql and parse_from_sql methods are replaced
# only looking for and including the info relevent to the type (i.e. full datetime or just time).
#
# It is used to represent dates, calculate ranges of dates
# and parsing to and from objects date, datetime or time typed properties
	
use strict;
use vars qw(@ISA);

use Date::EzDate ();

@ISA = qw(Date::EzDate);

my @short_months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @full_months = qw(January Feburary March April May June July August September October November December);

my @short_days = qw(Mon Tue Wed Thu Fri Sat Sun);

my $short_month_map = {
	jan => 0,
	feb => 1,
	mar => 2,
	apr => 3,
	may => 4,
	jun => 5,
	jul => 6,
	aug => 7,
	sep => 8,
	oct => 9,
	nov => 10,
	dec => 11 };
	
####################
# ABSTRACT - this should be overidden by Date, DateTime and Time
# Parse To SQL - this will return the MySQL representation of this date object

sub parse_to_sql
{
	my ($classname, $value) = @_;

	return $value;
}

####################
# ABSTRACT - this should be overidden by Date, DateTime and Time
# Parse From SQL - this will return the date object parsed from the given sql
# representation.

sub parse_from_sql
{
	my ($classname, $value) = @_;

	return $value;
}

#############
# Simply fills in a leading zero if required
# I.e.'8' becomes '08'

sub get_twodp_value
{
	my ($classname, $value) = @_;

	$value =~ s/^(\d)$/0$1/;

	return $value;
}

################
# Now, returns the correct class of object representing now in time (either datetime, date or time)

sub now
{
	my ($classname) = @_;

	my $value = Date::EzDate->new();

	bless($value, $classname);

	return $value;
}

###########
# ABSTRACT - to be overidden

sub get_full_string
{
	my ($self) = @_;


}

##################
# ABSTRACT
# Get string - returns the string containing the parts given by attr
# The defult is to give none, you should overide this method in each
# date class to include the required details

sub get_overide_string
{
	my ($self, $attr) = @_;

	return &get_string($self, $attr);
}

sub get_string
{
	my ($self, $attr) = @_;

	if(!$self) { return ''; }

	my $parts;

	if($attr->{day})
	{
		my $dayst = $self->Day;

		if(($attr->{full})&&(!$attr->{no_weekday}))
		{
			$dayst = $self->{'weekday long'}.' '.$dayst;
		}
			
		push(@$parts, $dayst);
	}

	if($attr->{month})
	{
		if($attr->{full})
		{
			push(@$parts, $self->{'month long'});
		}
		else
		{
			push(@$parts, $self->Month);
		}
	}

	if($attr->{year})
	{
		my $year = $self->Year;

		if($attr->{short_year})
		{
			$year =~ s/^\d\d//;
		}

		push(@$parts, $year);
	}

	if($attr->{hour})
	{
		my $hour = $self->Hour;

		if($hour!~/\d/) { $hour = '00'; }

		push(@$parts, $hour);
	}

	if($attr->{min})
	{
		my $min = $self->Min;

		if($min!~/\d/)
		{
			$min = '00';
		}

		push(@$parts, $min);
	}

	if($attr->{sec})
	{
		my $sec = $attr->{sec};

		if($sec!~/\d/) { $sec = '00'; }

		push(@$parts, $sec);
	}

	if(!$attr->{delimeter})
	{
		$attr->{delimeter} = ' ';
	}

	if(!$parts)
	{
		$parts = [];
	}

	foreach my $part (@$parts)
	{
		$part =~ s/^(\d)$/0$1/;
	}

	my $string = join($attr->{delimeter}, @$parts);

	return $string;
}

########################
# From Params
# This method takes the params and the fieldname
# It then looks for fieldname_extra
# where extra can be
# date
# month
# year
# hour
# min
# sec
#
# if it finds any of these, then it will return the created
# date as the given class

sub from_params
{
	my ($classname, $field, $params) = @_;

	my $st = $params->{$field.'_month'}.'/'.$params->{$field.'_date'}.'/'.$params->{$field.'_year'};
	
	if($st!~/\d+\/\d+\/\d+/)
	{
		return;
	}

	my $dateobj = Webkit::Date->new($st); 

	bless($dateobj, $classname);

	return $dateobj;
}

#########################
# Epoch days
# This will move the date in time by the given number of days (plus or minus)
# It then returns the number of days since the epoch this date represents

sub set_epoch_days
{
	my ($self, $days) = @_;

	$self->{'epoch day'} = $days;
}

sub epoch_days
{
	my ($self, $days) = @_;

	if($days)
	{
		$self->{'epoch day'} += $days;
	}

	return $self->{'epoch day'};
}

############################
# ABSTRACT, must be overidden so that the class remains intact
# Clone - this will create a new copy of this date
# using the Epoch as the next contructor

sub clone
{
	my ($self) = @_;
	
}

sub week_day_title
{
	my ($self) = @_;

	my $day = $self->WeekDay;

	return $short_days[$day-1];
}

############################
# The following methods are easy accessors for the direct date properties

sub WeekDay
{
	my ($self) = @_;

	my $day = $self->{'weekday number'};

	if($day==0)
	{
		$day=7;
	}

	$day =~ s/^0+//g;

	return $day;
}

sub Day
{
	my ($self, $new) = @_;

	if($new=~/\d/)
	{
		$self->{'day of month'} = $new;
	}

	my $ret = $self->{'day of month'};

	$ret =~ s/^0+//g;

	return $ret;
}

sub Month
{
	my ($self, $new) = @_;

	if($new=~/\d/)
	{
		$self->{'month number base 1'} = $new;
	}

	my $ret = $self->{'month number base 1'};

	$ret =~ s/^0+//g;

	return $ret;
}

sub Year
{
	my ($self, $new) = @_;

	if($new=~/\d/)
	{
		$self->{year} = $new;
	}

	my $ret = $self->{year};

	$ret =~ s/^0+//g;

	return $ret;
}

sub Hour
{
	my ($self, $new) = @_;

	if($new=~/^\d+$/)
	{
		$self->{hour} = $new;
	}

	my $ret = $self->{hour};

	return $ret;
}

sub Min
{
	my ($self, $new) = @_;

	if($new=~/^\d+$/)
	{
		$self->{min} = $new;
	}

	my $ret = $self->{min};

	return $ret;
}

sub Sec
{
	my ($self, $new) = @_;

	if($new=~/^\d+$/)
	{
		$self->{sec} = $new;
	}

	my $ret = $self->{sec};

	return $ret;
}

sub Epoch
{
	my ($self, $new) = @_;

	if($new=~/^\d+$/)
	{
		$self->{'epoch second'} = $new;
	}

	return $self->{'epoch second'};
}

sub get_full_monthname
{
	my ($classname, $index) = @_;

	return $full_months[$index-1];
}

sub get_month_options
{
	my ($classname, $selected) = @_;

	my $refs;

	for(my $i=1; $i<=12; $i++)
	{
		push(@$refs, {
			id => $i,
			title => Webkit::BaseDate->get_monthname($i) });
	}

	return Webkit::AppTools->get_select_options($refs, {
		key_field => 'id',
		value_field => 'title',
		selected => $selected });
}


sub get_monthname
{
	my ($classname, $index) = @_;

	return $short_months[$index-1];
}

sub get_calendar_string
{
	my ($self) = @_;

	my $day = $self->Day;
	my $month = $self->Month;
	my $year = $self->Year;

	my $st = $day.'/'.$month.'/'.$year;

	return $st;
}


sub get_calendar_store_string
{
	my ($self) = @_;

	my $day = $self->Day;
	my $month = $self->Month;
	my $year = $self->Year;

	my $st = $month.'/'.$day.'/'.$year;

	return $st;
}

sub from_calendar
{
	my ($classname, $value) = @_;

	if($value =~ /(\d+) ?\/ ?(\d+) ?\/ ?(\d+)/)
	{
		my $day = $1;
		my $month = $2;
		my $year = $3;

		$day=~s/^0//;
		$month=~s/^0//;

		if($year<2000)
		{
			$year += 2000;
		}

		my $date = Webkit::BaseDate->new();
		
		$date->Month($month);
		$date->Day($day);
		$date->Year($year);

		bless($date, $classname);

		return $date;
	}
	else
	{
		return undef;
	}
}

sub get_month_index_from_short_name
{
	my ($classname, $shortname) = @_;

	$shortname = lc($shortname);

	return $short_month_map->{$shortname};
}

sub get_js_month_map
{
	my ($classname, $full) = @_;

	my @months = @short_months;

	if($full) { @months = @full_months; }

	my $st=<<"+++";
var monthNames = new Array();
+++

	foreach my $month (@months)
	{
		$st.=<<"+++";
monthNames.push('$month');
+++
	}

	return $st;
}

package Webkit::BaseDate::Tie;

use strict;
use vars qw(@ISA);
@ISA = ('Date::EzDate::Tie');

1;
