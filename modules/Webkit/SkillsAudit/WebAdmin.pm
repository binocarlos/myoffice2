package Webkit::SkillsAudit::WebAdmin;

use vars qw(@ISA);

use strict qw(vars);

use Webkit::WebApplication;
use Webkit::Error;

@ISA = qw(Webkit::WebApplication);

my $app_name = 'skillsauditweb';
my $app_title = 'Skills Audit Website';

my $manual_page_methods = { };

#my $admin_email = 'fionadavies@wiltshire.gov.uk';
#my $admin_email = 'elaineharbour@wiltshire.gov.uk';

#my $wiltshire_admin_email = 'cindygreeley@wiltshire.gov.uk';

my $wiltshire_admin_email = 'beverleymessam@wiltshire.gov.uk';
my $nsomerset_admin_email = 'admin@ns-ictacaudit.org.uk';

my $admin_emails = {
	default => $wiltshire_admin_email,
	wiltshire => $wiltshire_admin_email,
	nsomerset => $nsomerset_admin_email };

########################################################################################
########################################################################################
######################
# SQL LOG
######################
########################################################################################
########################################################################################

my $sql_log=<<"+++";


+++

########################################################################################
########################################################################################
######################
# INCLUDES - for speed
######################
########################################################################################
########################################################################################

my $wiltshire_page_include=<<"+++";
<HTML> 
  <HEAD> 
	 <TITLE>Wiltshire LEA Skills Audit</TITLE>
<link rel="stylesheet" type="text/css" href="/lib/lib.css">
  </HEAD> 
<BODY class="normal">
<TABLE WIDTH="770" BORDER="0" CELLPADDING="0" CELLSPACING="0" align="center">
<TR>
  <TD HEIGHT="76" ALIGN="LEFT" VALIGN="TOP" WIDTH="203"><IMG SRC="/images/lea_logo.gif" WIDTH="203" HEIGHT="56" BORDER="0"></TD>
  <TD HEIGHT="76" ALIGN="RIGHT" VALIGN="TOP" WIDTH="100%"><IMG SRC="/images/skillsaudit.gif" WIDTH="160" HEIGHT="56" BORDER="0"></TD>
</TR>
</TABLE>
<TABLE WIDTH="770" BORDER="0" CELLPADDING="0" CELLSPACING="0" align="center">
<TR>
<TD WIDTH="100%" CLASS="content" ALIGN="LEFT" VALIGN="TOP"><content></TD>
</tr>
</TABLE>
</BODY>
</HTML>
+++

my $nsomerset_page_include=<<"+++";
<html> 
  <head> 
	 <TITLE>North Somerset</TITLE>
<link rel="stylesheet" type="text/css" href="/lib/lib.css">
  </head> 
<body bgcolor="#ffffff">
<div align="center" id="toplinks">
<table cellpadding="6" cellspacing="0" border="0" width="775">
<tr>
<td>
<b><a href="#maincontent">Skip navigation</a></b> | 
<b><a href="http://www.n-somerset.gov.uk/Your+Council/Communication+and+information/Website/websiteaccessibility.htm">Accessibility</a></b> | 
<b><a href="http://www.n-somerset.gov.uk/Your+Council/Communication+and+information/Contact+Us">Contact us</a></b> | 
<b><a href="http://www.n-somerset.gov.uk/atoz">A-Z</a></b> | 
<b><a href="http://www.n-somerset.gov.uk/faqlisting">FAQs</a></b>
</td>
</tr>
</table>
</div>
<div align="center" id="headerimg">
<map name="header">
<area alt="" coords="1,99,49,121" href="http://www.n-somerset.gov.uk/">
<area alt="" coords="50,98,142,121" href="http://www.n-somerset.gov.uk/Your+Council/">
<area alt="" coords="142,98,210,122" href="http://www.n-somerset.gov.uk/Business/">
<area alt="" coords="210,97,293,121" href="http://www.n-somerset.gov.uk/Community/">
<area alt="" coords="292,98,369,121" href="http://www.n-somerset.gov.uk/Education/">
<area alt="" coords="370,99,461,121" href="http://www.n-somerset.gov.uk/Environment/">
<area alt="" coords="461,98,520,122" href="http://www.n-somerset.gov.uk/Leisure/">
<area alt="" coords="520,99,603,122" href="http://www.n-somerset.gov.uk/Social+care/">
<area alt="" coords="604,97,676,121" href="http://www.n-somerset.gov.uk/Transport/">
</map>
<img src="/images/header.gif" width="775" height="129" border="0" usemap="#header">
</div>
<center>
<a name="maincontent"></a>
<content>
</center>
</body>
</html>
+++

my $page_includes = {
	default => $wiltshire_page_include,
	wiltshire => $wiltshire_page_include,
	nsomerset => $nsomerset_page_include };

my $panel_include=<<"+++";
<table cellpadding="0" cellspacing="0" border="0" width="<width>">
<tr><td class="panel_header"><title></td></tr>
<tr><td height="2"></td></tr>
<tr><td class="panel_body"><content></td></tr>
<tr><td height="2"></td></tr>
<tr><td class="panel_footer"></td></tr>
</table>
+++

