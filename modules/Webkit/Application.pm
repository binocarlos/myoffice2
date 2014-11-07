package Webkit::Application;

use strict;

#########################
# The following variables are used sitewide and are
# accessed via Webkit::Application->get_constant.

my $app_name = 'webkit';
my $app_title = 'Webkit';

use Webkit::DB ();
use Webkit::DBObject ();
use Webkit::Session ();
use Webkit::Page ();
use Webkit::Session ();

use Webkit::DateTime ();
use Webkit::Time ();
use Webkit::Date ();
use Webkit::BaseDate ();

use Webkit::Error ();

use Webkit::AppTools ();
use Webkit::Constants ();

use String::Random ();


###############
# Manual Page Methods - these are the methods that will not use
# the wrapper function to present the page.  I.e. these methods
# are completely responsible for printing content back to the browser.
# This should be overdidden by the actual application.

my $manual_page_methods = {
	iframe_title => 'nolog',
	iframe_title_frame => 'nolog',
	generate_window => 1 };

############################
############################
#
#
#
#
#
#### App Object Methods
#
#
#
#
#
############################
############################

sub new
{
	my ($classname) = @_;

	my $self = {};

	bless($self, $classname);

	$self->init;

	return $self;
}


#######
# Constructor - calls _init
# Creates a new Webkit::DB,
# Gets the params from Webkit::AppTools

sub init 
{
	my ($self) = @_;

	my $db = Webkit::DB->new($self->get_app_info);

	if(!$db)
	{
		Webkit::Error->wkerror("The DB did not start up");
	}

	my $r = Apache2::RequestUtil->request;
	
	$self->{_r} = $r;

	$self->{db} = $db;
}


#######
# Delete the following on finish
# db
# params

sub DESTROY
{
	my ($self) = @_;

	foreach my $key (keys %$self)
	{
		delete($self->{$key});
	}

	$self = undef;
}


#################################
# RUN
#
# This is the method that is called from the script once the App is constructed.
# It basically controls the flow of the application on each invocation
# It does this by using the method parameter as a guide to which page is next
# Each method relating to a page is then responsible for the object manipulation
# and page presentation for that method.
# 

sub run
{
	my ($self, $params) = @_;

	$self->assign_params($params);

	$self->assign_page;

	my $method = $self->method;

	$self->print_header;
	
	if(!$self->check_access)
        {
		###### The user has failed to login

		$self->{force_print} = 1;

		if(($self->{params}->{session_id}=~/\w/)||($self->{params}->{method} eq 'login'))
		{
			$self->login;
		}
		else
		{
			$self->open_login_page;
		}
        }
        else
        {
		if($method eq 'login') { $method = 'authenticate'; }

		###### The user is logged in.
                $self->assign_objects;

		$self->$method;

		if($self->{session}->{_session_id})
		{
			$self->{session}->save;
		}

#		$self->insert_log;
	}

        $self->print_page;

	$self->{db}->cleanup;
}

sub initialise_external_run
{
	my ($self, $org_id, $args) = @_;

	$self->assign_org($org_id);

	foreach my $key (keys %$args)
	{
		$self->{params}->{$key} = $args->{$key};
	}

	$self->assign_page;

	delete($self->{session});

	$self->assign_objects;
}

sub r
{
	my ($classname) = @_;

	my $ret;

	eval
	{
		#$ret = Apache->request;
		$ret = Apache2::RequestUtil->request;
	};

	if($@)
	{
		return undef;
	}
	else
	{
		return $ret;
	}
}

sub request
{
	my ($classname) = @_;
	
	my $r = Webkit::Application->r;
	
	return $r;

#	if($r)
#	{
#		#my $req = Apache::Request->new($r);
#		my $req = Apache2::RequestUtil->request($r);
#
#		return $req;
#	}
#	else
#	{
#		return undef;
#	}
}

############################
############################
#
#
#
#
#
#### App Information Methods
#
#
#
#
#
############################
############################

###########
# Method - will return the method parameter or $self->home_method if not defined

sub method
{
	my ($self) = @_;

	my $method = $self->{params}->{method} || $self->home_method;

	return $method;
}


#########################
# Script
# This will return the relative script name as used in forms
# eg /apps/appname.app

sub script
{
	my ($classname) = @_;

	return unless my $r = Webkit::Application->r;
	
	my $script = $r->uri;

	$script =~ s/^\/+/\//;

	return $script;
}

sub get_domain_variable
{
	my ($classname, $varname) = @_;

	return Webkit::Constants->get_domain_variable(Webkit::Application->hostname, $varname);
}

sub get_httpd_variable
{
	my ($classname, $varname) = @_;
	
	my $reader = Apache2::Request->new(Webkit::Application->r);

	return $reader->dir_config($varname);
	
	#my $r = Webkit::Application->r || return;
	#return $r->dir_config($varname);
}

sub hostname
{
	my ($classname) = @_;
	
	return $ENV{HTTP_HOST};

	#my $r = Webkit::Application->r || return;

	#my $hostname = $r->hostname();
#	my $hostname = $r->headers_in->get('X-Forwarded-Host');

	#if($hostname!~/\w/)
	#{
	#	$hostname = Webkit::Constants->get_domain_variable($hostname, 'real_hostname');
	#}

	#if($hostname!~/\w/)
	#{
	#	$hostname = $r->hostname();
	#}

	#return $hostname;
}

