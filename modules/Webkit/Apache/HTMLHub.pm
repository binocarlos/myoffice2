package Webkit::Apache::HTMLHub;

################################
## Webkit::Apache::HTMLHub
##
## This module contains useful HTML snippets to be used across ALL applications
## Because the HTML is embedded into the module, and you have access to the CGI params,
## You can selectively build the HTML to print (e.g. only include this TR if $params->{includeTr} eq 'y')

use strict qw(vars);

#use Apache::Constants qw(OK NOT_FOUND DECLINED);

my $framesets = {
	myoffice2_homepage => {
		width => 20,
		appname => 'myoffice2',
		left => {
			title => 'Options',
			frame_name => 'menucontent',
			method => 'homepage_tree' },
		right => {
			method => 'homepage_screen' } },

	myoffice2_booking_progress => {
		width => 240,
		appname => 'myoffice2',
		left => {
			title => 'Venues',
			frame_name => 'menucontent',
			method => 'booking_progress_tree' },
		right => {
			scroll => 'AUTO',
			title => '_booking_progress_sheet_toolbar',
			title_height => 120,
			method => 'booking_progress_sheet' } },

	myoffice2_booking_penciled => {
		width => 240,
		appname => 'myoffice2',
		left => {
			title => 'Venues',
			frame_name => 'menucontent',
			method => 'booking_penciled_tree' },
		right => {
			scroll => 'AUTO',
			title => '_booking_penciled_sheet_toolbar',
			title_height => 120,
			method => 'booking_penciled_sheet' } },

	myoffice2_tourlist => {
		width => 240,
		appname => 'myoffice2',
		left => {
			title => 'Dates',
			frame_name => 'menucontent',
			method => 'tourlist_tree' },
		right => {
			scroll => 'AUTO',
			title => '_tourlist_toolbar',
			title_height => 80,
			method => 'tourlist_frameset_proxy' } },

	myoffice2_timeline => {
		width => 240,
		appname => 'myoffice2',
		left => {
			title => 'Dates',
			frame_name => 'menucontent',
			method => 'timeline_tree' },
		right => {
			scroll => 'AUTO',
			title => '_venue_status_toolbar',
			title_height => 80,
			method => 'timeline_home' } },

	myoffice2_venue_status_modal => {
		width => 270,
		appname => 'myoffice2',
		left => {
			title => 'Tourdates',
			frame_name => 'menucontent',
			method => 'venue_status_tree' },
		right => {
			scroll => 'AUTO',
			title => 'Info',
			method => 'venue_status_sheet' } },

	myoffice2_booking_report => {
		width => 240,
		appname => 'myoffice2',
		left => {
			title => 'Venues',
			frame_name => 'menucontent',
			method => 'booking_report_tree' },
		right => {
			scroll => 'AUTO',
			title => '_booking_report_toolbar',
			title_height => 80,
			method => 'booking_report_sheet' } },

	myoffice2_venue_status => {
		width => 240,
		appname => 'myoffice2',
		left => {
			title => 'Tourdates',
			frame_name => 'menucontent',
			method => 'venue_status_tree' },
		right => {
			scroll => 'AUTO',
			title => '_venue_status_toolbar',
			title_height => 80,
			method => 'venue_status_sheet' } },

	myoffice2_sales_figures => {
		width => 240,
		appname => 'myoffice2',
		left => {
			title => 'Dates',
			frame_name => 'menucontent',
			method => 'sales_figures_tree' },
		right => {
			scroll => 'AUTO',
			title => '_sales_figures_toolbar',
			title_height => 80,
			method => 'sales_figures_sheet' } },

	myoffice2_print => {
		width => 240,
		appname => 'myoffice2',
		left => {
			title => 'Print Runs',
			frame_name => 'menucontent',
			method => 'print_tree' },
		right => {
			scroll => 'AUTO',
			title => '_print_toolbar',
			title_height => 80,
			method => 'print_frameset_proxy' } },

	skills_audit_manage_visitors => {
		width => 260,
		appname => 'skillsaudit',
		left => {
			method => 'visitors_tree' },
		right => {
			title => '_visitors_group_timeline_toolbar',
			title_height => 160,
			scroll => 'NO',
			method => 'visitors_group_timeline_home' } },

	resourceshare_options_frame => {
		width => 140,
		appname => 'resourceshare',
		left => {
			title => 'Websites',
			method => 'resources_options_list_websites' },
		right => {
			title => 'Current Website Options',
			method => 'resources_options_welcome' } },

	eb_schools_frame => {
		width => 120,
		appname => 'eb',
		left => {
			scroll => 'AUTO',
			title => '_schools_build_details_download',
			title_height => 200,
			method => 'invoices_school_tree' },
		right => {
			title => 'Current Schools',
			method => 'schools_home' } },

	eb_suppliers_frame => {
		width => 120,
		appname => 'eb',
		left => {
			title => 'Suppliers Menu',
			method => 'supplier_tree' },
		right => {
			title => 'Current Suppliers',
			method => 'supplier_home' } },

	eb_invoices_frame => {
		width => 120,
		appname => 'eb',
		left => {
			title => 'Schools',
			method => 'invoices_school_tree' },
		right => {
			title => 'Current Invoices',
			method => 'invoices_home' } },

	eb_invoices_frame_reload => {
		width => 120,
		appname => 'eb',
		left => {
			title => 'Schools',
			method => 'invoices_school_tree' },
		right => {
			title => 'Current Invoices',
			method => 'invoices_home' } },

	firstcontact_museum_form => {
		width => 240,
		appname => 'myoffice2',
		left => {
			title => 'Venues',
			method => 'booking_progress_tree' },
		right => {
			scroll => 'AUTO',
			title => '_booking_progress_sheet_toolbar',
			title_height => 120,
			method => 'booking_progress_sheet' } },

	nctest_progress_analysis => {
		width => 240,
		appname => 'nctest',
		left => {
			scroll => 'AUTO',
			title => 'Pupils',
			method => 'analysis_progress_report_tree'
		},
		right => {
			scroll => 'NO',
			content_scroll => 'AUTO',
			title => '_analysis_progress_report_toolbar',
			title_height => 122,
			method => 'analysis_progress_report' } },

	nctest_exams_home => {
		width => 220,
		appname => 'nctest',
		left => {
			scroll => 'NO',
			method => 'control_panel_sidemenu' },
		right => {
			scroll => 'NO',
			content_scroll => 'AUTO',
			title => '_control_panel_home_toolbar',
			title_height => 50,
			method => 'control_panel_home' } } };

