package Webkit::JSMenu;

use strict;
use XML::DOM ();

sub new
{
	my ($classname, $fullpath, $user) = @_;

	if($fullpath!~/\w/)
	{
		return;
	}

	my $packet = Webkit::AppTools->read_file_contents($fullpath);

	return Webkit::JSMenu->with_content_new($packet, $user);
}

sub browser_new
{
	my ($classname, $path, $browser) = @_;

	my $packet = Webkit::AppTools->read_file_contents($path);

	return Webkit::JSMenu->browser_new_with_content($packet, $browser);
}

sub browser_new_with_content
{
	my ($classname, $content, $browser) = @_;

	if($browser->is_high)
	{
		return Webkit::JSMenu->with_content_new($content);
	}
	else
	{
		return Webkit::JSMenu->low_grade_new($content);
	}
}

sub add_tools_menu
{
	my ($self, $packet) = @_;

	my $tools_menu = $self->get_tools_menu();

	$packet =~ s/<\/menu_config>/$tools_menu<\/menu_config>/;

	return $packet;
}

sub low_grade_new
{
	my ($classname, $packet) = @_;

	my $self = {};

	bless($self, $classname);

	$packet = $self->add_tools_menu($packet);

        my $parser = new XML::DOM::Parser;

        my $doc = $parser->parse($packet);

	my $menu_config = $doc->getFirstChild;

	$self->{level} = 0;

	$self->{menu_text}.=<<"+++";
<script>
function menuSelect_changed(elem)
{
	var action = elem.value;

	if((action!='')&&(action!='title'))
	{
		eval(action);
	}

	elem.options[0].selected = true;
}
</script>
+++

	$self->get_lowgrade_menublock($menu_config);

	$self->{text} = $self->{menu_text};

	return $self;

}

sub with_content_new
{
	my ($classname, $packet, $user, $no_help) = @_;

	my $self = {};

	bless($self, $classname);

	if(!$no_help)
	{
		$packet = $self->add_tools_menu($packet);
	}

        my $parser = new XML::DOM::Parser;

        my $doc = $parser->parse($packet);

	$self->{menutext}=<<"+++";
<link rel="stylesheet" type="text/css" href="/lib/htmlmenu/menucss.css">
<script type="text/javascript" src="/lib/htmlmenu/menucode.js"></script>
+++

	my $menu_config = $doc->getFirstChild;

	$self->{id} = 1;
	$self->{actionid} = 1;

	$self->get_menublock($menu_config, 1);

        my $menublocks = $menu_config->getChildNodes;

	$self->{menutext}.=<<"+++";
<div class="menuBar">
+++

	foreach my $ref (@{$self->{root_refs}})
	{
		my $title = $ref->{title};
		my $id = $ref->{id};

		$self->{menutext}.=<<"+++";
<a class="menuButton" href="" onclick="return buttonClick(event, 'menu$id');" onmouseover="buttonMouseover(event, 'menu$id');">$title</a>
+++
	}

	$self->{menutext}.=<<"+++";
</div>
+++

	$self->{text} = $self->{menutext};

	return $self;
}

sub get_lowgrade_menublock
{
	my ($self, $elem) = @_;

	$self->{level}++;

	my $title = $elem->getAttribute('title');

	if($self->{level}==2)
	{
		$self->{menu_text}.=<<"+++";
<select onChange="menuSelect_changed(this);" style="font-family:tahoma,verdana,arial; font-size:11px; color:#000000; background-color:#D4D0C8;">
<option value="title">$title</option>
+++
	}
	elsif($self->{level}>2)
	{
		$self->{menu_text}.=<<"+++";
<option></option>
<option value="" style="background-color:#0A246A; color:#FFFFFF;">$title</option>
+++
	}

	my $menublocks = $elem->getChildNodes;

        foreach my $menublock (@$menublocks)
        {
                if(($menublock)&&($menublock->getNodeType == XML::DOM::ELEMENT_NODE))
                {
			my $title = $menublock->getAttribute('title');
			my $action = $menublock->getAttribute('action');

			if($menublock->getTagName eq 'menublock')
			{
				$self->get_lowgrade_menublock($menublock);
			}
			else
			{
				$self->{menu_text}.=<<"+++";
<option value="$action">&#187;&nbsp;$title</option>
+++
			}
		}
	}

	if($self->{level}==2)
	{
		$self->{menu_text}.=<<"+++";
</select>
<script>
function apply_menuBar()
{
	var window_loading = document.getElementById('window_loading');

	if(window_loading)
	{
		window_loading.style.display='none';
	}
}
document.body.onload = apply_menuBar;
</script>
+++
	}

	$self->{level}--;
}

sub get_menublock
{
	my ($self, $elem, $root) = @_;

	$self->{id}++;

	my $id = $self->{id};

	my $menublocks = $elem->getChildNodes;

	my $text = '';

	my $has_submenus = undef;

        foreach my $menublock (@$menublocks)
        {
                if(($menublock)&&($menublock->getNodeType == XML::DOM::ELEMENT_NODE))
                {
			my $submenu_txt = 'null';
			my $submenu_id;

			if($menublock->getTagName eq 'menublock')
			{
				$has_submenus = 1;
				$submenu_id = $self->get_menublock($menublock);
				$submenu_txt = 'menu'.$submenu_id;
			}

			my $title = $menublock->getAttribute('title');
			my $action = $menublock->getAttribute('action');

			if($action!~/\w/)
			{
				$action = 'return false;';
			}

			if(!$root)
			{
				if(defined($submenu_id))
				{
					$text.=<<"+++";
<a class="menuItem" href="" onclick="return false;" onmouseover="menuItemMouseover(event, '$submenu_txt');"><span class="menuItemText">$title</span><span class="menuItemArrow">&#9654;</span></a>
+++
				}
				else
				{
					$text.=<<"+++";
<a class="menuItem" onclick="clearActiveButton();" href="javascript:$action">$title</a>
+++
				}
			}
			else
			{
				push(@{$self->{root_refs}}, {
					title => $title,
					id => $submenu_id });
			}
		}
	}

	if($root)
	{
		return $id;
	}

	my $mouse_over = '';

	if($has_submenus)
	{
		$mouse_over = ' onmouseover="menuMouseover(event);"';
	}

	$text=<<"+++";

<div id="menu$id" class="menu"$mouse_over>
$text
</div>
<iframe id="iframe_menu$id" class="menu" frameborder=0 scrolling=no src="/templates/blank.htm"></iframe>

+++

	$self->{menutext}.=$text;

	return $id;
}

sub get_tools_menu
{
	my ($self) = @_;

###	<menuitem title="Switch Application" action="get_menu_query('&amp;method=iframe_title_frame&amp;title=Select an Application...&amp;frame_method=switch_application');"/>

	my $tools_menu=<<"+++";
	<menublock title="Help" width="90">
		<menuitem title="Contact Support" action="get_menu_query('&amp;method=iframe_title_frame&amp;title=Support&amp;frame_method=support_home');"/>
		<menuitem title="Edit Personal Details" action="get_menu_query('&amp;method=iframe_title_frame&amp;title=Edit Personal Details&amp;frame_method=edit_personal_details');"/>
		<menuitem title="About" action="get_menu_query('&amp;method=iframe_title_frame&amp;title=About&amp;frame_method=about_home');"/>
	</menublock>
+++

	return $tools_menu;
}

1;
