package Webkit::SkillsAudit::QuestionTypes::MChoice;

use strict;

@Webkit::SkillsAudit::QuestionTypes::MChoice::ISA = qw(Webkit::SkillsAudit::Question);

sub parse
{
	my ($self) = @_;

	my @values = split(/:/, $self->question_data);

	foreach my $value (@values)
	{
		push(@{$self->{_options}}, $value);
	}
}

sub assign_node
{
	my ($self, $node) = @_;

	my $optionNodes = $node->getElementsByTagName("option", 0);

	for (my $i = 0; $i < $optionNodes->getLength; $i++)
	{
		my $optionNode = $optionNodes->item($i);

		my $value = $optionNode->getAttribute('value');

		push(@{$self->{_options}}, $value);
	}

	my $value_st = join(':', @{$self->{_options}});

	$self->question_data($value_st);
}

sub get_answer_js
{
	my ($self, $answer_obj) = @_;

	my $count = 1;

	my @answers = split(/:/, $answer_obj->answer);

	my $ret;

	foreach my $answer (@answers)
	{
		my $mkey = $self->tag.'_'.$count;

		if($answer=~/\w/)
		{
			$ret.=<<"+++";
answers.$mkey = 1;
+++
		}

		$count++;
	}

	return $ret;
}

sub save_answer
{
	my ($self, $answer, $params) = @_;

	if(!$answer) { return; }

	my $answers;

	my $count = 1;

	foreach my $option (@{$self->{_options}})
	{
		my $mkey = $self->tag.'_'.$count;

		my $mparam_value = $params->{$mkey};

		push(@$answers, $mparam_value);

		$count++;
	}

	my $answer_st = join(':', @$answers);

	$answer->answer($answer_st);

	$answer->save_or_create;
}

1;