my $adminmenu_include=<<"+++";
<a href="/admin/index.htm?session_id=<session_id>" class="location" id="homeLink">Account Home</a> | <a href="/admin/edit_details.htm?session_id=<session_id>" class="location">Edit Account Details</a> | <a href="/admin/administrator.htm?session_id=<session_id>" class="location">Administrator Access</a> | <a href="/index.htm" class="location">Log Out</a>
+++

my $calendar_include=<<"+++";
<script>
	var calendarGui = null;
	
		giMinYear = 2000;

		giMaxYear = 2010;
		
	function callback_obj()
	{
		this.purpose = 'to provide a place to stick a function callback for a change of date';
		
		return this;
	}
	
	function reset_calendar()
	{
		set_calendar_display(false);
			
		calendarGui	= null;
	}
	
	function accept_calendar()
	{
		var cal = document.getElementById('calendar');
		
		var st = cal.day + ' / ' + cal.month + ' / ' + cal.year;
		
		if(calendarGui)
		{
			calendarGui.value = st;
			
			if(calendar_callback_obj.onUpdate)
			{
				calendar_callback_obj.onUpdate(calendarGui);
			}
		}
		
		reset_calendar();
	}
	
	function calendar_click(gui)
	{
		if(set_calendar_date(gui.value))
		{
			calendarGui = gui;
			
			set_calendar_display(true);
		}
		else
		{
			alert('There is a problem with ' + gui.value);
		}
		
	}
	
	function set_calendar_date(datest)
	{
		var arr = new Array();
		
		if((!datest)||(datest==''))
		{
			var dt = new Date();
			
			arr[0] = dt.getDate();
			arr[1] = dt.getMonth() + 1;
			arr[2] = dt.getFullYear();
		}
		else
		{
			datest = datest.replace(/ /g, "");
			arr = datest.split("/");
		
			for(var i=0; i<arr.length; i++)
			{
				var st = arr[i];
				st = st.replace(/^0+/, "");
				
				var val = parseInt(st);
			
				if(val>0)
				{
					arr[i] = val;
				}
				else
				{
					return false;
				}
			}
		}
		
		var cal = document.getElementById('calendar');
		
		cal.day = arr[0];
		cal.month = arr[1];
		cal.year = arr[2];
		
		return true;		
	}
	
	function set_calendar_display(mode)
	{
		if(mode)
		{
			var ctable = document.getElementById('calendar_table');
			var ciframe = document.getElementById('calendar_iframe');		
				
			var bodywidth = document.body.clientWidth;
			var bodyheight = document.body.clientHeight;
			var cwidth = 260;
			var cheight = 260;		
		
			var cx = (bodywidth/2) - (cwidth/2);
			var cy = (bodyheight/2) - (cheight/2);
		
			ciframe.style.top = cy;
			ciframe.style.left = cx;
			ciframe.style.display = 'inline';					
				
			ctable.style.top = cy;
			ctable.style.left = cx;
			ctable.style.display = 'inline';
			
			ciframe.style.width = ctable.clientWidth;
			ciframe.style.height = ctable.clientHeight;		
		}
		else
		{
			var ctable = document.getElementById('calendar_table');		
			var ciframe = document.getElementById('calendar_iframe');
					
			ctable.style.display = 'none';
			ciframe.style.display = 'none';		
		}
	}
	
	calendar_callback_obj = new callback_obj();
</script>
	
<span id="calendar_iframe" style="background-color:#ffffff;width:272px;height:323px;left:0px;top:0px;display:none;position:absolute;z-index:1000;"> 
<iframe width=272 height=323 scrolling=no src="/wk/templates/blank.htm"></iframe>
</span>
  
<TABLE id="calendar_table" style="left:0px;top:0px;width:260px;height:260px;display:none;position:absolute;z-index:1010;" BORDER="0" CELLPADDING="0" CELLSPACING="0" CLASS="panelouter"> 
<tr>		
<td class="panelinner" style="padding:3px; color:#FFFFFF;" bgcolor="#0A246A" height="2"><b>Calendar</b></td>
</tr>
  <TR> 
	 
<TD HEIGHT="100%" align="center"> 
		<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0"
		 CLASS="panelinner"> 
		  <TR> 
			 <TD CLASS="panelbody"> 
				<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="8"> 
				  <TR> 
					 
<TD COLSPAN="2" ALIGN="right" height="58"> 
						
<DIV ID="calendar" STYLE="behavior:url(/wk/lib/calendar.htc); width:250px; height:250px;"></DIV>
<IMG src="/wk/images/layout/clear.gif" BORDER="0" WIDTH="1" HEIGHT="8"><BR><INPUT
						TYPE="button" VALUE="OK" STYLE="width:75px;"
						ONCLICK="accept_calendar();" CLASS="button"><IMG
						src="/wk/images/layout/clear.gif" BORDER="0" WIDTH="8" HEIGHT="1"><INPUT
						TYPE="button" VALUE="Cancel" STYLE="width:75px;" ONCLICK="reset_calendar();"
						CLASS="button">
 </TD> 
				  </TR> 
				</TABLE></TD> 
		  </TR> 
		</TABLE>
</TD> 
  </TR> 
</TABLE>		
+++


sub get_page_include
{
	my ($self, $props) = @_;

	my $org_key = $self->org_key;

	my $ret = $page_includes->{$org_key};

	my $content = $props->{content};
	my $title = $props->{title};

	$ret =~ s/<content>/$content/;
	$ret =~ s/<title>/$title/;

	return $ret;
}

