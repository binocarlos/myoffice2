package Webkit::SkillsAudit::Answer;

use strict;

@Webkit::SkillsAudit::Answer::ISA = qw(Webkit::DBObject);

my $schema = {
			org_id => {		type => 'id',
						required => 1 },

			school_id => {		type => 'id',
						required => 1 },

			audit_id => {		type => 'id',
						required => 1 },

			question_group_id => {		type => 'id',
							required => 1 },

			question_id => {		type => 'id',
							required => 1 },

			visitor_id => {		type => 'id',
						required => 1 },

			answer => {		type => 'string' },

			score_answer => {	type => 'int' } };

sub table
{
        return 'skillsaudit.answer';
}

sub schema
{
        return $schema;
}

sub get_priority_factor
{
	my ($self, $good) = @_;

	if($self->{_priority_factor}) { return $self->{_priority_factor}; }

	my $high = Webkit::SkillsAudit::Question->highest_priority;
	my $diff;

	my $downgrade_keystage = $self->{data}->{keystage_downgrade};
	my $should_downgrade = undef;

	if($downgrade_keystage =~ /\w/)
	{
		my $found = undef;
		my @keystages = split(/:/, $self->{data}->{keystages});

		foreach my $keystage (@keystages)
		{
			if(lc($keystage) eq lc($downgrade_keystage))
			{
				$found = 1;
				last;
			}
		}

		if(!$found)
		{
			$should_downgrade = 1;
		}
	}

	if($good)
	{
		if($should_downgrade)
		{
			$diff = 0;
		}
		else
		{
			$diff = $high - $self->get_priority;
		}
	}
	else
	{
		if($should_downgrade)
		{
			$diff = $high;
		}
		else
		{
			$diff = $self->get_priority - 1;
		}
	}

	my $factor = 1 + ($diff * (1/$high));

	$self->{_priority_factor} = $factor;

	return $factor;
}

sub get_priority_score
{
	my ($self, $good) = @_;

	return $self->answer * $self->get_priority_factor($good);
}

sub get_question_text
{
	my ($self) = @_;

	return $self->{data}->{question_text};
}

sub get_priority
{
	my ($self) = @_;

	return $self->{data}->{priority};
}

1;
