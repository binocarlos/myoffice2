package Webkit::Player::Views;

use strict;

my $ignore_attributes = {
	id => 1,
	name => 1,
	filter_on => 1,
	noactivities => 1,
	filter_config => 1,
	can_subscribe => 1,
	auto_expand => 1,
	structure => 1
};

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# Constructor
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub new
{
	my ($classname, $db, $installation_id, $menu_to_use) = @_;
	
	if(!$db) { die "You cannot create a new Views.pm without a DB"; }

	if(!$installation_id) { die "You cannot create a new Views.pm without a installation_id"; }
	
	my $installation = Webkit::Player::Installation->load($db, {
		id => $installation_id });
		
	return Webkit::Player::Views->new_with_installation($installation, $menu_to_use);
}
	
sub new_with_installation
{
	my ($classname, $installation, $menu_to_use) = @_;

	if(!$installation) { die "You cannot create a new Views.pm without a installation"; }

	my $self = {};

	bless($self, $classname);

	$self->{db} = $installation->{db};

	$self->{installation} = $installation;

	$self->{xml} = $self->{installation}->views;
	
	$self->{document_root} = $ENV{DOCUMENT_ROOT};
	$self->{menu_to_use} = $menu_to_use;

	my $parser = XML::DOM::Parser->new;

	my $doc = $parser->parse($self->{xml});

	$self->{doc} = $doc;

	return $self;
}

sub parse_structure
{
	my ($self, $structure) = @_;
	
	if($structure !~ /\w/) { return; }
	
	my $full_structure_path = $self->{document_root}.$structure;
	
	if(!-e $full_structure_path) { return; }
	
	my $structure_xml = Webkit::AppTools->read_file_contents($full_structure_path);
	
	my $parser = XML::DOM::Parser->new;

	my $doc = $parser->parse($structure_xml);
	
	return $doc;
}

