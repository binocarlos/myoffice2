package Webkit::SkillsAudit::Admin;

use vars qw(@ISA);

use strict qw(vars);

use Webkit::Application;
use Webkit::Error;

use Webkit::SkillsAudit::Answer ();
use Webkit::SkillsAudit::Audit ();
use Webkit::SkillsAudit::AuditTemplate ();
use Webkit::SkillsAudit::Question ();
use Webkit::SkillsAudit::QuestionGroup ();
use Webkit::SkillsAudit::School ();
use Webkit::SkillsAudit::Visitor ();
use Webkit::SkillsAudit::WebAdmin ();
use Webkit::SkillsAudit::Org ();

use Webkit::SkillsAudit::QuestionTypes::MChoice ();
use Webkit::SkillsAudit::QuestionTypes::Radio ();
use Webkit::SkillsAudit::QuestionTypes::Score ();
use Webkit::SkillsAudit::QuestionTypes::Text ();

@ISA = qw(Webkit::Application);

my $app_name = 'skillsaudit';
my $app_title = 'Skills Audit';

my $manual_page_methods = {
	visitors_group_timeline_graph => 'header',
	visitors_group_targets_graph => 'header',
	visitors_timeline_graph => 'header',
	visitors_audit_graph => 'header',
	generate_window => 1 };

########################################################################################
########################################################################################
######################
# Boot
######################
########################################################################################
########################################################################################

sub app_name
{
	my ($self) = @_;

	return $app_name;
}

sub app_title
{
	my ($self) = @_;

	return $app_title;
}

sub manual_page_methods
{
	my ($self) = @_;

	return $manual_page_methods;
}

########################################################################################
########################################################################################
######################
# USER ORG Inheritance
######################
########################################################################################
########################################################################################

sub load_org
{
	my ($self, $attr) = @_;

	return Webkit::SkillsAudit::Org->load($self->{db}, $attr);
}

sub bless_org
{
	my ($self, $org) = @_;

	bless($org, 'Webkit::SkillsAudit::Org');
}

sub get_org_classname
{
	return 'Webkit::SkillsAudit::Org';
}

########################################################################################
########################################################################################
######################
# LOGIN
######################
########################################################################################
########################################################################################

sub generate_window
{
	my ($self, $attr) = @_;

	my $href = $self->href;

	my $packet = $self->{page}->get_template('menu');

	my $jsmenu = Webkit::JSMenu->with_content_new($packet, $self->{user});

	my $props = {
		menu => $jsmenu->{text},
		href => $href };

	foreach my $key (keys %$attr)
	{
		$props->{$key} = $attr->{$key};
	}

	my $template_code = $self->{page}->get_template('window', $props);

	$self->{page}->{manual_page} = $template_code;
}

sub audithome
{
	my ($self) = @_;

	$self->{page}->ab("This is the homepage for the Skills Audit System");
}


sub audit_template_home
{
	my ($self) = @_;

	my $defs = [
		{	title => 'ID',
			method => 'get_id',
			width => '50' },
		{	title => 'Name',
			prop => 'name',
			width => '*' },

		{	title => 'Created',
			method => 'get_created_string',
			width => '200' },
		{	title => 'Active',
			method => 'active',
			width => 100 } ];

	my $buttons = [
		{	key => 'add',
			title => 'Add Template',
			normal_method => 'audit_template_form' },
		{	key => 'edit',
			title => 'Edit Template',
			width => 120,
			method => 'audit_template_form' },
		{	key => 'activate',
			width => 120,
			title => 'Activate Template',
			method => 'audit_template_activate_submit' },
		{	key => 'delete',
			width => 120,
			title => 'Delete Template',
			method => 'audit_template_delete' } ];

	$self->{org}->load_audit_templates;

	$self->{page}->add_template('object_list', {
		defs => $defs,
		object_tag => 'audit_template',
		objects => $self->{org}->get_child_array('audit_template'),
		button_refs => $buttons });
}

sub audit_template_activate_submit
{
	my ($self) = @_;

	$self->{org}->load_audit_templates;

	$self->{db}->begin_transaction;

	foreach my $template (@{$self->{org}->ensure_child_array('audit_template')})
	{
		if($template->get_id==$self->{params}->{audit_template_id})
		{
			$template->active('y');
		}
		else
		{
			$template->active('n');
		}

		$template->save;
	}

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'audit_template_home' });
}

