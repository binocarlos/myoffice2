package Webkit::Player::Moderation;

use strict;

@Webkit::Player::Moderation::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>	{	type => 'id',
									required => 1 },
									
			account_id => {			type => 'id',
									required => 1 },
									
			user_id => {			type => 'id',
									required => 1 },	
									
			ou_id => {			type => 'id' },								
									
			created =>	{	type => 'datetime',
							required => 1 },
			
			moderated_by =>	{	type => 'id' },

			moderated_date => 	{	type => 'datetime' },
			
			action_type => 	{	type => 'string',
								required => 1 },									
			
			action_data => {	type => 'string' }																															
};

sub table
{
        return 'player.moderation';
}

sub schema
{
        return $schema;
}

sub accept
{
	my ($self) = @_;

	if($self->is_add_word)
	{
		my $existing = Webkit::Player::OU->load($self->{db}, {
			clause => 'installation_id = ? and ou_type = ? and name = ?',
			binds => [$self->installation_id, 'word', $self->action_data] });
			
		if(!$existing)
		{
			my $parent_ou = Webkit::Player::OU->load($self->{db}, {
				clause => 'installation_id = ? and ou_type = ? and name = ?',
				binds => [$self->installation_id, 'folder', substr($self->action_data, 0, 1)] });
				
			my $new_word = Webkit::Player::OU->constructor($self->{db});
			$new_word->installation_id($self->installation_id);
			$new_word->account_id($self->account_id);
			$new_word->user_id($self->user_id);
			$new_word->ou_type('word');
			$new_word->name($self->action_data);
			
			if($parent_ou)
			{
				$new_word->ou_id($parent_ou->get_id);
			}
			
			$new_word->create;
		}
	}
	elsif($self->is_add_definition)
	{
		my ($id, $wordtext, $type, $text) = split(/:::/, $self->action_data);
		
		my $word = Webkit::Player::OU->load($self->{db}, {
			id => $id });
			
		my $definition = Webkit::Player::OU->constructor($self->{db});
	
		$definition->installation_id($self->installation_id);
		$definition->account_id($self->account_id);
		$definition->user_id($self->user_id);
		$definition->ou_id($word->get_id);
		$definition->ou_type('definition');
	
		$definition->name($word->name);
		$definition->comment($text);
	
		$definition->create;
	
		if($self->{params}->{type}=~/\w/)
		{
			$definition->create_keyword('word_type', $type, 'word_type');
		}
	
		$definition->copy_keywords_from_ou($word);	
	}
	elsif($self->is_phonic_sequence)
	{
		my $ou = Webkit::Player::OU->load($self->{db}, {
			id => $self->ou_id });
			
		$ou->create_keyword('phonic_sequence', $self->action_data, 'normal');
	}
}

sub get_date_formatted
{
	my ($self, $date_obj) = @_;
	
	#return Webkit::AppTools->get_date_formatted($date_obj);
	
	if(!$date_obj) { return ''; }
	
	return &Webkit::Date::get_string($date_obj);
}

sub get_created_summary
{
	my ($self) = @_;
	
	return $self->get_date_formatted($self->created);
}

sub is_add_word
{
	my ($self) = @_;
	
	if($self->action_type eq 'add_word')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub is_phonic_sequence
{
	my ($self) = @_;
	
	if($self->action_type eq 'phonic_sequence')
	{
		return 1;
	}
	else
	{
		return undef;
	}	
}

sub is_add_definition
{
	my ($self) = @_;
	
	if($self->action_type eq 'add_definition')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub get_summary
{
	my ($self) = @_;
	
	if($self->is_add_word)
	{
		return 'New Word: '.$self->action_data;
	}
	elsif($self->is_add_definition)
	{
		my ($id, $word, $type, $text) = split(/:::/, $self->action_data);
		
		if($type=~/\w/) { $type = ' ('.$type.')'; }
		
		return 'Definition for: '.$word.$type.' --- '.$text;
	}
	elsif($self->is_phonic_sequence)
	{
		my @parts = split(/:/, $self->action_data);
		
		my $part_st = join(', ', @parts);
		
		return 'Phonic sequence for: '.$self->{data}->{ou_name}.' ('.$part_st.')';
	}

	return '';	
}

1;
