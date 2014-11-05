package Webkit::Player::Installation;

use strict;

@Webkit::Player::Installation::ISA = qw(Webkit::DBObject);

my $schema = {
			name =>	{	type => 'string',
					required => 1 },

			views => {	type => 'string' },
			
			features => {	type => 'string' },
			
			default_account_settings => {	type => 'string' }
};

sub table
{
        return 'player.installation';
}

sub schema
{
        return $schema;
}

sub is_dictionary
{
	my ($self) = @_;
	
	if($self->name eq 'dictionary') { return 1; }
	else { return undef; }	
}

########################################################################################
########################################################################################
######################
# General Data Tools
######################
########################################################################################
########################################################################################

sub load_school_accounts
{
	my ($self) = @_;
	
	$self->load_children('Webkit::Player::Account', {
		clause => 'account_type = ?',
		binds => ['customer'],
		order => 'name' });
}

########################################################################################
########################################################################################
######################
# Becta Vocab Tree
######################
########################################################################################
########################################################################################

sub get_becta_vocab_tree_dump
{
	my ($self, $vocab_id) = @_;

	$self->load_becta_vocab_tree;

	my $json = new JSON ();

	$self->{json} = $json;

	my $node_arr = [];

	if($vocab_id==0)
	{
		$node_arr = $self->{vocab_tree_roots};
	}
	else
	{
		my $choosen_node = $self->get_child('becta_vocab', $vocab_id);
		$node_arr = $choosen_node->ensure_child_array('becta_vocab');
	}

	if(!$node_arr) { $node_arr = []; }

	@$node_arr = sort { $a->term_name cmp $b->term_name } @$node_arr;

	my $top_arr = [];

	foreach my $tree_root (@$node_arr)
	{
		my $obj_dump = $self->get_becta_vocab_obj_dump($tree_root);

		push(@$top_arr, $obj_dump);
	}

	return $top_arr;
}

sub get_becta_vocab_obj_dump
{
	my ($self, $obj) = @_;

	if(!$obj) { return undef; }

	my $children = $obj->ensure_child_array('becta_vocab');

	if(!$children) { $children = []; }

	my $child_count = @$children;

	my $is_leaf = $self->{json}->true;

	if($child_count>0)
	{
		$is_leaf = $self->{json}->false;
	}

	my $retobj = {
		id => $obj->get_id,
		term_id => $obj->term_id,
		text => $obj->term_name,
		term_type => $obj->term_type,
		leaf => $is_leaf };

	return $retobj;
}

sub load_becta_vocab_tree
{
	my ($self) = @_;

	if($self->{_becta_vocab_tree_loaded}) { return; }
	$self->{_becta_vocab_tree_loaded} = 1;

	$self->add_children('Webkit::Player::BectaVocab', {
		order => 'term_name' });

	$self->add_children('Webkit::Player::BectaVocabLink');

	foreach my $link (@{$self->ensure_child_array('becta_vocab_link')})
	{
		my $parent = $self->get_child('becta_vocab', $link->parent_id);
		my $child = $self->get_child('becta_vocab', $link->child_id);

		$parent->add_child($child);
		$child->{has_parent} = 1;
	}

	my $tree_roots;

	foreach my $vocab (@{$self->ensure_child_array('becta_vocab')})
	{
		if(!$vocab->{has_parent})
		{
			push(@$tree_roots, $vocab);
		}
	}

	$self->{vocab_tree_roots} = $tree_roots;
}

sub get_structured_vocab_tree_dump
{
	my ($self) = @_;
	
	my $json = new JSON ();

	$self->{json} = $json;		
	
	my $views = Webkit::Player::Views->new_with_installation($self);

	my $used_structures = $views->get_list_of_structure_files_used;
	
	my $tree = [];
	
	my $st = '';
	
	foreach my $structure_file (@$used_structures)
	{		
		my $doc = $views->parse_structure($structure_file);
		
		my $doc_node = $doc->getDocumentElement;
		
		my $structure_name = $doc_node->getAttribute('id');
		
		my $tree_desc = {
			tree_type => 'structure',
			keyword_type => $structure_name,
			text => $structure_name };
			
		push(@$tree, $tree_desc);
		
		my $child_nodes = $doc_node->getChildNodes;
		
		if(!$child_nodes) { next; }
		
		for (my $i = 0; $i < @$child_nodes; $i++)
		{
			my $child_node = $child_nodes->[$i];
			
			if($child_node->getNodeType != 1) { next; }
			
			$self->parse_tree_structure_node($tree_desc, $child_node);
		}
	}
   
	return $tree;	
}

