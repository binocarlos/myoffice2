package Webkit::SkillsAudit::Org;

use vars qw(@ISA);

use strict;

@ISA = qw(Webkit::Org);

sub load_audit_templates
{
	my ($self) = @_;

	if(!$self->{_audit_templates_loaded})
	{
		$self->load_children('Webkit::SkillsAudit::AuditTemplate', {
			order => 'name' });

		$self->{_audit_templates_loaded} = 1;
	}
}

sub get_school_options
{
	my ($self, $selected) = @_;

	$self->load_children('Webkit::SkillsAudit::School', {
		order => 'name' });

	return Webkit::AppTools->get_object_select_options($self->ensure_child_array('school'), {
		selected => $selected,
		value_field => 'name' });
}

sub load_schools_with_visitors_count
{
	my ($self) = @_;

	if($self->{_schools_with_visitors_count_loaded}) { return; }

	$self->{_schools_with_visitors_count_loaded} = 1;

	$self->add_children('Webkit::SkillsAudit::School', {
		table => 'skillsaudit.school, skillsaudit.visitor',
		cols => 'school.*, count(*) as visitor_count',
		clause => 'school.org_id = ? and visitor.school_id = school.id',
		binds => [$self->get_id],
		order => 'school.city, school.name',
		group => 'school.id' });
}

sub load_schools
{
	my ($self, $params) = @_;

	if($self->{_schools_loaded}) { return; }

	$self->{_schools_loaded} = 1;

	if(!$params->{limit}) { $params->{limit} = 50; }
	if(!$params->{start}) { $params->{start} = 1; }

	my $limit = $params->{limit};
	my $start = $params->{start} - 1;
	my $search = $params->{search};

	my $clause=<<"+++";
org_id = ?
+++

	my $binds = [$self->get_id];

	if($search=~/\w/)
	{
		$clause.=<<"+++";
and
(
	( name like ? ) or ( address like ? ) or ( city like ? )
)
+++

		my $bind = '%'.$search.'%';

		push(@$binds, $bind, $bind, $bind);
	}

	my $limitst = $start.', '.$limit;

	$self->add_children('Webkit::SkillsAudit::School', {
		table => 'skillsaudit.school',
		cols => 'school.*',
		clause => $clause,
		binds => $binds,
		limit => $limitst,
		order => 'name' });
}



sub fix_date_string
{
	my ($self, $string) = @_;

	my @parts = split(/\D+/, $string);
	my @new_parts;

	foreach my $part (@parts)
	{
		$part =~ s/^(\d)$/0$1/;
		push(@new_parts, $part);
	}

	return join(' / ', @new_parts);
}

sub assign_group_info
{
	my ($self, $params) = @_;

	my $from_date = $params->{from_date};
	my $to_date = $params->{to_date};

	$from_date = $self->fix_date_string($from_date);
	$to_date = $self->fix_date_string($to_date);

	my $group_title = 'All Schools';

	if($params->{school_id}>0)
	{
		my $school = Webkit::SkillsAudit::School->load($self->{db}, {
			id => $params->{school_id} });

		$group_title = $school->name;
	}

	if($from_date!~/\d/)
	{
		my $from = Webkit::Date->now;
		my $to = Webkit::Date->now;

		$from->epoch_days(-365);
		$to->epoch_days(1);

		$from_date = $from->get_string({
			delimeter => ' / ' });

		$to_date = $to->get_string({
			delimeter => ' / ' });
	}

	$self->{from_date} = $from_date;
	$self->{to_date} = $to_date;

	my $from_sql = $self->get_target_date_sql($from_date);
	my $to_sql = $self->get_target_date_sql($to_date);

	$self->{from_sql_date} = $from_sql;
	$self->{to_sql_date} = $to_sql;

	$self->{group_title} = $group_title;
}

sub get_slice_options
{
	my ($self, $selected) = @_;

	if($selected) { $self->{slice} = $selected; }

	my $options = [
	{	title => 'Weeks',
		key => 'WEEK' },
	{	title => 'Months',
		key => 'MONTH' },
	{	title => 'Quarters',
		key => 'QUARTER' },
	{	title => 'Years',
		key => 'YEAR' } ];

	return Webkit::AppTools->get_select_options($options, {
		key_field => 'key',
		value_field => 'title',
		selected => $self->{slice} });
}

sub get_date_key_title
{
	my ($self, $key) = @_;

	$key =~ /^(\d+)-(\d+)$/;

	if($self->{slice} eq 'WEEK')
	{
		return "Wk $2 $1";
	}
	elsif($self->{slice} eq 'MONTH')
	{
		my $month = Webkit::BaseDate->get_monthname($2);

		return "$month $1";
	}
	elsif($self->{slice} eq 'QUARTER')
	{
		my $term_map = {
			term1 => 'Spr',
			term2 => 'Sum',
			term3 => 'Hols',
			term4 => 'Aut' };

		my $term = $term_map->{'term'.$2};

		return "$term $1";
	}
	else
	{
		return $1;
	}
}