sub get_panel_include
{
	my ($self, $props) = @_;

	my $ret = $panel_include;
	my $content = $props->{content};
	my $title = $props->{title};
	my $width = $props->{width};

	$content =~ s/^\s+//;
	$content =~ s/\s+$//;

	$ret =~ s/<content>/$content/;
	$ret =~ s/<title>/$title/;
	$ret =~ s/<width>/$width/;

	return $ret;
}

sub get_adminmenu_include
{
	my ($self, $props) = @_;

	my $ret = $adminmenu_include;
	my $session_id = $props->{session_id};

	$ret =~ s/<session_id>/$session_id/g;

	return $ret;
}

sub get_calendar_include
{
	my ($self, $props) = @_;

	my $ret = $calendar_include;
	
	return $ret;
}

sub get_template_for_output
{
	my ($self, $filename) = @_;

	my $filecontent = $self->get_template($filename);

	return $self->parse_page_includes($filecontent);
}

sub test_page_handler
{
	my ($self) = @_;

	$self->{page_content} = 'the test is '.$self->{params}->{test_text};
}

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

sub handler
{
	my ($r) = @_;

	return &Webkit::WebApplication::handler($r, 'Webkit::SkillsAudit::WebAdmin');
}

sub org_id
{
	my ($classname) = @_;

	my $r = Webkit::Application->r || return;

	return $r->dir_config('OrgId');
}

sub get_admin_email
{
	my ($self) = @_;

	my $org_key = $self->org_key;

	return $admin_emails->{$org_key};
}

sub org_key
{
	my ($classname) = @_;

	my $r = Webkit::Application->r || return;

	my $ret = $r->dir_config('ORGKey');

	if($ret!~/\w/)
	{
		$ret = 'default';
	}

	return $ret;
}

sub dfes_strip
{
	my ($classname) = @_;

	my $r = Webkit::Application->r || return;

	return $r->dir_config('DFESStrip');
}

sub load_org
{
	my ($self) = @_;

	if($self->{org}) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$self->{org} = $org;
	$self->{page_props}->{objs}->{org} = $org;
}

sub load_audit_template
{
	my ($self) = @_;

	if($self->{audit_template}) { return; }

	my $audit_template = Webkit::SkillsAudit::AuditTemplate->load($self->{db}, {
		clause => 'org_id = ? and active = ?',
		binds => [$self->org_id, 'y'] });

	$self->{audit_template} = $audit_template;
	$self->{page_props}->{objs}->{audit_template} = $audit_template;

	return $audit_template;
}

sub construct_visitor
{
	my ($self, $school_id) = @_;

	if($self->{visitor}) { return; }

	my $visitor = Webkit::SkillsAudit::Visitor->constructor($self->{db});

	$visitor->school_id($school_id);
	$visitor->name('Admin Visitor');

	$self->{visitor} = $visitor;
	$self->{page_props}->{objs}->{visitor} = $visitor;

	return $visitor;
}

sub load_visitor
{
	my ($self, $id) = @_;

	if($self->{visitor}) { return; }

	if($id!~/\d/) { $id = $self->{params}->{visitor_id}; }

	if($id!~/\d/)
	{
		if($self->{session})
		{
			$id = $self->{session}->visitor_id;
		}
	}

	if($id!~/\d/) { die "You must give an id to call load_visitor"; }

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $id });

	$self->{visitor} = $visitor;
	$self->{page_props}->{objs}->{visitor} = $visitor;

	return $visitor;
}

sub load_session
{
	my ($self) = @_;

	my $session_id = $self->{params}->{session_id};

	if($session_id!~/\w/) { return undef; }

	my $session = Webkit::SkillsAudit::VisitorSession->load($self->{db}, {
		clause => 'session_id = ?',
		binds => [$session_id] });

	if(!$session) { return undef; }

	if(!$session->is_active) { return undef; }

	$session->modified(Webkit::DateTime->now);

	$self->{db}->begin_transaction;

	$session->save;

	$self->{db}->commit;

	$self->{session} = $session;
	$self->{session_id} = $session->session_id;
	$self->{page_props}->{session_id} = $session->session_id;
	$self->{page_props}->{objs}->{session} = $session;

	if($session->visitor_id>0)
	{
		$self->load_visitor($session->visitor_id);
	}
	else
	{
		$self->{page_props}->{lea_proxy} = 1;
		$self->construct_visitor($session->school_id);
	}

	return 1;	
}

sub ensure_session
{
	my ($self) = @_;

	if($self->{session}) { return; }

	if(!$self->load_session)
	{
		$self->access_error('Incorrect Session Details<br><br>You have been inactive for too long - please log back into the system and try again.<br><br>All data you have entered is saved...');
		return undef;
	}

	return 1;
}

sub access_error
{
	my ($self, $error) = @_;

	$self->{page_props}->{error} = $error;

	$self->set_page('/access_error.htm');
}

sub index_handler
{
	my ($self) = @_;


}

