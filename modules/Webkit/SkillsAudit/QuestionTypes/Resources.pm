package Webkit::SkillsAudit::QuestionTypes::Resources;

use strict;

@Webkit::SkillsAudit::QuestionTypes::Resources::ISA = qw(Webkit::SkillsAudit::Question);

sub get_answer_js
{
	my ($self, $answer) = @_;

	my $key = $self->tag;
	my @lines = split(/\n/, $answer->answer); 
	my $values;

	foreach my $line (@lines)
	{
		if($line=~/^(\w+)=(.*)$/)
		{
			$values->{$1} = $2;
		}
	}

	my $ret=<<"+++";
answers.usage_$key='$values->{usage}';
answers.frequency_$key='$values->{frequency}';
+++

	return $ret;
}

sub save_answer
{
	my ($self, $answer, $params) = @_;

	if(!$answer) { return; }

	my $key = $self->tag;

	my $usage = $params->{'usage_'.$key};
	my $frequency = $params->{'frequency_'.$key};

	my $string = '';

	if($usage=~/\w/)
	{
		$string=<<"+++";
usage=$usage
frequency=$frequency
+++
	}

	$answer->answer($string);

	$answer->save_or_create;
}

1;
