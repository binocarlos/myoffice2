package Webkit::SkillsAudit::School;

use strict;

@Webkit::SkillsAudit::School::ISA = qw(Webkit::DBObject);

my $schema = {
			org_id => {		type => 'id',
						required => 1 },

			real_school_id => 	{	type => 'id' },

			name => {		type => 'string',
						required => 1 },

			dfes_number => {	type => 'string',
						required => 1 },

			address => {		type => 'string' },

			city => {		type => 'string' },

			postcode => {		type => 'string' },

			type => {		type => 'string' }
};

my $types = [
	{	type => 'infant',
		title => 'Infant' },
	{	type => 'primary',
		title => 'Primary' },
	{	type => 'junior',
		title => 'Junior' },
	{	type => 'middle',
		title => 'Middle' },
	{	type => 'first',
		title => 'First' },
	{	type => 'secondary',
		title => 'Secondary' },
	{	type => 'special',
		title => 'Special' } ];

my $keystage_map = {
	infant => '?',
	junior => '?',
	primary => 'Foundation, KS1 & KS2',
	middle => 'KS2 & KS3',
	first => '?',
	secondary => 'KS3 & KS4',
	special => '?' };

my $choose_subject_types = {
	middle => 1,
	special => 1,
	secondary => 1 };

sub table
{
        return 'skillsaudit.school';
}

sub schema
{
        return $schema;
}

sub save_form_params
{
	my ($self, $params) = @_;

	$self->name($params->{name});
	$self->set_value('real_school_id', $params->{real_school_id});
	$self->dfes_number($params->{dfes_number});
	$self->address($params->{address});
	$self->city($params->{city});
	$self->postcode($params->{postcode});
	$self->type($params->{type});
}

sub load_visitors_audits
{
	my ($self) = @_;

	if($self->{_visitors_audits_loaded}) { return; }

	$self->{_visitors_audits_loaded} = 1;

	$self->load_visitors;
	$self->load_audits;

	foreach my $audit (@{$self->ensure_child_array('audit')})
	{
		my $visitor = $self->get_child('visitor', $audit->visitor_id);

		$visitor->add_child($audit);
	}
}

sub load_visitors
{
	my ($self) = @_;

	if($self->{_visitors_loaded}) { return; }

	$self->{_visitors_loaded} = 1;

	$self->load_children('Webkit::SkillsAudit::Visitor', {
		order => 'name' });
}

sub load_audits
{
	my ($self) = @_;

	if($self->{_audits_loaded}) { return; }

	$self->{_audits_loaded} = 1;

	$self->load_children('Webkit::SkillsAudit::Audit', {
		clause => 'finished IS NOT NULL',
		order => 'taken DESC' });
}

sub get_types
{
	my ($classname) = @_;

	return $types;
}

sub get_type_options
{
	my ($self) = @_;

	return Webkit::AppTools->get_select_options($types, {
		key_field => 'type',
		value_field => 'title',
		selected => $self->type });
}

sub get_audit_taken_refs
{
	my ($self) = @_;

	my $refs = $self->{db}->get_select_refs({
		table => 'skillsaudit.audit',
		cols => 'concat(monthname(taken), \' \', year(taken)) as date_string, count(*) as count',
		clause => 'school_id = ? and finished IS NOT NULL',
		binds => [$self->get_id],
		group => 'date_string',
		order => 'taken' });

	return $refs;
}

sub get_keystage_title
{
	my ($self) = @_;

	return $keystage_map->{$self->type};
}

sub has_subject_choice
{
	my ($self) = @_;

	return $choose_subject_types->{$self->type};
}

sub get_type_title
{
	my ($self, $type) = @_;

	foreach my $typeref (@$types)
	{
		if($typeref->{type} eq $type)
		{
			return $typeref->{title};
		}
	}

	return '';
}

1;