### Constructor - used by the handler to create a HTMLHub object that is used to run the method on

sub new
{
	my ($classname, $params, $uri) = @_;

	my $self = {};

	bless($self, $classname);

	$self->{params} = $params;
	$self->{uri} = $uri;

	return $self;
}


### Handler - the front end method that creates a new HTMLHub object and runs its get_content method
### before returning http to the browser

sub handler
{
	my ($r) = @_;

	my $request = Apache2::Request->new($r);

	my $params;

	foreach my $key ($request->param)
	{
		$params->{$key} = $request->param($key);
	}

	my $uri = $r->uri;

	my $hub = Webkit::Apache::HTMLHub->new($params, $uri);

	my $content = $hub->get_content;
	my $length = length($content);

	$r->content_type('text/html');
	$r->set_content_length($length);
	$r->no_cache;
	$r->send_http_header;

	$r->print($content);

	return Apache2::Const::OK;
}

### the method that translates the URI (/htmlhub/somesnippet.htm -> sub somesnippet)
### into a method, runs the method and returns its response as page_content

sub get_content
{
	my ($self) = @_;

	my $uri = $self->{uri};

	$uri =~ s/^\/htmlhub\///i;
	$uri =~ s/\.html?$//i;

	#### Method is now the method we need to run on the HTMLHub object
	my $method = lc($uri);

	$self->{method} = $method;

	if($self->can($method))
	{
		return $self->$method;
	}
	else
	{
		return $self->not_found_page;
	}
}

sub get_query_string
{
	my ($self, $ignores) = @_;
	
	my $ignore = {
		frameset_key => 1,
		method => 1,
		frame_method => 1,
		session_id =>1,
		appname =>1 };

	foreach my $key (keys %$ignores)
	{
		$ignore->{$key} = 1;
	}
	
	my $pairs;
	
	foreach my $field (keys %{$self->{params}})
	{
		push(@$pairs, $field.'='.$self->{params}->{$field});	
	}
	
	my $ret = join('&', @$pairs);
	
	return $ret;			
}

sub get_href
{
	my ($self) = @_;

	my $session_id = $self->{params}->{session_id};
	my $appname = $self->{params}->{appname};	
	my $method = $self->{params}->{method};
	my $querystring = $self->get_query_string;

	if($method!~/\w/)
	{
		$method = $self->{params}->{frame_method};
	}
	
	my $href = "/apps/$appname.app?session_id=$session_id&method=$method&$querystring";
	
	return $href;		
}