sub modal_toolbar_frameset_handler
{
	my ($self) = @_;

	my $top_page = $self->{params}->{top_page};
	delete($self->{params}->{top_page});

	my $bottom_page = $self->{params}->{bottom_page};
	delete($self->{params}->{bottom_page});

	my $height = $self->{params}->{height};
	delete($self->{params}->{height});

	my $reverse = $self->{params}->{reverse};
	delete($self->{params}->{reverse});

	if($height!~/\d/) { $height = 50; }
	
	my $params_st = Webkit::AppTools->get_params_st($self->{params});

	$params_st = 'session_id='.$self->{params}->{session_id}.'&'.$params_st;

	my $top_src = $top_page.'?'.$params_st;
	my $bottom_src = $bottom_page.'?'.$params_st;

	my $frames_st = '';

	my $top=<<"+++";
<TR><TD HEIGHT="$height" id="topTd"><IFRAME id="topFrame" SRC="$top_src" WIDTH="100%" HEIGHT="$height" NAME="topFrame" SCROLLING="NO" FRAMEBORDER="0"></IFRAME></TD></TR>		
+++

	my $bottom=<<"+++";
<tr><TD HEIGHT="100%" id="bottomTd"><IFRAME id="bottomFrame" SRC="$bottom_src" WIDTH="100%" HEIGHT="100%" NAME="bottomFrame" SCROLLING="AUTO" FRAMEBORDER="0"></IFRAME></TD></TR>
+++

	if($reverse)
	{
		$frames_st=<<"+++";
$bottom
$top
+++
	}
	else
	{
		$frames_st=<<"+++";
$top
$bottom
+++
	}

	my $page=<<"+++";
<HTML>
<HEAD>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
<script>
	function setHeight(height)
	{
		document.getElementById('topTd').height = height;
		document.getElementById('topFrame').height = height;
	}
</script>
<title>Skills Audit Administration</title>
</HEAD>
<BODY style="margin:0px;">
<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%" HEIGHT="100%" STYLE="border-left:#808080 1px solid; border-right:#FFFFFF 1px solid; border-top:#808080 1px solid; border-bottom:#FFFFFF 1px solid;"><TR><TD WIDTH="100%" HEIGHT="100%">
<TABLE WIDTH="100%" BORDER="0" CELLPADDING="0" CELLSPACING="0" HEIGHT="100%" STYLE="border-right:1px #808080 solid; border-bottom:1px #808080 solid; border-top:1px #FFFFFF solid; border-left:1px #FFFFFF solid;">
$frames_st
</TABLE>
</TD></TR></TABLE>
</BODY>
</HTML>
+++

	$self->{page_content} = $page;
}

sub modal_frameset_handler
{
	my ($self) = @_;

	my $parts;
	my $page = $self->{params}->{page};

	foreach my $key (keys %{$self->{params}})
	{
		if($key ne 'page')
		{
			push(@$parts, $key.'='.$self->{params}->{$key});
		}
	}

	my $param_st = join('&', @$parts);

	my $uri = $page.'?'.$param_st;

	$self->{page_content}=<<"+++";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html>
<head>
<title>ICT Audit Administrator Screens</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<frameset rows="0,*" frameborder="NO" border="0" framespacing="0">
  <frame src="/admin/administrator/blank.htm" name="topFrame" scrolling="NO" noresize>
  <frame src="$uri" name="mainFrame">
</frameset>
<noframes><body>
</body></noframes>
</html>
+++
}

sub register__remind_pin_submit_handler
{
	my ($self) = @_;

	my $username = $self->{params}->{username};
	$username =~ s/\s//g;

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		clause => 'email_address = ?',
		binds => [$username] });

	if(!$visitor)
	{
		$self->{page_props}->{error} = 'Incorrect Details';
		$self->set_page('/register/remind_pin.htm');
		return;
	}
	elsif($visitor->has_email)
	{
		my $school = $visitor->load_school;
		my $message;

		$self->{page_props}->{name} = $visitor->name;
		$self->{page_props}->{phone_number} = $visitor->phone_number;
		$self->{page_props}->{school_name} = $school->name;
		$self->{page_props}->{username} = $visitor->username;
		$self->{page_props}->{pin_number} = $visitor->pin_number;

		my $email_address = $visitor->email_address;

		my $email_template_file = $self->get_uri_file_path('/register/remind_email.htm');

		my $email_content = $self->get_template($email_template_file);

		my $admin_email = $self->get_admin_email;

		Webkit::AppTools->send_email({
			from => $admin_email,
			to => $visitor->email_address,
			subject => 'Skills Audit Registration Details',
			message => $email_content });

		$message="An email has been sent to $email_address containing your access details.";

		$self->{page_content}=<<"+++";
<script>
alert('$message');
top.close();
</script>
+++
	}
	else
	{
		$self->{page_props}->{objs}->{visitor} = $visitor;

		$self->set_page('/register/remind_pin_question.htm');
	}
}

sub register__remind_pin_question_submit_handler
{
	my ($self) = @_;

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $self->{params}->{visitor_id} });

	my $school = Webkit::SkillsAudit::School->load($self->{db}, {
		id => $visitor->school_id });

	$self->{page_props}->{name} = $visitor->name;
	$self->{page_props}->{phone_number} = $visitor->phone_number;
	$self->{page_props}->{school_name} = $school->name;
	$self->{page_props}->{city} = $school->city;	
	$self->{page_props}->{username} = $visitor->username;
	$self->{page_props}->{pin_number} = $visitor->pin_number;
	$self->{page_props}->{question} = $visitor->reminder_question;
	$self->{page_props}->{answer} = $visitor->reminder_answer;
	$self->{page_props}->{given_answer} = $self->{params}->{answer};

	my $email_template_file = $self->get_uri_file_path('/register/remind_email_phone.htm');

	my $email_content = $self->get_template($email_template_file);

	my $admin_email = $self->get_admin_email;

	Webkit::AppTools->send_email({
		from => $admin_email,
		to => $admin_email,
		subject => 'Skills Audit PIN Reminder Request',
		message => $email_content });

	my $message="Somebody will contact you shortly via phone to remind you of your access details.";

	$self->{page_content}=<<"+++";
