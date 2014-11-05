package Webkit::Apache::FlashComponent;

use strict;

#use Apache::Constants qw(OK NOT_FOUND);
#use Apache ();
#use Apache::Request ();

sub handler
{
	my $r = shift;

	eval
	{
		my $obj = Webkit::Apache::FlashComponent->new($r);

		my $result = $obj->get_result;
		my $mime = $obj->get_mime;

		$r->set_content_length(length($result));
		$r->send_http_header($mime);

		$r->print($result);
	};

	if($@)
	{
		$r->send_http_header('text/html');

		$r->print($@);
	}

	return $Apache2::Const::OK;
}

sub get_mime
{
	my ($self) = @_;

	my $mime = $self->{mime};

	if($mime!~/\w/)
	{
		$mime = 'text/plain';
	}

	return $mime;
}

sub get_result
{
	my ($self) = @_;

	if($self->{params}->{method} eq 'download_resource')
	{
		return $self->download_resource;
	}
	else
	{
		return $self->get_search_packet;
	}
}

sub download_resource
{
	my ($self) = @_;

	my $resource_id = $self->{params}->{resource_id};

	my $resource = Webkit::ResourceShare::Resource->load($self->{db}, {
		id => $resource_id });

	my $contents = $resource->get_download_contents;

	$self->{mime} = $resource->get_mime_type;

	return $contents;
}

sub get_search_packet
{
	my ($self) = @_;

# notes = include the notes with each resource
# keywords = include the keywords with each resource
# limit = limit to this number of results
# order = which field to order the results by
# desc = if ordering should be done descending
# andor = whether the search is done by and/or (and = default)

	$self->{mime} = 'text/xml';
	my $org_id = $self->{org}->get_id;

	my $reserved_words = {
		notes => 'key',
		keywords => 'key',
		limit => 'key',
		order => 'key',
		desc => 'key',
		andor => 'key' };

	my $search_props;
	my $search_clauses;
	my $search_binds;
	my $query_count;

	foreach my $key (keys %{$self->{params}})
	{
		if($reserved_words->{$key})
		{
			$search_props->{$key} = $self->{params}->{$key};
		}
		else
		{
			my $value = $self->{params}->{$key};

			$key =~ s/_+$//;

			my $clause=<<"+++";
(word = ? and value = ?)
+++

			push(@$search_binds, $key);
			push(@$search_binds, $value);
			push(@$search_clauses, $clause);

			$query_count++;
		}
	}

	if($query_count==0)
	{
		return '<resources/>';
	}

	if($search_props->{andor}!~/\w/)
	{
		$search_props->{andor} = 'and';
	}

	my $search_clause = join("\n or \n", @$search_clauses);

	$search_clause=<<"+++";
(
$search_clause
)
and org_id = ?
+++

	push(@$search_binds, $org_id);

	my $query_props = {
		table => 'resourceshare.keyword',
		cols => 'keyword.resource_id as resource_id',
		clause => $search_clause,
		binds => $search_binds,
		group => 'keyword.id' };

	my $resource_ids = $self->{db}->get_select_refs($query_props);

	my $result_counts;

	foreach my $resource_result (@$resource_ids)
	{
		$result_counts->{$resource_result->{resource_id}}++;
	}

	my $results_required = $query_count;

	if($search_props->{andor} eq 'or')
	{
		$results_required = 1;
	}

	my $resource_clauses;
	my $resource_binds;

	foreach my $resource_id (keys %$result_counts)
	{
		my $count = $result_counts->{$resource_id};

		if($count>=$results_required)
		{
			push(@$resource_clauses, " resource.id = ? ");
			push(@$resource_binds, $resource_id);
		}
	}

	if(!$resource_clauses)
	{
		return '<resources/>';
	}

	my $resource_clause = join("\n or \n", @$resource_clauses);

	$self->{org}->load_children('Webkit::ResourceShare::Resource', {
		table => 'resourceshare.resource',
		cols => 'resource.*',
		group => 'resource.id',
		clause => $resource_clause,
		binds => $resource_binds });

	if($search_props->{keywords})
	{
		$resource_clause=<<"+++";
keyword.resource_id = resource.id
and
(
$resource_clause
)
+++
		$self->{org}->add_children('Webkit::ResourceShare::Keyword', {
			table => 'resourceshare.keyword, resourceshare.resource',
			cols => 'keyword.*',
			group => 'keyword.id',
			clause => $resource_clause,
			binds => $resource_binds });

		foreach my $keyword (@{$self->{org}->ensure_child_array('keyword')})
		{
			my $resource = $self->{org}->get_child('resource', $keyword->get_value('resource_id'));

			$resource->add_child($keyword);
		}
	}
	

	my $packet.=<<"+++";
<resources>
+++

	foreach my $resource (@{$self->{org}->ensure_child_array('resource')})
	{
		my $id = $resource->get_id;
		my $title = $resource->get_value('title');
		my $type = $resource->get_value('type');
		my $size = $resource->get_value('size');
		my $mime = $resource->get_mime_type;
		my $details = $resource->get_value('details');
		my $resourcenotes = $resource->get_value('notes');

		$resourcenotes =~ s/^\s+//;

		$title=~s/"//g;

		$packet.=<<"+++";
<resource id="$id" title="$title" type="$type" size="$size" mime="$mime" details="$details">
+++

		if(($search_props->{notes})&&($resourcenotes=~/\w/))
		{
			$packet.=<<"+++";
  <notes>
$resourcenotes
  </notes>
+++

#<![CDATA[ ]]>
		}

		if($search_props->{keywords})
		{
			foreach my $keyword (@{$resource->ensure_child_array('keyword')})
			{
				my $word = $keyword->word;
				my $value = $keyword->value;

				$packet.=<<"+++";
  <keyword word="$word" value="$value"/>
+++
			}
		}

		$packet.=<<"+++";
</resource>
+++
	}

	$packet.=<<"+++";
</resources>
+++

	return $packet;
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
