package Webkit::Apache::ImageTemplate;

use strict;

#use Apache::Constants qw(OK NOT_FOUND);
#use Apache ();

my $template = '/home/singalong/www/sweden/sp/tem.htm';

sub handler
{
	my $r = shift;

	my $uri = $r->uri;
	my $filename = $r->filename;

	my $mode = '';

	if($uri=~/\.(\w{3})$/)
	{
		my $ext = $1;

		if($ext eq 'img')
		{
			$uri =~ s/\.img$/\.jpg/i;
			$filename =~ s/\.img$/\.jpg/i;

			$r->uri($uri);
			$r->filename($filename);

			$mode = 'image';
		}
		else
		{
			$mode = 'page';
		}
	}
	else
	{
		return $Apache2::Const::NOT_FOUND;
	}

	unless (-f $r->finfo)
	{
		$r->log_error("$filename was not found to access StatsHandler");
		return $Apache2::Const::NOT_FOUND;
	}

	if($mode eq 'image')
	{
		my $fh = Apache::File->new($filename);

		$r->send_http_header;
		$r->send_fd($fh);

		return $Apache2::Const::OK;
	}
	else
	{
		my $template_text = &get_template_content($uri);

		$r->send_http_header('text/html');

		$r->print($template_text);

		return $Apache2::Const::OK;
	}
}

sub get_template_content
{
	my ($imageuri) = @_;

	open(TEMPLATE, $template);

	my $text = '';

	while(<TEMPLATE>)
	{
		$text.=$_;
	}

	close(TEMPLATE);

	$imageuri =~ s/\.jpg$/\.img/i;

	my $replace=<<"+++";
<img src="$imageuri">
+++

	$text =~ s/<apacheimage>/$replace/gi;

	return $text;
}

1;