<script>
alert('$message');
top.close();
</script>
+++
}

sub register__index_handler
{
	my ($self, $visitor) = @_;

	$self->load_org;

	if(!$visitor)
	{
		$visitor = Webkit::SkillsAudit::Visitor->constructor($self->{db});
	}

	$self->{page_props}->{school_options} = $self->{org}->get_school_options($visitor->school_id);
	$self->{page_props}->{objs}->{visitor} = $visitor;
}

sub register__submit_handler
{
	my ($self) = @_;

	my $visitor = Webkit::SkillsAudit::Visitor->constructor($self->{db});

	$visitor->org_id($self->org_id);

	my $school = Webkit::SkillsAudit::School->load($self->{db}, {
		id => $self->{params}->{school_id} });

	$visitor->save_register_params($self->{params}, $school);

	if($visitor->error)
	{
		$self->{page_props}->{error_text} = $visitor->{error_text};

		$self->register__index_handler($visitor);
		$self->set_page('/register');
	}
	else
	{
		$self->{db}->begin_transaction;

		$visitor->create;

		my $session = $visitor->generate_session;

		$self->{db}->commit;

		$self->set_page('/register/confirm.htm', {
			session_id => $session->session_id,
			message => 'Registering Your Details',
			visitor_id => $visitor->get_id });
	}
}

sub register__confirm_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = $self->{visitor};

	my $school = $visitor->load_school;

	$self->{page_props}->{school_name} = $school->name;
	$self->{page_props}->{username} = $visitor->username;
	$self->{page_props}->{pin_number} = $visitor->hidden_pin_number;

	if($visitor->has_email)
	{
		my $email_template_file = $self->get_uri_file_path('/register/confirm_email.htm');

		my $email_content = $self->get_template($email_template_file);

		Webkit::AppTools->send_email({
			from => 'skillsaudit@wk1.net',
			to => $visitor->email_address,
			subject => 'Skills Audit Registration Details',
			message => $email_content }); 
	}
}

sub admin__login_handler
{
	my ($self) = @_;

	my $visitor = Webkit::SkillsAudit::Visitor->new_from_login($self->{db}, $self->{params});

	if(!$visitor)
	{
		$self->{page_props}->{error} = 'Incorrect Login Details';
		$self->set_page('/index.htm');
	}
	else
	{
		$self->{db}->begin_transaction;

		my $session = $visitor->generate_session;

		$self->{db}->commit;

		$self->set_page('/admin/index.htm', {
			session_id => $session->session_id,
			message => 'Logging In' });
	}
}

sub admin__index_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	$self->{visitor}->load_all_audits;

	my $audit = $self->{visitor}->get_unfinished_audit;

	$self->{page_props}->{objs}->{audit} = $audit;
}

sub admin__administrator_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator_thanks_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }
}

sub admin__register_administrator_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $email = $self->{params}->{email};
	my $phone = $self->{params}->{phone};

	my $error_text;

	my $visitor = $self->{visitor};

	$visitor->email_address($email);
	$visitor->phone_number($phone);
	my $school = $visitor->load_school;

	if(!Webkit::AppTools->check_email_address($email))
	{
		$error_text = 'Invalid Email';
	}

	if(!Webkit::AppTools->check_phone_number($phone))
	{
		$error_text = 'Invalid Phone Number';
	}

	if($error_text=~/\w/)
	{
		$self->{page_props}->{objs}->{school} = $school;
		$self->{page_props}->{error_text} = $error_text;

		$self->set_page('/admin/administrator.htm');

		return;
	}

	$self->{db}->begin_transaction;

	$visitor->save;

	$self->{db}->commit;

	my $address = $school->address;
	my $name = $visitor->name;
	my $emailaddr = $visitor->email_address;
	my $phonenmbr = $visitor->phone_number;
	my $school_name = $school->name;

	my $message=<<"+++";
A visitor from the ICT Audit has requested administrator Access,
the details are as follow:

--------------------------------------------------

Name:		$name
Email:		$emailaddr
Phone:		$phonenmbr

School:		$school_name

$address

--------------------------------------------------
+++

	my $admin_email = $self->get_admin_email;

	Webkit::AppTools->send_email({
		from => $email,
		to => $admin_email,
		subject => 'ICT Audit Administrator Request',
		message => $message });

	$self->set_page('/admin/administrator_thanks.htm', {
		session_id => $self->{session_id} });
}

sub admin__delete_audit_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $audit = $self->{visitor}->get_unfinished_audit;

	if($audit)
	{
		$self->{db}->begin_transaction;

		$audit->delete;

		$self->{db}->commit;
	}

	$self->set_page('/admin/index.htm', {
		session_id => $self->{session_id} });

}