sub get_hidden_input_string
{
	my ($self, $ignores) = @_;

	my $reader = Apache2::Request->new($self->{_r});

	my $parts;

	foreach my $param ($reader->param)
	{
		if(!$ignores->{$param})
		{
			
			my $value = $reader->param($param);

			my $part=<<"+++";
<input type="hidden" name="$param" value="$value">
+++

			push(@$parts, $part);
		}
	}

	my $ret = join('', @$parts);

	return $ret;
}

sub get_params_query_string
{
	my ($self, $ignores) = @_;

	my $parts;

	foreach my $param (keys %{$self->{params}})
	{
		if(!$ignores->{$param})
		{
			push(@$parts, $param.'='.$self->{params}->{$param});
		}
	}

	my $ret = '';

	if($parts)
	{
		$ret = join('&', @$parts);
	}

	return $ret;
}

sub get_query_string
{
	my ($self, $ignores) = @_;

	my $request = Apache2::Request->new($self->{_r});

	my $parts;

	foreach my $param ($request->param)
	{
		if(!$ignores->{$param})
		{
			push(@$parts, $param.'='.$request->param($param));
		}
	}

	my $ret = '';

	if($parts)
	{
		$ret = join('&', @$parts);
	}

	return $ret;
}

sub http_host
{
	my ($classname) = @_;

	return Webkit::Application->http_hostname;
}

sub http_hostname
{
	my ($classname) = @_;

	my $ret = '';

	if(Webkit::Application->https)
	{
		$ret = 'https://';
	}
	else
	{
		$ret = 'http://';
	}

	return $ret.Webkit::Application->hostname;
}

sub href
{
	my ($self, $appname, $method) = @_;

	my $session_id;

	if($self->{session})
	{
		$session_id = $self->{session}->session_id;
	}

	return Webkit::Application->class_href($session_id, $appname, $method);
}


##########################
# class_Href
# This will return the relative href (i.e. script + session_id) as used in links
# eg /apps/appname.app?session_id=K3OK34343O433500S099DS8
# If there is no session, it will return blank

sub class_href
{
	my ($classname, $session_id, $appname, $method) = @_;

	my $script = Webkit::Application->script;

	if($appname =~ /\w/)
	{
		$script =~ s/\/\w+\.app$/\/$appname\.app/;

		if($script!~/\.app$/) { $script = "/apps/$appname.app"; }
	}

	my $http_host = Webkit::Application->http_host;

	my $href = $http_host.$script.'?session_id=';

	if($session_id)
	{
		$href .= $session_id;
	}

	if($method=~/\w/)
	{
		$href .= '&method='.$method;
	}

	return $href;
}

sub static_host
{
	my ($self) = @_;

	return Webkit::Application->hostname;
}

sub host
{
	my ($self) = @_;

	return Webkit::Application->hostname;
}

sub session_id
{
	my ($self) = @_;

	if($self->{session})
	{
		return $self->{session}->session_id;
	}
	else
	{
		return '';
	}
}

sub https
{
	my ($classname) = @_;

	my $r = Webkit::Application->r;

	if(!$r)
	{
		return undef;
	}

	my $ssl = $r->subprocess_env('https');

	if($ssl=~/\w/)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}


########################
# If the current Org's debug property is 'y'
# Then the application will run in debug mode
# I.e. status bar, allowed to print sql 
# Templates can also make use of this to add additional content

sub debug
{
	my ($self) = @_;

	if(!$self->{org})
	{
		return undef;
	}
	else
	{
		if($self->{org}->is_debug)
		{
			return 1;
		}
		else
		{
			return undef;
		}
	}
}


############
# Returns a constant from the $CONSTANTS hash.

sub get_constant
{
	my ($classname, $key) = @_;

	return Webkit::Constants->get_constant($key);
}

#######
# Returns the SQL Connect info

sub get_static_db
{
	my ($classname, $app_name) = @_;

	if($app_name!~/\w/)
	{
		$app_name = 'webkit';
	}

	my $info = {
		dev => 1,
		sqldb => $app_name,
		sqluser => 'webkit',
		sqlpassword => 'Wk5ut_9Lt' };

	my $db = Webkit::DB->new($info);

	return $db;
}

sub get_app_info
{
	my ($self) = @_;

	my $info = {
		dev => 1,
		sqldb => $self->get_sqldb,
		sqluser => $self->get_sql_user,
		sqlpassword => $self->get_sql_password };

	return $info;
}

sub get_sqldb
{
	my ($self) = @_;

	return $self->app_name;
}

sub get_sql_user
{
	return 'webkit';
}

sub get_sql_password
{
	return 'Wk5ut_9Lt';
}

############################
############################
#
#
#
#
#
#### Access Control Methods
#
#
#
#
#
############################
############################

###################
# Check Access
#
# This method will authenticate the request.
# If this method returns false, the application will default to the login screen.
# You do not need to overide this method, but you MUST overide the app_name method
# otherwise check_access will find no privilage and the request will fail.
#
# IT IS IMPORTANT TO SPLIT THE PRIVILAGES AND ACCESS
# Some applications may only require that somebody has entered their username/password
# Not that the user has particular privilages.