sub get_frameset_width
{
	my ($self) = @_;

	my $width = 150;

	if($self->{params}->{frameset_key}=~/\w/)
	{
		my $frameset = $framesets->{$self->{params}->{frameset_key}};

		$width = $frameset->{width};
	}

	return $width;
}

sub get_frame_query
{
	my ($self, $side, $key) = @_;

	my $method = $self->{params}->{$side.'_method'};
	my $title = $self->{params}->{$side.'_title'};
	my $appname = $self->{params}->{appname};
	my $session_id = $self->{params}->{session_id};
	my $title_height = $self->{params}->{title_height};
	my $frame_name = $self->{params}->{frame_name};

	if($key=~/\w/)
	{
		my $frameset = $framesets->{$key}->{$side};

		$method = $frameset->{method};
		$title = $frameset->{title};
		$title_height = $frameset->{title_height};
		$frame_name = $frameset->{frame_name};

		$appname = $framesets->{$key}->{appname};
	}

	my $query_string = $self->get_query_string({
		left_method => 1,
		left_title => 1,
		right_method => 1,
		right_title => 1 });

	$query_string = "session_id=$session_id&appname=$appname&side=$side&method=$method&title=$title&title_height=$title_height&$query_string&frame_name=$frame_name";

	return $query_string;
}

### The method called if there is no corresponding method from the uri

sub not_found_page
{
	my ($self) = @_;

	my $page=<<"+++";
$self->{method} has not been found in the HTMLHub
+++

	return $page;
}

### returns static content regardless of any params

sub simple_test
{
	my ($self) = @_;

	my $page=<<"+++";
<b style="color:red;">THIS IS A TEST!</b>
+++

	return $page;
}

### returns a table containing another row if the 'include_row' param equals 'y'

sub if_test
{
	my ($self) = @_;

	my $page=<<"+++";
<table border=1>
<tr>
<td>This is the test table</td>
</tr>
+++

	if($self->{params}->{include_row} eq 'y')
	{
		$page.=<<"+++";
<tr><td>THE ROW HAS BEEN INCLUDED!!!!</td></tr>
+++
	}

	$page.=<<"+++";
</table>
+++

	return $page;
}

sub frames_title
{
	my ($self) = @_;

	my $title = $self->{params}->{title};	

	my $page=<<"+++";
<HTML>
<HEAD>
<script>
function set_title(text)
{
	document.getElementById('title').innerText = text;
}
</script>
  </HEAD>
  <META HTTP-EQUIV="MSThemeCompatible" Content="no">
 <BODY style="background:#D4D0C8; border:0px; margin:0px;">
<TABLE WIDTH="100%" BORDER="0" CELLPADDING="2" CELLSPACING="0" STYLE="border-bottom:1px #808080 solid;" HEIGHT="100%">
<TR>
  <TD WIDTH="100%" HEIGHT="100%" STYLE="font-family:tahoma,verdana; font-size:11px; color:#000000;">&nbsp;<span id="title">$title</span></TD>
</TR>
</TABLE></BODY>
</HTML>
+++

	return $page;
}

sub frames_main
{
	my ($self) = @_;
	

	my $page=<<"+++";
<HTML>
<HEAD>
</HEAD>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
<BODY style="background:#FFFFFF; border:10px; margin:0px;">
</BODY>
</HTML>
+++

	return $page;
}

sub frames_single
{
	my ($self) = @_;
	
	my $href = $self->get_href;
	
	my $title = $self->{params}->{title};
	my $title_tr;
	
	if($title=~/\w/)
	{
		$title_tr=<<"+++";
<TR><TD HEIGHT="21" id="titleTd"><IFRAME id="title" SRC="/htmlhub/frames_title?title=$title" WIDTH="100%" HEIGHT="21" NAME="title" SCROLLING="NO" FRAMEBORDER="0"></IFRAME></TD></TR>		
+++
	}

	my $page=<<"+++";
<HTML>
<HEAD>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
</HEAD>
<BODY style="margin:0px;">
<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%" HEIGHT="100%" STYLE="border-left:#808080 1px solid; border-right:#FFFFFF 1px solid; border-top:#808080 1px solid; border-bottom:#FFFFFF 1px solid;"><TR><TD WIDTH="100%" HEIGHT="100%">
<TABLE WIDTH="100%" BORDER="0" CELLPADDING="0" CELLSPACING="0" HEIGHT="100%" STYLE="border-right:1px #808080 solid; border-bottom:1px #808080 solid; border-top:1px #FFFFFF solid; border-left:1px #FFFFFF solid;">
$title_tr
<tr><TD HEIGHT="100%" id="contentTd"><IFRAME id="content" SRC="$href" WIDTH="100%" HEIGHT="100%" NAME="content" SCROLLING="AUTO" FRAMEBORDER="0"></IFRAME></TD></TR>
</TABLE>
</TD></TR></TABLE>
</BODY>
</HTML>
+++

	return $page;
}

