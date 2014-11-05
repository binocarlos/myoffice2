package Webkit::SkillsAudit::Visitor;

use strict;

@Webkit::SkillsAudit::Visitor::ISA = qw(Webkit::DBObject);

my $schema = {
			org_id => {		type => 'id',
						required => 1 },

			school_id => {		type => 'id',
						required => 1 },

			admin => {		type => 'string',
						required => 1 },

			name => {		type => 'string',
						required => 1 },

			email_address => {		type => 'string' },

			phone_number => {	type => 'string' },

			pin_number => {		type => 'string',
						required => 1 },

			key_stages => {		type => 'string' },

			subjects => {		type => 'string' },

			reminder_question => {	type => 'string' },

			reminder_answer => {	type => 'string' } };

my $keystages = [
{	keystage => 'f',
	title => 'Foundation',
	subjects => 0, }, 
{	keystage => '1',
	title => '1',
	subjects => 0 },
{	keystage => '2',
	title => '2',
	subjects => 0 },
{	keystage => '3',
	title => '3',
	subjects => 1 },
{	keystage => '4',
	title => '4',
	subjects => 1 } ];


my $subject_map = {
	english => 'English',
	maths => 'Mathematics',
	science => 'Science',
	ict => 'ICT',
	languages => 'Foreign Languages',
	music => 'Music',
	history => 'History',
	geography => 'Geography',
	design_technology => 'Design Technology',
	art => 'Art and Design',
	pe => 'Physical Education',
	re => 'Religious Education',
	citizenship => 'Citizenship' };

my $theme_map = {
	communicating => 'Communicating',
	handling_data => 'Handling Data',
	control => 'Control',
	modelling => 'Modelling',
	monitoring => 'Monitoring' };

sub table
{
        return 'skillsaudit.visitor';
}

sub schema
{
        return $schema;
}

sub assign_data
{
	my ($self, $data) = @_;

	$self->SUPER::assign_data($data);

	$self->parse_flat_fields;
}

#### Turns the key_stages and subjects fields into in-memory arrays (fields are split by : in DB)

sub parse_flat_fields
{
	my ($self) = @_;

	my @key_stages = split(/:/, $self->key_stages);
	my @subjects = split(/:/, $self->subjects);

	$self->{key_stage_array} = \@key_stages;
	$self->{subject_array} = \@subjects;

	foreach my $key_stage (@key_stages)
	{
		$self->{key_stages}->{$key_stage} = 1;
	}

	foreach my $subject (@subjects)
	{
		$self->{subjects}->{$subject} = 1;
	}
}

sub save_firstcontact_params
{
	my ($self, $params) = @_;

	$self->name($params->{name});
	$self->email_address($params->{email_address});
	$self->phone_number($params->{phone_number});
	$self->subjects($params->{subjects});
	$self->key_stages($params->{key_stages});
}

sub save_admin_params
{
	my ($self, $params) = @_;

	$self->name($params->{name});
	$self->email_address($params->{email_address});
	$self->phone_number($params->{phone_number});

	if($params->{new_pin_number1}=~/\w/)
	{
		if($params->{new_pin_number1} eq $params->{new_pin_number2})
		{
			$self->pin_number($params->{new_pin_number1});
		}
	}
}

sub save_edit_params
{
	my ($self, $params) = @_;

	$self->{_original_email} = $self->email_address;

	$self->name($params->{name});

	$self->save_phone_number($params->{phone});
	$self->save_subjects_and_keystages($params);

	$self->{_actual_password} = $self->pin_number;
	$self->{_current_password} = lc($params->{current_password});
	$self->{_new_password1} = lc($params->{new_password1});
	$self->{_new_password2} = lc($params->{new_password2});

	$self->reminder_question($params->{reminder_question});
	$self->reminder_answer($params->{reminder_answer});


	if(($params->{new_password1}=~/\w/)||($params->{new_password2}=~/\w/)||($params->{current_password}=~/\w/))
	{
		$self->{_password_changed} = 1;
		$self->pin_number($params->{new_password1});
	}

	if($self->{_original_email} ne $self->email_address)
	{
		$self->{_email_changed} = 1;
	}
}

