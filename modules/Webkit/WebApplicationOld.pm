package Webkit::WebApplication;

##### WebApp is a wrapper for Webkit::Application that is suitable
##### for direct PerlHandler use with particular websites
#####
##### you can selectively choose directories or the whole wite to be parsed through
##### any given App that extends from the WebApp
#####
##### The WebApp turns pages into methods which you can optionally define
##### Basically you have the option to write fully fledged engine code
##### based on the invocation of any web-page within the selected website.
#####
##### The output is the contents of the requested file but parsed as an app template
##### Therefore - the web-pages on disk are templates not pages
##### The App code can either contain a method (the name is based on the filename)
##### Or the template can operate Perl of its own

use vars qw(@ISA);

use strict qw(vars);

use Webkit::Application;
use Webkit::Error;

@ISA = qw(Webkit::Application);

my $app_name = 'webapp';
my $app_title = 'Web App Framework';

my $manual_page_methods = {};

#### This will hold the content of any static include that has been called (to avoid loading from disk each time)

my $static_includes;

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

sub get_sqldb
{
	my ($self) = @_;

	return 'webkit';
}

sub manual_page_methods
{
	my ($self) = @_;

	return $manual_page_methods;
}


########################################################################################
########################################################################################
######################
# LOGIN
######################
########################################################################################
########################################################################################


#### Main Perl Handler

sub handler
{
	my ($r, $classname) = @_;

	my $content = '';
	my $content_type = '';

	eval
	{
		my $app = Webkit::WebApplication->new;

		if($classname=~/\w/)
		{
			bless($app, $classname);
		}

		$app->assign_params(&Webkit::Apache::PerlHandler::get_params($r));

		$app->{_r} = $r;

		$content = $app->run_web;
		$content_type = $app->{content_type};
	};

	if($@)
	{
		$content = $@;
	}

	#### Return '_no_header' from any method to disable the auto headers (i.e. for printing images and stuff)
	if($content ne '_no_header')
	{
		if($content_type!~/\w/)
		{
			$content_type = 'text/html';
		}

		$r->content_type($content_type);
		$r->set_content_length(length($content));
		$r->no_cache(1);
		$r->send_http_header;

		$r->print($content);
	}

	return $Apache::OK;
}

sub check_file
{
	my ($self, $filename) = @_;

	## If it is a HTML file then check that it exists
	if($filename=~/\.x?html?$/)
	{
		if(!-e $filename)
		{
			$self->{error_text} = "Sorry - we are afraid that we could not find $filename...";
			return 1;
		}
	}

	return undef;
}

sub run_web
{
	my ($self) = @_;

	my $r = $self->{_r};

	my $filename = $r->filename;

	if($self->check_file($filename))
	{
		return $self->{error_text};
	}

	$self->{filename} = $filename;

	my $method = $self->get_page_method;

	if($self->can($method))
	{
		$self->$method;
	}

	my $content = $self->{page_content};

	if($content!~/\w/)
	{
		$content = $self->get_template_for_output($self->{filename});
	}

	if($content!~/\w/)
	{
		$content = 'This request did not return any content';
	}

	return $content;
}

sub get_uri_query_string
{
	my ($self) = @_;

	return $self->get_uri.'?'.$self->get_query_string;
}

sub get_httpd_var
{
	my ($self, $varname) = @_;

	my $r = Webkit::Application->r || return;
	return $r->dir_config($varname) || 0;
}

sub get_uri
{
	my ($self) = @_;

	my $r = $self->{_r};

	my $method = $r->uri;

	return $method;
}

sub get_page_method
{
	my ($self) = @_;

	my $r = $self->{_r};

	my $method = $r->uri;

	$method =~ s/^\///;
	$method =~ s/\.\w+$//;
	$method =~ s/\//__/g;
	$method .= '_handler';

	return $method;
}

sub get_template_for_output
{
	my ($self, $filename) = @_;

	return $self->get_template($filename);
}

#### This method is a post-processing parser for the includes
#### It is called recursivly so you can contain includes within includes (cool eh)

