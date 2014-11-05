package Webkit::Privilage;

use strict;

@Webkit::Privilage::ISA = qw(Webkit::DBObject);

my $schema = {	users_id => {		type => 'id',
					required => 1 },

		application_id => {	type => 'string',
					required => 1 },

		sub_application_id => {	type => 'string',
					required => 1 },

		active => {		type => 'string',
					required => 1 } };

sub table
{
        return 'webkit.privilage';
}

sub schema
{
        return $schema;
}

sub is_active
{
	my ($self) = @_;

	if($self->get_value('active') eq 'y')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub application
{
	my ($self) = @_;

	return $self->get_value('application_id');
}

sub sub_application
{
	my ($self) = @_;

	return $self->get_value('sub_application_id');
}

sub get_application_obj
{
	my ($self) = @_;

	my $application_obj = Webkit::Apache::ApplicationHub->get_application($self->get_value('application_id'));

	return $application_obj;
}

sub is_standalone
{
	my ($self) = @_;

	my $app = $self->get_application_obj;

	if(!$app)
	{
		return undef;
	}

	if($app->get_value('standalone') eq 'y')
	{
		return 1;
	}
}

sub is_standalone_and_active
{
	my ($self) = @_;

	if(!$self->is_standalone)
	{
		return undef;
	}

	if(!$self->is_active)
	{
		return undef;
	}

	return 1;
}

1;