sub get_audit_template
{
	my ($self, $id) = @_;

	if($id!~/\d/)
	{
		$id = $self->{params}->{audit_template_id};
	}

	my $template;

	if($id=~/\d/)
	{
		$template = Webkit::SkillsAudit::AuditTemplate->load($self->{db}, {
			id => $id });
	}
	else
	{
		$template = Webkit::SkillsAudit::AuditTemplate->constructor($self->{db});
		$template->org_id($self->{org}->get_id);
	}

	return $template;
}

sub audit_template_form
{
	my ($self, $template) = @_;

	if(!$template) { $template = $self->get_audit_template; }

	$self->{page}->add_template('audit_template_form', {
		template => $template });
}

sub audit_template_form_submit
{
	my ($self) = @_;

	my $template = $self->get_audit_template;

	$template->save_form_params($self->{params});

	if($template->error)
	{
		$self->audit_template_form($template);

		return;
	}
	else
	{
		$self->{db}->begin_transaction;

		$template->save_or_create;

		$template->process_xml;

		$self->{db}->commit;

		$self->{page}->ab($template->get_log("<br>"));

#		$self->{page}->add_redir({
#			method => 'audit_template_home' });
	}
}

sub get_visitor
{
	my ($self, $id) = @_;

	if($id!~/\d/)
	{
		$id = $self->{params}->{visitor_id};
	}

	my $visitor;

	if($id=~/\d/)
	{
		$visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
			id => $id });
	}
	else
	{
		$visitor = Webkit::SkillsAudit::Visitor->constructor($self->{db});
	}

	return $visitor;
}

sub visitor_form
{
	my ($self, $visitor) = @_;

	if(!$visitor) { $visitor = $self->get_visitor; }

	$self->{page}->add_template('visitor_form', {
		school => $visitor->load_school,
		visitor => $visitor });
}

sub visitor_form_submit
{
	my ($self) = @_;

	my $visitor = $self->get_visitor;

	$visitor->save_admin_params($self->{params});

	if($visitor->error)
	{
		$self->visitor_form($visitor);
		return;
	}
	else
	{
		$self->{db}->begin_transaction;

		$visitor->save_or_create;

		$self->{db}->commit;

		$self->{page}->add_redir({
			school_id => $visitor->school_id,
			method => 'visitors_school_home' });
	}
}


sub schools_home
{
	my ($self) = @_;

	my $coldefs = [
		{	title => 'Name',
			prop => 'name',
			width => '*' },

		{	title => 'DfES Number',
			prop => 'dfes_number',
			width => 200 },

		{	title => 'City',
			prop => 'city',
			width => 200 } ];

	my $bdefs = {
		add => {	key => 'add',
				title => 'Add School',
				normal_method => 'school_form' },
		edit => {	key => 'edit',
				title => 'Edit School',
				method => 'school_form' },
		delete => {	key => 'delete',
				title => 'Delete School',
				method => 'school_delete' } };

	my $buttons;
	my $cols;

	if($self->{user}->is_webkit)
	{
		$buttons = [$bdefs->{add}, $bdefs->{edit}, $bdefs->{delete}];
		@$cols = ({
			title => 'ID',
			method => 'get_id',
			width => '50' }, @$coldefs);
	}
	else
	{
		$buttons = [$bdefs->{edit}];
		$cols = $coldefs;
	}

	$self->{org}->load_schools($self->{params});

	my $school_list = $self->{page}->get_template('object_list', {
		defs => $cols,
		object_tag => 'school',
		objects => $self->{org}->get_child_array('school'),
		button_refs => $buttons });

	$self->{page}->add_template('schools_home', {
		school_table => $school_list });
}

sub get_school
{
	my ($self, $id) = @_;

	if($id!~/\d/)
	{
		$id = $self->{params}->{school_id};
	}

	my $school;

	if($id=~/\d/)
	{
		$school = Webkit::SkillsAudit::School->load($self->{db}, {
			id => $id });
	}
	else
	{
		$school = Webkit::SkillsAudit::School->constructor($self->{db});
	}

	return $school;
}