sub parse_tree_structure_node
{
	my ($self, $parent_obj, $node) = @_;

	my $desc_obj = {
		tree_type => 'keyword',
		keyword_type => $parent_obj->{keyword_type},
		keyword => $node->getNodeName,
		text => $node->getAttribute('value') };
		
	my $child_nodes = $node->getChildNodes;

	my $actual_child_count = 0;
		
	for (my $i = 0; $i < @$child_nodes; $i++)
	{
		my $child_node = $child_nodes->[$i];
			
		if($child_node->getNodeType != 1) { next; }
			
		$actual_child_count++;
			
		$self->parse_tree_structure_node($desc_obj, $child_node);
	}
		
	if($actual_child_count<=0)
	{
		$desc_obj->{leaf} = $self->{json}->true;
	}
	
	push(@{$parent_obj->{children}}, $desc_obj);
}

sub has_feature
{
	my ($self, $feature) = @_;
	
	if(!$self->{feature_map})
	{
		$self->{feature_map} = {};
		
		my @features = split(/,/, $self->features);
		
		foreach my $feature (@features)
		{
			$self->{feature_map}->{$feature} = 1;
		}
	}
	
	return $self->{feature_map}->{$feature};
}

sub get_config_dump_path
{
	my ($classname) = @_;
	
	return '/home/webkit/sites/player/config_dump/';
}

sub get_default_account_settings_path
{
	my ($classname) = @_;
	
	my $path = Webkit::Player::Installation->get_config_dump_path;
	
	$path .= 'default_account_types.xml';
	
	return $path;
}

sub get_default_account_settings_file_contents
{
	my ($classname) = @_;
	
	my $contents = Webkit::AppTools->read_file_contents(Webkit::Player::Installation->get_default_account_settings_path);
	
	return $contents;
}

sub get_default_account_settings_map
{
	my ($classname, $xml_content) = @_;
	
	my $map = {};
	
	if($xml_content!~/\w/)
	{
		$xml_content = Webkit::Player::Installation->get_default_account_settings_file_contents;
		
		if($xml_content!~/\w/)
		{
			return $map;
		}
	}
	
	my $parser = new XML::DOM::Parser;

	my $doc = $parser->parse($xml_content);
	
	my $topNode = $doc->getDocumentElement;
	
	my $settings_nodes = $topNode->getChildNodes;

	for (my $i = 0; $i < @$settings_nodes; $i++)
	{
		my $settings_node = $settings_nodes->[$i];
		
		if($settings_node->getNodeType != 1) { next; }

		if($settings_node->getNodeName ne 'account') { next; }
		
		my $settings = {};
		
		my $account_type = $settings_node->getAttribute('type');
		
		$settings->{name} = $settings_node->getAttribute('display_name');
		
		if($settings_node->getAttribute('individual') eq 'y')
		{
			$settings->{individual} = 'y';
		}
		
		if($settings_node->getAttribute('can_link') eq 'y')
		{
			$settings->{can_link} = 'y';
		}
		
		if($settings_node->getAttribute('trial_enabled') eq 'y')
		{
			$settings->{trial_enabled} = 'y';
		}
		
		if($settings_node->getAttribute('has_pupils') eq 'y')
		{
			$settings->{has_pupils} = 'y';
		}
		
		if($settings_node->getAttribute('open_access') eq 'y')
		{
			$settings->{open_access} = 'y';
		}
		
		if($settings_node->getAttribute('disallow_free_subscription') eq 'y')
		{
			$settings->{disallow_free_subscription} = 'y';
		}
		
		if($settings_node->getAttribute('upseller') eq 'y')
		{
			$settings->{upseller} = 'y';
		}
		
		if($settings_node->getAttribute('disable_shop') eq 'y')
		{
			$settings->{disable_shop} = 'y';
		}		
		
		if($settings_node->getAttribute('free_allowed') =~ /\d/)
		{
			$settings->{free_allowed} = $settings_node->getAttribute('free_allowed');
		}
		
		$map->{$account_type} = $settings;			
	}
	
	return $map;
}

1;