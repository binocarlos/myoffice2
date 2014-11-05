package Webkit::SkillsAudit::QuestionGroup;

use strict;

@Webkit::SkillsAudit::QuestionGroup::ISA = qw(Webkit::DBObject);

my $schema = {
			org_id => {		type => 'id',
						required => 1 },

			audit_template_id => {	type => 'id',
						required => 1 },

			display_template => {	type => 'string' },

			title => {		type => 'string',
						required => 1 },

			numberorder => {	type => 'int',
						required => 1 },

			rank => {		type => 'int',
						required => 1 },

			tag => {		type => 'string',
						required => 1 },

			type => {		type => 'string',
						required => 1 },

			keystages => {		type => 'string' },

			subjects => {		type => 'string' },

			intro_text => {		type => 'string' },

			complete_mode => {	type => 'string',
						required => 1 } };


my $default_display_template = '/audit/q_template.htm';			


sub table
{
        return 'skillsaudit.question_group';
}

sub schema
{
        return $schema;
}

sub load_actual_questions
{
	my ($self) = @_;

	if(!$self->{_questions_loaded})
	{
		$self->load_children('Webkit::SkillsAudit::Question', {
			clause => 'type != ?',
			binds => ['header'],
			order => 'numberorder' });

		$self->{_questions_loaded} = 1;
	}

}

sub load_questions
{
	my ($self) = @_;

	if(!$self->{_questions_loaded})
	{
		$self->load_children('Webkit::SkillsAudit::Question', {
			order => 'numberorder' });

		$self->{_questions_loaded} = 1;
	}
}

sub count_question_groups
{
	my ($self) = @_;

	if(!$self->{_question_groups_counted})
	{
		my $count_ref = $self->{db}->get_select_ref({
			table => 'skillsaudit.question_group',
			cols => 'count(*) as count',
			clause => 'audit_template_id = ?',
			binds => [$self->audit_template_id] });

		$self->{_question_group_count} = $count_ref->{count};
		$self->{_question_groups_counted} = 1;
	}

	return $self->{_question_group_count};
}

sub get_display_template
{
	my ($self) = @_;

	my $ret = $self->display_template;

	if($ret=~/\w/)
	{
		return $ret;
	}
	else
	{
		return $default_display_template;
	}
}

sub add_answer
{
	my ($self, $answer) = @_;

	$self->add_child($answer);
}

sub calculate_answer_stats
{
	my ($self) = @_;

	if($self->{_answer_stats_calculated}) { return; }

	$self->{_answer_stats_calculated} = 1;

	my $answers = $self->ensure_child_array('answer');
	my $answer_count = $self->get_child_count('answer');

	if($answer_count<=0) { return; }

	foreach my $answer (@$answers)
	{
		$self->{_total_score} += $answer->answer;
	}

	$self->{_average_score} = sprintf("%.2f", $self->{_total_score} / $answer_count);

	foreach my $answer (@$answers)
	{
		$answer->{_priority_score} = $answer->get_priority_score($self->is_good);
		$self->{_total_priority_score} += $answer->{_priority_score};
	}

	if($self->is_good)
	{
		@$answers = sort { $b->{_priority_score} <=> $a->{_priority_score} } @$answers;
	}
	else
	{
		@$answers = sort { $a->{_priority_score} <=> $b->{_priority_score} } @$answers;
	}

	$self->{_order_array} = $answers;
	$self->{_leading_answer} = $answers->[0];
	$self->{_average_priority_score} = sprintf("%.2f", $self->{_total_priority_score} / $answer_count);
}

sub get_important_answers
{
	my ($self) = @_;

	my $count = 0;
	my $ret;

	foreach my $answer (@{$self->{_order_array}})
	{
		if(($count>0)&&($count<3))
		{
			push(@$ret, $answer);
		}

		$count++;
	}
	
	return $ret;
}

sub is_good
{
	my ($self) = @_;

	my $boundary = Webkit::SkillsAudit::Audit->good_boundary;

	my $avg = $self->average_score;

	if($avg>=$boundary) { return 1; }
	else { return undef; }
}

sub total_score
{
	my ($self) = @_;

	return $self->{_total_score};
}

sub average_score
{
	my ($self) = @_;

	return $self->{_average_score};
}

sub average_priority_score
{
	my ($self) = @_;

	return $self->{_average_priority_score};
}

sub leading_answer
{
	my ($self) = @_;

	return $self->{_leading_answer};
}

sub leading_question_text
{
	my ($self) = @_;

	my $answer = $self->leading_answer;

	return $answer->get_question_text;
}

sub normal_complete
{
	my ($self) = @_;

	if($self->complete_mode eq 'normal')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub seen_complete
{
	my ($self) = @_;

	if($self->complete_mode eq 'seen')
	{
		return 1;
	}
	else
	{
		return undef;
	}
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

1;
