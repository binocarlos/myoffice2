package Webkit::Apache::Hiscores;

use strict;

#use Apache::Constants qw(OK NOT_FOUND);
#use Apache ();
#use Apache::Request ();

sub handler
{
	my $r = shift;

	my $request;
	my $params;

	my $uri = $r->uri;

	$request = Apache::Request->new($r);

	foreach my $key ($request->param)
	{
		$params->{$key} = $request->param($key);
	}

	my $app = Webkit::Components::Admin->new;

	my $method = 'hiscores_list';

	if($uri =~ /\/(\w+)\.hiscore/)
	{
		$method = $1;
	}

	$params->{method} = $method;

	if($app)
	{
		eval
		{
			$app->{params} = $params;

			$app->initialise_external_run($r->dir_config('RunOrgId'));

			my $content = $app->$method;

			$r->content_type($app->content_type);
			$r->send_http_header;

			print $content;
		};

		if($@)
		{
			return &handler_error($r, $@, $params);
		}
		else
		{
			$app = undef;

			return $Apache2::Const::OK;
		}
	}
	else
	{
		return &handler_error($r, 'No App Created');
	}
}

sub handler_error
{
	my ($r, $text, $params) = @_;

	Webkit::Error->wkerror($text, 1, $params);

	return $Apache2::Const::OK;
}

1;