sub get_audit_taken_refs
{
	my ($self) = @_;

	my $refs = $self->{db}->get_select_refs({
		table => 'skillsaudit.audit',
		cols => 'concat(monthname(taken), \' \', year(taken)) as date_string, count(*) as count',
		clause => 'org_id = ? and finished IS NOT NULL',
		binds => [$self->get_id],
		group => 'date_string',
		order => 'taken' });

	return $refs;
}

sub construct_query_ref
{
	my ($self, $params, $ref) = @_;

	if($params->{school_id}>0)
	{
		$ref->{clause}.=<<"+++";
and answer.school_id = ?
+++

		$ref->{visitor_clause}.=<<"+++";
and visitor.school_id = ?
+++

		$ref->{audit_count_clause}.=<<"+++";
and visitor.school_id = ?
+++

		push(@{$ref->{visitor_binds}}, $params->{school_id});
		push(@{$ref->{binds}}, $params->{school_id});
		push(@{$ref->{audit_count_binds}}, $params->{school_id});
	}
	else
	{
		$ref->{clause}.=<<"+++";
and answer.org_id = ?
+++

		$ref->{visitor_clause}.=<<"+++";
and visitor.org_id = ?
+++

		$ref->{audit_count_clause}.=<<"+++";
and visitor.org_id = ?
+++

		push(@{$ref->{visitor_binds}}, $self->get_id);
		push(@{$ref->{binds}}, $self->get_id);
		push(@{$ref->{audit_count_binds}}, $self->get_id);
	}

	my $add_visitor_table = undef;
	my $add_school_table = undef;
	

	if(($params->{keystage}=~/\w/)&&($params->{keystage}!='-1'))
	{
		$add_visitor_table = 1;

		my $part=<<"+++";
and visitor.key_stages like ?
+++

		$ref->{clause} .= $part;
		$ref->{visitor_clause} .= $part;
		$ref->{audit_count_clause} .= $part;

		push(@{$ref->{visitor_binds}}, '%'.$params->{keystage}.'%');
		push(@{$ref->{binds}}, '%'.$params->{keystage}.'%');
		push(@{$ref->{audit_count_binds}}, '%'.$params->{keystage}.'%');
	}

	if(($params->{subject}=~/\w/)&&($params->{subject}!='-1'))
	{
		$add_visitor_table = 1;

		my $part=<<"+++";
and visitor.subjects like ?
+++

		$ref->{clause} .= $part;
		$ref->{visitor_clause} .= $part;
		$ref->{audit_count_clause} .= $part;

		push(@{$ref->{visitor_binds}}, '%'.$params->{subject}.'%');		
		push(@{$ref->{binds}}, '%'.$params->{subject}.'%');
		push(@{$ref->{audit_count_binds}}, '%'.$params->{subject}.'%');
	}

	if(($params->{school_type}=~/\w/)&&($params->{school_type}!=-1))
	{
		$add_school_table = 1;

		my $part=<<"+++";
and school.type = ?
+++

		$ref->{clause} .= $part;
		$ref->{visitor_clause} .= $part;
		$ref->{audit_count_clause} .= $part;

		push(@{$ref->{visitor_binds}}, ''.$params->{school_type});
		push(@{$ref->{audit_count_binds}}, ''.$params->{school_type});
		push(@{$ref->{binds}}, ''.$params->{school_type});
	}

	if($params->{postcode}=~/\w/)
	{
		$add_school_table = 1;

		my $part=<<"+++";
and school.postcode like ?
+++

		$ref->{clause} .= $part;
		$ref->{visitor_clause} .= $part;
		$ref->{audit_count_clause} .= $part;

		push(@{$ref->{visitor_binds}}, ''.$params->{postcode}.'%');
		push(@{$ref->{audit_count_binds}}, ''.$params->{postcode}.'%');
		push(@{$ref->{binds}}, ''.$params->{postcode}.'%');
	}

	if($add_visitor_table)
	{
		if($ref->{table}!~/skillsaudit\.visitor/)
		{
			$ref->{table}.=', skillsaudit.visitor';

			$ref->{clause}.=<<"+++";
and answer.visitor_id = visitor.id
+++
		}
	}

	if($add_school_table)
	{
		if($ref->{table}!~/skillsaudit\.school/)
		{
			$ref->{table} .= ', skillsaudit.school';
			$ref->{visitor_table} .= ', skillsaudit.school';
			$ref->{audit_count_table} .= ', skillsaudit.school';

			$ref->{clause}.=<<"+++";
and audit.school_id = school.id
+++

			$ref->{visitor_clause}.=<<"+++";
and audit.school_id = school.id
+++

			$ref->{audit_count_clause}.=<<"+++";
and audit.school_id = school.id
+++
		}
	}
}

