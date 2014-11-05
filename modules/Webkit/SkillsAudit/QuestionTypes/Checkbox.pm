package Webkit::SkillsAudit::QuestionTypes::Checkbox;

use strict;

@Webkit::SkillsAudit::QuestionTypes::Checkbox::ISA = qw(Webkit::SkillsAudit::Question);

sub get_answer_js
{
	my ($self, $answer) = @_;

	my $key = $self->tag;
	my $value = $answer->answer;

	my $js_value = 'false';

	if($value=~/\w/)
	{
		$js_value = 'true';
	}

	my $ret=<<"+++";
answers.$key = $js_value;
+++

	return $ret;
}

sub save_answer
{
	my ($self, $answer, $params) = @_;

	if(!$answer) { return; }

	my $key = $self->tag;

	$answer->answer($params->{$key});

	$answer->save_or_create;
}

1;
