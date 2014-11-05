package Webkit::Time;

####################
# Webkit::Time overides Webkit::BaseDate giving it just the time portion
# of a datetime
	
use strict;

use Webkit::BaseDate ();

@Webkit::Time::ISA = qw(Webkit::BaseDate);

####################
# Parse To SQL - this will return the MySQL representation of this date object

sub parse_to_sql
{
	my ($classname, $value) = @_;

	if(!$value)
	{
		return '00:00:00';
	}

	if(ref($value)!~/\w/)
	{
		return $value;
	}

	my $hour = Webkit::BaseDate->get_twodp_value($value->Hour);
	my $min = Webkit::BaseDate->get_twodp_value($value->Min);
	my $sec = Webkit::BaseDate->get_twodp_value($value->Sec);

	my $sql_value = "$hour:$min:$sec";

	return $sql_value;
}

####################
# Parse From SQL - this will return the date object parsed from the given sql
# representation.

sub parse_from_sql
{
	my ($classname, $value) = @_;

	if($value eq '00:00:00')
	{
		return undef;
	}

	if($value=~/^(\d{2}):(\d{2}):(\d{2})$/)
	{
		my $time = Webkit::Time->new;

		$time->Sec($3);
		$time->Min($2);
		$time->Hour($1);

		return $time;
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

	return $self->get_string;
}

##################
# get_string - overidden to append date info

sub get_string
{
	my ($self, $attr) = @_;

	my $string = $self->SUPER::get_string({
		delimeter => ':',
		hour => 1,
		min => 1,
		sec => 1 });

	return $string;
}

############################
# Clone - this will create a new copy of this date
# using the Epoch as the next contructor

sub clone
{
	my ($self) = @_;

	return Webkit::Time->new($self->{'epoch second'});
}

package Webkit::Time::Tie;

use strict;
use vars qw(@ISA);
@ISA = ('Date::EzDate::Tie');
	
1;