sub save_register_params
{
	my ($self, $params, $school) = @_;

	if($school)
	{
		if($school->real_school_id>0)
		{
			$self->{_other_school} = $school;

			$self->school_id($school->real_school_id);
		}
		else
		{
			$self->school_id($school->get_id);
		}
	}
	else
	{		
		$self->school_id($params->{school_id});
	}

	$self->name($params->{name});

	if($params->{noemail} eq 'y')
	{
		my $email = lc($self->name);

		$email =~ s/\W//g;

		my $existing_map;

		my $existing_refs = $self->{db}->get_select_refs({
			table => 'skillsaudit.visitor',
			cols => 'email_address',
			clause => 'org_id = ? and email_address like ?',
			binds => [$self->org_id, $email.'%'] });

		foreach my $ref (@$existing_refs)
		{
			my $existing = $ref->{email_address};

			if($existing!~/\@/)
			{
				$existing_map->{$existing} = 1;
			}
		}

		if($existing_map->{$email})
		{
			my $max_loops = 10000;
			my $loop_count = 1;
			my $found = undef;

			while((!$found)&&($loop_count<$max_loops))
			{
				my $test = $email.$loop_count;

				if(!$existing_map->{$test})
				{
					$email = $test;
					$found = 1;
				}

				$loop_count++;
			}
		}

		$self->email_address($email);
		$self->reminder_question($params->{reminder_question});
		$self->reminder_answer($params->{reminder_answer});
	}
	else
	{
		$self->email_address($params->{email});
		$self->reminder_question('');
		$self->reminder_answer('');
	}

	my $dfes_strip = Webkit::SkillsAudit::WebAdmin->dfes_strip;

	my $dfes = lc($params->{dfes});

	$dfes =~ s/\W//g;

	$dfes =~ s/^$dfes_strip//;

	$self->{_dfes} = $dfes;
	
	$self->pin_number($params->{password});

	$self->{_password1} = $params->{password};
	$self->{_password2} = $params->{password2};

	if($self->admin!~/\w/) { $self->admin('n'); }

	$self->save_phone_number($params->{phone});
	$self->save_subjects_and_keystages($params);
}

sub save_phone_number
{
	my ($self, $value) = @_;

	$value =~ s/\s//g;

	$self->phone_number($value);
}
	

sub save_subjects_and_keystages
{
	my ($self, $params) = @_;

	my $keystage_arr;
	my $subject_arr;

	my $keystage_map;

	foreach my $key (keys %$params)
	{
		if($key=~/^keystage_(\w+)$/)
		{
			push(@$keystage_arr, $1);
			$keystage_map->{$1} = 1;
		}

		if($key=~/^subject_(\w+)$/)
		{
			push(@$subject_arr, $1);
		}
	}

	if($keystage_arr)
	{
		$self->key_stages(join(':', @$keystage_arr));
	}
	else
	{
		$self->set_value('key_stages', '');
	}

	if($subject_arr)
	{
		$self->subjects(join(':', @$subject_arr));
	}
	else
	{
		$self->set_value('subjects', '');
	}

	$self->parse_flat_fields;
}

sub firstcontact_error
{
	my ($self) = @_;

	return $self->SUPER::error;
}

