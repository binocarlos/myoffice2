package Webkit::Error;

use strict;

sub get_caller_info
{
	my ($classname, $delim) = @_;

	if(!$delim) { $delim = '<hr>'; }

	my $parts;

	my $depth = 1;

	while(my @props = caller($depth))
	{
		my ($package, $filename, $line, $subr) = @props;

		my $part=<<"+++";
$subr ($line)
+++

		push(@$parts, $part);

		$depth++;
	}

	my $ret = join($delim, @$parts);

	return $ret;
}

sub wkerror
{
	my ($classname, $text, $noexit, $params, $noheader) = @_;

	my $log = '';
	my $paramsst = '';
	my $depth = 1;

	while(my @props = caller($depth))
	{
		my ($package, $filename, $line, $subr) = @props;

		$log.=<<"+++";
$subr ($line)<hr>
+++

		$depth++;
	}

	foreach my $key (keys %$params)
	{
		$paramsst.=<<"+++";
$key - $params->{$key}<p>
+++
	}

	if(!$noheader)
	{
		Webkit::AppTools->print_header;
	}

	print<<"+++";
<html>
<head>
<title>Webkit Error</title>
<body bgcolor=#ffffff>
<table width=100% height=100% border=0>
<tr>
<td align=center valign=middle>
<font face="Verdana" size=3 color=#880000>
Webkit Error
</font>
<p>
<font face="Verdana" size=2 color=#000000>
$log<hr>
<b style="color:#880000;">$text</b><hr>
$paramsst<hr>
</font>
</td>
</tr>
</table>
<script>
if(document.all('loading_table'))
{
	hide_loading_table();
}
</script>
</body>
</html>
+++

    	die $text;
}

1;
