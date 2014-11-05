package Webkit::Apache::StatsHandler;

use strict;

#use Apache::Constants qw(OK FORBIDDEN NOT_FOUND SERVER_ERROR);
#use Apache::Request ();
#use Apache::File ();

use Webkit::SiteManager::Admin ();
use Webkit::Session ();

sub handler
{
	my $r = shift;

	my $uri = $r->uri;

	my $session_id = $r->path_info;

	$session_id =~ s/^\///;

	if(!$session_id)
	{
		$r->log_error("$session_id was missing to access StatsHandler");
		return $Apache2::Const::FORBIDDEN;
	}

	my $app = Webkit::SiteManager::Admin->new;

	$app->{params}->{session_id} = $session_id;

	if(!$app->check_access)
	{
		$r->log_error("$session_id was not validated to access StatsHandler");
		return $Apache2::Const::FORBIDDEN;
	}

	my $filename = $r->filename;

	unless (-f $r->finfo)
	{
		$r->log_error("$filename was not found to access StatsHandler");
		return $Apache2::Const::NOT_FOUND;
	}

	my $fh = Apache2::File->new($filename);

	unless($fh)
	{
		$r->log_error("Cannot open (for StatsHandler): $filename: $!");
		return $Apache2::Const::SERVER_ERROR;
	}

	if($filename=~/^\/home\/stats\/www\/(\w+\/\w+)\/\w+\.html/)
	{
		my $base = Webkit::Application->http_host.'/stats/'.$1.'/';

		my $after = '/'.$session_id;

		my $filecontent = do {local $/;<$fh>};

		$filecontent =~ s/src="(\w+\.png)"/src="$base$1$after"/gi;

		$r->set_content_length(length($filecontent));
		$r->send_http_header('text/html');

		$r->print($filecontent);
	}
	else
	{
		$r->send_http_header;
		$r->send_fd($fh);
	}

	return $Apache2::Const::OK;
}

1;
