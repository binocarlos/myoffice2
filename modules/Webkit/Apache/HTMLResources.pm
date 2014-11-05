package Webkit::Apache::HTMLResources;

use strict;

#use Apache::Constants qw(OK NOT_FOUND);
#use Apache ();
#use Apache::Request ();

sub handler
{
	my $r = shift;

	unless (-f $r->finfo)
	{
		my $file = $r->filename;

		$r->log_error("$file does not exist");
		return $Apache2::Const::NOT_FOUND;
	}	

	eval
	{
		my $obj = Webkit::Apache::HTMLResources->new($r);

		$obj->html_page($r);
	};

	if($@)
	{
		$r->send_http_header('text/html');

		$r->print($@);
	}

	return $Apache2::Const::OK;
}

sub html_page
{
	my ($self, $r) = @_;

	my $org_id = $self->{org}->get_id;
	my $log = '';

	my $filecontent = Webkit::AppTools->read_file_contents($r->filename);

	my $request = Apache2::Request->new($r);

	my $params;

	foreach my $key ($request->param)
	{
		$params->{$key} = $request->param($key);
	}

	while($filecontent =~ /<htmlparam value ?= ?["']?(\w+)["']?\/?>/gsi)
	{
		my $copy = $filecontent;

		my $param = $params->{$1};

		$copy =~ s/<htmlparam value ?= ?["']?(\w+)["']?\/?>/$param/si;

		$filecontent = $copy;
	}

	while($filecontent =~ /<htmlresources([^>]+)>(.*?)<\/htmlresources>/gsi)
	{
		my $copy = $filecontent;

		my $args_string = $1;
		my $template = $2;

		my $andor = 'and';

		my $args;

		my $table_id = '';

		while($args_string =~ /(\w+) ?= ?["']([^'"]+)["']/gsi)
		{
			my $key = lc($1);
			my $value = lc($2);

			if($key eq 'id')
			{
				$table_id = $value;
			}
			else
			{
				$args->{$key} = $value;
			}
		}

		foreach my $param (keys %$params)
		{
			if($param=~/^__/)
			{
				next;
			}

			if($param=~/(\w+):(\w+)/)
			{
				my $found_id = lc($1);
				my $found_key = lc($2);

				if($found_id eq $table_id)
				{
					$args->{$found_key} = $params->{$param};
				}
			}
			else
			{
				my $key = lc($param);

				$args->{$key} = $params->{$param};
			}
		}

		if($args->{andor})
		{
			$andor = $args->{andor};

			delete($args->{andor});
		}

		my $binds = [$org_id];
		my $clause_parts;
		my $total_words = 0;

		my $resource_clauses;
		my $resource_binds = ['n'];

		foreach my $key (keys %$args)
		{
			push(@$clause_parts, "(word = ? and value = ?)");

			push(@$binds, $key);
			push(@$binds, $args->{$key});

			$total_words++;
		}

		if($clause_parts)
		{
			my $clausejoin = join("\n or \n", @$clause_parts);

			my $clause=<<"+++";
org_id = ?
and
(
	$clausejoin
)
+++

			my $count_refs = $self->{db}->get_select_refs({
				table => 'resourceshare.keyword',
				cols => 'count(*) as count, resource_id',
				clause => $clause,
				binds => $binds,
				group => 'resource_id' });

			my $words_required = 1;

			if($andor eq 'and')
			{
				$words_required = $total_words;
			}

			foreach my $ref (@$count_refs)
			{
				if($ref->{count}>=$words_required)
				{
					push(@$resource_clauses, " resource.id = ? ");
					push(@$resource_binds, $ref->{resource_id});
				}
			}
		}

		my $resources;

		if($resource_clauses)
		{
			my $resource_id_clause = join("\n or \n", @$resource_clauses);

			my $resource_clause=<<"+++";
resource.deleted = ?
and
(
	$resource_id_clause
)
+++

			$resources = Webkit::ResourceShare::Resource->load_objects($self->{db}, {
				table => 'resourceshare.resource',
				cols => 'resource.*',
				clause => $resource_clause,
				binds => $resource_binds,
				order => 'title' });

			my $resource_hash = Webkit::AppTools->get_id_hash($resources);

			my $keyword_clause=<<"+++";
keyword.resource_id = resource.id
and
$resource_clause
+++

			my $keywords = Webkit::ResourceShare::Keyword->load_objects($self->{db}, {
				table => 'resourceshare.resource, resourceshare.keyword',
				cols => 'keyword.*',
				clause => $keyword_clause,
				binds => $resource_binds });

			foreach my $keyword (@$keywords)
			{
				my $resource = $resource_hash->{$keyword->get_value('resource_id')};

				$resource->{_keywords}->{$keyword->word} = $keyword->value;
			}
		}

		my $text = '';

		foreach my $resource (@$resources)
		{
			$resource->bless_type;

			my $new_text = $template;

			while($new_text =~ /<htmlresources_if (\w+) ?= ?"?(\w+)"?>(.*?)<\/htmlresources_if>/gsi)
			{
				my $newcopy = $new_text;

				my $if_field = lc($1);
				my $if_value = lc($2);

				my $content = $3;

				if($resource->check_html_if($if_field, $if_value))
				{
					$newcopy =~ s/<htmlresources_if (\w+) ?= ?"?(\w+)"?>(.*?)<\/htmlresources_if>/$content/si;
				}
				else
				{
					$newcopy =~ s/<htmlresources_if (\w+) ?= ?"?(\w+)"?>(.*?)<\/htmlresources_if>//si;
				}

				$new_text = $newcopy;
			}

			my $title = $resource->get_value('title');
			my $url = $resource->get_html_url;
			my $type = $resource->get_mime_title;
			my $description = $resource->get_value('notes');
			my $size = $resource->get_value('size');
			my $author = $resource->get_value('author');
			my $created = $resource->get_created_title;
			my $modified = $resource->get_modified_title;

			$description =~ s/\n/<br>/g;

			$new_text =~ s/<htmlresource_title\/?>/$title/gsi;
			$new_text =~ s/<htmlresource_url\/?>/$url/gsi;
			$new_text =~ s/<htmlresource_type\/?>/$type/gsi;
			$new_text =~ s/<htmlresource_notes\/?>/$description/gsi;
			$new_text =~ s/<htmlresource_size\/?>/$size/gsi;
			$new_text =~ s/<htmlresource_author\/?>/$author/gsi;
			$new_text =~ s/<htmlresource_created\/?>/$created/gsi;
			$new_text =~ s/<htmlresource_modified\/?>/$modified/gsi;

			while($new_text =~ /<htmlresource_(\w+)\/?>/gsi)
			{
				my $tcopy = $new_text;

				my $value = $resource->{_keywords}->{$1};

				$tcopy =~ s/<htmlresource_(\w+)\/?>/$value/si;

				$new_text = $tcopy;
			}

			$text .= $new_text;
		}

		$copy =~ s/<htmlresources([^>]+)>(.*?)<\/htmlresources>/$text/si;

		$filecontent = $copy;
	}

#	$filecontent = $log.$filecontent;
#	$filecontent .= $self->{db}->get_log;

	$r->set_content_length(length($filecontent));
	$r->send_http_header('text/html');

	$r->print($filecontent);
}

sub download_resource
{
	my $r = shift;

	my $obj = Webkit::Apache::HTMLResources->new($r);

	my $resource_id = $obj->{params}->{resource_id};

	my $resource = Webkit::ResourceShare::Resource->load($obj->{db}, {
		id => $resource_id });

	$resource->bless_type;

	$r->filename($resource->get_full_file_path);
	$r->content_type($resource->get_mime_type);
#	$r->headers_out->set('Content-Disposition' => "attachment; filename=download");


	return $Apache2::Const::OK;
}

sub new
{
	my ($classname, $r) = @_;

	my $self = {};

	bless($self, $classname);

	my $params;

	my $request = Apache::Request->new($r);

	foreach my $key ($request->param)
	{
		$params->{$key} = $request->param($key);
	}

	my $db = Webkit::Application->get_static_db;

	$self->{params} = $params;
	$self->{db} = $db;
	$self->{org} = Webkit::Org->load($self->{db}, {
		id => $r->dir_config('RunOrgId') });

	return $self;
}

1;