sub load_group_questions_analysis
{
	my ($self, $params) = @_;

	if($self->{_group_questions_loaded}) { return; }

	$self->{_group_questions_loaded} = 1;

	$self->assign_group_info($params);

	my $table=<<"+++";
skillsaudit.question,
skillsaudit.question_group,
skillsaudit.answer,
skillsaudit.audit
+++

	my $cols=<<"+++";
question_group.tag as tag,
question.tag as question_tag,
question.text as question_text,
question.numberorder as numberorder,
question_group.id as question_group_id,
question.id as question_id,
answer.answer as answer,
count(*) as count
+++

	my $clause=<<"+++";
answer.audit_id = audit.id
and answer.question_group_id = question_group.id
and answer.question_id = question.id
and audit.taken >= ?
and audit.taken <= ?
and audit.finished IS NOT NULL
and
(
	question_group.tag = ? or question_group.tag = ?
)
+++

	my $visitor_clause=<<"+++";
audit.visitor_id = visitor.id
and audit.taken >= ?
and audit.taken <= ?
and audit.finished IS NOT NULL
+++

	my $visitor_table=<<"+++";
skillsaudit.visitor,
skillsaudit.audit
+++

	my $binds = [$self->{from_sql_date}, $self->{to_sql_date}, 'resources', 'improvements'];
	my $visitor_binds = [$self->{from_sql_date}, $self->{to_sql_date}];

	my $ref = {
		clause => $clause,
		visitor_clause => $visitor_clause,
		table => $table,
		visitor_table => $visitor_table,
		binds => $binds,
		visitor_binds => $visitor_binds };

	$self->construct_query_ref($params, $ref);

	my $refs = $self->{db}->get_select_refs({
		table => $ref->{table},
		cols => $cols,
		clause => $ref->{clause},
		binds => $ref->{binds},
		group => 'question.tag, answer.answer',
		order => 'numberorder' });

	my $visitor_count_refs = $self->{db}->get_select_refs({
		table => $ref->{visitor_table},
		cols => 'visitor.id as id',
		clause => $ref->{visitor_clause},
		binds => $ref->{visitor_binds},
		group => 'visitor.id' });

	my $visitor_count = 0;

	if($visitor_count_refs)
	{
		$visitor_count = @$visitor_count_refs;
	}

	$self->{_visitor_count} = $visitor_count;

	foreach my $ref (@$refs)
	{
		push(@{$self->{question_refs}->{$ref->{tag}}->{$ref->{question_tag}}}, $ref);

		$self->{question_titles}->{$ref->{question_tag}} = $ref->{question_text};
	}
}

sub load_group_people
{
	my ($self, $params) = @_;

	my $operators = {
		low => '<',
		high => '>' };

	if($self->{_group_people_loaded}) { return; }

	$self->{_group_people_loaded} = 1;

	$self->assign_group_info($params);	

	if($params->{operator}!~/\w/) { $params->{operator} = 'low'; }
	if($params->{percent}!~/\d/) { $params->{percent} = 50; }
	if($params->{type}!~/\w/) { $params->{type} = 'people'; }

	$params->{operator_symbol} = $operators->{$params->{operator}};

	my $table=<<"+++";
skillsaudit.question,
skillsaudit.answer,
skillsaudit.audit,
skillsaudit.visitor
+++

	my $cols=<<"+++";
avg(answer.score_answer) as avg,
visitor.id as visitor_id,
visitor.name as visitor_name,
visitor.key_stages as key_stages,
visitor.subjects as subjects
+++

	my $clause=<<"+++";
answer.audit_id = audit.id
and answer.question_id = question.id
and answer.visitor_id = visitor.id
and question.type = ?
and audit.taken >= ?
and audit.taken <= ?
and audit.finished IS NOT NULL
+++

	### THIS IS FOR THE LEA VIEW
	if(!$params->{school_id}>0)
	{
		$table.=<<"+++";
,skillsaudit.school
+++

		$clause.=<<"+++";
and visitor.school_id = school.id
+++

		$cols.=<<"+++";
,school.name as school_name,school.type as school_type, school.id as school_id
+++
	}

	my $binds = ['score', $self->{from_sql_date}, $self->{to_sql_date}];

	my $ref = {
		clause => $clause,
		table => $table,
		binds => $binds };

	$self->construct_query_ref($params, $ref);

	my $order_desc = '';

	if($params->{operator} eq 'high')
	{
		$order_desc = ' DESC';
	}

	my $group = 'visitor.id';

	if($params->{type} eq 'school') { $group = 'school.id'; }

	my $refs = $self->{db}->get_select_refs({
		table => $ref->{table},
		cols => $cols,
		clause => $ref->{clause},
		binds => $ref->{binds},
		group => $group,
		order => 'avg'.$order_desc });

	if($params->{type} ne 'score')
	{
		$self->assign_group_people_by_people($params, $refs);
	}
	else
	{
		$self->assign_group_people_by_score($params, $refs);
	}
}

sub assign_group_people_by_people
{
	my ($self, $params, $refs) = @_;

	my $total_people = 0;

	if($refs)
	{
		$total_people = @$refs;
	}

	my $people_count = ($params->{percent} / 100) * $total_people;

	my $current_count = 0;
	my $match_count = 0;

	foreach my $ref (@$refs)
	{
		$current_count++;

		$self->{_eval_st}.="$current_count <= $people_count";

		if($current_count<=$people_count)
		{
			push(@{$self->{people_refs}}, $ref);

			$match_count++;
		}
	}

	$self->{_total_count} = $current_count;
	$self->{_match_count} = $match_count;
	$self->{_not_shown_count} = $current_count - $match_count;
}