sub check_access
{
	my ($self, $attr) = @_;

	my $session = Webkit::Session->new($self);

	if(!$session->login)
	{

		return undef;
	}
	else
	{
		my $user_obj = Webkit::User->constructor($self->{db});
		$user_obj->{data} = $session->{user_data};

		my $org_obj = Webkit::Org->constructor($self->{db});
		$org_obj->{data} = $session->{org_data};

		$org_obj->{application_id} = $self->base_application;

		$self->bless_org($org_obj);
		$self->bless_user($user_obj);

		$self->{user} = $user_obj;
		$self->{org} = $org_obj;
		$self->{session} = $session;

		$self->assign_initial_session_values;

		return $self->check_privilages;
	}
}

################### 
# Check Privilages -
# This will call the users->load_privilage_obj method
# and if this succeeds (i.e. there is a priv for this user and that app_name)
# then the user is allowed to use this application.

sub check_privilages
{
	my ($self) = @_;

	my $base_application = $self->base_application;

	my $sub_application = $self->current_application_id;

	if($sub_application eq $base_application)
	{
		$sub_application = undef;
	}

	return $self->{session}->check_privilages($base_application, $sub_application);
}

############################
############################
#
#
#
#
#
#### App Bless Methods (Which application is it).
#
#
#
#
#
############################
############################


########################
# App Name - this returns the name of the current application (used in matching privilages).

sub bless_application
{
	my ($self, $classname) = @_;

	bless($self, $classname);

	my $org_class = $self->get_org_classname;

	if($self->{org})
	{
		bless($self->{org}, $org_class);
	}

	$self->{page}->set_appname($self->app_name);

	my $r = Webkit::Application->r;

	my $uri = '';

	if($r)
	{
		$uri = $r->uri;
	}

	my $newappname = $self->current_application_id;

	$uri =~ s/(\w+)\.app/$newappname\.app/;

	if($r)
	{
		$r->uri($uri);
	}

	$self->assign_objects;
}

# This should be the base application_id of the window

sub app_name
{
	my ($self) = @_;


	return $app_name;
}

sub base_application
{
	my ($self) = @_;

	my $base = $self->{session}->{base_application};

	if($base!~/\w/)
	{
		$base = $self->app_name;
	}

	return $base;
}

# This returns the application_id to be used by the page object to find templates

sub page_application_id
{
	my ($self) = @_;

	return $self->app_name;
}

# This should be the application_id of the current function

sub current_application_id
{
	my ($self) = @_;

	return $self->app_name;
}

sub get_application_title
{
	my ($self) = @_;

	return $self->get_application_property('title');
}

sub get_application_description
{
	my ($self) = @_;

	return $self->get_application_property('description');
}

sub get_application_property
{
	my ($self, $prop) = @_;

	my $app_id = $self->base_application;

	my $app_obj = Webkit::Apache::ApplicationHub->get_application($app_id);

	return $app_obj->get_value($prop);
}

########################
# App Title - this returns the title of the current application

sub app_title
{
	my ($self) = @_;

	return $app_title;
}

########################
# Home Method - this returns the default method if none is given in the params (usually login)

sub home_method
{
	my ($self) = @_;

	return $self->get_constant('home_method');
}

############################
############################
#
#
#
#
#
#### App Setup Methods
#
#
#
#
#
############################
############################

sub assign_objects
{
        my ($self) = @_;

	if($self->{params}->{printsql}=~/\w/)
	{
		$self->{session}->set('printsql', $self->{params}->{printsql});
	}

#	####### User Details
	if($self->{user})
	{
	        $self->{page}->add_static("user", $self->{user});
	}

#	####### Org Details
	if($self->{org})
	{
		if(!$self->{params}->{page_org})
		{
			$self->{page}->set_org_id($self->{org}->get_id);
		}

		$self->{page}->add_static("org", $self->{org});
	}

#	####### Session Details
	if($self->{session})
	{
	        $self->{page}->add_static("session_id", $self->session_id);
	        $self->{page}->add_static("session", $self->{session});
	}

	$self->{page}->add_static("base_app_name", $self->base_application);
	$self->{page}->add_static("app_name", $self->current_application_id);
        $self->{page}->add_static("href", $self->href);
        $self->{page}->add_static("script", $self->script);

#	####### Debug

	if($self->debug)
	{
		$self->{page}->add_static("debug", 'y');
	}
}


sub assign_page
{
	my ($self) = @_;

	$self->{page} = Webkit::Page->new($self->page_application_id);

#	####### Script Details

	$self->{page}->add_static("params", $self->{params});
	$self->{page}->add_static("hostname", $self->hostname);
	$self->{page}->add_static("help_domain", $self->get_domain_variable('help_domain'));

	if($self->{params}->{page_org})
	{
		$self->{page}->set_org_id($self->{params}->{page_org});
	}
}


sub assign_params
{
	my ($self, $params) = @_;

	if($params)
	{
		$self->{params} = $params;
	}
	else
	{
		#my $req = $self->request;
		my $req = Apache2::Request->new($self->{_r});

		if($req)
		{
			foreach my $key ($req->param)
			{
				$self->{params}->{$key} = $req->param($key);
			}
		}
	}
	
	foreach my $k (keys %{$self->{params}})
	{
		$self->{params}->{$k} =~ s/Â//g;
	}
}