sub school_form
{
	my ($self, $school) = @_;

	if(!$school) { $school = $self->get_school; }

	$self->{page}->add_template('school_form', {
		school => $school });
}

sub school_form_submit
{
	my ($self) = @_;

	my $school = $self->get_school;

	$school->save_form_params($self->{params});
	$school->org_id($self->{org}->get_id);

	if($school->error)
	{
		$self->school_form($school);
		return;
	}
	else
	{
		$self->{db}->begin_transaction;

		$school->save_or_create;

		$self->{db}->commit;

		$self->{page}->add_redir({
			method => 'schools_home' });
	}
}

sub school_delete
{
	my ($self) = @_;

	my $school = Webkit::SkillsAudit::School->load($self->{db}, {
		id => $self->{params}->{school_id} });

	my $message=<<"+++";
WARNING - by deleting this School - you will remove All:<p>
Visitors<br>
Audits<br>
School Analysis<p>
<b style="color:red;">Are you absolutely sure?</b>
+++

	$self->{page}->add_template('general_confirm', {
		title => 'Delete '.$school->get_value('name'),
		message => $message,
		object_id => $school->get_id,
		confirm_method => 'school_delete_confirm',
		cancel_method => 'schools_home' });
}

sub school_delete_confirm
{
	my ($self) = @_;

	my $school = Webkit::SkillsAudit::School->load($self->{db}, {
		id => $self->{params}->{object_id} });

	$self->{db}->begin_transaction;

	$school->delete_children('Webkit::SkillsAudit::Answer');
	$school->delete_children('Webkit::SkillsAudit::Audit');
	$school->delete_children('Webkit::SkillsAudit::Visitor');
	$school->delete_children('Webkit::SkillsAudit::VisitorSession');

	$school->delete;

	$self->{db}->commit;

	$self->{page}->add_redir({
		message => 'School and all data deleted....',
		method => 'schools_home' });
}

sub visitors_tree
{
	my ($self) = @_;

	$self->{org}->load_schools_with_visitors_count;

	$self->{page}->add_template('visitor_tree');
}

sub visitors_home
{
	my ($self) = @_;

	$self->{page}->ab("Visitors Home");
}

sub create_webapp_session
{
	my ($self, $school_id, $visitor_id) = @_;

	my $session = Webkit::SkillsAudit::VisitorSession->new_with_school_id($self->{db}, $self->{org}->get_id, $school_id, $visitor_id);

	$self->{db}->begin_transaction;

	$session->create;

	$self->{db}->commit;

	return $session->session_id;
}

sub get_webapp_proxy_address
{
	my ($self) = @_;

	my $domain = $self->get_httpd_variable('SkillsAuditProxyAddress');

	return $domain;
}

sub visitors_school_home
{
	my ($self) = @_;

	if($self->{params}->{visitor_id}>0)
	{
		my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
			id => $self->{params}->{visitor_id} });

		$self->{params}->{school_id} = $visitor->school_id;
	}

	my $session_id = $self->create_webapp_session($self->{params}->{school_id});

	my $domain = $self->get_webapp_proxy_address;

	my $new_loc = 'http://'.$domain.'/modal_toolbar_frameset.app?top_page=/admin/administrator/main_toolbar.htm&height=50&bottom_page=/admin/administrator/school_home.htm&session_id='.$session_id.'&visitor_id='.$self->{params}->{visitor_id};

	$self->{page}->ab(<<"+++");
Re-directing
<script>
	document.location = '$new_loc';
</script>
+++

}

sub visitors_school_home2
{
	my ($self) = @_;

	my $school = $self->get_school;

	$school->load_visitors_audits;

	$self->{page}->add_template('visitor_school_home', {
		school => $school });
}

sub visitors_group_questions_toolbar
{
	my ($self) = @_;

	$self->{org}->assign_group_info($self->{params});

	$self->{page}->add_template('visitor_group_questions_toolbar');
}

sub visitors_group_questions_home
{
	my ($self) = @_;

	$self->{org}->load_group_questions_analysis($self->{params});

	$self->{page}->add_template('visitor_group_questions_home', {
		calendar_table => $self->{page}->get_template('calendar') });
}

