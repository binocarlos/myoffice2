package Webkit::Apache::DownloadHandler;


# Needs to be installed as a PerlFixupHandler
# It will add the one Content-Disposition: header
# with a filename based on the requested file.

use strict;

#use Apache::Constants qw(OK NOT_FOUND SERVER_ERROR);
#use Apache ();
#use Apache::File (); 

sub handler
{
	my $r = shift;

	my $file = $r->filename;

	unless (-f $r->finfo)
	{
		$r->log_error("$file does not exist");
		return $Apache2::Const::NOT_FOUND;
	}

	my $download_filename;

	if($file=~/\/(\w+\.\w+)$/)
	{
		$download_filename = $1;
	}
	else
	{
		$download_filename = 'image';
	}

	$r->headers_out->set('Content-Disposition' => "attachment; filename=$download_filename");

	return $Apache2::Const::OK;
}

1;
