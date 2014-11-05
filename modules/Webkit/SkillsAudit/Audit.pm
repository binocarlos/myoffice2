package Webkit::SkillsAudit::Audit;

use strict;

@Webkit::SkillsAudit::Audit::ISA = qw(Webkit::DBObject);

my $schema = {
			org_id => {		type => 'id',
						required => 1 },

			school_id => {		type => 'id',
						required => 1 },

			visitor_id => {		type => 'id',
						required => 1 },

			audit_template_id => {	type => 'id',
						required => 1 },

			taken => {		type => 'datetime',
						required => 1 },

			finished => {		type => 'datetime' } };

### What must a groups average score be to be in the good group
my $good_boundary = 6;

### How many answers to show in the 'these are the things to do most of' report
my $lowest_answer_count = 5;

#### Summary Group Count = how many groups to show in the 'could improve' and 'doing well' columns
my $summary_group_count = 5;

sub table
{
        return 'skillsaudit.audit';
}

sub schema
{
        return $schema;
}

sub delete
{
	my ($self) = @_;

	$self->delete_children('Webkit::SkillsAudit::Answer');

	$self->SUPER::delete;
}

sub has_completed_question_group
{
	my ($self, $question_group) = @_;

	my $id = $question_group->get_id;

	my $question_count = $self->{question_counts}->{$id};
	my $answer_count = $self->{answer_counts}->{$id};

	if($question_group->seen_complete)
	{
		if($answer_count>0) { return 1; }
		else { return undef; }
	}
	else
	{
		if($answer_count>=$question_count) { return 1; }
		else { return undef; }
	}
}

sub load_answer_counts
{
	my ($self, $visitor) = @_;

	if(!$visitor) { die "Audit->load_answer_counts Requires a visitor object"; }

	if(!$self->{_answer_counts_loaded})
	{
		my $audit_id = $self->get_id;

		my $cols=<<"+++";
question.id as question_id, question.question_group_id as question_group_id, question.keystages as keystages, question.subjects as subjects, answer.id as answer_id
+++

		my $table=<<"+++";
skillsaudit.question left join skillsaudit.answer on answer.question_id = question.id and answer.audit_id = $audit_id
+++

		my $clause=<<"+++";
question.audit_template_id = ?
and question.type != ?
+++

		my $refs = $self->{db}->get_select_refs({
			table => $table,
			cols => $cols,
			clause => $clause,
			binds => [$self->audit_template_id, 'header'] });

		foreach my $ref (@$refs)
		{
			if(!$visitor->can_see_keystage_string($ref->{keystages})) { next; }
			if(!$visitor->can_see_subject_string($ref->{subjects})) { next; }

			$self->{question_counts}->{$ref->{question_group_id}}++;

			if($ref->{answer_id}>0)
			{
				$self->{answer_counts}->{$ref->{question_group_id}}++;
			}
		}

		$self->{_answer_counts_loaded} = 1;
	}
}

sub has_partially_answered_sections
{
	my ($self, $visitor) = @_;

	if(!$visitor) { die "audit->can_finish requires a visitor object"; }

	$self->load_to_complete_groups($visitor);

	foreach my $group (@{$self->{_to_complete_groups}})
	{
		if($group->{data}->{answer_count}<$group->{data}->{question_count})
		{
			if($group->{data}->{answer_count}>0)
			{
				return 1;
			}
		}
	}

	return undef;
}

sub can_finish
{
	my ($self, $visitor) = @_;

	if(!$visitor) { die "audit->can_finish requires a visitor object"; }

	$self->load_to_complete_groups($visitor);

	foreach my $group (@{$self->{_to_complete_groups}})
	{
		if($group->{data}->{answer_count}<$group->{data}->{question_count})
		{
			return undef;
		}
	}

	return 1;
}

sub load_audit_template
{
	my ($self) = @_;

	if($self->{_audit_template_loaded}) { return; }
	$self->{_audit_template_loaded} = 1;

	my $template = Webkit::SkillsAudit::AuditTemplate->load($self->{db}, {
		id => $self->audit_template_id });

	$self->{_audit_template} = $template;

	return $template;
}