sub admin__timeline_toolbar_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = $self->{visitor};

	if($self->{params}->{visitor_id}>0)
	{
		$visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
			id => $self->{params}->{visitor_id} });
	}

	$self->{page_props}->{objs}->{school} = $visitor->load_school;
	$self->{page_props}->{objs}->{visitor} = $visitor;	
}

sub admin__timeline_analysis_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = $self->{visitor};

	if($self->{params}->{visitor_id}>0)
	{
		$visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
			id => $self->{params}->{visitor_id} });
	}

	$visitor->load_timeline_analysis;

	$self->{page_props}->{objs}->{visitor} = $visitor;
}

sub admin__timeline_analysis_graph_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = $self->{visitor};

	if($self->{params}->{visitor_id}>0)
	{
		$visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
			id => $self->{params}->{visitor_id} });
	}

	my $gd = $visitor->get_timeline_gd;

	my $content = $gd->png;

	my $length = length($content);

	print<<"+++";
Content-type: image/png
Content-length: $length

$content
+++

	$self->{page_content} = '_no_header';
}

sub admin__audit_analysis_toolbar_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $audit = Webkit::SkillsAudit::Audit->load($self->{db}, {
		id => $self->{params}->{audit_id} });

	my $visitor = $audit->load_visitor;

	$self->{page_props}->{objs}->{school} = $visitor->load_school;
	$self->{page_props}->{objs}->{audit} = $audit;
	$self->{page_props}->{objs}->{visitor} = $visitor;
}

sub admin__audit_analysis_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $audit = Webkit::SkillsAudit::Audit->load($self->{db}, {
		id => $self->{params}->{audit_id} });

	$audit->load_analysis;
	$audit->load_ict_analysis;

	my $visitor = $audit->load_visitor;

	$self->{page_props}->{objs}->{audit} = $audit;
	$self->{page_props}->{objs}->{visitor} = $visitor;
}

sub admin__audit_analysis_graph_handler
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

	$self->{page_content} = '_no_header';
}


sub admin__edit_details_handler
{
	my ($self, $visitor) = @_;

	if(!$self->ensure_session) { return; }

	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__edit_details_submit_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = $self->{visitor};

	$visitor->save_edit_params($self->{params});

	if($visitor->error)
	{
		$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;

		$self->set_page('/admin/edit_details.htm');
	}
	else
	{
		$self->{db}->begin_transaction;

		$visitor->save;

		$self->{db}->commit;

		my $alert = '';

		if($visitor->{_password_changed})
		{
			$alert = 'You have changed your password - please use this password next time you login.';
		}

		if($visitor->{_email_changed})
		{
			$alert = 'You have changed your email address - please use this address next time you login';
		}

		$self->set_page('/admin/index.htm', {
			alert => $alert,
			session_id => $self->{session}->session_id,
			message => 'Saving your details' });
	}
}

sub admin__administrator__main_toolbar_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $school = $self->{visitor}->load_school;

	$self->{page_props}->{objs}->{school} = $school;
	$self->{page_props}->{objs}->{visitor} = $self->{visitor};
}

sub admin__administrator__school_home_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $school = $self->{visitor}->load_school;

	$school->load_visitors_audits;

	$self->{page_props}->{objs}->{school} = $school;
}


sub admin__administrator__delete_audit_handler
{
	my ($self) = @_;
	
	if(!$self->ensure_session) { return; }
	
	my $audit = Webkit::SkillsAudit::Audit->load($self->{db}, {
		id => $self->{params}->{audit_id} });
		
	$self->{db}->begin_transaction;

	$audit->delete;

	$self->{db}->commit;	
	
	$self->set_page('/admin/administrator/school_home.htm', {
		message => 'deleting audit',
		session_id => $self->{session_id} });	
}

sub admin__administrator__reset_password_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $self->{params}->{visitor_id} });

	$visitor->pin_number('password');

	$self->{db}->begin_transaction;

	$visitor->save;

	$self->{db}->commit;

	my $name = $visitor->name;

	$self->set_page('/admin/administrator/school_home.htm', {
		session_id => $self->{session_id},
		alert => $name.'s password has been reset to "password"' });
}

sub admin__administrator__audit_analysis_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $audit = Webkit::SkillsAudit::Audit->load($self->{db}, {
		id => $self->{params}->{audit_id} });

	$audit->load_analysis;
	$audit->load_ict_analysis;

	my $visitor = $audit->load_visitor;

	$self->{page_props}->{objs}->{audit} = $audit;
	$self->{page_props}->{objs}->{audit_visitor} = $visitor;
	$self->{page_props}->{objs}->{school} = $visitor->load_school;
}

sub admin__administrator__visitor_timeline_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $self->{params}->{visitor_id} });

	$visitor->load_timeline_analysis;

	$self->{page_props}->{objs}->{visitor} = $visitor;
	$self->{page_props}->{objs}->{school} = $visitor->load_school;
}

sub admin__administrator__visitor_timeline_graph_handler
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

	$self->{page_content} = '_no_header';
}