sub error
{
	my ($self) = @_;

	if(($self->exists)&&($self->{_password_changed}))
	{
		if($self->pin_number!~/\w/)
		{
			$self->{error_text} = 'Please enter a new password in order to change it';
			return 1;
		}
	}

	if($self->SUPER::error)
	{
		return 1;
	}

	if($self->email_address!~/\w/)
	{
		$self->{error_text} = 'The Email Address field is required';
		return 1;
	}

	if($self->email_address=~/\@/)
	{
		if(!Webkit::AppTools->check_email_address($self->email_address))
		{
			$self->{error_text} = $self->email_address.' is not a valid email address';
			return 1;
		}
	}

	if($self->phone_number=~/\w/)
	{
		if(!Webkit::AppTools->check_phone_number($self->phone_number))
		{
			$self->{error_text} = 'The phone number is invalid';
			return 1;
		}
	}

	if(!$self->exists)
	{
		my $school = Webkit::SkillsAudit::School->load($self->{db}, {
			id => $self->school_id });

		if(!$school)
		{
			$self->{error_text} = 'No School Found';
			return 1;
		}

		if($self->{_dfes} ne $school->dfes_number)
		{
			my $correct = undef;

			if($self->{_other_school})
			{
				if($self->{_dfes} eq $self->{_other_school}->dfes_number)
				{
					$correct = 1;
				}
			}

			if(!$correct)
			{
				$self->{error_text} = 'Incorrect DfES Number';
				return 1;
			}
		}

		if($self->{_password1} ne $self->{_password2})
		{
			$self->{error_text} = 'The 2 password do not match - please re-enter';
			return 1;
		}

		if(length($self->pin_number)<5)
		{
			$self->{error_text} = 'Your password must contain at least 5 characters';
			return 1;
		}

		if($self->pin_number =~ /\W/)
		{
			$self->{error_text} = 'Your password can only contain letters and numbers';
			return 1;
		}

		my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
			clause => 'org_id = ? and email_address = ?',
			binds => [$self->org_id, $self->email_address] });

		if($visitor)
		{
			$self->{error_text} = 'There is already a visitor with those details';
			return 1;
		}
	}
	else
	{
		if($self->{_password_changed})
		{
			if($self->{_current_password} ne $self->{_actual_password})
			{
				$self->{error_text} = 'Please enter the correct current password in order to change it';
				return 1;
			}

			if($self->{_new_password1} ne $self->{_new_password2})
			{
				$self->{error_text} = 'Your two passwords do not match - please re-enter';
				return 1;
			}

			if(length($self->pin_number)<5)
			{
				$self->{error_text} = 'Your password must contain at least 5 characters';
				return 1;
			}

			if($self->pin_number =~ /\W/)
			{
				$self->{error_text} = 'Your password can only contain letters and numbers';
				return 1;
			}
		}
	}

	return undef;
}

sub new_from_login
{
	my ($classname, $db, $params) = @_;

	my $username = $params->{username};
	my $pin = $params->{pin};

	if(($username!~/\w/)||($pin!~/\w/))
	{
		return;
	}

	my $clause=<<"+++";
pin_number = ?
and
(
	email_address = ?
or
	phone_number = ?
)
+++

	my $visitor = Webkit::SkillsAudit::Visitor->load($db, {
		clause => $clause,
		binds => [$pin, $username, $username] });

	return $visitor;
}

sub generate_session
{
	my ($self) = @_;

	if(!$self->{db}->in_transaction)
	{
		die "Visitor->generate_session requires a transaction"; 
	}

	my $session = Webkit::SkillsAudit::VisitorSession->new_with_visitor($self);

	$session->create;

	return $session;
}

sub generate_pin_number
{
	my ($self) = @_;

	return;

	my $found = 1;

	while($found)
	{
		my $codest_obj = new String::Random();

		my $codest = $codest_obj->randpattern("CCCCCC");

		my $exists = Webkit::SkillsAudit::Visitor->load($self->{db}, {
			clause => 'pin_number = ?',
			binds => [$codest] });

		if(!$exists)
		{
			$found = undef;
			$self->pin_number($codest);
		}
	}
}

sub load_school
{
	my ($self) = @_;

	if($self->{school})
	{
		return $self->{school};
	}

	my $school = Webkit::SkillsAudit::School->load($self->{db}, {
		id => $self->school_id });

	$self->{school} = $school;

	return $self->{school};
}

sub username
{
	my ($self) = @_;

	if($self->email_address=~/\w/)
	{
		return $self->email_address;
	}
	else
	{
		return $self->phone_number;
	}
}

sub can_see_subjects
{
	my ($self) = @_;

	foreach my $keystage (@$keystages)
	{
		if($keystage->{subjects})
		{
			if($self->has_keystage($keystage->{keystage}))
			{
				return 1;
			}
		}
	}

	return undef;
}

sub has_keystage
{
	my ($self, $key_stage) = @_;

	return $self->{key_stages}->{$key_stage};
}

sub can_have_subject
{
	my ($self) = @_;

	foreach my $keystage (@$keystages)
	{
		if( ($keystage->{subjects}) && ($self->has_keystage($keystage->{keystage})) )
		{
			return 1;
		}
	}

	return undef;
}