sub load_to_complete_groups
{
	my ($self, $visitor) = @_;

	if(!$visitor) { die "Audit->can_finish requires a visitor object"; }

	if($self->{_to_complete_refs_loaded}) { return; }

	$self->{_to_complete_refs_loaded} = 1;

	my $group_clause=<<"+++";
question.question_group_id = question_group.id
and question_group.audit_template_id = ?
and question_group.complete_mode = ?
and question.type != ?
+++

	$self->add_children('Webkit::SkillsAudit::QuestionGroup', {
		table => 'skillsaudit.question_group, skillsaudit.question',
		cols => 'question_group.*',
		clause => $group_clause,
		binds => [$self->audit_template_id, 'normal', 'header'],
		order => 'question_group.numberorder',
		group => 'question_group.id' });

	$self->add_children('Webkit::SkillsAudit::Question', {
		table => 'skillsaudit.question_group, skillsaudit.question',
		cols => 'question.*',
		clause => $group_clause,
		binds => [$self->audit_template_id, 'normal', 'header'],
		order => 'question.numberorder',
		group => 'question.id' });

	my $answer_clause=<<"+++";
answer.question_group_id = question_group.id
and answer.audit_id = ?
and question_group.audit_template_id = ?
and question_group.complete_mode = ?
+++

	my $answer_refs = $self->{db}->get_select_refs({
		table => 'skillsaudit.question_group, skillsaudit.answer',
		cols => 'question_group.id as question_group_id, count(*) as answer_count',
		clause => $answer_clause,
		binds => [$self->get_id, $self->audit_template_id, 'normal'],
		group => 'question_group.id' });

	foreach my $question (@{$self->ensure_child_array('question')})
	{
		if($visitor->can_see_question($question))
		{
			my $question_group = $self->get_child('question_group', $question->question_group_id);
			$question_group->{data}->{question_count}++;
		}
	}

	foreach my $answer (@$answer_refs)
	{
		my $group = $self->get_child('question_group', $answer->{question_group_id});

		$group->{data}->{answer_count} = $answer->{answer_count};
	}

	my $can_see_groups;

	foreach my $group (@{$self->ensure_child_array('question_group')})
	{
		if($visitor->can_see_question_group($group))
		{
			push(@$can_see_groups, $group);
		}
	}

	$self->{_to_complete_groups} = $can_see_groups;
}

sub load_analysis
{
	my ($self) = @_;

	if($self->{_analysis_loaded}) { return; }

	$self->{_analysis_loaded} = 1;

	my $visitor = $self->load_visitor;

	my $group_clause=<<"+++";
answer.question_group_id = question_group.id 
and answer.question_id = question.id
and answer.audit_id = ? 
and question.type = ?
+++

	$self->add_children('Webkit::SkillsAudit::QuestionGroup', {
		table => 'skillsaudit.question_group, skillsaudit.question, skillsaudit.answer',
		cols => 'question_group.*',
		clause => $group_clause,
		binds => [$self->get_id, 'score'],
		group => 'question_group.id',
		order => 'numberorder' });

	my $answer_clause=<<"+++";
answer.audit_id = ? 
and answer.question_id = question.id 
and question.type = ?
+++

	$self->add_children('Webkit::SkillsAudit::Answer', {
		table => 'skillsaudit.answer, skillsaudit.question, skillsaudit.visitor',
		cols => 'answer.*, question.tag as tag, question.priority as priority, question.text as question_text, question.keystage_downgrade as keystage_downgrade, visitor.key_stages as keystages',
		clause => $answer_clause,
		binds => [$self->get_id, 'score'],
		group => 'question.tag' });

	foreach my $answer (@{$self->ensure_child_array('answer')})
	{
		if(!$answer) { next; }

		my $question_group = $self->get_child('question_group', $answer->question_group_id);

		$question_group->add_answer($answer);
	}

	my $good;
	my $bad;

	foreach my $question_group (@{$self->ensure_child_array('question_group')})
	{
		if(!$visitor->can_see_question_group($question_group))
		{
			next;
		}

		if($question_group->get_child_count('answer')<=0)
		{
			next;
		}

		$question_group->calculate_answer_stats;

		if($question_group->is_good)
		{
			push(@$good, $question_group);
		}
		else
		{
			push(@$bad, $question_group);
		}
	}

	if($good)
	{
		@$good = sort { $b->average_priority_score <=> $a->average_priority_score } @$good;
	}
	else
	{
		$good = [];
	}

	if($bad)
	{
		@$bad = sort { $a->average_priority_score <=> $b->average_priority_score } @$bad;
	}
	else
	{
		$bad = [];
	}

	my $group_limit = Webkit::SkillsAudit::Audit->summary_group_count;

	splice(@$good, $group_limit, @$good);
	splice(@$bad, $group_limit, @$bad);

	$self->{_ok_array} = $good;
	$self->{_notok_array} = $bad;
}

