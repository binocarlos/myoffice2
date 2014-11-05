package Webkit::SkillsAudit::QuestionTypes::Score;

use strict;

@Webkit::SkillsAudit::QuestionTypes::Score::ISA = qw(Webkit::SkillsAudit::Question);

sub save_answer
{
	my ($self, $answer, $params) = @_;

	if(!$answer) { return; }

	my $param_value = $params->{$self->tag};

	if($param_value!~/\w/)
	{
		return;
	}

	$answer->answer($param_value);
	$answer->score_answer($param_value);
	$answer->save_or_create;
}

1;