sub assign_group_people_by_score
{
	my ($self, $params, $refs) = @_;

	my $highest = 0;
	my $lowest = 10;

	foreach my $ref (@$refs)
	{
		if($ref->{avg}>$highest)
		{
			$highest = $ref->{avg};
		}

		if($ref->{avg}<$lowest)
		{
			$lowest = $ref->{avg};
		}
	}

	my $gap = $highest - $lowest;
	my $operator = $params->{operator_symbol};
	my $percent = $params->{percent};
	my $compare_number = 0;
	my $percent_of_gap = ($percent/100) * $gap;	

	if($operator eq '<')
	{
		$compare_number = $lowest + $percent_of_gap;
	}
	else
	{
		$compare_number = $highest - $percent_of_gap;
	}

	my $compare_st = $operator.$compare_number;

	foreach my $ref (@$refs)
	{
		my $avg = $ref->{avg};
		my $matched = undef;

		my $eval_st=<<"+++";
if($avg $compare_st)
{
	\$matched = 1;
}
+++

		$self->{_eval_st}.=$eval_st;

		eval($eval_st);

		if($matched)
		{
			push(@{$self->{people_refs}}, $ref);

			$self->{_eval_st}.= ' - YES';
		}

		$self->{_eval_st} .= '<hr>';
	}
}

sub load_ict_summary
{
	my ($self, $params) = @_;

	if($self->{_ict_summary_loaded}) { return; }

	$self->{_ict_summary_loaded} = 1;

	my $slice = $params->{slice};
	my $subject = $params->{subject};
	my $tag = $params->{tag};

	if($slice!~/\w/) { $slice = 'YEAR'; }

	my ($year, $part) = split(/-/, $params->{date_key});

	my $cols=<<"+++";
visitor.name as visitor_name,
visitor.subjects as visitor_subjects,
question_group.subjects as question_subjects,
school.name as school_name,
audit.taken as audit_taken,
audit.id as audit_id,
answer.score_answer as score,
question_group.tag as tag
+++

	my $table=<<"+++";
skillsaudit.answer,
skillsaudit.visitor,
skillsaudit.school,
skillsaudit.question,
skillsaudit.question_group,
skillsaudit.audit
+++

	my $clause=<<"+++";
answer.audit_id = audit.id
and answer.question_group_id = question_group.id
and answer.question_id = question.id
and question.type = ?
and YEAR(audit.taken) = ?
and $slice(audit.taken) = ?
and audit.visitor_id = visitor.id
and visitor.school_id = school.id
and audit.finished IS NOT NULL
+++

	my $binds = ['ict', $year, $part];

	if($tag=~/\w/)
	{
		$clause.=<<"+++";
and question_group.tag = ?
+++

		push(@$binds, $tag);
	}

	if($params->{school_id}>0)
	{
		$clause.=<<"+++";
and answer.school_id = ?
+++

		push(@$binds, $params->{school_id});
	}
	else
	{
		$clause.=<<"+++";
and answer.org_id = ?
+++

		push(@$binds, $self->get_id);
	}

	my $refs = $self->{db}->get_select_refs({
		table => $table,
		cols => $cols,
		clause => $clause,
		binds => $binds,
		order => 'visitor.name',
		group => 'answer.id' });

	my $refs_by_audit_id;
	my $all_refs;

	foreach my $ref (@$refs)
	{
		my $visitor_map = $self->get_ict_subject_map($ref->{visitor_subjects});

		if(!$visitor_map->{$subject}) { next; }

		if($tag!~/\w/)
		{
			my $question_map = $self->get_ict_subject_map($ref->{question_subjects});

			if(!$question_map->{$subject}) { next; }
		}

		push(@$all_refs, $ref);

		my $existing = $refs_by_audit_id->{$ref->{audit_id}};

		if(!$existing)
		{
			$existing = $ref;
			$existing->{_count} = 1;
			$existing->{_total} = $ref->{score};

			$refs_by_audit_id->{$existing->{audit_id}} = $existing;
		}
		else
		{
			$existing->{_count}++;
			$existing->{_total} += $ref->{score};
		}
	}

	my @final_refs = values %$refs_by_audit_id;

	@final_refs = sort { $a->{visitor_name} cmp $b->{visitor_name} } @final_refs;
	
	$self->{_ict_summary_all_refs} = $all_refs;
	$self->{_ict_summary_refs} = \@final_refs;
}