sub assign_initial_session_values
{
	my ($self) = @_;

	if($self->{params}->{reassign_base_application})
	{
		$self->{session}->delete('base_application');
	}

	if($self->{session}->{base_application}!~/\w/)
	{
		$self->{session}->set('base_application', $self->app_name);
	}

	return 1;
}

###################Initi
# Assign Org
# This will accept an id and load that org into the app.
# Should be used when the application is called from an external script.

sub assign_org
{
	my ($self, $id) = @_;

	if($self->{org})
	{
		return;
	}

	my $org = $self->load_org({
		id => $id });

	$self->{org} = $org;

	$self->{org}->set_application_id($self->base_application);
}

########################################################################################
########################################################################################
######################
# USER ORG Inheritance
######################
# These methods will return User and Org objects that are blessed into the correct class
# for the current application.  I.e. if the Application needs the Webkit::Holiday::User class,
# then it should return this when get_user_with_id etc is called.
######################
########################################################################################
########################################################################################

sub get_blank_user
{
	my ($self) = @_;

	return Webkit::User->constructor($self->{db});
}

sub load_user
{
	my ($self, $attr) = @_;

	return Webkit::User->load($self->{db}, $attr);
}

sub get_org_classname
{
	my ($self) = @_;

	return 'Webkit::Org';
}

sub load_org
{
	my ($self, $attr) = @_;

	return Webkit::Org->load($self->{db}, $attr);
}

sub create_default_user_data
{
	my ($self, $user) = @_;

}

############ The methods above are deprecated although still left alone
############ The new way to load a user and org for the app is by
############ calling $app->bless_user/org passing the object to bless

sub bless_user
{
	my ($self, $user) = @_;

#	bless($user, 'Webkit::User');

}

sub bless_org
{
	my ($self, $org) = @_;

#	bless($org, 'Webkit::Org');
}


############################
############################
#
#
#
#
#
#### Page Methods
#
#
#
#
#
############################
############################

####################
# Print Page
# This will actually print the page content back to the browser
# It is called last in run.
# Basically, the method will arrange the objects, and dump the template
# into the page, and then this method will print the whole lot back
#
# If $self->is_manual_page_method is true, this method will do nothing

sub print_header
{
	my ($self) = @_;

	if(!$self->is_manual_page_method)
	{
		my $r = $self->r;

		if($r)
		{
			$r->content_type($self->content_type);
	#		$r->set_content_length(length($page_content));
			$r->no_cache(1);
			$r->send_http_header;
		}
		else
		{
			my $content_type = $self->content_type;

			print "Content-type: $content_type\n\n";
		}

		my $loading = $self->{page}->get_template('loading_div');

		my $line_count;

		$loading .= '<!-- ';

		for(my $i=0; $i<=1024; $i++)
		{
			$loading.=" buffer ";

			$line_count++;

			if($line_count>100)
			{
				$loading.="\n";
				$line_count = 0;
			}
		}

		$loading .= "-->";

		$r->print($loading);
	}
}

sub print_page
{
	my ($self) = @_;

	if($self->is_manual_page_method)
	{
		$self->print_manual_page;
	}
	else
	{
		$self->print_normal_page;
	}
}

sub print_manual_page
{
	my ($self) = @_;

	if($self->get_manual_page_method eq 'header')
	{
		return;
	}

	my $page = $self->{page}->{manual_page};

	my $r = $self->r;

	if($r)
	{
		$r->content_type($self->content_type);
		$r->set_content_length(length($page));
		$r->no_cache(1);
		$r->send_http_header;

		$r->print($page);
	}
	else
	{
		my $content_type = $self->content_type;
		my $length = length($page);

		print<<"+++";
Content-type: $content_type
Content-length: $length

$page
+++
	}
}

sub print_normal_page
{
        my ($self) = @_;

	if($self->is_manual_page_method)
	{
		return;
	}

	my $page_content = '';

	if(!$self->{page}->has_wrapper)
	{
		$self->{page}->set_wrapper('wrapper', {
			href => $self->href });
	}

        if($self->{session}->{printsql} eq 'y')
        {
                $self->{page}->ab("<hr>".$self->{db}->get_log);
        }

        $page_content = $self->{page}->print;

	my $method = $self->method;

	$page_content.=<<"+++";
<script>

/////// THE METHOD IS $method

</script>
+++

	$page_content = $self->post_parse_page($page_content);

	$page_content.=$self->get_close_loading;

	print $page_content;
}

sub get_close_loading
{
	my ($self) = @_;

	my $close=<<"+++";
<script>
if(document.getElementById('loadingdiv'))
{
	document.getElementById('loadingdiv').style.display = 'none';
}
</script>
+++

	return $close;
}

sub post_parse_page
{
	my ($self, $content) = @_;

	if($self->is_manual_page_method)
	{
		return $content;
	}

	if($content=~/<head>/)
	{
		my $new_head=<<"+++";
<head>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
+++

		$content =~ s/<head>/$new_head/i;
	}
	else
	{
		$content=<<"+++";
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
$content
+++
	}

	return $content;
}

