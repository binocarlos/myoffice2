package Webkit::ApplicationInfo;

use strict;

@Webkit::ApplicationInfo::ISA = qw(Webkit::DBObject);

my $schema = {	title => {	type => 'string',
				required => 1 },

		module => { 	type => 'string',
				required => 1 },

		logo => {	type => 'id',
					required => 1 },

		description => {	type => 'string' },

		standalone => {		type => 'string',
					required => 1 },

		sub_applications => {	type => 'string' } };

sub table
{
        return 'webkit.application';
}

sub schema
{
        return $schema;
}

sub get_subapplication_ids
{	
	my ($self) = @_;

	my @arr = split(/:/, $self->get_value('sub_applications'));

	return \@arr;
}

sub is_standalone
{
	my ($self) = @_;

	if($self->get_value('standalone') eq 'y')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

1;