sub load_ict_timeline
{
	my ($self, $params) = @_;

	if($self->{_ict_timeline_loaded}) { return; }

	$self->{_ict_timeline_loaded} = 1;

	$self->assign_group_info($params);

	$self->{slice} = $params->{slice};

	if($self->{slice}!~/\w/) { $self->{slice} = 'YEAR'; }

	my $slice = $self->{slice};

	my $table=<<"+++";
skillsaudit.answer,
skillsaudit.visitor,
skillsaudit.question,
skillsaudit.question_group,
skillsaudit.audit
+++

	my $cols=<<"+++";
count(*) as count,
sum(answer.score_answer) as total,
$slice(audit.taken) as period,
YEAR(audit.taken) as year,
question_group.tag as tag,
visitor.id as visitor_id,
visitor.subjects as visitor_subjects,
question_group.subjects as question_subjects
+++

	my $clause=<<"+++";
answer.audit_id = audit.id
and answer.question_group_id = question_group.id
and answer.question_id = question.id
and question.type = ?
and audit.taken >= ?
and audit.taken <= ?
and audit.visitor_id = visitor.id
and audit.finished IS NOT NULL
+++

	my $binds = ['ict', $self->{from_sql_date}, $self->{to_sql_date}];

	if($params->{school_id}>0)
	{
		$clause.=<<"+++";
and answer.school_id = ?
+++

		push(@$binds, $params->{school_id});
	}
	else
	{
		$clause.=<<"+++";
and answer.org_id = ?
+++

		push(@$binds, $self->get_id);
	}

	if(($params->{keystage}=~/\w/)&&($params->{keystage}!='-1'))
	{
		$clause.=<<"+++";
and visitor.key_stages like ?
+++

		push(@$binds, '%'.$params->{keystage}.'%');
	}

	my $refs = $self->{db}->get_select_refs({
		table => $table,
		cols => $cols,
		clause => $clause,
		binds => $binds,
		group => 'period, year, tag, visitor_id' });

	foreach my $ref (@$refs)
	{
		my $date_key = $ref->{year}.'-'.$ref->{period};
		$ref->{date_key} = $date_key;

		my $question_map = $self->get_ict_subject_map($ref->{question_subjects});
		my $visitor_map = $self->get_ict_subject_map($ref->{visitor_subjects});
		
		foreach my $key (keys %$question_map)
		{
			if($visitor_map->{$key})
			{
				$self->{_ict_map}->{$date_key}->{$ref->{tag}}->{$key}->{total} += $ref->{total};
				$self->{_ict_map}->{$date_key}->{$ref->{tag}}->{$key}->{count} += $ref->{count};

				$self->{_ict_map}->{$date_key}->{$ref->{tag}}->{total} += $ref->{total};
				$self->{_ict_map}->{$date_key}->{$ref->{tag}}->{count} += $ref->{count};

				$self->{_ict_map}->{$date_key}->{$key}->{total} += $ref->{total};
				$self->{_ict_map}->{$date_key}->{$key}->{count} += $ref->{count};

				$self->{_ict_map}->{$date_key}->{total} += $ref->{total};
				$self->{_ict_map}->{$date_key}->{count} += $ref->{count};
			}
		}
	}	

	my @date_keys = keys %{$self->{_ict_map}};

	@date_keys = sort { $self->sort_date_key_score($b) <=> $self->sort_date_key_score($a) } @date_keys;

	$self->{_date_keys} = \@date_keys;
}

sub sort_date_key_score
{
	my ($self, $date_key) = @_;

	$date_key =~ /^(\d+)-(\d+)$/;

	return $1 + ($2/100);
}

sub get_ict_subject_map
{
	my ($self, $string) = @_;

	if($self->{_ict_subject_maps}->{$string})
	{
		return $self->{_ict_subject_maps}->{$string};
	}

	my @subjects = split(/:/, $string);

	my $ret;

	foreach my $subject (@subjects)
	{
		$ret->{$subject} = 1;
	}

	$self->{_ict_subject_maps}->{$string} = $ret;

	return $ret;
}

