package Webkit::Browser;

use strict;

sub new
{
	my ($classname) = @_;

	my $self = {};

	bless($self, $classname);

	$self->init;

	return $self;
}

sub init
{
	my ($self) = @_;

	my $version;
	my $os;
	my $browsertype;

	my $browser = $ENV{HTTP_USER_AGENT};

	if($browser=~/\(.*?MSIE (\d\.\d).*?\)/)
	{
		$browsertype = 'ie';
		$version = $1;

		if($browser =~ /Win/)
		{
			$os = 'win';
		}
		elsif($browser =~ /Mac/)
		{
			$os = 'mac';
		}
		else
		{
			$os = undef;
		}
	}

	if($browser =~/Safari/)
	{
		$browsertype = 'safari';
		$os = 'mac';
	}

	if($browser =~/Mac/)
	{
		$os = 'mac';
	}
	
	if($browser =~/Firefox/)
	{
		$browsertype = 'firefox';
	}

	$self->{browser} = $browsertype;
	$self->{version} = $version;
	$self->{os} = $os;
}

sub is_high
{
	my ($self) = @_;

	if(($self->is_win)&&($self->version>=5.5))
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub is_ie
{
	my ($self) = @_;

	if($self->{browser} eq 'ie') { return 1; }
	else { return undef; }
}

sub os
{
	my ($self) = @_;

	return $self->{os};
}

sub version
{
	my ($self) = @_;

	return $self->{version};
}

sub if_is_mac
{
	my ($classname, $text) = @_;

	my $b = Webkit::Browser->new;

	if($b->is_mac) { return $text; }
	else { return ''; }
}

sub if_not_mac
{
	my ($classname, $text) = @_;

	my $b = Webkit::Browser->new;

	if($b->is_mac) { return ''; }
	else { return $text; }
}

sub is_mac
{
	my ($self) = @_;

	if(!ref($self)) { $self = Webkit::Browser->new; }

	if($self->os eq 'mac')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub is_win
{
	my ($self) = @_;

	if($self->os eq 'win')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub is_valid
{
	my ($self) = @_;

	if($self->os eq 'win')
	{
		if($self->version>=5)
		{
			return 1;
		}
		else
		{
			return undef;
		}
	}
	elsif($self->os eq 'mac')
	{
		if($self->version>=5)
		{
			return 1;
		}
		else
		{
			return undef;
		}
	}
	else
	{
		return undef;
	}
}

1;