##############
# Print Open Loading
# This will print the loading div to the screen and is called before the method is called

sub print_open_loading
{
	my ($self) = @_;

	return;
}

########################
# Manual Page methods - this returns the hash of methods to be printed manually

sub content_type
{
	my ($self, $new) = @_;

	if($new)
	{
		$self->{content_type} = $new;
	}

	my $content_type = 'text/html';

	if($self->{content_type})
	{
		$content_type = $self->{content_type};
	}

	return $content_type;
}

sub manual_page_methods
{
	my ($self) = @_;

	return $manual_page_methods;
}

sub is_manual_header_method
{
	my ($self) = @_;

	if($self->get_manual_page_method eq 'header')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub get_manual_page_method
{
	my ($self) = @_;

	my $overrides = $self->manual_page_methods;

	if($overrides->{$self->method})
	{
		return $overrides->{$self->method};
	}
	else
	{
		return $manual_page_methods->{$self->method};
	}
}

sub has_loading_div
{
	my ($self) = @_;

	if(!$self->is_manual_page_method)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

########################
# Returns true if $self->method is within $self->manual_page_methods
# i.e. the current method needs to be printed manually

sub is_manual_page_method
{
	my ($self) = @_;

	if($self->{force_print})
	{
		return undef;
	}

	return $self->get_manual_page_method($self->method);
}

############################
############################
#
#
#
#
#
#### Browser Methods
#
#
#
#
#
############################
############################

sub ensure_browser
{
	my ($self) = @_;

	$self->{browser} = Webkit::Browser->new;

	return $self->{browser}->is_valid;
}

sub get_user_agent
{
	my ($self) = @_;

	return $ENV{HTTP_USER_AGENT};
}


sub is_mac
{
	my ($self) = @_;

	return $self->{browser}->is_mac;
}


############################
############################
#
#
#
#
#
#### Log Methods
#
#
#
#
#
############################
############################

sub should_log 
{
	my ($self) = @_;

	if((!$self->{org})||(!$self->{user}))
	{
		return undef;
	}

	if($self->method=~/_frameset$/)
	{
		return undef;
	}

	if($self->method=~/^pagetop_/)
	{
		return undef;
	}

	if($self->{params}->{nolog})
	{
		return undef;
	}

	if($self->get_manual_page_method eq 'no_log')
	{
		return undef;
	}

	return 1;
}

sub insert_log
{
	my ($self) = @_;

	if($self->should_log)
	{
		my $log = Webkit::AppLog->constructor($self->{db});

		$log->set_value('org_id', $self->{org}->get_id);
		$log->set_value('users_id', $self->{user}->get_id);
		$log->set_value('requested', Webkit::DateTime->now);
		$log->set_value('method', $self->method);
		$log->set_value('application_id', $self->base_application);

		if($self->current_application_id ne $self->base_application)
		{
			$log->set_value('sub_application_id', $self->current_application_id);
		}

		$log->set_value('sql', $self->{db}->get_log);

		if(!$self->{params_no_log})
		{
			my $st = '';

			foreach my $key (keys %{$self->{params}})
			{
				my $value = $self->{params}->{$key};

				$st.="$key = $value\n\n";
			}

			$log->set_value('params', $st);
		}

		$self->{db}->begin_transaction;

		$log->create;

		$self->{db}->commit;
	}
}





########################################################################################
########################################################################################
######################
# Login Methods
##############
# These methods deal with the user accessing the application, you can change this default
# flow by overiding the home_method method and controlling the flow from there.
# Also, it is important that you ensure the templates point the correct next
# method.  The default set of templates are used if no other template is present.
######################
########################################################################################
########################################################################################

####################
# Remind Password
# This method is used if the user has forgotten their password
# They just supply their username (email) and their password is
# emailed to them

sub remind_password
{
        my ($self) = @_;

        my $email = $self->{params}->{username};

        my $status = '';	

        if(Webkit::AppTools->check_email_address($email))
        {
                my $user = $self->load_user({
			clause => " username = ? ",
			binds => [$email] });

                if($user)
                {
                        my $date_st = Webkit::DateTime->now->get_full_string;

			my $app_title = $self->app_title;

			my $username = $user->get_value('username');
			my $password = $user->get_value('password');

                        my $message=<<"+++";
This is an email to remind you of your password to log-in to the $app_title system.

Email sent:     $date_st

Your username is:        $username

Your password is:        $password

----------------------------------------

+++

                        my $message_hash = {
                                from => 'support@webkit.tv',
                                to => $user->get_value('username'),
                                subject => $app_title.' Password Reminder',
                                message => $message };

                        Webkit::AppTools->send_email($message_hash);

                        $status = "An Email has been sent to $username with the password";
                }
                else
                {
                        $status = "There is no such user with the email of $email";
                }
        }
        else
        {
                $status = "$email is an invalid address";
        }

        $self->{page}->add_template('login', {
                remind_status => $status });
}

sub open_login_page
{
	my ($self) = @_;

	$self->{page}->add_template('open_login_page');
}

####################
# Login
# This will present the user with a login screen
# The method within the form should be authenticate
# if you want the default log-in flow.

sub login
{
        my ($self, $message) = @_;

	if($self->{params}->{login_page})
	{
		my $text=<<"+++";
<script>
	document.location = '$self->{params}->{login_page}';
</script>
+++

		$self->{page}->ab($text);
	}
	else
	{
		my $login_method = 'authenticate';

		if($self->{params}->{login_method}=~/\w/)
		{
			$login_method = $self->{params}->{login_method};
		}

		my $hidden_string=<<"+++";
<input type="hidden" name="method" value="$login_method">
+++

		my $printable_login_params = {
			page_org => 1,
			login_method => 1 };

		foreach my $key (keys %{$self->{params}})
		{
			if(!$printable_login_params->{$key})
			{
				next;
			}

			my $value = $self->{params}->{$key};

			$hidden_string.=<<"+++";
<input type="hidden" name="$key" value="$value">
+++
		}
	
		$self->{page}->add_template('login', {
			hidden_string => $hidden_string,
			username => $self->{params}->{username},
	                login_status => $message });


	}
}

####################
# Authenticate
# The execution will only get here once check_access has
# returned true (and all objects are therefore setup).
# The purpose of this method is to print the template
# that opens the Application Window.

sub authenticate
{
	my ($self) = @_;

#	my $status = ', true';
#
#	if(($self->debug)||($self->{params}->{debug}=~/\w/))
#	{
#		$status = ', true';
#	}
#
#	my $next = $self->{params}->{login_page};
#
#	if($next!~/\w/)
#	{
#		$next = $self->href.'&method=login';
#	}
#
#	$self->{page}->add_template('open_js_window', {
#		next => $next,
#		status => $status });

	$self->{page}->add_redir({
		method => 'generate_window' });
}

#####################
# Logged in - this is simply the page that authenticate should redirect to 
# (currently done in the template) - you can change the flow by changing
# the template

sub logged_in
{
	my ($self) = @_;

	$self->{page}->add_template('logged_in', {
		app_title => $self->app_title } );
}

#########################
# Generate Window
# This is the method that is called first from the Application Window.
# It is responsible for creating the application framework via Iframes

sub generate_window
{
	my ($self, $attr) = @_;

	my $href = $self->href;

	foreach my $key (keys %$attr)
	{
		$attr->{$key} = $attr->{$key};
	}

	my $template_code = $self->{page}->get_template('window', $attr);

	$self->{page}->{manual_page} =  $template_code;
}

#########################
# ABSTRACT
# Home Frameset
# This is a placeholder for the frameset to be called from generate window.
# If the application requires several frames within its main frame,
# This is where to create the frameset.
# Otherwise, the default is to call $self->home

sub home_frameset
{
	my ($self) = @_;

	$self->home;
}

#########################
# ABSTRACT
# Home
# This is the placeholder for the home page of the application.
# You can print content or redirect the flow to other methods.

sub home
{
	my ($self) = @_;

	my $app_title = $self->app_title;
	my $user_title = $self->{user}->get_fullname;

	$self->{page}->ab("Welcome $user_title, this is the $app_title homepage.");
}

##############################
# get_userform_props
#
# This method is called to assign values to a hash
# Ready for a userform

sub get_userform
{
	my ($self, $user, $config) = @_;

	if($config->{form_config}->{signin_details}!=-1)
	{
		$config->{form_config}->{signin_details} = 1;
	}
	else
	{
		delete($config->{form_config}->{signin_details});
	}

	if($config->{form_config}->{personal_details}!=-1)
	{
		$config->{form_config}->{personal_details} = 1;
	}
	else
	{
		delete($config->{form_config}->{personal_details});
	}

	if($config->{form_config}->{privilages}!=-1)
	{
		if($self->{user}->admin)
		{
			if($config->{form_config}->{privilages}!~/\w/)
			{
				$config->{form_config}->{privilages} = 1;
			}
		}
		else
		{
			delete($config->{form_config}->{privilages});
		}
	}
	else
	{
		delete($config->{form_config}->{privilages});
	}

	my $org = $self->{org};

	if($config->{formorg})
	{
		$org = $config->{formorg};
	}

	if(!$org)
	{
		my $org_id = $user->get_value('org_id');

		if(!$org_id>0)
		{
			$org_id = $self->{session}->{edit_org_id};
		}

		if($org_id>0)
		{
			$org = Webkit::Org->load($self->{db}, {
				id => $user->get_value('org_id') });
		}
	}

	$config->{formorg} = $org;
	$config->{formuser} = $user;

	my $userform = $self->{page}->get_template('user_form', $config);

	return $userform;
}

sub save_userform
{
	my ($self, $user) = @_;

	$user->save_form_data($self->{params});
	$user->save_department_info($self->{params});

	return;

	my @simple_props = qw(firstname surname username password type phone mobile position homephone sex address);

	foreach my $prop (@simple_props)
	{
		if(defined($self->{params}->{$prop}))
		{
			$user->set_value($prop, $self->{params}->{$prop});
		}
	}
}

sub users_home
{
	my ($self, $config) = @_;

	if(!$self->{user}->admin)
	{
		$self->{page}->ab("Admin function");
		return;
	}

	$self->{session}->set('view_method', 'users_home');

	my $app_name = $self->{session}->{base_application};

	if(defined($self->{session}->{users_home_app_name}))
	{
		$app_name = $self->{session}->{users_home_app_name};
	}

	my $user_filter = $self->{params}->{object_list_filter};

	if($user_filter !~ /\w/)
	{
		$user_filter = 'all';
	}

	my $org = $self->{org};

	if($self->{session}->{edit_org_id}>0)
	{
		$org = Webkit::Org->load($self->{db}, {
			id => $self->{session}->{edit_org_id} });
	}

	$org->load_users({
		appname => $self->{session}->{base_application},
		privilage => $user_filter });

	$org->load_departments(1);

	my $add_method = '';

	if($self->{session}->{users_home_add_method}=~/\w/)
	{
		$add_method = $self->{session}->{users_home_add_method};
	}
	else
	{
		$add_method = 'add_user';
	}	

	my $defs = [
		{	title => 'Name',
			method => 'get_fullname',
			width => '*' },

		{	title => 'Username',
			prop => 'username',
			width => '220' },

		{	title => 'Group',
			method => 'get_department_name',
			width => '140' },

		{	title => 'Type',
			method => 'get_type_title',
			width => '140' } ];

	my $buttons = [
		{	key => 'add',
			title => 'Add User',
			normal_method => $add_method },
		{	key => 'edit',
			title => 'Edit User',
			method => 'edit_user' },
		{	key => 'delete',
			title => 'Delete User',
			method => 'delete_user' } ];
			

	if($config->{defs})
	{
		$defs = $config->{defs};
	}

	if($self->{session}->{users_home_no_active} ne 'y')
	{
		push(@$defs, {	
			title => 'Exists',
			align => 'center',
			args => [$self->{session}->{base_application}],
			method => 'get_app_exists_image',
			width => '45' });

		push(@$defs, {	
			title => 'Active',
			align => 'center',
			args => [$self->{session}->{base_application}],
			method => 'get_active_image',
			width => '45' });
	}

	$self->{page}->add_template('object_list', {
		defs => $defs,
		filter_options => $self->get_user_filter_options,
		filter_submit_method => 'users_home',
		objects => $org->get_child_array('users'),
		button_refs => $buttons });
}

sub add_user
{
	my ($self, $user, $config) = @_;

	if(!$user)
	{
		$user = $self->get_blank_user;
		$user->set_form_defaults;
	}

	my $userform = $self->get_userform($user, $config);

	$self->{page}->add_template('user_form_wrapper', {
		user_form => $userform,
		cancel_method => 'users_home',
		submit_method => 'add_user_submit',
		submit_title => 'Add User',
		formuser => $user });
}

sub add_user_submit
{
	my ($self, $attr) = @_;

	my $user = $self->get_blank_user;

	my $org_id = $self->{org}->get_id;

	if($self->{session}->{edit_org_id}>0)
	{
		$org_id = $self->{session}->{edit_org_id};
	}

	$user->set_value('org_id', $org_id);
	$user->set_value('type', 'normal');
	$user->set_value('general_type', 'normal');
	$user->set_value('deleted', 'n');

	$self->save_userform($user);

	if($user->error)
	{
		$self->add_user($user);

		return;
	}
	else
	{
		$user->load_all_privilages;

		$self->{db}->begin_transaction;

		$user->commit_department_info;

		$user->create;

		if(!$attr->{no_privilages})
		{
			$user->save_all_privilages($self->{params});

			$user->commit_changed_privilages;
		}

		$self->{db}->commit;

		$self->{page}->add_redir({
			method => 'users_home' });
	}
}

sub edit_personal_details
{
	my ($self) = @_;

	$self->{params}->{object_id} = $self->{user}->get_id;

	$self->edit_user;
}

sub edit_user
{
	my ($self, $user, $config) = @_;

	if(!$user)
	{
		$user = $self->load_user({
			id => $self->{params}->{object_id} });
	}

	my $userform = $self->get_userform($user, $config);

	$self->{page}->add_template('user_form_wrapper', {
		user_form => $userform,		
		cancel_method => 'users_home',
		submit_method => 'edit_user_submit',
		submit_title => 'Save User',
		formuser => $user });
}

sub edit_user_submit
{
	my ($self, $attr) = @_;

	my $user = $self->load_user({
		id => $self->{params}->{user_id} });

	$self->save_userform($user);

	if($user->error)
	{
		$self->edit_user($user);

		return;
	}
	else
	{
		$user->load_all_privilages;

		$self->{db}->begin_transaction;

		$user->commit_department_info;

		$user->save;

		if(!$attr->{no_privilages})
		{
			$user->save_all_privilages($self->{params});

			$user->commit_changed_privilages;
		}

		$self->{db}->commit;

		if($self->{params}->{close_method} eq 'jswindow')
		{
			$self->{page}->ab(<<"+++");
<script>
	top.close();
</script>
+++
		}
		else
		{
			$self->{page}->add_redir({
				method => 'users_home' });
		}
	}
}

sub delete_user
{
	my ($self) = @_;

	if($self->{params}->{object_id}==$self->{user}->{id})
	{
		$self->users_home;

		return;
	}

	my $user = $self->load_user({
		id => $self->{params}->{object_id} });

	$self->{page}->add_template('object_delete_confirm', {
		object_title => $user->get_fullname,
		cancel_method => 'users_home',
		confirm_method => 'delete_user_submit',
		object_id => $user->get_id });

}

sub delete_user_submit
{
	my ($self) = @_;

	my $user = $self->load_user({
		id => $self->{params}->{object_id} });

	$self->{db}->begin_transaction;

	$user->delete_application_privilages($self->base_application);

	$self->{db}->commit;

	$self->{page}->add_redir({
		method => 'users_home' });
}


sub iframe_title_frame
{
	my ($self) = @_;

	my $frameset = Webkit::Apache::TemplateHub->iframe_title_frame_html({
		params => $self->{params},
		href => $self->href });

	$self->{page}->{manual_page} = $frameset;
}

sub iframe_title
{
	my ($self) = @_;

	my $title = $self->{params}->{title};
	
	$self->{page}->{manual_page} =  $self->{page}->get_template('iframe_title',{
		iframe_title => $title });			
}

sub add_iframe_update
{
	my ($self, $title) = @_;

	$self->{page}->add_iframe_update('title', $title);
}

sub get_user_filter_options
{
	my ($self, $submit_method) = @_;

	if(!$submit_method)
	{
		$submit_method = 'users_home';
	}

	my $selected = $self->{params}->{object_list_filter};

	if(!$selected)
	{
		$selected = 'all';
	}

	my $option_data = [	{
				title => 'All Users',
				key => 'all' },	
			{
				title => 'Existing Users (cannot login)',
				key => 'exists' },
			{
				title => 'Active Users (can login)',
				key => 'active' } ];


	my $options = Webkit::AppTools->get_select_options($option_data, {
		key_field => 'key',
		value_field => 'title',
		selected => $selected });

	return $options;
}

sub support_home
{
	my ($self) = @_;

	my $now = Webkit::DateTime->now;

	my $contact_option_array = [{	title => 'Email',
					value => 'email' },
				{	title => 'Telephone',
					value => 'phone' }];

	my $contact_options = Webkit::AppTools->get_select_options($contact_option_array, {
		key_field => 'value',
		value_field => 'title',
		selected => $self->{params}->{contact_via} });

	$self->{page}->add_template('support_home', {
		contact_options => $contact_options,
		date_title => $now->get_string,
		app_title => $self->get_application_title });
}

sub support_submit_query
{
	my ($self) = @_;

	if($self->{params}->{query}!~/\w/)
	{
		$self->{params}->{status} = 'Please type a question';

		$self->support_home;

		return;
	}

	my $org_name = $self->{org}->get_value('name');
	my $org_id = $self->{org}->get_id;

	my $user_name = $self->{user}->get_fullname;
	my $user_id = $self->{user}->get_id;

	my $app_title = $self->get_application_title;

	my $contact_via = $self->{params}->{contact_via};

	my $contact_details = $self->{params}->{contact_details};

	my $browser = $self->{params}->{browser};

	my $operating_system = $self->{params}->{operating_system};

	my $screen_resolution = $self->{params}->{screen_resolution};

	my $query = $self->{params}->{query};

	my $message=<<"+++";
Client: $org_name ($org_id)
User: $user_name ($user_id)

Application: $app_title

Browser: $browser
Operating System: $operating_system
Screen Resolution: $screen_resolution

Contact Via: $contact_via
Contact Details: $contact_details

Problem:
------------------------------
$query
------------------------------
+++

	my $mail_hash = {
		from => $self->{user}->get_value('username'),
		subject => 'Support Submission From '.$user_name.' of '.$org_name,
		message => $message };

	my $admin_refs = $self->{db}->get_select_refs({
		table => 'webkit.users',
		cols => 'username, id',
		clause => " org_id = 1 and type = 'admin' and general_type = 'webkit' " });

	foreach my $ref (@$admin_refs)
	{
		$mail_hash->{to} = $ref->{username};

		Webkit::AppTools->send_email($mail_hash);
	}

	$self->{page}->add_redir({
		method => 'support_home',
		status => 'Thank you, your problem has been emailed to us, and we will contact you shortly' });
}


sub about_home
{
	my ($self) = @_;

	$self->{page}->add_template('about_home', {
		app_title => $self->get_application_title,
		version_title => '3.112',
		description_title => $self->get_application_description });
}

sub logout
{
	my ($self) = @_;

	$self->log_out;
}

sub log_out
{
	my ($self) = @_;

	$self->{user}->load_all_privilages;

	my $now_date = Webkit::DateTime->now;

	$self->{page}->add_template('log_out', {
		logged_in_title => $self->{session}->get_logged_in_title,
		logging_out_title => $now_date->get_string,
		duration_title => $self->{session}->get_duration_title });
}

sub switch_application
{
	my ($self) = @_;

	my $app_id = $self->base_application;

	$self->bless_application('Webkit::Login::Admin');

	$self->home_frameset_content($app_id);
}

sub inform_upgrade_browser
{
	my ($self) = @_;

	if($self->is_manual_page_method)
	{
		$self->{page}->{manual_page} = $self->{page}->get_template('browser');
	}
	else
	{
		$self->{page}->add_template('browser');
	}
}

1;