sub load_ict_analysis
{
	my ($self) = @_;

	if($self->{_ict_analysis_loaded}) { return; }

	$self->{_ict_analysis_loaded} = 1;

	my $visitor = $self->load_visitor;

	if(!$visitor->can_have_subject) { return; }

	my $answer_clause=<<"+++";
answer.audit_id = ? 
and answer.question_id = question.id 
and question.type = ?
+++

	my $answers = Webkit::SkillsAudit::Answer->load_objects($self->{db}, {
		table => 'skillsaudit.answer, skillsaudit.question, skillsaudit.visitor',
		cols => 'answer.*, question.tag as tag, question.text as question_text',
		clause => $answer_clause,
		binds => [$self->get_id, 'ict'],
		order => 'question.tag',
		group => 'question.tag' });

	foreach my $answer (@$answers)
	{
		if(!$answer) { next; }

		$self->{_ict_answer_count}++;

		push(@{$self->{_ict_answers_by_score}->{$answer->answer}}, $answer);
	}
}

sub get_analysis_gd
{
	my ($self) = @_;

	$self->load_analysis;

	my $graph = GD::Graph::hbars->new(600, 400);

	$graph->set( 
		shadow_depth	=> +3,
		bar_spacing	=> 10,
		text_space	=> 20,
		borderclrs 	=> ['#000000'],
		fgclr 		=> '#000000',
		cycle_clrs	=> 1,
		shadowclr	=> '#c0c0c0',
		y_label 	=> 'Average Score For Each Section',
		y_min_value	=> 0,
		y_max_value	=> 10 ) or die $graph->error;

	$graph->set_text_clr('#000000');

	$graph->set_title_font('/home/webkit/app_files/fonts/tahoma.ttf', 14);
	$graph->set_legend_font('/home/webkit/app_files/fonts/tahoma.ttf', 10);

	$graph->set_x_label_font('/home/webkit/app_files/fonts/tahoma.ttf', 10);
	$graph->set_y_label_font('/home/webkit/app_files/fonts/tahoma.ttf', 10);

	$graph->set_x_axis_font('/home/webkit/app_files/fonts/tahoma.ttf', 10);
	$graph->set_y_axis_font('/home/webkit/app_files/fonts/tahoma.ttf', 10);

	$graph->set_values_font('/home/webkit/app_files/fonts/tahoma.ttf', 8);

	my $titles;
	my $values;
	my $dclrs;

	my $visitor = $self->load_visitor;

	foreach my $question_group (@{$self->ensure_child_array('question_group')})
	{
		if(!$visitor->can_see_question_group($question_group))
		{
			next;
		}

		push(@$titles, $question_group->title);
		push(@$values, $question_group->average_score);

		my $color = '#ffe5e5';

		if($question_group->is_good)
		{
			$color = '#e5ffe5';
		}

		push(@$dclrs, $color);
	}

	$graph->set(dclrs => $dclrs);

	my $data = [$titles, $values];

	my $gd = $graph->plot($data) or die $graph->error;

	return $gd;
}

sub get_lowest_answer_array
{
	my ($self) = @_;

	my $arr = $self->ensure_child_array('answer');

	my $ret = [];

	for(my $i=0; $i<$lowest_answer_count; $i++)
	{
		my $val = $arr->[$i];

		if($val)
		{
			if($val->answer<Webkit::SkillsAudit::Audit->good_boundary)
			{
				push(@$ret, $val);
			}
		}
	}

	return $ret;
}

sub taken_date
{
	my ($self) = @_;

	return &Webkit::Date::get_string($self->taken);
}


sub load_school
{
	my ($self) = @_;

	if($self->{school}) { return $self->{school}; }

	$self->{school} = Webkit::SkillsAudit::School->load($self->{db}, {
		id => $self->school_id });

	return $self->{school};
}

sub load_visitor
{
	my ($self) = @_;

	if($self->{visitor}) { return $self->{visitor}; }

	$self->{visitor} = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $self->visitor_id });

	return $self->{visitor};
}

sub good_boundary
{
	my ($classname) = @_;

	return $good_boundary;
}

sub get_lowest_answer_count
{
	my ($classname) = @_;

	return $lowest_answer_count;
}

sub summary_group_count
{
	my ($classname) = @_;

	return $summary_group_count;
}
1;