sub admin__administrator__visitor_group_targets_toolbar_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$org->assign_group_info($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator__visitor_group_targets_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$self->{params}->{school_id} = $self->{visitor}->school_id;

	$org->load_group_targets($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator__visitor_group_targets_graph_handler
{
	my ($self) = @_;

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	my $gd = $org->get_group_targets_gd($self->{params});

	my $content = $gd->png;

	my $length = length($content);

	print<<"+++";
Content-type: image/png
Content-length: $length

$content
+++

	$self->{page_content} = '_no_header';
}

sub admin__administrator__visitor_group_people_toolbar_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$org->assign_group_info($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}


sub admin__administrator__visitor_group_people_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$self->{params}->{school_id} = $self->{visitor}->school_id;

	$org->load_group_people($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator__visitor_group_timeline_toolbar_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$org->assign_group_info($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator__visitor_group_timeline_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$self->{params}->{school_id} = $self->{visitor}->school_id;

	$org->load_group_timeline($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator__visitor_group_timeline_graph_handler
{
	my ($self) = @_;

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	my $gd = $org->get_group_timeline_gd($self->{params});

	my $content = $gd->png;

	my $length = length($content);

	print<<"+++";
Content-type: image/png
Content-length: $length

$content
+++

	$self->{page_content} = '_no_header';
}

sub admin__administrator__visitor_group_ict_timeline_toolbar_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$org->assign_group_info($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator__ict_summary_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$self->{params}->{school_id} = $self->{visitor}->school_id;

	$org->load_ict_summary($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator__visitor_group_ict_timeline_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$self->{params}->{school_id} = $self->{visitor}->school_id;

	$org->load_ict_timeline($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator__visitor_group_questions_toolbar_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$org->assign_group_info($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}


sub admin__administrator__visitor_group_questions_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $org = Webkit::SkillsAudit::Org->load($self->{db}, {
		id => $self->org_id });

	$self->{params}->{school_id} = $self->{visitor}->school_id;

	$org->load_group_questions_analysis($self->{params});

	$self->{page_props}->{objs}->{org} = $org;
	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;
}

sub admin__administrator__date_wizard_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $school = $self->{visitor}->load_school;

	$self->{page_props}->{objs}->{refs} = $school->get_audit_taken_refs;

}

sub admin__administrator__edit_visitor_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $school = $self->{visitor}->load_school;

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $self->{params}->{visitor_id} });

	$self->{page_props}->{objs}->{school} = $school;
	$self->{page_props}->{objs}->{visitor} = $visitor;
}

sub admin__administrator__edit_visitor_submit_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $self->{params}->{visitor_id} });

	$visitor->save_admin_params($self->{params});

	if($self->{params}->{lea_proxy}=~/\w/)
	{
		if($self->{params}->{admin} eq 'y')
		{
			$visitor->admin('y');
		}
		else
		{
			$visitor->admin('n');
		}
	}

	if($visitor->error)
	{
		my $school = $self->{visitor}->load_school;
		$self->{page_props}->{objs}->{school} = $school;
		$self->{page_props}->{objs}->{visitor} = $visitor;
		$self->set_page('/admin/administrator/edit_visitor.htm');
	}
	else
	{
		$self->{db}->begin_transaction;

		$visitor->save;

		$self->{db}->commit;

		$self->set_page('/admin/administrator/school_home.htm', {
			session_id => $self->{session_id},
			message => 'Saving Details...' });
	}
}

sub admin__administrator__delete_visitor_submit_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = Webkit::SkillsAudit::Visitor->load($self->{db}, {
		id => $self->{params}->{visitor_id} });

	$self->{db}->begin_transaction;

	$visitor->delete_children('Webkit::SkillsAudit::Answer');
	$visitor->delete_children('Webkit::SkillsAudit::Audit');
	$visitor->delete_children('Webkit::SkillsAudit::VisitorSession');

	$visitor->delete;

	$self->{db}->commit;

	$self->set_page('/admin/administrator/school_home.htm', {
		session_id => $self->{session_id},
		message => $visitor->name.' is now deleted...',
		alert => $visitor->name.' is now deleted...' });
}

sub audit__audit_frameset_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $audit = $self->{visitor}->load_previous_audit;

	if(!$audit)
	{
		return;
	}
	else
	{
		if(!$audit->finished) { return; }

		my $taken_epoch = $audit->taken->Epoch;
		my $now_epoch = Webkit::DateTime->now->Epoch;
		
		if($now_epoch>$taken_epoch + (60*60*24*14))
		{
			return;
		}
		else
		{
			$self->{page_content}=<<"+++";
<html>
<head>
<title>Skills Audit</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<frameset rows="0,*" frameborder="NO" border="0" framespacing="0">
    <frame name="blank" scrolling="no" noresize src="/audit/blank.htm" >
    <frame name="remind" scrolling="no" noresize src="/audit/toosoon.htm" >
</frameset>
<noframes> 
<body bgcolor="#FFFFFF" text="#000000">
</body>
</noframes> 
</html>
+++
		}
	}
}

sub audit__audit_review_frameset_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

}

sub audit__print_audit_frameset_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }
}

sub audit__print_audit_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $audit = $self->audit_get_audit;

	my $template = Webkit::SkillsAudit::AuditTemplate->load($self->{db}, {
		id => $audit->audit_template_id });

	$template->load_questions_with_groups;

	$self->{page_props}->{objs}->{audit_template} = $template;
}