sub has_email
{
	my ($self) = @_;

	if(Webkit::AppTools->check_email_address($self->email_address))
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub has_subject
{
	my ($self, $subject) = @_;

	if(!$self->can_have_subject) { return undef; }

	my @subjects = keys %{$self->{subjects}};

	my $count = @subjects;

	if($count>0)
	{
		if($subject eq 'all')
		{
			return 1;
		}
		else
		{
			$self->{subjects}->{$subject};
		}
	}
	else
	{
		return undef;
	}
}

sub get_subject_map
{
	my ($self) = @_;

	return $subject_map;
}

sub get_keystages
{
	my ($self) = @_;

	return $keystages;
}

sub get_subject_keys
{
	my ($self) = @_;

	my @keys = sort keys %$subject_map;

	return \@keys;
}

sub keystage_title
{
	my ($self, $keystage) = @_;

	my $titles = {
		titlef => 'Foundation',
		title1 => 'KS1',
		title2 => 'KS2',
		title3 => 'KS3',
		title4 => 'KS4' };

	return $titles->{'title'.$keystage};
}

sub subject_title
{
	my ($self, $subject) = @_;

	return $subject_map->{$subject};
}	

sub keystage_checkbox
{
	my ($self, $keystage) = @_;

	my $checked = '';

	if($self->has_keystage($keystage))
	{
		$checked = ' CHECKED';
	}

	my $ret=<<"+++";
<input type="checkbox" name="keystage_$keystage" value="y"$checked onClick="reflowKeystages();">
+++

	return $ret;
}

sub subject_checkbox
{
	my ($self, $subject) = @_;

	my $checked = '';

	if($self->has_subject($subject))
	{
		$checked = ' CHECKED';
	}

	my $ret=<<"+++";
<input type="checkbox" name="subject_$subject" value="y"$checked>
+++

	return $ret;
}

sub load_all_audits
{
	my ($self) = @_;

	if(!$self->{_audits_loaded})
	{
		my $desc = ' DESC';

		$self->load_children('Webkit::SkillsAudit::Audit', {
			order => 'taken'.$desc });

		$self->{_audits_loaded} = 1;
	}
}	

sub load_audits
{
	my ($self, $rev) = @_;

	if(!$self->{_audits_loaded})
	{
		my $desc = ' DESC';
		if($rev) { $desc = ''; }

		$self->load_children('Webkit::SkillsAudit::Audit', {
			clause => 'finished IS NOT NULL',
			order => 'taken'.$desc });

		$self->{_audits_loaded} = 1;
	}
}

sub get_unfinished_audit
{
	my ($self) = @_;

	if($self->{_audits_loaded})
	{
		foreach my $audit (@{$self->ensure_child_array('audit')})
		{
			if(!$audit->finished)
			{
				return $audit;
			}
		}

		return undef;
	}
	else
	{
		return $self->load_unfinished_audit;
	}
}

sub load_previous_audit
{
	my ($self) = @_;

	if($self->{_previous_audit_loaded})
	{
		return $self->{_previous_audit};
	}

	$self->{_previous_audit_loaded} = 1;

	my $audit = Webkit::SkillsAudit::Audit->load($self->{db}, {
		clause => 'visitor_id = ?',
		binds => [$self->get_id],
		order => 'taken DESC' });

	$self->{_previous_audit} = $audit;
	$self->{_previous_audit_loaded} = 1;

	return $self->{_previous_audit};
}

sub load_unfinished_audit
{
	my ($self) = @_;

	if($self->{_unfinished_audit_loaded})
	{
		return $self->{_unfinished_audit};
	}

	my $audit = Webkit::SkillsAudit::Audit->load($self->{db}, {
		clause => 'visitor_id = ? and finished IS NULL',
		binds => [$self->get_id],
		order => 'taken DESC' });

	$self->{_unfinished_audit} = $audit;
	$self->{_unfinished_audit_loaded} = 1;

	return $self->{_unfinished_audit};
}

sub construct_new_audit
{
	my ($self, $audit_template_id) = @_;

	if($audit_template_id<=0) { die "Visitor->construct_new_audit requires an audit template id"; }

	my $audit = Webkit::SkillsAudit::Audit->constructor($self->{db});

	$audit->org_id($self->org_id);
	$audit->school_id($self->school_id);
	$audit->visitor_id($self->get_id);
	$audit->audit_template_id($audit_template_id);
	$audit->taken(Webkit::DateTime->now);

	return $audit;
}

sub get_answer_for_question
{
	my ($self, $question) = @_;

	return $self->{_question_answers}->{$question->get_id};
}

sub add_answer
{
	my ($self, $answer) = @_;

	$self->{_question_answers}->{$answer->question_id} = $answer;
	push(@{$self->{_question_group_answers}->{$answer->question_group_id}}, $answer);
}

sub load_answers_for_question_group_and_audit
{
	my ($self, $question_group, $audit) = @_;

	if((!$question_group)||(!$audit)) { die "load_answers_for_question_group_and_audit needs a question_group and audit"; }

	$self->load_children('Webkit::SkillsAudit::Answer', {
		clause => 'question_group_id = ? and audit_id = ?',
		binds => [$question_group->get_id, $audit->get_id] });

	foreach my $answer (@{$self->ensure_child_array('answer')})
	{
		$self->add_answer($answer);
	}
}

sub can_see_question_group
{
	my ($self, $question_group) = @_;

	my $subject_array = $question_group->subject_array;
	my $keystage_array = $question_group->keystage_array;

	my $required_count = 0;
	my $found_count = 0;

	foreach my $subject (@$subject_array)
	{
		$required_count++;

		if($self->has_subject($subject))
		{
			$found_count++;
		}
	}

	foreach my $keystage (@$keystage_array)
	{
		$required_count++;

		if($self->has_keystage($keystage))
		{
			$found_count++;
		}
	}

	if($required_count<=0)
	{
		return 1;
	}
	elsif($found_count>0)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub can_see_subject_string
{
	my ($self, $string) = @_;

	my @subject_array = split(/:/, $string);

	my $required_count = 0;
	my $found_count = 0;

	foreach my $subject (@subject_array)
	{
		$required_count++;

		if($self->has_subject($subject))
		{
			$found_count++;
		}
	}

	if($required_count<=0)
	{
		return 1;
	}
	elsif($found_count>0)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}


sub can_see_keystage_string
{
	my ($self, $string) = @_;

	my @keystage_array = split(/:/, $string);

	my $required_count = 0;
	my $found_count = 0;

	foreach my $keystage (@keystage_array)
	{
		$required_count++;

		if($self->has_keystage($keystage))
		{
			$found_count++;
		}
	}

	if($required_count<=0)
	{
		return 1;
	}
	elsif($found_count>0)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub can_see_question
{
	my ($self, $question) = @_;

	my $subject_array = $question->subject_array;
	my $keystage_array = $question->keystage_array;

	my $required_count = 0;
	my $found_count = 0;

	foreach my $subject (@$subject_array)
	{
		$required_count++;

		if($self->has_subject($subject))
		{
			$found_count++;
		}
	}

	foreach my $keystage (@$keystage_array)
	{
		$required_count++;

		if($self->has_keystage($keystage))
		{
			$found_count++;
		}
	}

	if($required_count<=0)
	{
		return 1;
	}
	elsif($found_count>0)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub get_timeline_gd
{
	my ($self) = @_;

	my $graph = GD::Graph::lines->new(600, 400);

	$graph->set( 
		legend_placement => 'BC',
		shadow_depth	=> 2,
		bar_spacing	=> 10,
		text_space	=> 20,
		show_values	=> 1,
		x_label_position => 0.5,
		x_label		=> 'Average Score For Each Audit',
		line_width	=> 1,
		borderclrs 	=> ['#000000'],
		fgclr 		=> '#000000',
		legendclr	=> '#000000',
		dclrs		=> ["#cc4444", "#44cc44", "#4444cc", "#cccc44"],
		shadowclr	=> '#c0c0c0',
		y_min_value	=> 0,
		y_max_value	=> 10,
		y_tick_number	=> 10  ) or die $graph->error;

	$graph->set_text_clr('#000000');

#	$graph->set_legend(@{$self->{_legend}});

	$graph->set_title_font('/home/webkit/app_files/fonts/tahoma.ttf', 14);
	$graph->set_legend_font('/home/webkit/app_files/fonts/tahoma.ttf', 10);

	$graph->set_x_label_font('/home/webkit/app_files/fonts/tahoma.ttf', 9);
	$graph->set_y_label_font('/home/webkit/app_files/fonts/tahoma.ttf', 9);

	$graph->set_x_axis_font('/home/webkit/app_files/fonts/tahoma.ttf', 9);
	$graph->set_y_axis_font('/home/webkit/app_files/fonts/tahoma.ttf', 9);

	$graph->set_values_font('/home/webkit/app_files/fonts/tahoma.ttf', 8);

	$self->load_timeline_analysis;

	my $avg_arr;

	my $dates;
	my $avgs;
	my $ict_avgs;

	foreach my $audit (@{$self->ensure_child_array('audit')})
	{
		my $ict_avg = $self->{_ict_avgs}->{$audit->get_id};

		if($ict_avg!~/\d/)
		{
			$ict_avg = 0;
		}

		push(@$dates, $audit->taken_date);
		push(@$avgs, $audit->{_avg});
		push(@$ict_avgs, $ict_avg);
	}

	my $data = [$dates, $avgs];

	if($self->can_have_subject)
	{
		push(@$data, $ict_avgs);
	}

	my $gd = $graph->plot($data) or die $graph->error;

	return $gd;
}

sub load_timeline_analysis
{
	my ($self) = @_;

	my $avgs = $self->{db}->get_select_refs({
		table => 'skillsaudit.answer, skillsaudit.question, skillsaudit.question_group',
		cols => 'question_group.tag as tag, question_group.title as title, avg(answer.score_answer) as avg, answer.audit_id as audit_id',
		clause => 'answer.question_id = question.id and question.question_group_id = question_group.id and question.type = ? and answer.visitor_id = ?',
		binds => ['score', $self->get_id],
		group => 'answer.audit_id, answer.question_group_id' });

	$self->load_audits(1);

	foreach my $avg_ref (@$avgs)
	{
		$avg_ref->{avg} = sprintf("%.2f", $avg_ref->{avg});

		my $audit_id = $avg_ref->{audit_id};

		my $avg = $avg_ref->{avg};
		my $tag = $avg_ref->{tag};

		my $audit = $self->get_child('audit', $audit_id);

		$audit->{_avg_total} += $avg;
		$audit->{_avg_count}++;

		$audit->{_tag_avgs}->{$tag} = $avg_ref->{avg};

		$self->{_tag_titles}->{$avg_ref->{tag}} = $avg_ref->{title};
	}

	foreach my $audit (@{$self->ensure_child_array('audit')})
	{
		my $count = $audit->{_avg_count};
		my $total = $audit->{_avg_total};

		if($count<=0)
		{
			$audit->{_avg} = 0;
		}
		else
		{
			$audit->{_avg} = sprintf("%.2f", $total/$count);
		}
	}

	if($self->can_have_subject)
	{
		my $ict_avgs = $self->{db}->get_select_refs({
			table => 'skillsaudit.answer, skillsaudit.question',
			cols => 'avg(answer.score_answer) as avg, answer.audit_id as audit_id',
			clause => 'answer.question_id = question.id and question.type = ? and answer.visitor_id = ?',
			binds => ['ict', $self->get_id],
			group => 'answer.audit_id' });

		foreach my $ict_avg (@$ict_avgs)
		{
			my $audit_id = $ict_avg->{audit_id};

			$self->{_ict_avgs}->{$audit_id} = sprintf("%.2f", ($ict_avg->{avg}+10)/4);
		}
	}

}

sub email_or_phone
{
	my ($self) = @_;

	my $ret = $self->email_address;

	if($ret!~/\w/) { $ret = $self->phone_number; }

	return $ret;
}

sub is_admin
{
	my ($self) = @_;

	if($self->admin eq 'y')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub get_admin_checked
{
	my ($self) = @_;

	my $ret = '';

	if($self->is_admin)
	{
		$ret = ' CHECKED';
	}

	return $ret;
}

sub get_reminder_question_options
{
	my ($self) = @_;

	my $options = ["Date of Birth", "Place of Birth", "Mother's Maiden Name", "Favourite Colour", "Pet's Name"];
	my $refs;

	foreach my $option (@$options)
	{
		push(@$refs, {
			title => $option,
			value => $option });
	}

	return Webkit::AppTools->get_select_options($refs, {
		key_field => 'value',
		value_field => 'title',
		selected => $self->reminder_question });
}

sub hidden_pin_number
{
	my ($self) = @_;

	my $pin = $self->pin_number;

	$pin =~ s/./\*/g;

	return $pin;
}

sub get_email_andor_phone
{
	my ($self) = @_;

	my $parts;

	if($self->email_address=~/\w/)
	{
		push(@$parts, 'e : '.$self->email_address);
	}

	if($self->phone_number=~/\w/)
	{
		push(@$parts, 'p : '.$self->phone_number);
	}

	if(!$parts) { return ''; }

	my $ret = join(', ', @$parts);

	return $ret;
}

sub get_firstcontact_finished_title
{
	my ($self) = @_;

	my $date = Webkit::DateTime->parse_from_sql($self->{data}->{finished});

	if(!$date) { return ''; }

	return $date->get_string;
}

1;