sub load_group_timeline
{
	my ($self, $params) = @_;

	if($self->{_group_timeline_loaded}) { return; }

	$self->{_group_timeline_loaded} = 1;

	$self->assign_group_info($params);

	$self->{slice} = $params->{slice};

	if($self->{slice}!~/\w/) { $self->{slice} = 'MONTH'; }

	my $slice = $self->{slice};

	my $table=<<"+++";
skillsaudit.question,
skillsaudit.question_group,
skillsaudit.answer,
skillsaudit.audit
+++

	my $cols=<<"+++";
avg(answer.score_answer) as avg,
$slice(audit.taken) as period,
YEAR(audit.taken) as year,
question_group.tag as tag,
question_group.title as group_title
+++

	my $audit_count_cols=<<"+++";
count(*) as count,
$slice(audit.taken) as period,
YEAR(audit.taken) as year
+++

	my $clause=<<"+++";
answer.audit_id = audit.id
and answer.question_group_id = question_group.id
and answer.question_id = question.id
and question.type = ?
and audit.taken >= ?
and audit.taken <= ?
and audit.finished IS NOT NULL
+++

	my $visitor_clause=<<"+++";
audit.visitor_id = visitor.id
and audit.taken >= ?
and audit.taken <= ?
and audit.finished IS NOT NULL
+++

	my $visitor_table=<<"+++";
skillsaudit.visitor,
skillsaudit.audit
+++

	my $audit_count_table=<<"+++";
skillsaudit.visitor,
skillsaudit.audit
+++

	my $audit_count_clause=<<"+++";
audit.visitor_id = visitor.id
and audit.taken >= ?
and audit.taken <= ?
and audit.finished IS NOT NULL
+++

	my $binds = ['score', $self->{from_sql_date}, $self->{to_sql_date}];
	my $visitor_binds = [$self->{from_sql_date}, $self->{to_sql_date}];
	my $audit_count_binds = [$self->{from_sql_date}, $self->{to_sql_date}];

	my $ref = {
		clause => $clause,
		visitor_clause => $visitor_clause,
		table => $table,
		audit_count_table => $audit_count_table,
		audit_count_clause => $audit_count_clause,
		audit_count_binds => $audit_count_binds,
		visitor_table => $visitor_table,
		binds => $binds,
		visitor_binds => $visitor_binds };

	$self->construct_query_ref($params, $ref);

	my $refs = $self->{db}->get_select_refs({
		table => $ref->{table},
		cols => $cols,
		clause => $ref->{clause},
		binds => $ref->{binds},
		group => 'period, year, tag',
		order => 'period, year, tag' });

	my $visitor_count_refs = $self->{db}->get_select_refs({
		table => $ref->{visitor_table},
		cols => 'visitor.id as id',
		clause => $ref->{visitor_clause},
		binds => $ref->{visitor_binds},
		group => 'visitor.id' });

	my $audit_count_refs = $self->{db}->get_select_refs({
		table => $ref->{audit_count_table},
		cols => $audit_count_cols,
		clause => $ref->{audit_count_clause},
		binds => $ref->{audit_count_binds},
		group => 'period, year',
		order => 'period, year' });

	my $visitor_count = 0;

	if($visitor_count_refs)
	{
		$visitor_count = @$visitor_count_refs;
	}

	$self->{_visitor_count} = $visitor_count;

	foreach my $ref (@$refs)
	{
		$ref->{avg} = sprintf("%.2f", $ref->{avg});
		my $date_key = $ref->{year}.'-'.$ref->{period};
		$ref->{date_key} = $date_key;

		$self->{timeline_map}->{$date_key}->{$ref->{tag}} = $ref;
		$self->{timeline_map}->{$date_key}->{total} += $ref->{avg};
		$self->{timeline_map}->{$date_key}->{count}++;

		my $latest_title = $self->{latest_tag_titles}->{$ref->{tag}};

		$self->{timeline_tags}->{$ref->{tag}} = $ref->{group_title};
	}

	foreach my $audit_count_ref (@$audit_count_refs)
	{
		my $date_key = $audit_count_ref->{year}.'-'.$audit_count_ref->{period};
		$audit_count_ref->{date_key} = $date_key;

		$self->{audit_count_map}->{$date_key} = $audit_count_ref->{count};
	}

	my @date_keys = keys %{$self->{timeline_map}};

	foreach my $date_key (@date_keys)
	{
		my $total = $self->{timeline_map}->{$date_key}->{total};
		my $count = $self->{timeline_map}->{$date_key}->{count};

		my $avg = sprintf("%.2f", $total / $count);

		$self->{timeline_map}->{$date_key}->{avg} = $avg;
	}

	@date_keys = sort { $self->sort_date_key_score($a) <=> $self->sort_date_key_score($b) } @date_keys;

	$self->{date_keys} = \@date_keys;
}

