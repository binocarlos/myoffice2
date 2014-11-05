package Webkit::Player::OU;

use strict qw(vars);

use vars qw(@ISA);

@Webkit::Player::OU::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>	{	type => 'id',
							required => 1 },

			account_id =>		{	type => 'id',
							required => 1 },
							
			user_id => {		type => 'id' },

			ou_id =>		{	type => 'id',
							required => 1 },

			ou_type =>		{	type => 'string',
							required => 1 },

			item_type =>		{	type => 'string' },

			item_path => 		{	type => 'string' },

			name =>			{	type => 'string',
							required => 1 },

			comment =>		{	type => 'string' },
			
			quick_comment =>	{	type => 'string' },
			
			teacher_quote =>	{	type => 'string' },
			
			pupil1_quote =>		{	type => 'string' },
			
			pupil2_quote =>		{	type => 'string' },
			
			tes_url =>		{	type => 'string' }
};

my $type_titles = {
	word => 'Word',
	definition => 'Definition',
	folder => 'Folder',
	teaching_resource => 'Teaching Resource',
	file => 'File' };

my $item_type_titles = {
	activity => 'Main Activity File',
	thumbnail => 'Main Thumbnail Image',
	screenshot => 'Screen Shot',
	help => 'Help Document' };

my $unique_file_types = {
	activity => 1,
	thumbnail => 1 };

sub table
{
        return 'player.ou';
}

