package Webkit::Apache::SiteEditorProxy;

use strict;

#use Apache::Constants qw(OK FORBIDDEN NOT_FOUND SERVER_ERROR DECLINED);
#use Apache::Request ();
#use Apache::File ();

use LWP::Simple ();
#use Apache::File (); 

sub get_request_details
{
	my ($uri) = @_;

	my $site_key;
	my $file_uri;

	if($uri =~ /^\/siteeditor\/(\w+)(\/.*)$/)
	{
		$site_key = $1;
		$file_uri = $2;
	}
	else
	{
		return $Apache2::Const::NOT_FOUND;
	}

	my $site;
	my $app;

	eval {
		$app = Webkit::SiteManager::Admin->new;

		$site = Webkit::SiteManager::Website->load($app->{db}, {
			clause => 'log_username = ?',
			binds => [$site_key] });
	};

	if($@)
	{
		return $Apache2::Const::SERVER_ERROR;
	}
	elsif(!$site)
	{
		return $Apache2::Const::NOT_FOUND;
	}
	else
	{
		my $ret = {
			uri => $uri,
			app => $app,
			site => $site,
			file_uri => $file_uri,
			site_key => $site_key };

		return $ret;
	}
}

sub handler
{
	my $r = shift;

	my $uri = $r->uri;

	my $details = &get_request_details($uri);

	if(($details==$Apache2::Const::SERVER_ERROR)||($details==$Apache2::Const::NOT_FOUND))
	{
		return $details;
	}

	if($details->{uri}=~/\.s?html?$/i)
	{
		my $request = Apache2::Request->new($r);

		my $page_id = $request->param('page_id');
		my $editor = $request->param('editor');
		my $session_id = $request->param('session_id');
		my $preview = $request->param('preview');

		my $url = $details->{site}->get_url.$details->{file_uri};

		if($editor)
		{
			$url.='?editor=1';
		}

		if($session_id)
		{
			$url.='?session_id='.$session_id;
		}

		my $page_content = &LWP::Simple::get($url);

		my $site_key = $details->{site_key};

#					$page_content =~ s/src ?= ?("|')?(\/[^\.]+\.\w{2,4})("|')?/src="\/siteeditor\/$site_key$2"/gis;


#### This removes pre-designated blocks

		while($page_content=~/<wks_applink image="([\w\.]+)" app="(\w+)" method="(\w+)"\/>/gsi)
		{
			my $new_copy = $page_content;

			my $img = $1;
			my $app = $2;
			my $method = $3;

			my $replace=<<"+++";
<wksinput type="image" src="/img/editor/$img" onClick="document.location = top.href + '&method=$method&appname=$app';">
+++

			$new_copy =~ s/<wks_applink image="([\w\.]+)" app="(\w+)" method="(\w+)"\/>/$replace/si;

			$page_content = $new_copy;
		}

		while($page_content=~/<wksignore img="([\w\.]+)">.*?<\/wksignore>/gsi)
		{
			my $newcopy = $page_content;

			my $src = "/img/editor/$1";

			$newcopy =~ s/<wksignore img="([\w\.]+)">.*?<\/wksignore>/<img src="$src">/si;

			$page_content = $newcopy;
		}

		$page_content =~ s/<wksignore>.*?<\/wksignore>//gsi;

#### This one removes all links

		$page_content =~ s/<\/?a.*?>//sgi;

		$page_content =~ s/<wksa/<a/gsi;
		$page_content =~ s/<\/wksa/<\/a/gsi;

#### This inserts the session ID when needed

		$page_content =~ s/<wks_session_id>/$session_id/gsi;

#### This one removes all script references

		$page_content =~ s/<script.*?<\/script>//gsi;

		$page_content =~ s/<script.*?>//gsi;

		$page_content =~ s/<input.*?>//gsi;
		$page_content =~ s/\bwksinput\b/input/gsi;
		$page_content =~ s/<\/?textarea.*?>//gsi;

		$page_content =~ s/\bwksscript\b/script/gsi;

#### This one removes all iframes

		$page_content =~ s/<iframe.*?\/iframe>//gsi;
		$page_content =~ s/\bwksiframe\b/iframe/gsi;

#### This one makes sure that the html links come through LWP

		my $website_url = $details->{site}->get_value('url');

		$page_content =~ s/$website_url//gsi;

#### Here are the SRC replaces

		$page_content =~ s/["'= ](\/[\/\w_]+\.\w+)["' ]/'\/siteeditor\/$site_key$1'/gis;

#### This is the fix for the /wk dir

		$page_content =~ s/\/siteeditor\/$site_key\/wk\//\//gis;

		if(!$preview)
		{
			$page_content.=<<"+++";
<script>
	function remove_topbar()
	{
		parent.topbar.reset_page();
	}

	document.body.onunload = remove_topbar;
</script>
+++
		}

		$r->set_content_length(length($page_content));
		$r->send_http_header('text/html');

		$r->print($page_content);

		return $Apache2::Const::OK;
	}
	else
	{
		my $local_path = $details->{site}->get_value('home_directory');

		$local_path.=$details->{file_uri};

		if(-e $local_path)
		{
			my $fh = Apache::File->new($local_path);

			$r->send_fd($fh);

			return $Apache2::Const::OK;
		}
		else
		{
			$r->log_error("$local_path NOT FOUND");

			return $Apache2::Const::NOT_FOUND;
		}
	}
}

1;
