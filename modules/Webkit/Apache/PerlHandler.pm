package Webkit::Apache::PerlHandler;

use strict;

use Apache2::Upload ();
use Webkit::MyOffice2::Admin ();

#######################################
#######################################
### Handler - this method is the actual PerlHandler plugged into .app requests
### It basically grabs the params (get_params) and the dispatches control to
### application_hander
###
### Future note - handler is where to delegate requests for other resources than
### standard .app - i.e. .db or .game etc could be handled differently

sub handler
{
	$| = 1;

	my $r = shift;
	
	my $params = &get_params($r);

	return &application_handler($r, $params);
}

#######################################
#######################################
### Get Params - this method uses the Apache object and constructs an Apache::Request
### It detects whether the form is multipart/form-data and if so will grab the upload contents.
### By doing so it creates an array ($params->{_uploads}) that holds a reference to info
### about each upload (content, filename, type, size).
### Either way it grabs the standard params submitted to the request (GET or POST)
### and returns a reference to a hash containing them

sub get_params
{
	my ($r) = @_;

	my $request;
	my $params;

#	if($r->headers_in->get('Content-Type') =~ /^multipart\/form-data/)
#	{
#		$request = Apache2::Request->new($r,
#						POST_MAX => 100 * 1024 * 1024,
#						DISABLE_UPLOADS => 1);
#
#		my $status = $request->parse();
#
#		#if($status!=OK)
#		#{
#		#	return &error_page($r, "Problem with upload");
#		#}
#
#		foreach my $upload ($request->upload)
#		{
#			my $fh = $upload->fh;
#
#			my $content = do {local $/; <$fh>};
#
#			$fh = undef;
#
#			my $upload_file = $upload->filename;
#
#			my $ext = '';
#
#			if($upload_file=~/\.(\w+)$/)
#			{
#				$ext = $1;
#			}
#
#			$params->{_uploads}->{$upload->name} = {
#				ext => $ext,
#				content => $content,
#				filename => $upload->filename,
#				type => $upload->type,
#				size => $upload->size };
#				
#		}
#	}
#	else
#	{
		$request = Apache2::Request->new($r);
		
		#my $status = $request->parse;
		
		foreach my $uploadname ($request->upload())
		{
			my $upload = $request->upload($uploadname);
			
			my $fh = $upload->fh;

			my $content = do {local $/; <$fh>};

			$fh = undef;

			my $upload_file = $upload->filename;
			
			my $ext = '';

			if($upload_file=~/\.(\w+)$/)
			{
				$ext = $1;
			}

			$params->{_uploads}->{$uploadname} = {
				ext => $ext,
				content => $content,
				filename => $upload->filename,
				type => $upload->type,
				size => $upload->size };
				
		}		
#	}

	foreach my $key ($request->param)
	{
		$params->{$key} = $request->param($key);
	}

	return $params;
}

#######################################
#######################################
### This method is Webkit Application specific in that it uses ApplicationHub
### to map the requested .app onto the Perl module that will handle the request (Webkit::****::Admin usually)
### It runs the entire App within an Eval block so if something goes wrong - the
### custom error page can be printed as opposed to the 'Internal Server Error'

sub application_handler
{
	my ($r, $params) = @_;

	my $uri = $r->uri;
	
	my $appname = '';

	$uri =~ s/\/+$//;

	if($uri =~ /(\w+)\.app$/)
	{
		$appname = $1;
	}
	else
	{
		return &error_page($r, "URI Not regexp - $uri");
	}

	if($params->{appname} =~ /\w/)
	{
		my $newappname = $params->{appname};

		$uri =~ s/$appname/$newappname/;

		if(!$params->{app_proxy})
		{
			$appname = $params->{appname};
		}

		if($params->{appname_single}!~/\w/)
		{
			$r->uri($uri);
		}
	}
	
	my $application = Webkit::Apache::ApplicationHub->get_application($appname);
	
	if(!$application)
	{
		return &error_page($r, "No Application returned by the ApplicationHub for $appname - $application");
	}

	my $module = $application->get_value('module');

	if($module !~ /\w/)
	{
		return &error_page($r, "Module Not Found for $appname");
	}

	#print "Content-type: text/plain\n\n";
	#print "Making app\n";
	
	my $app = eval($module.'->new');

	#if(!$app) { print "no app\n"; } else { print "have app\n"; }
	if(!$app) { return &error_page($r, "No Modules Loaded for $module"); }

	#exit 1;
	eval
	{
		$app->run($params);
	};
	
	if($@)
	{
		&error_page($r,$@,$params,$app);
	}

	$app = undef;

	return $Apache2::Const::OK;
}

#######################################
#######################################
## This is the custom error_page that is called if the main Eval block for an App kicks off an error
## It will inform the user there is an error with an expand button to show the die message,
## the parameters and the SQL log

sub error_page
{
	my ($r, $text, $params,$app) = @_;

	my $parts;

	foreach my $key (keys %$params)
	{
		push(@$parts, "$key=".$params->{$key});
	}

	my $content = '';

	if($parts)
	{
		$content = join('&', @$parts);
	}

	$text .= "<hr><pre>".$content."</pre>";

	if($app->{db})
	{
		$text .= "<hr><pre>".$app->{db}->get_log."</pre>";
	}

	my $page = Webkit::Page->new();

	my $errorcontent = $page->get_template('error', {
		error => $text });

	#$r->no_cache(1);
	print "Content-type: text/html\n\n";

#	if((!ref($app))||(!$app->has_loading_div))
#	{
#
#	}
#	else
#	{
		print<<"+++";
<script>
	if(document.getElementById('loadingdiv'))
	{
		hide_loading();
	}
</script>
+++
#	}

	print $errorcontent;

	return $Apache2::Const::OK;
}

1;