sub schema
{
        return $schema;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
# overides

sub save_or_create
{
	my ($self, $fileref) = @_;

	$self->SUPER::save_or_create;

	if($self->is_file)
	{
		$self->output_file_contents($fileref);
	}
}

sub delete
{
	my ($self) = @_;

	if($self->is_activity)
	{
		foreach my $keyword (@{$self->ensure_child_array('keyword')})
		{
			$keyword->delete;
		}
	}

	if($self->is_file)
	{
		$self->remove_file;
	}

	$self->SUPER::delete;
}

sub get_definitions
{
	my ($self) = @_;
	
	my $ret = $self->{definition_array};
	
	if(!$ret) { $ret = []; }
	
	return $ret;
}

sub add_definition
{
	my ($self, $child) = @_;
	
	push(@{$self->{definition_array}}, $child);
	$self->{definition_map}->{$child->get_id} = $child;	
}

sub add_child
{
	my ($self, $child) = @_;

	if($child->table eq 'player.keyword')
	{
		$self->add_keyword($child);
	}

	$self->SUPER::add_child($child);
}

sub error
{
	my ($self) = @_;

	if((!$self->is_file)&&(!$self->is_definition))
	{
		my $clause=<<"+++";
ou_id = ?
and name = ?
+++

		my $binds = [$self->ou_id, $self->name];

		if($self->exists)
		{
			$clause.=<<"+++";
and id != ?
+++

			push(@$binds, $self->get_id);
		}

		my $existing_ou = Webkit::Player::OU->load($self->{db}, {
			clause => $clause,
			binds => $binds });

		if($existing_ou)
		{
			$self->{error_text} = 'There is already a '.$self->type_title.' with that name';
			return 1;
		}
	}

	if($self->is_unique_file_type)
	{
		my $file_type_clause=<<"+++";
ou_id = ?
and
item_type = ?
+++

		my $file_type_binds = [$self->ou_id, $self->item_type];

		if($self->exists)
		{
			$file_type_clause.=<<"+++";
and id != ?
+++

			push(@$file_type_binds, $self->get_id);
		}

		my $existing_unique_file_type_ou = Webkit::Player::OU->load($self->{db}, {
			clause => $file_type_clause,
			binds => $file_type_binds });

		if($existing_unique_file_type_ou)
		{
			$self->{error_text} = 'There is already a '.$self->item_type_title.' for this activity';
			return 1;
		}
	}

	return $self->SUPER::error;
}

sub comment
{
	my ($self, $new_value) = @_;

	if(defined($new_value))
	{
		$self->set_value('comment', $new_value);
	}

	my $ret = $self->get_value('comment');

	return Webkit::AppTools->remove_non_standard_characters($ret);
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
# CHILD OUS

sub load_ou_children
{
	my ($self) = @_;

	$self->load_children('Webkit::Player::OU');
}

sub load_thumbnail_path
{
	my ($self) = @_;

	my $thumbnail = $self->load_child_ou('file', 'thumbnail');
	
	if(!$thumbnail) { return; }
	
	return $thumbnail->item_path;	
}

sub load_child_ou
{
	my ($self, $ou_type, $item_type) = @_;
	
	my $clause=<<"+++";
ou_id = ?
and ou_type = ?
and item_type = ?
+++

	my $binds = [$self->get_id, $ou_type, $item_type];
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		clause => $clause,
		binds => $binds
	});
	
	return $ou;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
# files

sub get_file_local_path
{
	my ($self) = @_;

	if(!$self->has_file) { return; }

	return $self->get_player_folder.$self->item_path;
}

sub get_file_web_path
{
	my ($self) = @_;

	if(!$self->has_file) { return; }

	return '/files/'.$self->item_path;
}

sub has_file
{
	my ($self) = @_;

	if($self->item_path=~/\w/)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub process_existing_file_dir
{
	die $File::Find::name;
}

sub output_file_contents
{
	my ($self, $fileref) = @_;

	if(!$fileref) { return; }

	if(!$fileref->{size}>0) { return; }
	
	my $file_folder = $self->ensure_file_folder;
	
	my @sizes = (100, 350);
	
	foreach my $size (@sizes)
	{
		my $filename = $self->get_player_folder.$file_folder.'/'.$self->get_id.'.'.$size.'.'.lc($fileref->{ext});
		
		if(-e $filename)
		{
			unlink($filename);
		}
	}

	my @parts = split(/[\\\/]/, $fileref->{filename});

	$self->name(pop(@parts));
	$self->item_path($file_folder.'/'.$self->get_id.'.'.lc($fileref->{ext}));

	my $full_item_path = $self->get_file_local_path;

	open(FILEHANDLE, ">$full_item_path");
	binmode(FILEHANDLE);
	print FILEHANDLE $fileref->{content};
	close(FILEHANDLE);

	$self->save;
}

sub get_player_folder
{
	my ($classname) = @_;

	return Webkit::Constants->get_constant('player_file_dir');
}

sub ensure_file_folder
{
	my ($self) = @_;

	my $folder = $self->get_player_folder;

	my $now_date = Webkit::Date->now;

	my $account_number = $self->account_id;
	my $owner_id = $self->ou_id;

	my $ret_folder_path = $account_number.'/'.$owner_id;

	my $make_folder_path = $folder.$ret_folder_path;

	Webkit::AppTools->ensure_folder_exists($make_folder_path);

	return $ret_folder_path;
}

sub remove_file
{
	my ($self) = @_;

	if(!$self->has_file) { return; }
	
	### we don't want to remove statically uploaded files!
	if($self->item_path =~ /^literacyGames/) { return; }
	if($self->item_path =~ /^phonicsThumbnails/) { return; }

	unlink($self->get_file_local_path);
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
# keywords

sub delete_keywords
{
	my ($self) = @_;

	$self->delete_children('Webkit::Player::Keyword');
}

sub delete_searchwords
{
	my ($self) = @_;

	$self->delete_children('Webkit::Player::SearchWord');
}

sub save_keywords
{
	my ($self, $params) = @_;

	foreach my $word (keys %$params)
	{
		if($word!~/^keyword_/) { next; }

		my $value = $params->{$word};
		
		$word =~ s/^keyword_//;

		$word =~ s/^(.*?)__\d+__//;

		my $type = $1;

		$self->create_keyword($word, $value, $type);
	}
}

sub copy_keywords_from_ou
{
	my ($self, $other_ou) = @_;
	
	$other_ou->load_keywords;
	
	foreach my $keyword (@{$other_ou->ensure_child_array('keyword')})
	{
		if(!$self->has_keyword_value($keyword->word, $keyword->value, $keyword->keyword_type))
		{
			$self->create_keyword($keyword->word, $keyword->value, $keyword->keyword_type);
		}
	}
}

sub load_keywords
{
	my ($self) = @_;
	
	if($self->{_keywords_loaded}) { return; }
	
	$self->{_keywords_loaded} = 1;

	$self->load_children('Webkit::Player::Keyword');
	
	foreach my $keyword (@{$self->ensure_child_array('keyword')})
	{
		$self->add_keyword($keyword);
	}
}

sub create_keyword
{
	my ($self, $word, $value, $type) = @_;

	if(!defined($value))
	{
		return;
	}

	if($type!~/\w/) { $type = 'normal'; }

	if(ref($value) eq "ARRAY")
	{
		foreach my $val (@$value)
		{
			$self->create_keyword($word, $val, $type);
		}

		return;
	}
	elsif(ref($value) eq "HASH")
	{
		foreach my $key (keys %$value)
		{
			### $word is the type here because tyhe types are the top level group
			$self->create_keyword($key, $value->{$key}, $word);
		}

		return;
	}

	if($value!~/\w/)
	{
		return;
	}

	my $keyword = Webkit::Player::Keyword->constructor($self->{db});

	$keyword->installation_id($self->installation_id);
	$keyword->account_id($self->account_id);
	$keyword->ou_id($self->get_id);
	$keyword->keyword_type($type);
	$keyword->word($word);
	$keyword->value($value);

	$keyword->create;

	$self->add_child($keyword);
}

sub add_keyword
{
	my ($self, $keyword) = @_;

	my $word = 'none';

	if($keyword->word=~/\w/)
	{
		$word = $keyword->word;
	}

	push(@{$self->{keywords}->{$word}}, $keyword);
}

sub get_keywords
{
	my ($self, $word) = @_;

	my $keywords = $self->{keywords}->{$word};

	return $keywords;
}

#### WARNING - this only returns the first instance and so is not suitable for checking
#### the presence of a keyword value

sub get_keyword
{
	my ($self, $word) = @_;

	my $arr = $self->get_keywords($word);

	if($arr)
	{
		return $arr->[0];
	}
	else
	{
		return undef;
	}
}

sub has_keyword
{
	my ($self, $word) = @_;

	return $self->has_keyword_value($word, '*');	
}

sub has_keyword_value
{
	my ($self, $word, $value, $type) = @_;
	
	my $arr = $self->get_keywords($word);
	
	if(!$arr) { return undef; }
	
	if($value eq '*')
	{
		return 1;
	}
	
	foreach my $check_value (@$arr)
	{
		if($check_value->value eq $value)
		{
			if($type=~/\w/)
			{
				if($check_value->keyword_type eq $type)
				{
					return 1;
				}
			}
			else
			{
				return 1;
			}
		}
	}
	
	return undef;
}

sub get_keyword_value
{
	my ($self, $word) = @_;

	my $keyword = $self->get_keyword($word);

	if($keyword)
	{
		return $keyword->value;
	}
	
	return undef;
}

sub get_keyword_value_array
{
	my ($self, $word) = @_;
	
	my $ret = [];
	
	my $arr = $self->get_keywords($word);
	
	if(!$arr) { return $ret; }
	
	foreach my $keyword (@$arr)
	{
		push(@$ret, $keyword->value);
	}
	
	return $ret;
}

sub get_keyword_hash
{
	my ($self) = @_;

	my $hash = {};

	foreach my $word (keys %{$self->{keywords}})
	{
		my $arr = $self->{keywords}->{$word};

		my $len = @$arr;
		my $first = $arr->[0];

		if($len==1)
		{
			$hash->{$first->keyword_type}->{$word} = $arr->[0]->value;
		}
		else
		{
			my $valarr = [];

			foreach my $keyword_obj (@$arr)
			{
				push(@$valarr, $keyword_obj->value);
			}

			$hash->{$first->keyword_type}->{$word} = $valarr;
		}
	}

	return $hash;
}

sub save_searchwords
{
	my ($self, $searchwords_string) = @_;

	$self->create_searchwords_from_title;
	$self->create_searchwords_from_keywords;

	my @parts = split(/,/, $searchwords_string);

	foreach my $part (@parts)
	{
		$part =~ s/^\W+//;
		$part =~ s/\W+$//;

		my $searchword = Webkit::Player::SearchWord->constructor($self->{db});
		
		$searchword->ou_id($self->get_id);
		$searchword->installation_id($self->installation_id);
		$searchword->word_type('searchword');
		$searchword->word($part);

		$searchword->create;
	}
}

sub create_all_searchwords
{
	my ($self) = @_;

	$self->create_searchwords_from_title;
	$self->create_searchwords_from_keywords;
}

sub create_searchwords_from_title
{
	my ($self) = @_;

	my @parts = split(/\W+/, $self->name);

	foreach my $part (@parts)
	{
		$part =~ s/\W//g;

		if($part !~ /\w/) { next; }

		my $searchword = Webkit::Player::SearchWord->constructor($self->{db});
		
		$searchword->ou_id($self->get_id);
		$searchword->installation_id($self->installation_id);
		$searchword->word_type('title');
		$searchword->word($part);

		$searchword->create;		
	}
}

sub create_searchwords_from_keywords
{
	my ($self) = @_;

	$self->load_keywords;

	foreach my $keyword (@{$self->ensure_child_array('keyword')})
	{
		my $searchword = Webkit::Player::SearchWord->constructor($self->{db});
		
		$searchword->ou_id($self->get_id);
		$searchword->installation_id($self->installation_id);
		$searchword->word_type('keyword');
		$searchword->word($keyword->value);

		$searchword->create;
	}	
}

sub load_searchwords_string
{
	my ($self) = @_;

	$self->load_children('Webkit::Player::SearchWord', {
		clause => 'word_type = ?',
		binds => ['searchword'] });

	return $self->get_searchwords_string;
}

sub get_searchwords_string
{
	my ($self) = @_;

	my $parts = [];

	foreach my $searchword (@{$self->ensure_child_array('searchword')})
	{
		push(@$parts, $searchword->word);
	}

	my $string = join(', ', @$parts);

	return $string;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
# help text

sub load_help_text_ou
{
	my ($self) = @_;
}

sub get_help_text
{
	my ($self) = @_;

}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
# property questions

sub type_title
{
	my ($self) = @_;

	return $type_titles->{$self->ou_type};
}

sub item_type_title
{
	my ($self) = @_;

	return $item_type_titles->{$self->item_type};
}

sub is_unique_file_type
{
	my ($self) = @_;

	if(!$self->is_file) { return undef; }

	return $unique_file_types->{$self->item_type};	
}

sub is_folder
{
	my ($self) = @_;

	if($self->ou_type eq 'folder') { return 1; }

	return undef;
}

sub is_activity
{
	my ($self) = @_;

	if($self->ou_type eq 'teaching_resource') { return 1; }

	return undef;
}

sub is_word
{
	my ($self) = @_;

	if($self->ou_type eq 'word') { return 1; }

	return undef;
}

sub is_playlist
{
	my ($self) = @_;

	if($self->ou_type eq 'playlist') { return 1; }

	return undef;
}

sub is_definition
{
	my ($self) = @_;

	if($self->ou_type eq 'definition') { return 1; }

	return undef;
}

sub is_file
{
	my ($self) = @_;

	if($self->ou_type eq 'file') { return 1; }

	return undef;
}

sub is_sound
{
	my ($self) = @_;

	if($self->item_type eq 'sound') { return 1; }

	return undef;
}

sub is_thumbnail
{
	my ($self) = @_;

	if($self->item_type eq 'thumbnail') { return 1; }

	return undef;
}

sub is_activity_file
{
	my ($self) = @_;

	if($self->item_type eq 'activity') { return 1; }

	return undef;
}

sub is_help
{
	my ($self) = @_;

	if($self->item_type eq 'help') { return 1; }

	return undef;
}

sub is_text_help
{
	my ($self) = @_;

	if(!$self->is_help) { return undef; }

	if($self->get_ext eq 'txt') { return 1; }

	return undef;
}

sub get_ext
{
	my ($self) = @_;

	if(!$self->is_file) { return undef; }

	my @parts = spllit(/\./, $self->item_path);

	my $ext = lc(pop(@parts));

	return $ext;
}

sub has_help
{
	my ($self) = @_;
	
	if($self->comment =~ /\w/)
	{
		return 1;
	}
	
	return undef;
}

sub ensure_quick_comment
{
	my ($self) = @_;
	
	if($self->quick_comment =~ /\w/)
	{ 
		my $ret = $self->quick_comment;
		
		if($ret =~ /\w$/)
		{
			$ret .= '.';	
		}
	
		return $ret;
	}
	
	if($self->comment !~ /\w/) { return ''; }
	
	my @parts = split(/[\!\.\?\(\:]/, $self->comment);
	
	my $quick_comment = $parts[0];
	
	$quick_comment =~ s/<\/?\w+>//g;
	
	if($quick_comment =~ /\w$/)
	{
		$quick_comment .= '.';	
	}
	
	my $ret = "$quick_comment";
	
	return $ret;
}

1;
