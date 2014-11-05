package Webkit::DateTime;

####################
# Webkit::Date overides Webkit::BaseDate giving it just the date portion
# of a datetime
	
use strict;

use Webkit::BaseDate ();

@Webkit::DateTime::ISA = qw(Webkit::BaseDate);

####################
# Parse To SQL - this will return the MySQL representation of this date object

sub parse_to_sql
{
	my ($classname, $value) = @_;

	if(!$value)
	{
		return '0000-00-00 00:00:00';
	}

	if(ref($value)!~/\w/)
	{
		return $value;
	}

	my $year = $value->Year;
	my $month = Webkit::BaseDate->get_twodp_value($value->Month);
	my $day = Webkit::BaseDate->get_twodp_value($value->Day);
	my $hour =  Webkit::BaseDate->get_twodp_value($value->Hour);
	my $min = Webkit::BaseDate->get_twodp_value($value->Min);
	my $sec = Webkit::BaseDate->get_twodp_value($value->Sec);

	if($hour!~/\d/) { $hour = '00'; }

	my $sql_value = "$year-$month-$day $hour:$min:$sec";

	return $sql_value;
}

####################
# Parse From SQL - this will return the date object parsed from the given sql
# representation.

sub parse_from_sql
{
	my ($classname, $value) = @_;

	my $null_values = {
		'2000-00-00 00:00:00' => 1,
		'0000-00-00 00:00:00' => 1 };

	if($null_values->{$value})
	{
		return undef;
	}

	if($value=~/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)
	{
		my $st = "$2/$3/$1 $4:$5:$6";

		my $date = Webkit::DateTime->new($st);

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

	my $datepart = &Webkit::Date::get_full_string($self);

	my $timepart = &Webkit::Time::get_full_string($self);

	return $datepart.' '.$timepart;	
}

##################
# get_string - overidden to append date and time info

sub get_string
{
	my ($self, $attr) = @_;

	my $datepart = &Webkit::Date::get_string($self, $attr);

	my $timepart = &Webkit::Time::get_string($self, $attr);

	return $datepart.' '.$timepart;
}

############################
# Clone - this will create a new copy of this date
# using the Epoch as the next contructor

sub clone
{
	my ($self) = @_;

	return Webkit::DateTime->new($self->{'epoch second'});
}

package Webkit::DateTime::Tie;

use strict;
use vars qw(@ISA);
@ISA = ('Date::EzDate::Tie');
	
1;