sub parse_page_includes
{
	my ($self, $text) = @_;

	while($text =~ /<wk(\w+)_include([^>]*)>(.*?)<\/wk\1_include>/gs)
	{
		my $temp = $text;

		my $method = $1;
		my $prop_st = $2;
		my $content = $self->parse_page_includes($3);

		my $props;

		while($content =~ /<wkprop_(\w+)>(.*?)<\/wkprop_\1>/gs)
		{
			my $contenttemp = $content;

			my $prop_name = $1;
			my $prop_content = $2;

			$props->{$prop_name} = $prop_content;

			$contenttemp =~ s/<wkprop_(\w+)>(.*?)<\/wkprop_\1>//s;

			$content = $contenttemp;
		}

		$props->{content} = $content;

		while($prop_st =~ /(\w+)="([^"]+)"/gs)
		{
			my $temp_prop_st = $prop_st;

			$props->{$1} = $2;

			$temp_prop_st =~ s/(\w+)="([^"]+)"//;

			$prop_st = $temp_prop_st;
		}

		my $eval_st = '$includecontent = $self->get_'.$method.'_include($props);';

		my $includecontent;

		eval($eval_st);

		$temp =~ s/<wk(\w+)_include([^>]*)>(.*?)<\/wk\1_include>/$includecontent/s;

		$text = $temp;		
	}

	return $text;
}

sub check_access
{
	my ($self) = @_;

	return 1;
}

sub include
{
	my ($self, $uri, $static) = @_;

	my $path = $self->get_uri_file_path($uri);

	if($static)
	{
		#### We have already hit this include inside this process so don't need to load it again
		if($self->{_static_includes}->{$path})
		{
			return $self->{_static_includes}->{$path};
		}

		my $content = $self->get_template($path);

		$self->{_static_includes}->{$path} = $content;

		return $content;
	}
	else
	{
		return $self->get_template($path);
	}
}

sub get_template
{
	my ($self, $file) = @_;

	if($file=~/\.app$/)
	{
		return '';
	}

	if(!-e $file)
	{
		return "Sorry - we are afraid that we could not find $file...";
	}

	my $content = Webkit::AppTools->read_file_contents($file);

        my $template = new Text::Template(	TYPE => 'STRING',
						DELIMITERS => ['<wk>', '</wk>'],
						SOURCE => $content );

	my $props;

	foreach my $key (keys %{$self->{page_props}})
	{
		$props->{$key} = $self->{page_props}->{$key};
	}

	$props->{params} = $self->{params};
	$props->{hostname} = $self->hostname;
	$props->{objs}->{app} = $self;

        my $result = $template->fill_in(HASH => $props);

	return $result;
}

sub get_cookie
{
	my ($self, $key) = @_;

	my %cookiejar = Apache::Cookie->new($self->{_r})->parse;

	my $cookie = $cookiejar{$key};

	if(!$cookie)
	{
		return;
	}

	return $cookie->value;
}

sub bake_cookie
{
	my ($self, $key, $value) = @_;

	my $cookie = Apache::Cookie->new($self->{_r},
		-name => $key,
		-value => $value,
		-path => '/' );

	$cookie->bake;
}

sub remove_cookie
{
	my ($self, $key) = @_;

	my $cookie = Apache::Cookie->new($self->{_r},
		-name => $key,
		-value => '',
		-path => '/',
		-expires => '+0m' );

	$cookie->bake;
}

### Page is a URI - in that it needs to be added onto the Document Root to get a full file path
###
### If $redirect_params is defined then it dictates that the page must be re-directed
### as opposed to simply changed.
###
### If it is a redirect - there is no need to generate a full filepath
### rather simply create a redirect <script> output with the URI 

sub set_page
{
	my ($self, $uri, $redirect_params) = @_;

	if($redirect_params)
	{
		my $message = 'Redirecting Page';
		my $alert;

		if($redirect_params->{message}=~/\w/)
		{
			$message = $redirect_params->{message};
			delete($redirect_params->{message});
		}

		if($redirect_params->{alert}=~/\w/)
		{
			my $text = $redirect_params->{alert};

			$alert=<<"+++";
alert('$text');
+++
		}

		my @pairs;

		foreach my $key (keys %$redirect_params)
		{
			push(@pairs, $key.'='.$redirect_params->{$key});
		}

		my $param_st = join('&', @pairs);

		my $path = $uri.'?'.$param_st;

		$self->{page_content}=<<"+++";
<body bgcolor=#ffffff>
<span style="font-family:tahoma,verdana,arial; font-size:11px; color:#000000;">
$message
</span>
<script>
	$alert
	document.location = '$path';
</script>
+++
	}
	else
	{
		$self->{filename} = $self->get_uri_file_path($uri);
	}
}

####### Gives you the full-path to a uri based on this document root

sub get_uri_file_path
{
	my ($self, $uri) = @_;

	if($uri !~ /\/\w+\.\w+$/)
	{
		if($uri!~/\/$/)
		{
			$uri = $uri.'/';
		}

		$uri .= 'index.htm';
	}

	my $document_root = $self->{_r}->filename;

	$document_root =~ s/\/$//;

	return $document_root.$uri;
}

1;