sub get_list_of_structure_files_used
{
	my ($self) = @_;
	
	my $ret = [];
	
	my $view_nodes = $self->get_array_of_all_view_nodes;
	
	foreach my $view_node (@$view_nodes)
	{
		if($view_node->getAttribute('structure') =~ /\w/)
		{
			push(@$ret, $view_node->getAttribute('structure'));
		}
	}
	
	return $ret;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# XML Processing
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub get_description_text
{
	my ($self, $view_node) = @_;

	my $child_nodes = $view_node->getChildNodes;

	for (my $i = 0; $i < @$child_nodes; $i++)
	{
		my $child_node = $child_nodes->[$i];
		
		if($child_node->getNodeType != 1) { next; }
		
		if($child_node->getNodeName=='description')
		{
			my $text_node = $child_node->getFirstChild;
			
			if($text_node->getNodeType==3)
			{
				return $text_node->getNodeValue;
			}
		}
	}	
}

sub get_array_of_all_view_nodes
{
	my ($self, $include_dividers) = @_;
	
	my $topNode = $self->{doc}->getDocumentElement;

	my $view_collection_nodes = $topNode->getChildNodes;
	my $view_nodes = [];
	my $view_nodes_array = [];
	
	for (my $i = 0; $i < @$view_collection_nodes; $i++)
	{
		my $collection_node = $view_collection_nodes->[$i];
		
		if($collection_node->getNodeType != 1) { next; }
		if($collection_node->getNodeName ne 'view_collection') { next; }
		
		$view_nodes = $collection_node->getChildNodes;
		
		push(@$view_nodes_array, $view_nodes);
	}
	
	my $arr = [];

	for (my $j = 0; $j < @$view_nodes_array; $j++)
	{
		my $current_view_nodes = $view_nodes_array->[$j];
		
		for (my $i = 0; $i < @$current_view_nodes; $i++)
		{
			my $view_node = $current_view_nodes->[$i];
		
			if($view_node->getNodeType != 1) { next; }

			if($view_node->getNodeName ne 'view')
			{
				if($view_node->getNodeName ne 'divider') { next; }
				if(!$include_dividers) { next; }
			}

			push(@$arr, $view_node);
		}
	}
	
	#@$arr = sort { $a->getAttribute('name') cmp $b->getAttribute('name') } @$arr;

	return $arr;	
	
}

sub get_array_of_view_nodes
{
	my ($self, $include_dividers) = @_;

	my $topNode = $self->{doc}->getDocumentElement;

	my $view_collection_nodes = $topNode->getChildNodes;
	my $view_nodes = [];
	
	my $collection_to_use = 'default';
	
	if($self->{menu_to_use} =~ /\w/)
	{
		$collection_to_use = $self->{menu_to_use};
	}
	
	for (my $i = 0; $i < @$view_collection_nodes; $i++)
	{
		my $collection_node = $view_collection_nodes->[$i];
		
		if($collection_node->getNodeType != 1) { next; }
		if($collection_node->getNodeName ne 'view_collection') { next; }
		if($collection_node->getAttribute('id') ne $collection_to_use) { next; }
		
		$view_nodes = $collection_node->getChildNodes;
	}
	
	my $arr = [];

	for (my $i = 0; $i < @$view_nodes; $i++)
	{
		my $view_node = $view_nodes->[$i];
		
		if($view_node->getNodeType != 1) { next; }

		if($view_node->getNodeName ne 'view')
		{
			if($view_node->getNodeName ne 'divider') { next; }
			if(!$include_dividers) { next; }
		}

		push(@$arr, $view_node);
	}
	
	#@$arr = sort { $a->getAttribute('name') cmp $b->getAttribute('name') } @$arr;

	return $arr;
}

sub get_array_of_view_info
{
	my ($self) = @_;
	
	my $nodes = $self->get_array_of_view_nodes;
	
	my $ret = [{
		id => 'all',
		name => 'All Activities' }];
	
	foreach my $node (@$nodes)
	{
		push(@$ret, {
			id => $node->getAttribute('id'),
			name => $node->getAttribute('name')
		});
	}
	
	return $ret;
}

sub get_collection_name
{
	my ($self, $collection_id) = @_;
	
	if($collection_id eq 'all') { return 'All Activities'; }
	
	my $node = $self->get_node_by_id($collection_id);
	
	if(!$node) { return ''; }
	
	return $node->getAttribute('name');
}

sub get_node_by_id
{
	my ($self, $node_id) = @_;

	$self->build_node_collection;

	return $self->{node_map}->{$node_id};
}

sub build_node_collection
{
	my ($self) = @_;

	my $view_nodes = $self->get_array_of_view_nodes;

	foreach my $view_node (@$view_nodes)
	{
		$self->add_view_node_to_collection($view_node);
	}
}

sub add_view_node_to_collection
{
	my ($self, $view_node) = @_;
	
	#if($view_node->getNodeName eq 'divider') { return; }
	if(($view_node->getNodeName ne 'view')&&($view_node->getNodeName ne 'group')) { return; }

	$self->{node_map}->{$view_node->getAttribute('id')} = $view_node;
	push(@{$self->{node_array}}, $view_node);

	my $node_children = $self->get_child_elements($view_node);

	foreach my $child (@$node_children)
	{
		$self->add_view_node_to_collection($child);
	}
}

sub get_child_elements
{
	my ($self, $node) = @_;

	my $children = $node->getChildNodes;

	my $arr = [];

	foreach my $child (@$children)
	{
		if($child->getNodeType == 1)
		{
			if(($child->getNodeName eq 'view')||($child->getNodeName eq 'group'))
			{
				push(@$arr, $child);
			}
		}
	}

	return $arr;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# DATABASE Selection
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub get_collection_keywords
{
	my ($self, $node_id) = @_;

	my $node = $self->get_node_by_id($node_id);
	
	if(!$node)
	{
		return {};
	}
	
	return $self->get_node_keyword_attributes($node);
}

sub get_node_keyword_attributes
{
	my ($self, $node) = @_;

	my $attributes = $node->getAttributes;

	my $search_keywords = {};

	my $st = '';

	foreach my $key (keys %$attributes)
	{
		if($key !~ /\w/) { next; }
		if($ignore_attributes->{$key}) { next; }

		$search_keywords->{$key} = $node->getAttribute($key);
	}

	return $search_keywords;
}

sub should_run_search
{
	my ($self, $props) = @_;
	
	my $count = 0;

	foreach my $key (keys %$props)
	{		
		if($key ne 'maxNumberActivities')
		{
			$count++;
		}
	}

	if($count>0)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub get_keyword_count
{
	my ($self, $keyword_hash) = @_;

	my $count = 0;

	foreach my $key (keys %$keyword_hash)
	{
		if($key ne 'namesearch')
		{
			$count++;
		}
	}

	return $count;
}

sub get_keyword_sql_attr
{
	my ($self, $keywords, $ou_types) = @_;

	my $keyword_queries = [];
	my $binds = [];
	
	my $name_value = undef;
	my $has_keyword = undef;

	foreach my $key (keys %$keywords)
	{		
		my $value = $keywords->{$key};
		
		if($key eq 'namesearch')
		{
			$name_value = $value;
			
			next;
		}
		
		$has_keyword = 1;

		if(($value eq '*')||($value eq '?'))
		{
			push(@$keyword_queries, "	( keyword.word = ? )");
			push(@$binds, $key);
		}
		elsif($value =~ /[\*\?]/)
		{
			push(@$keyword_queries, "	( keyword.word = ? and keyword.value like ? )");
			push(@$binds, $key);
			
			my $val = $value;
			
			$val =~ s/[\*\?]/\%/g;
			
			push(@$binds, $val);
		}
		else
		{
			push(@$keyword_queries, "	( keyword.word = ? and keyword.value = ? )");
			push(@$binds, $key);
			push(@$binds, $value);
		}
	}

	my $clause=<<"+++";
ou.installation_id = ?
+++

	my $table = 'player.ou';
	my $cols = 'ou.*';

	if($has_keyword)
	{
		$table .= ', player.keyword';
		$cols .= ', count(*) as count';
		
		$clause.=<<"+++";
and keyword.ou_id = ou.id		
+++
	}

	my $start_binds = [$self->{installation}->get_id];

	if(defined($name_value))
	{
		$clause.=<<"+++";
and ou.name REGEXP ?
+++

		my $sql_value = $name_value;
		my $star_replace = '([a-z]+)';
		
		$sql_value =~ s/ ?\* ?/$star_replace/g;
		
		while($sql_value =~ / ?\/([\w ]+)\/ ?/)
		{
			my $val = $1;
			$val =~ s/ //g;
			
			$sql_value =~ s/ ?\/([\w ]+)\/ ?/\[$val\]/;
		}
		
		$sql_value = '^'.$sql_value.'$';

		push(@$start_binds, $sql_value);
	}
	
	if($ou_types)
	{
		my $type_clauses = [];
		
		foreach my $type (@$ou_types)
		{
			push(@$type_clauses, "ou.ou_type = ?");
			push(@$start_binds, $type);
		}
		
		my $type_clause = join(" or ", @$type_clauses);
		
		$clause.=<<"+++";
and
(
	$type_clause
)
+++
	}
	
	foreach my $bind (@$binds)
	{
		push(@$start_binds, $bind);
	}
		
	$binds = $start_binds;
			
	my $keyword_count = @$keyword_queries;

	if($keyword_count>0)
	{
		my $keyword_sql = join("\n	or\n", @$keyword_queries);

		$clause.=<<"+++";
and
(
	$keyword_sql		
)
+++
	}

	my $attr = {
		table => $table,
		cols => $cols,
		clause => $clause,
		binds => $binds,
		group => 'ou.id',
		order => 'ou.name' };

	return $attr;
}

sub load_ous_from_keywords
{
	my ($self, $sql_attributes, $keyword_count) = @_;

	my $ous = Webkit::Player::OU->load_objects($self->{db}, $sql_attributes);

	my $hit_count = 0;

	foreach my $ou (@$ous)
	{
		if($ou->{data}->{count}>=$keyword_count)
		{
			$self->{ou_map}->{$ou->get_id} = $ou;
			push(@{$self->{ou_array}}, $ou);

			$hit_count++;
		}
	}

	return $hit_count;
}

sub load_definitions_for_ous
{
	my ($self, $ou_array) = @_;
	
	return;
	
	my $children = $self->load_children_for_ous($ou_array, {
		ou_type => 'definition' });
		
	foreach my $child_ou (@$children)
	{
		my $ou = $self->{ou_map}->{$child_ou->ou_id};

		if($ou)
		{
			$ou->add_definition($child_ou);
		}
	}	
}

sub load_thumbnails_and_sounds_for_ous
{
	my ($self, $ou_array) = @_;
	
	my $clause=<<"+++";
ou_type = ?
and
(
	item_type = ?
	or
	item_type = ?
)
+++

	my $binds = ['file', 'thumbnail', 'sound'];
	
	my $children = $self->load_children_for_ous_with_sql($ou_array, $clause, $binds);
		
	foreach my $child_ou (@$children)
	{
		my $ou = $self->{ou_map}->{$child_ou->ou_id};

		if($ou)
		{
			if($child_ou->is_sound)
			{
				$ou->{data}->{sound_url} = $child_ou->{data}->{item_path};
			}
			elsif($child_ou->is_thumbnail)
			{
				$ou->{data}->{thumbnail_url} = $child_ou->{data}->{item_path};
			}
		}
	}		
}

sub load_thumbnails_for_ous
{
	my ($self, $ou_array) = @_;
	
	my $children = $self->load_children_for_ous($ou_array, {
		ou_type => 'file',
		item_type => 'thumbnail' });
		
	foreach my $child_ou (@$children)
	{
		my $ou = $self->{ou_map}->{$child_ou->ou_id};

		if($ou)
		{
			$ou->{data}->{thumbnail_url} = $child_ou->{data}->{item_path};
		}
	}		
}

sub load_children_for_ous
{
	my ($self, $ou_array, $queries) = @_;
	
	if(!$ou_array)
	{
		$ou_array = $self->{ou_array} || [];
	}
	
	if(!$queries)
	{
		$queries = {};
	}

	my $ou_count = @{$ou_array};

	if($ou_count<=0) { return; }

	my $main_queries = [];
	my $binds = [];
	
	foreach my $key (keys %$queries)
	{
		push(@$main_queries, $key." = ?");
		push(@$binds, $queries->{$key});
	}
	
	my $main_clause = join(" and ", @$main_queries);
	
	return $self->load_children_for_ous_with_sql($ou_array, $main_clause, $binds);
}

sub load_children_for_ous_with_sql
{
	my ($self, $ou_array, $sql, $binds) = @_;
	
	if(!$ou_array)
	{
		return [];
	}
	
	my $count = @$ou_array;
	
	if($count<=0)
	{
		return [];
	}
	
	my $ou_queries = [];

	foreach my $ou (@$ou_array)
	{
		if(!$self->{ou_map}->{$ou->get_id})
		{
			$self->{ou_map}->{$ou->get_id} = $ou;
		}
		
		push(@$ou_queries, " ou_id = ? ");
		push(@$binds, $ou->get_id);
	}

	my $clause = join(" or ", @$ou_queries);

	my $main_clause=<<"+++";
$sql
+++

	if($clause=~/\w/)
	{
		$main_clause.=<<"+++";
and
(
	$clause
)
+++
	}

	my $child_ous = Webkit::Player::OU->load_objects($self->{db}, {
		table => 'player.ou',
		clause => $main_clause,
		binds => $binds,
		group => 'ou.id' });
		
	if(!$child_ous)
	{
		$child_ous = [];
	}
	
	return $child_ous;	
}

sub load_keywords_for_ous
{
	my ($self, $ou_array) = @_;
	
	if(!$ou_array)
	{
		$ou_array = $self->{ou_array} || [];
	}	

	my $ou_count = @{$ou_array};

	if($ou_count<=0) { return; }

	my $keyword_queries = [];
	my $binds = [];

	foreach my $ou (@$ou_array)
	{
		push(@$keyword_queries, " ou_id = ? ");
		push(@$binds, $ou->get_id);
	}

	my $clause = join(" or ", @$keyword_queries);

	my $keywords = Webkit::Player::Keyword->load_objects($self->{db}, {
		table => 'player.keyword',
		clause => $clause,
		binds => $binds,
		group => 'keyword.id' });

	foreach my $keyword (@$keywords)
	{
		my $ou = $self->{ou_map}->{$keyword->ou_id};

		if($ou)
		{
			$ou->add_keyword($keyword);
		}
	}
}

sub get_node_child_node
{
	my ($self, $parent_node) = @_;

	my $child_group_nodes = $self->get_child_elements($parent_node);

	my $group_node = $child_group_nodes->[0];

	return $group_node;
}

sub get_keyword_based_groups
{
	my ($self, $keyword) = @_;

	my $keyword_objects = Webkit::Player::Keyword->load_objects($self->{db}, {
		table => 'player.keyword',
		cols => 'keyword.*',
		clause => 'word = ?',
		binds => [$keyword],
		group => 'keyword.id' });

	if(!$keyword_objects) { return []; }

	foreach my $keyword_object (@$keyword_objects)
	{
		my $ou = $self->{ou_map}->{$keyword_object->ou_id};

		if($ou)
		{
			if($keyword_object->value =~ /\w/)
			{
				push(@{$ou->{keyword_map_for_groups}->{$keyword}}, $keyword_object->value);
			}
		}
	}

	my $unique_values = {};
	my $group_array = [];
	
	my $allowed_values = $self->get_allowed_group_values($keyword);

	foreach my $ou (@{$self->{ou_array}})
	{
		my $values = $ou->{keyword_map_for_groups}->{$keyword};

		if(!$values) { next; }

		foreach my $value (@$values)
		{
			if((!$allowed_values)||($allowed_values->{$value}))
			{
				if(!$unique_values->{$value})
				{				
					$unique_values->{$value} = 1;
					push(@$group_array, $value)
				}
			}
		}
	}

	@$group_array = sort @$group_array;

	return $group_array;
}

### This will parse the associated structure XML file in order to find out whether
### the values returned by get_node_groups are allowed
### this is to account for the fact that the keywords themselves have no structure
### but need to relate to each other in some way (i.e. Year1 -> Calculating)

sub get_allowed_group_values
{
	my ($self, $keyword) = @_;
	
	if($self->{structure} !~ /\w/) { return undef; }
	
	my $array_on_the_way_up = $self->{groups_on_the_way_up} || [];
	
	@$array_on_the_way_up = reverse(@$array_on_the_way_up);
	
	my $array_count = @$array_on_the_way_up;
	
	my $currentNode = $self->{structure_doc}->getDocumentElement;
	my $final_structure_node = undef;	
	
	#### this means that we are at the top and therefore any value counts
	if($array_count<=0)
	{
		my $ret = {};
		
		my $top_nodes = $currentNode->getChildNodes;
		
		for (my $i = 0; $i < @$top_nodes; $i++)
		{
			my $child_node = $top_nodes->[$i];
			
			if($child_node->getNodeType != 1) { next; }
			
			#die $child_node->getNodeName;

			$ret->{$child_node->getAttribute('value')} = 1;
		}
		
		return $ret;
	}

	for (my $i = 0; $i < @$array_on_the_way_up; $i++)
	{
		my $view_node = $array_on_the_way_up->[$i];
		my $node_keyword = $view_node->getAttribute('keyword');
		my $looking_for_value = $self->{params}->{$node_keyword};
		
		my $structure_nodes = $currentNode->getChildNodes;

		for (my $j = 0; $j < @$structure_nodes; $j++)
		{
			my $structure_node = $structure_nodes->[$j];
			
			if($structure_node->getNodeType != 1) { next; }

			if($structure_node->getNodeName ne $node_keyword) { next; }
			
			my $node_value = $structure_node->getAttribute('value');
			
			if($node_value eq $looking_for_value)
			{
				$currentNode = $structure_node;
				$final_structure_node = $structure_node;
				
				last;
			}
		}
	}
	
	### If we have not found a structure node then it means that
	### the given value does not exist and is therefore invalid
	### we should not return undef because that means anything goes
	if(!$final_structure_node)
	{
		return {};
	}
	
	my $allowed_values = {};
	my $activity_must_have_keywords = [];
	
	my $final_structure_children = $final_structure_node->getChildNodes;
	
	### this should have children otherwise the structure is not lining up with the
	### view therefore return no answers (remember not undef cos that means anything goes)
	if(!$final_structure_children)
	{
		return {};
	}
	
	my $child_count = @$final_structure_children;
	
	### same as above
	if($child_count<=0)
	{
		return {};
	}
	
	for (my $i = 0; $i < @$final_structure_children; $i++)
	{
		my $child_node = $final_structure_children->[$i];
		
		if($child_node->getNodeType != 1) { next; }
		
		if($child_node->getNodeName ne $keyword) { next; }
		
		$allowed_values->{$child_node->getAttribute('value')} = 1;
		
		push(@$activity_must_have_keywords, $child_node->getAttribute('value'));
	}
	
	$self->{activity_must_have_keyword_word} = $keyword;
	$self->{activity_must_have_keyword_values} = $activity_must_have_keywords;

	return $allowed_values;
}

#### this makes sure that an activity has the neccesary keywords to be part of the current node
sub does_activity_have_required_structure_keywords
{
	my ($self, $activity) = @_;
	
	if($self->{nokeywords} =~ /\w/)
	{
		my @cant_have_array = split(/:/, $self->{nokeywords});
		
		foreach my $cant_have (@cant_have_array)
		{
			if($activity->has_keyword($cant_have))
			{
				return;
			}
		}
	}
	
	if($self->{structure} !~ /\w/) { return 1; }
	
	if(!$self->{activity_must_have_keyword_values}) { return 1; }
	
	my $activity_values = $activity->get_keyword_value_array($self->{activity_must_have_keyword_word}) || [];
	my $check_values = $self->{activity_must_have_keyword_values} || [];
	my $check_value_hash = {};
	
	foreach my $check_value (@$check_values)
	{
		$check_value_hash->{$check_value} = 1;
	}
	
	foreach my $activity_value (@$activity_values)
	{	
		if($check_value_hash->{$activity_value})
		{
			return 1;
		}
	}
	
	return undef;
}

sub get_activity_results
{
	my ($self, $max_number) = @_;
	
	if(!defined($max_number))
	{
		$max_number = 1000;
	}
	
	if(!$self->{ou_array})
	{
		return [];
	}
	
	my $total_count = @{$self->{ou_array}};
	
	if($max_number>$total_count)
	{
		$max_number = $total_count;
	}
	
	my $ret = [];
	
	if($self->{noactivities} eq 'y') { return $ret; }
	
	for(my $i=0; $i<$max_number; $i++)
	{
		push(@$ret, $self->{ou_array}->[$i]);
	}
	
	return $ret;
}

##############################################################################
##############################################################################
##############################################################################
##############################################################################
##### This loads activities from a search string (based on the searchword table)
##############################################################################
##############################################################################
##############################################################################
##############################################################################

sub load_search_activities
{
	my ($self, $props, $ou_types) = @_;
	
	if(!$self->should_run_search($props))
	{
		return;
	}
	
	my $keyword_count = $self->get_keyword_count($props);

	my $sql_attributes = $self->get_keyword_sql_attr($props, $ou_types);

	$self->load_ous_from_keywords($sql_attributes, $keyword_count);
}
	
sub load_search_activities2
{
	my ($self, $props) = @_;

	my $search = $props->{name};
		
	$search =~ s/^\W+//;
	$search =~ s/\W+$//;
	
	my @parts = split(/\W+/, $search);
	
	my $keyword_queries = [];
	my $binds = [];
	
	foreach my $part (@parts)
	{
		$part = lc($part);
		
		if(Webkit::AppTools->is_stopword($part))
		{
			next;
		}
		
		push(@$keyword_queries, "	( searchword.word = ? ) ");
		push(@$binds, $part);
	}

	my $clause=<<"+++";
searchword.ou_id = ou.id
+++

	my $keyword_count = @$keyword_queries;

	if($keyword_count>0)
	{
		my $keyword_sql = join("\n	or\n", @$keyword_queries);

		$clause.=<<"+++";
and
(
	$keyword_sql		
)
+++
	}

	my $attr = {
		table => 'player.ou, player.searchword',
		cols => 'count(*) as count, ou.*',
		clause => $clause,
		binds => $binds,
		group => 'ou.id',
		order => 'count DESC, ou.name' };

	my $ous = Webkit::Player::OU->load_objects($self->{db}, $attr);
	
	if(!$ous) { $ous = []; }
	
	foreach my $ou (@$ous)
	{
		$self->{ou_map}->{$ou->get_id} = $ou;
		push(@{$self->{ou_array}}, $ou);
	}

	return $self->{ou_array};	
}

##############################################################################
##############################################################################
##############################################################################
##############################################################################
##### This loads activities found inside the cart id string of the account
##############################################################################
##############################################################################
##############################################################################
##############################################################################

sub load_cart_activities
{
	my ($self, $cart_ids) = @_;
	
	$self->load_id_string_activities($cart_ids);
}

sub load_playlist_activities
{
	my ($self, $playlist_ids) = @_;
	
	$self->load_id_string_activities($playlist_ids);
}

sub load_id_string_activities
{
	my ($self, $cart_ids) = @_;
	
	my @ids = split(/:/, $cart_ids);
	
	my $id_queries = [];
	my $binds = [];
	
	my $raw_words = [];
	
	foreach my $id (@ids)
	{
		if($id=~/^\d+$/)
		{
			push(@$id_queries, "	( id = ? ) ");
			push(@$binds, $id);
		}
		elsif($id=~/^newWord_(.*?)$/)
		{
			push(@$raw_words, $1);
		}
	}

	my $clause = "";

	my $id_count = @$id_queries;

	if($id_count>0)
	{
		$clause = join("\n	or\n", @$id_queries);
	}

	my $attr = {
		table => 'player.ou',
		cols => 'ou.*',
		clause => $clause,
		binds => $binds,
		group => 'ou.id' };

	my $ous = Webkit::Player::OU->load_objects($self->{db}, $attr);
	
	if(!$ous) { $ous = []; }
	
	foreach my $ou (@$ous)
	{
		$self->{ou_map}->{$ou->get_id} = $ou;
	}
	
	foreach my $id (@ids)
	{
		my $ou = $self->{ou_map}->{$id};
		
		if($ou)
		{
			push(@{$self->{ou_array}}, $ou);
		}
	}
	
	foreach my $raw_word (@$raw_words)
	{
		my $id = 'newWord_'.$raw_word;
		my $ou = Webkit::Player::OU->constructor($self->{db});
		$ou->{data}->{id} = $id;
		$ou->name($raw_word);
		
		$self->{ou_map}->{$id} = $ou;
		push(@{$self->{ou_array}}, $ou);
	}

	return $self->{ou_array};	
}

##############################################################################
##############################################################################
##############################################################################
##############################################################################
##### This gets the groups based of keyword selected and then the views xml grouping
##############################################################################
##############################################################################
##############################################################################
##############################################################################

sub get_node_groups
{
	my ($self, $config) = @_;

	my $view_id = $config->{view_id};
	my $params = $config->{params};
	my $json = $config->{json};
	
	$self->{params} = $params;
	
	### player mode is the flash front end asking for data therefore we ignore activities in the menu
	### and pass them back as seperate xml chunks so the player can use them for the right hand side activity grid
	my $player_mode = $config->{player_mode};

	#### The xml node id is the first part of the id string
	my @id_parts = split(/:/, $view_id);

	$view_id = $id_parts[0];

	#### lets get the XML node based on the id
	my $current_node = $self->get_node_by_id($view_id);
	
	if(!$current_node)
	{
		return [];
	}
	
	### should we not load any activities at all?
	$self->{noactivities} = $current_node->getAttribute('noactivities');
	$self->{nokeywords} = $current_node->getAttribute('nokeywords');
	
	my $group_node = $current_node;

	#### This is the first child of the selected node (i.e. the next group)
	my $children_array = $self->get_child_elements($current_node);
	my $child_node = $children_array->[0];

	my $children_count = 0;

	#### If there is no child node then we are at the end of the groping and
	#### will want to return activities (if they have been asked for)
	if($child_node)
	{
		my $children_array2 = $self->get_child_elements($child_node);
		$children_count = @$children_array2;
	}

	#### now we want to get each group node back to the top so we can 
	#### determine which params we need to grab
	my $groups_on_the_way_up = [];

	while($current_node->getNodeName ne 'view')
	{
		push(@$groups_on_the_way_up, $current_node);

		$current_node = $current_node->getParentNode;
	}
	
	$self->{groups_on_the_way_up} = $groups_on_the_way_up;

	############################################################
	############################################################
	############################################################
	#### now we have the view node (top level) we have the original selection criteria (e.g. origin = 'maths')
	my $view_node = $current_node;
	
	### this tells us if there are specific filters specified by the view
	$self->{filter_on} = $view_node->getAttribute('filter_on');
	$self->{filter_config} = $view_node->getAttribute('filter_config');
	
	### this tells us which XML file to use as the structure for the view
	$self->{structure} = $view_node->getAttribute('structure');
	
	$self->{structure_doc} = $self->parse_structure($self->{structure});

	#### the keyword clause is generated on the parameters inside the view node
	my $keyword_attributes = $self->get_node_keyword_attributes($current_node);

	#### now we go through each of the group nodes and add parameters to the clause
	foreach my $group (@$groups_on_the_way_up)
	{
		my $keyword_name = $group->getAttribute('keyword');
		my $keyword_value = $params->{$keyword_name};
		
		#### The wildcard only happens at the beggining
		#### once we are at group level the keyword values start kicking in
		if($keyword_value eq '*') { next; }

		if($keyword_value=~/\w/)
		{
			$keyword_attributes->{$keyword_name} = $keyword_value;
		}
	}

	#### the keyword count tells us how to check the answers for a full match
	my $keyword_count = $self->get_keyword_count($keyword_attributes);

	#### these 2 lines do the actual work of converting the attributes in sql and selecting ou records
	my $sql_attributes = $self->get_keyword_sql_attr($keyword_attributes, $config->{ou_types});

	$self->load_ous_from_keywords($sql_attributes, $keyword_count);

	############################################################################################
	############################################################################################
	############################################################################################
	############################################################################################
	#### this is checking whether there is a child XML node (i.e. are we at activity level or are
	#### there more group nodes below)
	my $grouping_node = $self->get_node_child_node($group_node);
	
	if(!$grouping_node)
	{	
		if($config->{return_activities})
		{
			$self->{has_activities} = 1;

			$self->load_keywords_for_ous;
			$self->load_thumbnails_for_ous;

			return $self->{ou_array};
		}
		else
		{
			if($config->{player_mode})
			{
				return [];
			}
			else
			{
				my $group_data = [];

				foreach my $ou (@{$self->{ou_array}})
				{
					#### finally lets return some data
					push(@$group_data, {
						id => 'viewtree'.$ou->get_id,
						ou_id => $ou->ou_id,
						db_id => $ou->get_id,
						ou_type => 'teaching_resource',
						text => $ou->name,
						node_type => 'teaching_resource',
						leaf => $json->true
					});
				}
			
				@$group_data = sort { $a->{text} cmp $b->{text} } @$group_data;

				return $group_data;
			}
		}
	}
	else
	{
		my $next_grouping_node = $self->get_node_child_node($grouping_node);

		#### This part is the making groups out of the activities that have been returned

		my $grouping_keyword = $grouping_node->getAttribute('keyword');
		my $grouping_id = $grouping_node->getAttribute('id');

		my $parent_grouping_node = $grouping_node->getParentNode;

		#### this goes through all of the activities and returns an array of groups based on the given keyword
		my $groups_loaded = $self->get_keyword_based_groups($grouping_keyword);

		my $group_count = 0;

		my $group_data = [];

		#### now we go through each of the groups and return properties based on them

		foreach my $group_loaded (@$groups_loaded)
		{
			$group_count++;

			#### the pass params tells each node what parameters they will have to ask for next time
			my $pass_params = {};

			foreach my $key (keys %$params)
			{
				$pass_params->{$key} = $params->{$key};
			}

			$pass_params->{$grouping_keyword} = $group_loaded;

			#### this is now set to always false because the activities are the leaf
			my $is_leaf = $json->false;

			#if($children_count>0)
			#{
			#	$is_leaf = $json->false;
			#}

			### this is the player_mode and we need to see if the next node is the last
			if($player_mode)
			{
				if(!$next_grouping_node)
				{
					$is_leaf = $json->true;
				}			
			}
			
			my $paramparts = [];
			
			foreach my $key (keys %$pass_params)
			{
				if($key !~ /_year/i) { next; }
				
				my $part = lc($key.$pass_params->{$key});
				
				$part =~ s/\W//g;
				
				push(@$paramparts, $part);
			}
			
			my $paramst = join('', @$paramparts);
			
			#### Lets make a unique id for this node
			my $id = $grouping_id.':'.$group_count.':'.$paramst;

			if($parent_grouping_node->getNodeName eq 'group')
			{
				my $parent_group_keyword = $parent_grouping_node->getAttribute('keyword');
				my $parent_group_value = $params->{$parent_group_keyword};

				$parent_group_value =~ s/\W//g;

				$id = $grouping_id.':'.$parent_group_value.':'.$group_count.':'.$paramst;
			}

			#### finally lets return some data
			push(@$group_data, {
				id => $id,
				text => $group_loaded,
				node_type => 'group',
				params => $pass_params,
				child_count => $children_count,
				leaf => $is_leaf
			});
		}
		
		@$group_data = sort { $a->{text} cmp $b->{text} } @$group_data;

		return $group_data;
	}
}

1;