sub load_group_targets
{
	my ($self, $params) = @_;

	if($self->{_group_targets_loaded}) { return; }

	$self->{_group_targets_loaded} = 1;

	$self->assign_group_info($params);

	my $table=<<"+++";
skillsaudit.question,
skillsaudit.question_group,
skillsaudit.answer,
skillsaudit.audit
+++

	my $cols=<<"+++";
avg(answer.score_answer) as avg, 
count(*) as count,
sum(answer.score_answer) as total,
question.tag as question_tag,
question_group.tag as question_group_tag,
question_group.title as group_title,
question.text as question_text,
question.priority as priority
+++

	my $clause=<<"+++";
answer.question_id = question.id
and answer.question_group_id = question_group.id
and answer.audit_id = audit.id
and question.type = ?
and audit.taken >= ?
and audit.taken <= ?
and audit.finished IS NOT NULL
+++

	my $visitor_clause=<<"+++";
audit.visitor_id = visitor.id
and audit.taken >= ?
and audit.taken <= ?
and audit.finished IS NOT NULL
+++

	my $visitor_table=<<"+++";
skillsaudit.visitor,
skillsaudit.audit
+++

	my $binds = ['score', $self->{from_sql_date}, $self->{to_sql_date}];
	my $visitor_binds = [$self->{from_sql_date}, $self->{to_sql_date}];


	my $ref = {
		clause => $clause,
		visitor_clause => $visitor_clause,
		table => $table,
		visitor_table => $visitor_table,
		binds => $binds,
		visitor_binds => $visitor_binds };

	$self->construct_query_ref($params, $ref);

	my $refs = $self->{db}->get_select_refs({
		table => $ref->{table},
		cols => $cols,
		clause => $ref->{clause},
		binds => $ref->{binds},
		group => 'question.tag' });

	my $visitor_count_refs = $self->{db}->get_select_refs({
		table => $ref->{visitor_table},
		cols => 'visitor.id as id',
		clause => $ref->{visitor_clause},
		binds => $ref->{visitor_binds},
		group => 'visitor.id' });

	my $visitor_count = 0;

	if($visitor_count_refs)
	{
		$visitor_count = @$visitor_count_refs;
	}

	$self->{_visitor_count} = $visitor_count;

	my $question_groups;

	foreach my $ref (@$refs)
	{
		my $question_group = $question_groups->{$ref->{question_group_tag}};

		push(@{$question_group->{refs}}, $ref);
		$question_group->{id} = $ref->{question_group_id};
		$question_group->{title} = $ref->{group_title};

		$question_groups->{$ref->{question_group_tag}} = $question_group;
	}

	my @question_group_array = values %{$question_groups};

	$self->{question_group_array} = \@question_group_array;

	my $good;
	my $bad;

	foreach my $group (@question_group_array)
	{
		$self->calculate_target_group($group);

		if($group->{is_good})
		{
			push(@$good, $group);
		}
		else
		{
			push(@$bad, $group);
		}
	}

	if($good)
	{
		@$good = sort { $b->{average_priority_score} <=> $a->{average_priority_score} } @$good;
	}
	else
	{
		$good = [];
	}

	if($bad)
	{
		@$bad = sort { $a->{average_priority_score} <=> $b->{average_priority_score} } @$bad;
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

sub get_group_targets_gd
{
	my ($self, $params) = @_;

	$self->load_group_targets($params);

	my $graph = GD::Graph::hbars->new(600, 400);

	$graph->set( 
#		y_label		=> 'Average Score',
		legend_placement => 'BC',
		shadow_depth	=> +3,
		bar_spacing	=> 10,
		text_space	=> 20,
#		show_values	=> 1,
		x_label_position => 0.5,
		borderclrs 	=> ['#000000'],
		fgclr 		=> '#000000',
		cycle_clrs	=> 1,
		shadowclr	=> '#c0c0c0',
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

	foreach my $question_group (@{$self->{question_group_array}})
	{
		push(@$titles, $question_group->{title});
		push(@$values, $question_group->{average_score});

		my $color = '#ffe5e5';

		if($question_group->{average_score}>=Webkit::SkillsAudit::Audit->good_boundary)
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

sub get_target_ref_priority_factor
{
	my ($self, $ref, $good) = @_;

	my $high = Webkit::SkillsAudit::Question->highest_priority;
	my $diff;

	if($good)
	{
		$diff = $high - $ref->{priority};
	}
	else
	{
		$diff = $ref->{priority} - 1;
	}

	my $factor = 1 + ($diff * (1/$high));

	return $factor;
}

sub get_target_ref_priority_score
{
	my ($self, $ref, $good) = @_;

	if($ref->{_priority_score}) { return $ref->{_priority_score}; }

	my $priority_score = sprintf("%.2f", $ref->{avg} * $self->get_target_ref_priority_factor($ref, $good));

	$ref->{_priority_score} = $priority_score;

	return $priority_score;
}

sub calculate_target_group
{
	my ($self, $group) = @_;

	my $answer_count = @{$group->{refs}};

	if($answer_count<=0) { return 0; }

	my $answers = $group->{refs};

	my $leading_answer;
	my $compare_symbol = '>';

	my $is_good = $self->is_target_group_good($group);

	foreach my $answer (@$answers)
	{
		my $score = $self->get_target_ref_priority_score($answer, $is_good);

		$group->{total_priority_score} += $score;
		$group->{total_score} += $answer->{avg};
	}

	if($is_good)
	{
		@$answers = sort { $b->{_priority_score} <=> $a->{_priority_score} } @$answers;
	}
	else
	{
		@$answers = sort { $a->{_priority_score} <=> $b->{_priority_score} } @$answers;
	}

	$group->{_order_array} = [$answers->[1], $answers->[2]];
	$group->{_leading_answer} = $answers->[0];
	$group->{average_priority_score} = sprintf("%.2f", $group->{total_priority_score} / $answer_count);
	$group->{average_score} = sprintf("%.2f", $group->{total_score} / $answer_count);	
}

sub is_target_group_good
{
	my ($self, $group) = @_;

	if($group->{_is_good_calculated}) { return $group->{is_good}; }

	$group->{_is_good_calculated} = 1;

	my $boundary = Webkit::SkillsAudit::Audit->good_boundary;

	my $avg = $group->{avg};

	if(!$avg)
	{
		my $count = 0;
		my $total = 0;

		foreach my $ref (@{$group->{refs}})
		{
			$total += $ref->{avg};
			$count++;
		}

		if($count>0)
		{
			$avg = $total / $count;
		}
		else
		{
			$avg = 0;
		}

		$group->{avg} = $avg;
	}

	my $is_good = undef;

	if($avg>=$boundary) { $is_good = 1; }

	$group->{is_good} = $is_good;

	return $is_good;
}

sub get_target_date_sql
{
	my ($self, $date) = @_;

	if($date =~ /^(\d+) ?\/ ?(\d+) ?\/ ?(\d+)$/)
	{
		my $day = $1;
		my $month = $2;
		my $year = $3;

		return $year.'-'.$month.'-'.$day;
	}

	return 'NULL';
}

sub get_group_timeline_gd
{
	my ($self, $params) = @_;

	$self->load_group_timeline($params);

	my $graph = GD::Graph::lines->new(600, 400);

	$graph->set( 
#		y_label		=> 'Avg Score',
		legend_placement => 'BC',
		shadow_depth	=> 2,
		bar_spacing	=> 10,
		text_space	=> 20,
		show_values	=> 1,
		x_label_position => 0.5,
		line_width	=> 1,
		borderclrs 	=> ['#000000'],
		fgclr 		=> '#000000',
		legendclr	=> '#000000',
		dclrs		=> ["#cc4444", "#4444cc", "#44cc44", "#cccc44"],
		shadowclr	=> '#c0c0c0',
		y_min_value	=> 0,
		y_max_value	=> 10,
		y_tick_number	=> 1   ) or die $graph->error;

	$graph->set_text_clr('#000000');

#	$graph->set_legend(@{$self->{_legend}});

	$graph->set_title_font('/home/webkit/app_files/fonts/tahoma.ttf', 14);
	$graph->set_legend_font('/home/webkit/app_files/fonts/tahoma.ttf', 10);

	$graph->set_x_label_font('/home/webkit/app_files/fonts/tahoma.ttf', 9);
	$graph->set_y_label_font('/home/webkit/app_files/fonts/tahoma.ttf', 9);

	$graph->set_x_axis_font('/home/webkit/app_files/fonts/tahoma.ttf', 9);
	$graph->set_y_axis_font('/home/webkit/app_files/fonts/tahoma.ttf', 9);

	$graph->set_values_font('/home/webkit/app_files/fonts/tahoma.ttf', 8);

	my $avg_arr;

	my $dates;
	my $avgs;

	foreach my $date_key (@{$self->{date_keys}})
	{
		my $title = $self->get_date_key_title($date_key);
		my $avg = $self->{timeline_map}->{$date_key}->{avg};

		push(@$dates, $title);
		push(@$avgs, $avg);
	}

	my $data = [$dates, $avgs];

	my $gd = $graph->plot($data) or die $graph->error;

	return $gd;
}

sub get_group_targets_js_date
{
	my ($self, $key) = @_;

	return $self->{'_group_target_js_date_'.$key};
}

sub get_keystage_options
{
	my ($self, $selected) = @_;

	return Webkit::AppTools->get_select_options(Webkit::SkillsAudit::Visitor->get_keystages, {
		null_title => 'Any',
		key_field => 'keystage',
		value_field => 'title',
		selected => $selected });
}

sub get_lea_people_type_options
{
	my ($self, $selected) = @_;

	my $options = [
		{ 	title => 'People',
			value => 'people' },
		{	title => 'Schools',
			value => 'school' }];

	return Webkit::AppTools->get_select_options($options, {
		key_field => 'value',
		value_field => 'title',
		selected => $selected });
}

sub get_people_type_options
{
	my ($self, $selected) = @_;

	my $options = [
		{ 	title => 'People',
			value => 'people' },
		{	title => 'Range Of Scores',
			value => 'score' }];

	return Webkit::AppTools->get_select_options($options, {
		key_field => 'value',
		value_field => 'title',
		selected => $selected });
}

sub get_people_operator_options
{
	my ($self, $selected) = @_;

	my $options = [
		{ 	title => 'Lowest Scoring',
			value => 'low' },
		{	title => 'Highest Scoring',
			value => 'high' }];

	return Webkit::AppTools->get_select_options($options, {
		key_field => 'value',
		value_field => 'title',
		selected => $selected });
}

sub get_people_percent_options
{
	my ($self, $selected) = @_;

	return Webkit::AppTools->get_number_select_options({
		min => 10,
		max => 90,
		gap => 10,
		selected => $selected });
}

sub get_subject_options
{
	my ($self, $selected) = @_;

	my $subject_map = Webkit::SkillsAudit::Visitor->get_subject_map;
	my $options;

	foreach my $key (@{Webkit::SkillsAudit::Visitor->get_subject_keys})
	{
		push(@$options, {
			title => Webkit::SkillsAudit::Visitor->subject_title($key),
			key => $key });
	}
	
	return Webkit::AppTools->get_select_options($options, {
		null_title => 'Any',
		key_field => 'key',
		value_field => 'title',
		selected => $selected });
}

sub get_school_type_options
{
	my ($self, $selected) = @_;

	return Webkit::AppTools->get_select_options(Webkit::SkillsAudit::School->get_types, {
		null_title => 'Any',
		key_field => 'type',
		value_field => 'title',
		selected => $selected });
}

1;
