package Webkit::SkillsAudit::AuditTemplate;

use strict;
use XML::DOM ();

@Webkit::SkillsAudit::AuditTemplate::ISA = qw(Webkit::DBObject);

my $schema = {
			org_id => {		type => 'id',
						required => 1 },

			name => {		type => 'string',
						required => 1 },

			created => {		type => 'datetime',
						required => 1 },

			locked => {		type => 'datetime' },

			active => {		type => 'string',
						required => 1 },

			xml => {		type => 'string' } };

sub table
{
        return 'skillsaudit.audit_template';
}

sub schema
{
        return $schema;
}

sub save_form_params
{
	my ($self, $params) = @_;

	$self->name($params->{name});
	
	my $xml = $params->{xml};

	$xml =~ s/\r[^\n]/\n/g;
	$xml =~ s/\r?\n/\n/g;

	if(!$self->exists)
	{
		$self->active('n');
	}

	if($self->xml ne $xml)
	{
		$self->{_has_xml_changed} = 1;
		$self->xml($xml);
	}

	if(!$self->exists)
	{
		$self->created(Webkit::DateTime->now);
	}
}

sub process_xml
{
	my ($self) = @_;

	if($self->xml!~/\w/) { return; }

	if(!$self->{db}->in_transaction) { die "AuditTemplate->process_xml requires a transaction"; }

	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parse($self->xml);

	$self->add_log("Doc Created - $doc");

	my $questionGroupNodes = $doc->getElementsByTagName("questionGroup");

	for (my $i = 0; $i < $questionGroupNodes->getLength; $i++)
	{
		my $questionGroupNode = $questionGroupNodes->item($i);

		$self->process_question_group_node($questionGroupNode, $i+1);
	}

	$doc->dispose;
}

sub process_question_group_node
{
	my ($self, $node, $order) = @_;

	my $question_group = Webkit::SkillsAudit::QuestionGroup->constructor($self->{db});
	$question_group->org_id($self->org_id);
	$question_group->audit_template_id($self->get_id);

	$question_group->title($node->getAttribute('title'));
	$question_group->numberorder($order);
	$question_group->rank($node->getAttribute('rank'));
	$question_group->tag($node->getAttribute('tag'));
	$question_group->type($node->getAttribute('type'));
	$question_group->keystages($node->getAttribute('keystages'));
	$question_group->subjects($node->getAttribute('subjects'));
	$question_group->display_template($node->getAttribute('display_template'));
	$question_group->intro_text($node->getAttribute('intro_text'));

	my $complete_mode = $node->getAttribute('complete_mode');
	if($complete_mode!~/\w/) { $complete_mode = 'normal'; }

	$question_group->complete_mode($complete_mode);

	if($question_group->error)
	{
		die $question_group->{error_text};
	}

	$question_group->create;

	$self->add_log("Question Group Created: ".$question_group->title.' ---- '.$question_group->get_id);

	my $questionNodes = $node->getElementsByTagName("question", 0);

	for (my $i = 0; $i < $questionNodes->getLength; $i++)
	{
		my $questionNode = $questionNodes->item($i);

		$self->process_question_node($questionNode, $question_group, $i+1);
	}
}

sub process_question_node
{
	my ($self, $node, $question_group, $order) = @_;

	my $question = Webkit::SkillsAudit::Question->constructor($self->{db});

	$question->org_id($self->org_id);
	$question->audit_template_id($self->get_id);
	$question->question_group_id($question_group->get_id);
	
	$question->numberorder($order);
	$question->tag($node->getAttribute('tag'));
	$question->type($node->getAttribute('type'));
	$question->keystage_downgrade($node->getAttribute('keystage_downgrade'));
	$question->keystages($node->getAttribute('keystages'));
	$question->subjects($node->getAttribute('subjects'));

	my $priority = $node->getAttribute('priority');

	if($priority!~/\d/) { $priority = 0; }

	$question->priority($priority);

	$question->bless_type;

	$question->assign_node($node);

	my $textElem = $node->getFirstChild;

	if(($textElem)&&($textElem->getNodeType==XML::DOM::TEXT_NODE))
	{
		my $text = $textElem->getNodeValue;

		$text =~ s/^\w+//;
		$text =~ s/\w+$//;

		$question->text($text);
	}

	if($question->error)
	{
		die $question->{error_text};
	}

	$question->create;

	$self->add_log("Question Created: ".$question->tag.' --- '.$question->type);
}

sub get_created_string
{
	my ($self) = @_;

	return $self->created->get_string;
}

sub add_log
{
	my ($self, $text) = @_;

	push(@{$self->{log}}, $text);
}

sub get_log
{
	my ($self, $join) = @_;

	if(!$join) { $join = "\n"; }

	my $arr = $self->{log};

	my @tojoin = ($self->name.' XML LOG');

	if($arr)
	{
		push(@tojoin, @$arr);
	}

	my $ret = join($join, @tojoin);

	return $ret;
}

sub load_questions_with_groups
{
	my ($self) = @_;

	if($self->{_questions_with_groups_loaded}) { return; }

	$self->{_questions_with_groups_loaded} = 1;

	$self->load_questions;
	$self->load_question_groups;

	foreach my $question (@{$self->ensure_child_array('question')})
	{
		my $group = $self->get_child('question_group', $question->question_group_id);

		$group->add_child($question);
	}
}

sub load_questions
{
	my ($self) = @_;

	if($self->{_questions_loaded}) { return; }

	$self->{_questions_loaded} = 1;

	$self->load_children('Webkit::SkillsAudit::Question', {
		order => 'numberorder' });

}

sub load_question_groups
{
	my ($self) = @_;

	if(!$self->{_question_groups_loaded})
	{
		$self->load_children('Webkit::SkillsAudit::QuestionGroup', {
			order => 'numberorder' });

		$self->{_question_groups_loaded} = 1;
	}
}

sub load_question_groups_for_visitor
{
	my ($self, $visitor) = @_;

	if(!$self->{_question_groups_loaded})
	{
		my $question_groups = Webkit::SkillsAudit::QuestionGroup->load_objects($self->{db}, {
			table => 'skillsaudit.question_group',
			clause => 'audit_template_id = ?',
			binds => [$self->get_id],
			order => 'numberorder' });

		foreach my $question_group (@$question_groups)
		{
			if($visitor->can_see_question_group($question_group))
			{
				$self->add_child($question_group);
			}
		}

		$self->{_question_groups_loaded} = 1;
	}
}

1;
