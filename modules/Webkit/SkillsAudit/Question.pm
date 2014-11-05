package Webkit::SkillsAudit::Question;

use strict;

@Webkit::SkillsAudit::Question::ISA = qw(Webkit::DBObject);

my $schema = {
			org_id => {		type => 'id',
						required => 1 },

			audit_template_id => {		type => 'id',
						required => 1 },

			question_group_id => {		type => 'id',
							required => 1 },

			numberorder => {	type => 'integer',
						required => 1 },

			priority => {		type => 'integer',
						required => 1 },

			keystage_downgrade => {	type => 'string' },

			tag => {		type => 'string',
							required => 1 },

			type => {		type => 'string',
						required => 1 },

			text => 		{	type => 'string',
							required => 1 },

			keystages =>		{	type => 'string' },

			subjects => 		{	type => 'string' },

			question_data => 	{	type => 'string' } };

my $type_map = {
	checkbox => 'Checkbox',
	resources => 'Resources',
	ict => 'Score',
	score => 'Score',
	mchoice => 'MChoice',
	radio => 'Radio',
	text => 'Text' };

my $ict_groups = [
	{	score => 0,
		title => 'Unsure of meaning' },
	{	score => 10,
		title => 'Never' },
	{	score => 20,
		title => 'Occasionally' },
	{	score => 30,
		title => 'Regularly' } ];

my @ict_subjects = qw(english maths science design_technology history geography languages art music pe citizenship re);

my $ict_tags = [
	{	key => 'ict_data',
		title => 'Using data and information sources' },
	{	key => 'ict_search',
		title => 'Searching and selecting' },
	{	key => 'ict_organize',
		title => 'Organising and investigating' },
	{	key => 'ict_auto',
		title => 'Analysing and automating processes' },
	{	key => 'ict_model',
		title => 'Models and modelling' },
	{	key => 'ict_control',
		title => 'Control and monitoring' },
	{	key => 'ict_fitness',
		title => 'Fitness for purpose' },
	{	key => 'ict_refining',
		title => 'Refining and presenting information' },
	{	key => 'ict_communicating',
		title => 'Communicating' } ];

my $highest_priority = 4;

sub table
{
        return 'skillsaudit.question';
}

sub schema
{
        return $schema;
}

sub assign_data
{
	my ($self, $data) = @_;

	$self->SUPER::assign_data($data);

	$self->bless_type;

	$self->parse;
}

sub bless_type
{
	my ($self) = @_;

	my $module = $type_map->{$self->type};

	if($module!~/\w/) { return; }

	my $class = 'Webkit::SkillsAudit::QuestionTypes::'.$module;

	bless($self, $class);
}

sub assign_node
{
	my ($self, $node) = @_;

}

sub parse
{
	my ($self) = @_;

}

sub highest_priority
{
	my ($classname) = @_;

	return $highest_priority;
}

sub save_answer
{
	my ($self, $answer, $params) = @_;

	if(!$answer) { return; }

	my $param_value = $params->{$self->tag};

	$answer->answer($param_value);
	$answer->score_answer(0);
	
	$answer->save_or_create;
}

sub js_answer
{
	my ($self, $answer) = @_;

	my $value = $answer->answer;

	$value =~ s/\r?\n/\\n/g;
	$value =~ s/'/\\'/g;

	return $value;
}

sub get_answer_js
{
	my ($self, $answer) = @_;

	my $value = $self->js_answer($answer);
	my $key = $self->tag;

	my $ret=<<"+++";
answers.$key = '$value';
+++

	return $ret;
}

sub subject_array
{
	my ($self) = @_;

	my @ret = split(/:/, $self->subjects);

	return \@ret;
}

sub keystage_array
{
	my ($self) = @_;

	my @ret = split(/:/, $self->keystages);

	return \@ret;
}

sub is_header
{
	my ($self) = @_;

	if($self->type eq 'header') { return 1; }
	else { return undef; }
}

sub get_ict_subjects
{
	my ($classname) = @_;

	return \@ict_subjects;
}

sub get_ict_tags
{
	my ($classname) = @_;

	return $ict_tags;
}

sub get_ict_groups
{
	my ($classname) = @_;

	return $ict_groups;
}

1;
