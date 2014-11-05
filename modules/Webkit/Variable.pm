package Webkit::Variable;

use strict;

@Webkit::Variable::ISA = qw(Webkit::DBObject);

my $schema = {		org_id => {	type => 'id',
					required => 1 },

			field => {	type => 'string',
					required => 1 },

			value => {	type => 'string' },

			modified => {	type => 'datetime',
					required => 1 } };

sub table
{
        return 'webkit.variable';
}

sub schema
{
        return $schema;
}

sub field
{
	my ($self) = @_;

	return $self->get_value('field');
}

sub value
{
	my ($self) = @_;

	return $self->get_value('value');
}

1;