sub date_wizard
{
	my ($self) = @_;

	$self->{page}->add_template('date_wizard', {
		calendar_table => $self->{page}->get_template('calendar'),
		refs => $self->{org}->get_audit_taken_refs });
}

sub visitors_group_ict_toolbar
{
	my ($self) = @_;

	$self->{org}->assign_group_info($self->{params});

	$self->{page}->add_template('visitor_group_ict_toolbar');
}

sub visitors_group_ict_home
{
	my ($self) = @_;

	$self->{org}->load_ict_timeline($self->{params});

	$self->{page}->add_template('visitor_group_ict_home', {
		calendar_table => $self->{page}->get_template('calendar') });
}

sub visitors_group_ict_summary
{
	my ($self) = @_;

	$self->{org}->load_ict_summary($self->{params});

	$self->{page}->add_template('ict_summary');
}

sub visitors_group_people_toolbar
{
	my ($self) = @_;

	$self->{org}->load_group_people($self->{params});

	$self->{page}->add_template('visitor_group_people_toolbar');
}

sub visitors_group_people_home
{
	my ($self) = @_;

	$self->{org}->load_group_people($self->{params});

	$self->{page}->add_template('visitor_group_people_home', {
		calendar_table => $self->{page}->get_template('calendar') });
}

sub visitors_group_timeline_toolbar
{
	my ($self) = @_;

	$self->{org}->assign_group_info($self->{params});

	$self->{page}->add_template('visitor_group_timeline_toolbar');
}

sub visitors_group_timeline_home
{
	my ($self) = @_;

	$self->{org}->load_group_timeline($self->{params});

	$self->{page}->add_template('visitor_group_timeline_home', {
		calendar_table => $self->{page}->get_template('calendar') });
}

sub visitors_group_timeline_graph
{
	my ($self) = @_;

	my $gd = $self->{org}->get_group_timeline_gd($self->{params});

	my $content = $gd->png;

	my $length = length($content);

	print<<"+++";
Content-type: image/png
Content-length: $length

$content
+++
}

sub visitors_group_targets_toolbar
{
	my ($self) = @_;

	$self->{org}->assign_group_info($self->{params});

	$self->{page}->add_template('visitor_group_targets_toolbar');
}

sub visitors_group_targets_home
{
	my ($self) = @_;

	$self->{org}->load_group_targets($self->{params});

	$self->{page}->add_template('visitor_group_targets_home', {
		calendar_table => $self->{page}->get_template('calendar') });
}

sub visitors_group_targets_graph
{
	my ($self) = @_;

	my $gd = $self->{org}->get_group_targets_gd($self->{params});

	my $content = $gd->png;

	my $length = length($content);

	print<<"+++";
Content-type: image/png
Content-length: $length

$content
+++
}

sub visitors_timeline_home
{
	my ($self) = @_;

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $self->{params}->{visitor_id} });

	$visitor->load_timeline_analysis;

	$self->{page}->add_template('visitor_timeline_home', {
		school => $visitor->load_school,
		visitor => $visitor });
}

sub visitors_timeline_graph
{
	my ($self) = @_;

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $self->{params}->{visitor_id} });

	my $gd = $visitor->get_timeline_gd;

	my $content = $gd->png;

	my $length = length($content);

	print<<"+++";
Content-type: image/png
Content-length: $length

$content
+++
}

sub visitors_audit_home
{
	my ($self) = @_;

	my $audit = Webkit::SkillsAudit::Audit->load($self->{db}, {
		id => $self->{params}->{audit_id} });

	$audit->load_analysis;

	$self->{page}->add_template('visitor_audit_home', {
		school => $audit->load_school,
		audit => $audit,
		visitor => $audit->load_visitor });
}

sub visitors_audit_graph
{
	my ($self) = @_;

	my $audit = Webkit::SkillsAudit::Audit->load($self->{db}, {
		id => $self->{params}->{audit_id} });

	my $gd = $audit->get_analysis_gd;

	my $content = $gd->png;

	my $length = length($content);

	print<<"+++";
Content-type: image/png
Content-length: $length

$content
+++
}

1;