sub frames_double_content
{
	my ($self) = @_;
	
	my $href = $self->get_href;

	my $title = $self->{params}->{title};
	my $title_frame;
	my $rows = "100%";
	my $css = ' STYLE="border-right:1px #808080 solid; border-bottom:1px #808080 solid; border-top:1px #FFFFFF solid; border-left:1px #FFFFFF solid;"';
	my $outer_css = '';
	my $inner_css = $css;

	my $key = $self->{params}->{frameset_key};
	my $side = $self->{params}->{side};

	my $scroll = $framesets->{$key}->{$side}->{content_scroll};

	if($scroll!~/\w/) { $scroll = 'AUTO'; }
	
	if($title=~/\w/)
	{
		my $src = "/htmlhub/frames_title?title=$title";
		$rows = "21,*";
		$outer_css = $css;
		$inner_css = '';
		my $id = 'title';

		if($title=~/^_(\w+)$/)
		{
			my $method = $1;
			$self->{params}->{method} = $method;
			$src = $self->get_href;
		}
		else
		{
			$id = 'title_text';
		}

		if($self->{params}->{title_height}>0)
		{
			$rows = $self->{params}->{title_height}.',*';
		}
		
		$title_frame=<<"+++";
<frame id="$id" src="$src" scrolling="NO" name="$id" frameborder="0">
+++
	}

	my $frame_name = 'content';

	if($self->{params}->{frame_name}=~/\w/) { $frame_name = $self->{params}->{frame_name}; }

	my $page=<<"+++";
<HTML>
<HEAD>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
</HEAD>
<frameset id="outer" rows="$rows" border="0" $outer_css>
$title_frame
<frame id="content" src="$href" scrolling="$scroll" name="$frame_name" frameborder="0" $inner_css>
</frameset>
</HTML>
+++

	return $page;
}

sub frames_double
{
	my ($self) = @_;

	my $key = $self->{params}->{frameset_key};

	my $left_query = $self->get_frame_query('left', $key);
	my $right_query = $self->get_frame_query('right', $key);
	my $width = $self->get_frameset_width;

	my $left_scroll = $framesets->{$key}->{left}->{scroll};
	my $right_scroll = $framesets->{$key}->{right}->{scroll};

	if($left_scroll!~/\w/) { $left_scroll = 'AUTO'; }
	if($right_scroll!~/\w/) { $right_scroll = 'AUTO'; }


	my $sidebar=<<"+++";
<FRAME NAME="sidebar" SRC="/htmlhub/frames_double_content?$left_query" MARGINWIDTH="5" MARGINHEIGHT="5" STYLE="border-left:#808080 1px solid; border-right:#FFFFFF 1px solid; border-top:#808080 1px solid; border-bottom:#FFFFFF 1px solid;" SCROLLING="$left_scroll" FRAMEBORDER="NO">
+++

	my $page=<<"+++";
 <FRAME NAME="page" SRC="/htmlhub/frames_double_content?$right_query" FRAMEBORDER="NO" MARGINWIDTH="5" MARGINHEIGHT="5" STYLE="border-left:#808080 1px solid; border-right:#FFFFFF 1px solid; border-top:#808080 1px solid; border-bottom:#FFFFFF 1px solid;" SCROLLING="$right_scroll">
+++

	my $frames=$sidebar.$page;
	my $width_st="$width,*";

	if($self->{params}->{reverse})
	{
		$frames=$page.$sidebar;
		$width_st="*,$width";
	}

	my $ret=<<"+++";
<HTML>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
  <FRAMESET COLS="$width_st" ID="vertical_frameset" FRAMEBORDER="YES" BORDER="5" bordercolor="#d4d0c8">
  $frames
</FRAMESET>
</HTML>
+++

	return $ret;
}

1;