sub audit__create_audit_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $audit = $self->{visitor}->load_unfinished_audit;

	if(!$audit)
	{
		my $audit_template = $self->load_audit_template;

		$audit = $self->{visitor}->construct_new_audit($audit_template->get_id);

		$self->{db}->begin_transaction;

		$audit->create;

		$self->{db}->commit;
	}

	$self->set_page('/audit/window.htm', {
		session_id => $self->{session_id},
		audit_id => $audit->get_id,
		message => 'Logging in to audit' });
}

sub audit__view_audit_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	$self->set_page('/audit/window.htm', {
		session_id => $self->{session_id},
		audit_id => $self->{params}->{audit_id},
		message => 'Logging in to audit' });	
}
	

sub audit__window_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	$self->{page_props}->{objs}->{school} = $self->{visitor}->load_school;

	my $audit = $self->audit_get_audit;

	$self->{page_props}->{objs}->{audit} = $audit;
}

sub audit__audit_frame_handler
{		
	my ($self) = @_;

	if(!$self->ensure_session) { return; }
}

sub audit_get_audit
{
	my ($self) = @_;

	if($self->{params}->{audit_id}!~/\d/)
	{
		die 'There is no audit with the id of '.$self->{params}->{audit_id};
	}

	my $audit = Webkit::SkillsAudit::Audit->load($self->{db}, {
		id => $self->{params}->{audit_id} });

	return $audit;
}

sub audit__tree_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = $self->{visitor};

	my $audit = $self->audit_get_audit;

	my $audit_template = $audit->load_audit_template;

	$audit_template->load_question_groups_for_visitor($visitor);

	$audit->load_answer_counts($self->{visitor});

	$self->{page_props}->{objs}->{audit} = $audit;
	$self->{page_props}->{objs}->{audit_template} = $audit_template;
}

sub audit__start_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }
}

sub audit__saveandquit_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }
}

sub audit__finish_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $visitor = $self->{visitor};

	my $audit = $self->audit_get_audit;

	$self->{page_props}->{objs}->{audit} = $audit;

	if(!$audit->can_finish($visitor))
	{
		$self->{page_props}->{partially_finished} = $audit->has_partially_answered_sections($visitor);
		$self->set_page('/audit/please_complete.htm');

		return;
	}
}

sub audit__question_group_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $question_group = Webkit::SkillsAudit::QuestionGroup->load($self->{db}, {
		id => $self->{params}->{question_group_id} });

	if(!$question_group) { die "No question group found for that id"; }

	$question_group->load_questions;

	my $visitor = $self->{visitor};

	my $audit = $self->audit_get_audit;

	$visitor->load_answers_for_question_group_and_audit($question_group, $audit);

	my $answer_js=<<"+++";
var answers = new Object();
+++

	foreach my $question (@{$question_group->ensure_child_array('question')})
	{
		my $answer = $visitor->get_answer_for_question($question);
		my $question_id = $question->get_id;

		if($answer)
		{
			$answer_js .= $question->get_answer_js($answer);
		}
	}

	$self->{page_props}->{objs}->{audit} = $audit;
	$self->{page_props}->{question_group_id} = $question_group->get_id;
	$self->{page_props}->{answer_js} = $answer_js;
	$self->{page_props}->{objs}->{question_group} = $question_group;

	my $display_template = $question_group->get_display_template;

	$self->set_page($display_template);
}

sub audit__save_question_group_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $question_group = Webkit::SkillsAudit::QuestionGroup->load($self->{db}, {
		id => $self->{params}->{question_group_id} });

	my $visitor = $self->{visitor};

	my $audit = $self->audit_get_audit;

	if(!$audit->finished)
	{
		$question_group->load_actual_questions;

		$visitor->load_answers_for_question_group_and_audit($question_group, $audit);

		$self->{db}->begin_transaction;

		foreach my $question (@{$question_group->ensure_child_array('question')})
		{
			if(!$visitor->can_see_question($question)) { next; }

			my $answer = $visitor->get_answer_for_question($question);

			if(!$answer)
			{
				$answer = Webkit::SkillsAudit::Answer->constructor($self->{db});

				$answer->org_id($visitor->org_id);
				$answer->school_id($visitor->school_id);
				$answer->audit_id($audit->get_id);
				$answer->question_group_id($question->question_group_id);
				$answer->question_id($question->get_id);
				$answer->visitor_id($visitor->get_id);
				$answer->score_answer(0);	
			}

			$question->save_answer($answer, $self->{params});
		}

		$self->{db}->commit;
	}

	my $next_url = $self->{params}->{next_url};
	my $next_id = $self->{params}->{next_question_group_id};

	if($next_id=~/\d/)
	{
		$self->set_page('/audit/question_group.app', {
			audit_id => $self->{params}->{audit_id},
			message => 'Saving Question',
			question_group_id => $next_id,
			session_id => $self->{session_id} });
	}
	elsif($next_url=~/\w/)
	{
		$self->set_page($next_url, {
			audit_id => $self->{params}->{audit_id},
			message => 'Saving Question',
			session_id => $self->{session_id} });
	}
}

sub audit__finish_commit_handler
{
	my ($self) = @_;

	if(!$self->ensure_session) { return; }

	my $audit = $self->audit_get_audit;

	if(!$audit->finished)
	{
		$audit->finished(Webkit::DateTime->now);

		$self->{db}->begin_transaction;
	
		$audit->save;

	 	$self->{db}->commit;
	}

	$self->{page_content}=<<"+++";
<script>

top.close();

</script>
+++
		
}

1;
