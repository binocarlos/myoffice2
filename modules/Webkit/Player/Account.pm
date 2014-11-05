package Webkit::Player::Account;

use strict;

@Webkit::Player::Account::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>	{	type => 'id',
									required => 1 },

			account_type =>		{	type => 'string',
									required => 1 },

			name =>			{	type => 'string',
								required => 1 },
								
			registered => {		type => 'datetime',
								required => 1 },
							
			org => 			{ 	type => 'string' },
			
			address => 		{	type => 'string' },
							
			city =>			{	type => 'string' },
			
			country => 		{	type => 'string' },
			
			postcode =>		{	type => 'string' },

			url =>			{	type => 'string',
								required => 1 },
							
			account_notes => {	type => 'string' },
			
			small_school => {	type => 'string' },
			
			account_flag => {	type => 'string' },
			
			account_settings=> {	type => 'string' },
			
			cart_ids => {		type => 'string' }
};

my $type_map = {
	lea => {
		name => 'org',
		free_allowed => 70,
		disallow_free_subscription => 1
	},
	lea_live => {
		name => 'org',
		upseller => 1
	},
	portal => {
		name => 'account',
		free_allowed => 70,
		disallow_free_subscription => 1 },
	portal_live => {
		name => 'account',
		upseller => 1 },
	gfl_advisor => {
		individual => 1,
		name => 'fullname',
		open_access => 1
	},
	champion => {
		individual => 1,
		name => 'fullname',
		open_access => 1
	},
	la_advisor => {
		individual => 1,
		name => 'fullname',
		open_access => 1
	},
	la_adviser => {
		individual => 1,
		name => 'fullname',
		open_access => 1		
	},
	non_uk_adviser => {
		individual => 1,
		name => 'fullname',
		open_access => 1
	},
	lecturer => {
		individual => 1,
		name => 'fullname',
		open_access => 1
	},
	trainer => {
		individual => 1,
		name => 'fullname',
		open_access => 1
	},
	home_user => {
		individual => 1,
		name => 'fullname',
		free_allowed => 30
	},
	student => {
		individual => 1,
		name => 'initial',
		open_access => 1
	},	
	home_educator => {
		individual => 1,
		name => 'fullname',
		free_allowed => 30
	},
	distributor => {
		name => 'org',
		open_access => 1
	},
	publisher => {
		name => 'org',
		open_access => 1
	},
	supply_teacher => {
		individual => 1,
		has_pupils => 1,
		name => 'initial',
		open_access => 1
	},	
	peripatetic_teacher => {
		individual => 1,
		name => 'initial',
		open_access => 1
	},
	other => {
		name => 'fullname',
		free_allowed => 30
	},
	teacher => {
		individual => 1,
		name => 'initial',
		free_allowed => 30
	},
	onlineclub_subscriber => {
		name => 'account',
		open_access => 1
	},
	tefl_teacher => {
		individual => 1,
		has_pupils => 1,
		name => 'initial',
		free_allowed => 30
	},
	school => {
		name => 'account',
		has_pupils => 1,
		free_allowed => 30
	}
};

sub table
{
        return 'player.account';
}

sub schema
{
        return $schema;
}

sub has_got_subscription
{
	my ($self) = @_;
	
	return undef;
}

sub get_array_of_account_types
{
	my ($classname) = @_;

	my $arr = [];
	
	foreach my $type (keys %$type_map)
	{
		push(@$arr, $type);
	}
	
	return $arr;
}

sub is_upseller
{
	my ($self) = @_;
	
	my $ret = $self->get_account_setting('upseller');
	
	if($ret eq 'y') { return 1; }
	else { return undef; }	
}

sub is_shop_disabled
{
	my ($self) = @_;

	if($self->is_open_access)
	{
		return 1;
	}
	
	my $ret = $self->get_account_setting('disable_shop');
	
	if($ret eq 'y') { return 1; }
	else { return undef; }	
}

sub is_open_access
{
	my ($self) = @_;

	if($self->get_account_flag('openAccess')) { return 1; }
	
	my $ret = $self->get_account_setting('open_access');
	
	if($ret eq 'y') { return 1; }
	else { return undef; }	
}

sub has_pupils
{
	my ($self) = @_;
	
	my $ret = $self->get_account_setting('has_pupils');
	
	if($ret eq 'y') { return 1; }
	else { return undef; }
}

sub can_link
{
	my ($self) = @_;
	
	my $ret = $self->get_account_setting('can_link');
	
	if($ret eq 'y') { return 1; }
	else { return undef; }
}

sub get_account_name
{
	my ($self) = @_;
	
	my $display_name_type = $self->get_account_setting('name');
	
	if($display_name_type eq 'account')
	{
		return $self->name;
	}
	elsif($display_name_type eq 'org')
	{
		return $self->org;
	}
	else
	{
		$self->load_users;
		
		my $user_array = $self->ensure_child_array('user');
		
		my $first_user = $user_array->[0];
		
		if(!$first_user) { return $self->name; }
		
		if($display_name_type eq 'initial')
		{
			return $first_user->get_initial_name;
		}
		else
		{
			return $first_user->get_name;
		}
	}
}

sub load_users
{
	my ($self) = @_;

	if($self->{_users_loaded}) { return; }
	$self->{_users_loaded} = 1;
	
	$self->load_children('Webkit::Player::User');	
}

sub load_teachers_with_playlist
{
	my ($self) = @_;
	
	if($self->{_teachers_with_playlists_loaded}) { return; }
	$self->{_teachers_with_playlists_loaded} = 1;
	
	$self->add_children('Webkit::Player::User', {
		table => 'player.user, player.ou',
		cols => 'user.*',
		clause => 'user.account_id = ? and ou.user_id = user.id and ou.ou_type = ?',
		binds => [$self->get_id, 'playlist'],
		group => 'user.id',
		order => 'user.firstname, user.surname' });
}

sub load_purchase_records
{
	my ($self) = @_;
	
	if($self->{_purchase_records_loaded}) { return; }
	$self->{_purchase_records_loaded} = 1;
	
	$self->load_children('Webkit::Player::PurchaseRecord');
}

sub load_purchase_record_summary
{
	my ($self, $views) = @_;

	$self->load_viewer_purchase_records(1);
	
	foreach my $purchase_record (@{$self->ensure_child_array('purchase_record')})
	{
		if($purchase_record->is_subscription)
		{
			my $collection_name = $views->get_collection_name($purchase_record->collection_id);
			
			$purchase_record->{data}->{product_name} = $collection_name;
		}
	}
}

sub load_invoices_summary
{
	my ($self, $views) = @_;

	$self->load_viewer_purchase_records(1);
	
	$self->load_children('Webkit::Player::Invoice', {
		order => 'date_sent' });
	
	foreach my $purchase_record (@{$self->ensure_child_array('purchase_record')})
	{
		if($purchase_record->is_subscription)
		{
			my $collection_name = $views->get_collection_name($purchase_record->collection_id);
			
			$purchase_record->{data}->{product_name} = $collection_name;
		}
		
		if($purchase_record->invoice_id>0)
		{
			my $invoice = $self->get_child('invoice', $purchase_record->invoice_id);
			
			if($invoice)
			{
				$invoice->{_purchase_records_loaded} = 1;
				$invoice->add_child($purchase_record);
			}
		}
	}
}

sub load_playlists
{
	my ($self, $user_id, $yeargroup) = @_;
	
	if($self->{_playlists_loaded}) { return; }
	$self->{_playlists_loaded} = 1;
	
	my $clause=<<"+++";
ou.account_id = ? and ou_type = ? and ou.user_id = user.id
+++

	my $binds = [$self->get_id, 'playlist'];
	
	if($user_id>0)
	{
		$clause.=<<"+++";
and user.id = ?		
+++

		push(@$binds, $user_id);
	}
	
	if($yeargroup=~/\w/)
	{		
		$clause.=<<"+++";
and user.yeargroup = ?
+++
		
		push(@$binds, $yeargroup);
	}
	
	$self->add_children('Webkit::Player::OU', {
		table => 'player.ou, player.user',
		cols => 'ou.*',
		clause => $clause,
		binds => $binds,
		group => 'ou.id',
		order => 'ou.name' });
		
	my $keyword_clause=<<"+++";
$clause
and keyword.ou_id = ou.id
+++
		
	$self->add_children('Webkit::Player::Keyword', {
		table => 'player.keyword, player.ou, player.user',
		cols => 'keyword.*',
		clause => $keyword_clause,
		binds => $binds,
		group => 'keyword.id',
		order => 'ou.name' });
		
	foreach my $keyword (@{$self->ensure_child_array('keyword')})
	{
		my $ou = $self->get_child('ou', $keyword->ou_id);
		
		if($ou)
		{
			$ou->add_keyword($keyword);
		}
	}	
}

sub load_viewer_purchase_records
{
	my ($self, $with_activity_names) = @_;
	
	if($self->{_purchase_records_loaded}) { return; }
	$self->{_purchase_records_loaded} = 1;
	
	$self->load_upsell_links;
	
	my $id_clauses = ["purchase_record.account_id = ?"];
	my $binds = [$self->get_id];
	
	foreach my $account_link (@{$self->ensure_child_array('account_link')})
	{
		push(@$id_clauses, "purchase_record.account_id = ?");
		push(@$binds, $account_link->parent_id);
	}

	my $id_clause = join(' or ', @$id_clauses);
	
	if($with_activity_names)
	{
		$self->add_children('Webkit::Player::PurchaseRecord', {
			cols => 'purchase_record.*, ou.name as product_name',
			table => 'player.purchase_record LEFT JOIN player.ou ON purchase_record.ou_id = ou.id',
			clause => $id_clause,
			order => 'purchase_record.purchase_date DESC',
			binds => $binds });
	}
	else
	{
		$self->add_children('Webkit::Player::PurchaseRecord', {
			table => 'player.purchase_record',
			clause => $id_clause,
			order => 'purchase_record.purchase_date DESC',
			binds => $binds });
	}
		
	foreach my $record (@{$self->ensure_child_array('purchase_record')})
	{
		if($record->account_id!=$self->get_id)
		{
			$record->purchase_type('upsell');
		}
	}
}

sub load_account_link_summary
{
	my ($self) = @_;

	$self->add_children('Webkit::Player::AccountLink', {
		table => 'player.account_link',
		clause => 'child_id = ? or parent_id = ?',
		binds => [$self->get_id, $self->get_id],
		group => 'account_link.id',
		order => 'created DESC' });	
		
	my $clause=<<"+++";
account_link.child_id = ?
or account_link.parent_id = ?
and
(
	account_link.child_id = account.id
	or
	account_link.parent_id = account.id
)
+++
		
	$self->add_children('Webkit::Player::Account', {
		table => 'player.account_link, player.account',
		clause => $clause,
		binds => [$self->get_id, $self->get_id],
		group => 'account.id',
		order => 'account.name' });
		
	foreach my $link (@{$self->ensure_child_array('account_link')})
	{
		my $parent_account = $self->get_child('account', $link->parent_id);
		my $child_account = $self->get_child('account', $link->child_id);
		
		if((!$parent_account)||(!$child_account)) { next; }
		
		$link->{linked_from} = $parent_account->get_account_name;
		$link->{linked_to} = $child_account->get_account_name;
		$link->{link_created} = Webkit::Player::PurchaseRecord->get_date_formatted($link->created);
	}
}

sub has_upsell_links
{
	my ($self) = @_;
	
	$self->load_upsell_links;
	
	if($self->get_child_count('account_link')>0) { return 1; }
	else { return undef; }
}

sub load_upsell_links
{
	my ($self) = @_;
	
	if($self->{_upsell_links_loaded}) { return; }
	$self->{_upsell_links_loaded} = 1;
	
	$self->add_children('Webkit::Player::AccountLink', {
		table => 'player.account_link',
		clause => 'child_id = ? and link_type = ?',
		binds => [$self->get_id, 'upsell'] });
}

sub is_online_club_current
{
	my ($self) = @_;
	
	### first do we have a currently active sbscription to all?
	
	$self->load_viewer_purchase_record_map;
	
	if(!$self->{purchase_record_subscription_map}->{all}) { return undef; }
	
	if($self->account_flag =~ /onlineclub_subscriber/i)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub load_viewer_purchase_record_map
{
	my ($self) = @_;
	
	if($self->{_purchase_record_map_loaded}) { return; }
	$self->{_purchase_record_map_loaded} = 1;

	$self->load_viewer_purchase_records;
	
	foreach my $record (@{$self->ensure_child_array('purchase_record')})
	{
		if(!$record->is_active) { next; }
		
		if($record->is_subscription)
		{
			$self->{purchase_record_subscription_map}->{$record->collection_id} = $record;
		}
		else
		{
			$self->{purchase_record_map}->{$record->ou_id} = $record;
		}
	}
}

sub load_purchase_record_map
{
	my ($self) = @_;
	
	if($self->{_purchase_record_map_loaded}) { return; }
	$self->{_purchase_record_map_loaded} = 1;

	$self->load_purchase_records;
	
	$self->process_purchase_record_map;
}

sub process_purchase_record_map
{
	my ($self) = @_;
	
	foreach my $record (@{$self->ensure_child_array('purchase_record')})
	{
		if(!$record->is_active) { next; }
		
		if($record->is_subscription)
		{
			$self->{purchase_record_subscription_map}->{$record->collection_id} = $record;
		}
		else
		{
			$self->{purchase_record_map}->{$record->ou_id} = $record;
		}
	}
}

sub load_viewer_purchased_activities
{
	my ($self) = @_;
	
	$self->load_purchased_activities(1);
}

sub load_all_library_activities2
{
	my ($self) = @_;
	
	my $ou_binds = [$self->installation_id, 'teaching_resource'];
	my $thumbnail_binds = [$self->installation_id, 'teaching_resource', 'thumbnail'];
	
	my $ou_clause=<<"+++";
ou.installation_id = ?
and ou.ou_type = ?
+++
	
	my $ou_load_props = {
		table => 'player.ou',
		cols => 'ou.*',
		clause => $ou_clause,
		binds => $ou_binds,
		group => 'ou.id',
		order => 'ou.name'
	};
	
	my $keyword_clause=<<"+++";
	$ou_clause
	and keyword.ou_id = ou.id
+++

	my $keyword_load_props = {
		table => 'player.ou, player.keyword',
		cols => 'keyword.*',
		clause => $keyword_clause,
		binds => $ou_binds,
		group => 'keyword.id'
	};
	
	my $thumbnail_clause=<<"+++";
	$ou_clause
	and ou2.ou_id = ou.id
	and ou2.item_type = ?
+++
	
	my $thumbnail_load_props = {
		table => 'player.ou as ou, player.ou as ou2',
		cols => 'ou2.*',
		clause => $thumbnail_clause,
		binds => $thumbnail_binds,
		group => 'ou2.id'
	};
	
	my $loader = $self->clone;
	
	Webkit::Player::OU->load_objects($self->{db}, $ou_load_props, $loader);
	Webkit::Player::Keyword->load_objects($self->{db}, $keyword_load_props, $loader);
	
	foreach my $keyword (@{$loader->ensure_child_array('keyword')})
	{
		my $ou = $loader->get_child('ou', $keyword->ou_id);
		
		if(!$ou) { return; }
		
		$ou->add_child($keyword);
	}
	
	my $thumbnails = Webkit::Player::OU->load_objects($self->{db}, $thumbnail_load_props);
	
	foreach my $thumbnail (@$thumbnails)
	{
		my $ou = $loader->get_child('ou', $thumbnail->ou_id);
		
		if(!$ou) { return; }
		
		$ou->{data}->{thumbnail_url} = $thumbnail->{data}->{item_path};
	}
	
	foreach my $ou (@{$loader->ensure_child_array('ou')})
	{
		if($self->has_purchased_activity($ou))
		{
			$self->add_child($ou);
		}
	}
}

sub load_all_library_activities
{
	my ($self, $installation) = @_;
	
	if(!$installation)
	{
		$installation = Webkit::Player::Installation->load($self->{db}, {
			id => $self->installation_id });
	}
		
	my $views = Webkit::Player::Views->new_with_installation($installation, $self->menu_to_use);
	
	my $ou_type = 'teaching_resource';
	
	if($installation->is_dictionary)
	{
		$ou_type = 'word';
	}
	
	my $ou_binds = [$self->installation_id, $ou_type];
	
	my $ou_clause=<<"+++";
ou.installation_id = ?
and ou.ou_type = ?
+++
	
	my $ou_load_props = {
		table => 'player.ou',
		cols => 'ou.*',
		clause => $ou_clause,
		binds => $ou_binds,
		group => 'ou.id',
		order => 'ou.name'
	};
	
	my $keyword_clause=<<"+++";
	$ou_clause
	and keyword.ou_id = ou.id
+++

	my $keyword_load_props = {
		table => 'player.ou, player.keyword',
		cols => 'keyword.*',
		clause => $keyword_clause,
		binds => $ou_binds,
		group => 'keyword.id'
	};
	
	my $loader = $self->clone;
	
	Webkit::Player::OU->load_objects($self->{db}, $ou_load_props, $loader);
	Webkit::Player::Keyword->load_objects($self->{db}, $keyword_load_props, $loader);
	
	foreach my $keyword (@{$loader->ensure_child_array('keyword')})
	{
		my $ou = $loader->get_child('ou', $keyword->ou_id);
		
		if(!$ou) { return; }
		
		$ou->add_child($keyword);
	}
	
	foreach my $ou (@{$loader->ensure_child_array('ou')})
	{
		if($self->has_purchased_activity($ou))
		{
			$self->add_child($ou);
		}
	}
	
	$views->load_thumbnails_for_ous($self->ensure_child_array('ou'));
	
	if($installation->is_dictionary)
	{
		$views->load_definitions_for_ous($self->ensure_child_array('ou'));
	}
}

sub load_purchased_activities
{
	my ($self, $viewer_mode) = @_;
	
	my $ou_binds = [$self->get_id];
	my $thumbnail_binds = [$self->get_id];
	
	my $id_clauses = ["purchase_record.account_id = ?"];	
	
	if($viewer_mode)
	{
		$self->load_upsell_links;
	
		foreach my $account_link (@{$self->ensure_child_array('account_link')})
		{
			push(@$id_clauses, "purchase_record.account_id = ?");
			push(@$ou_binds, $account_link->parent_id);
			push(@$thumbnail_binds, $account_link->parent_id);
		}
	}
	
	my $account_id_clause = join(' or ', @$id_clauses);		
	
	my $ou_clause=<<"+++";
	purchase_record.ou_id = ou.id
	and 
	(
		$account_id_clause
	)
	and
	(
		purchase_record.purchase_type = ?
		or
		purchase_record.purchase_type = ?
	)
+++

	push(@$ou_binds, 'purchase');
	push(@$ou_binds, 'free');
	push(@$thumbnail_binds, 'purchase');
	push(@$thumbnail_binds, 'free');
	push(@$thumbnail_binds, 'thumbnail');
	
	my $ou_load_props = {
		table => 'player.ou, player.purchase_record',
		cols => 'ou.*',
		clause => $ou_clause,
		binds => $ou_binds,
		group => 'ou.id',
		order => 'ou.name'
	};
	
	my $keyword_clause=<<"+++";
	$ou_clause
	and keyword.ou_id = ou.id
+++

	my $keyword_load_props = {
		table => 'player.ou, player.purchase_record, player.keyword',
		cols => 'keyword.*',
		clause => $keyword_clause,
		binds => $ou_binds,
		group => 'keyword.id'
	};
	
	my $thumbnail_clause=<<"+++";
	purchase_record.ou_id = ou.ou_id
	and 
	(
		$account_id_clause
	)
	and
	(
		purchase_record.purchase_type = ?
		or
		purchase_record.purchase_type = ?
	)
	and ou.item_type = ?
+++
	
	my $thumbnail_load_props = {
		table => 'player.ou, player.purchase_record',
		cols => 'ou.*',
		clause => $thumbnail_clause,
		binds => $thumbnail_binds,
		group => 'ou.id'
	};
	
	Webkit::Player::OU->load_objects($self->{db}, $ou_load_props, $self);
	Webkit::Player::Keyword->load_objects($self->{db}, $keyword_load_props, $self);
	
	foreach my $keyword (@{$self->ensure_child_array('keyword')})
	{
		my $ou = $self->get_child('ou', $keyword->ou_id);
		
		if(!$ou) { return; }
		
		$ou->add_child($keyword);
	}
	
	my $thumbnails = Webkit::Player::OU->load_objects($self->{db}, $thumbnail_load_props);
	
	foreach my $thumbnail (@$thumbnails)
	{
		my $ou = $self->get_child('ou', $thumbnail->ou_id);
		
		if(!$ou) { return; }
		
		$ou->{data}->{thumbnail_url} = $thumbnail->{data}->{item_path};
	}
}

sub has_purchased_activity_by_id
{
	my ($self, $id) = @_;
	
	if($self->is_open_access) { return 1; }
	
	$self->load_viewer_purchase_record_map;
	
	return $self->{purchase_record_map}->{$id};
}

sub load_views_object
{
	my ($self) = @_;

	if($self->{_views_object_loaded}) { return; }
	$self->{_views_object_loaded} = 1;
	
	$self->{views} = Webkit::Player::Views->new($self->{db}, $self->installation_id, $self->menu_to_use);
}

sub has_purchased_activity
{
	my ($self, $activity) = @_;
	
	if($self->is_open_access) { return 1; }
	
	$self->load_viewer_purchase_record_map;
	$self->load_views_object;
	
	my $id = $activity->get_id;
	
	foreach my $subscription (keys %{$self->{purchase_record_subscription_map}})
	{
		if($subscription eq 'all') { return 1; }
		
		my $required_keywords = $self->{views}->get_collection_keywords($subscription);
		
		my $match_all = 1;
		
		foreach my $keyword (keys %$required_keywords)
		{
			if(!$activity->has_keyword_value($keyword, $required_keywords->{$keyword}))
			{
				$match_all = undef;
			}
		}
		
		if($match_all)
		{
			return 1;
		}
	}
	
	return $self->{purchase_record_map}->{$id};
}

sub has_entered_account_info
{
	my ($self) = @_;
	
	if($self->url!~/\w/)
	{
		return undef;
	}
	
	return 1;
}

sub get_address_summary
{
	my ($self) = @_;
	
	my @values = ($self->org, $self->city, $self->country, $self->postcode);
	
	my $used_values = {};
	
	my $sts = [];
	
	foreach my $val (@values)
	{
		if($val!~/\w/) { next; }
		if($used_values->{$val}) { next; }
		$used_values->{$val} = 1;
		
		push(@$sts, $val);
	}
	
	my $st = join(', ', @$sts);
	
	return $st;
}

sub get_users_names
{
	my ($self) = @_;
	
	my $names = [];
	
	foreach my $user (@{$self->ensure_child_array('user')})
	{
		push(@$names, $user->get_name);
	}
	
	my $ret = join(', ', @$names);
	
	return $ret;
}

sub get_user_emails
{
	my ($self) = @_;
	
	$self->load_children('Webkit::Player::User');
	
	my $ret = [];
	
	foreach my $child (@{$self->ensure_child_array('user')})
	{
		push(@$ret, $child->username);
	}
	
	return $ret;
}

sub can_have_trial
{
	my ($self) = @_;

	my $value = $self->get_account_setting('trial_enabled');
	
	if($value eq 'y') { return 1; }
	else { return undef; }	
}

sub can_have_free_subscription
{
	my ($self) = @_;
	
	my $value = $self->get_account_setting('disallow_free_subscription');

	if($value eq 'y') { return undef; }
	
	return 1;
	
	my $free_allowed = $self->get_free_activities_allowed;
	
	if($free_allowed>0)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub get_free_activities_allowed
{
	my ($self) = @_;
	
	if($self->get_account_flag('free_subscription')) { return 0; }
	if($self->get_account_flag('onlineclub_subscriber')) { return 0; }
	
	#### HACK UNTIL I GET THE 2 WEEKS EXPIRED CHOICE PLUGGED IN
	if($self->get_account_flag('2week_subscription'))
	{
		return 0;
	}
	else
	{
		my $value = $self->get_account_setting('free_allowed');
	
		if(!$value)
		{
			$value = 0;
		}
	
		return $value;
	}
}

sub free_activities_left
{
	my ($self) = @_;

	my $free_allowed = $self->get_free_activities_allowed;
	
	if($free_allowed<=0) { return 0; }
	
	$self->load_children('Webkit::Player::PurchaseRecord', {
		clause => 'purchase_type = ?',
		binds => ['free'] });
		
	my $free_taken = $self->get_child_count('purchase_record');
	
	return $free_allowed - $free_taken;
}

sub error
{
	my ($self) = @_;

#	my $name_account = $self->get_existing_object_with_same_value('name');
#	my $url_account = $self->get_existing_object_with_same_value('url');
#
#	if($name_account)
#	{
#		$self->{error_text} = 'An account with that name already exists - please choose another';
#		return 1;		
#	}
#
#	if($url_account)
#	{
#		$self->{error_text} = 'An account with that URL already exists - please choose another';
#		return 1;		
#	}

	return $self->SUPER::error;
}

sub is_type
{
	my ($self, $type) = @_;

	if($self->account_type eq $type) { return 1; }
	else { return undef; }
}

sub is_root
{
	my ($self) = @_;

	return $self->is_type('root');
}

sub is_seller
{
	my ($self) = @_;

	return $self->is_type('seller');
}

sub get_text_entry
{
	my ($self, $text_name) = @_;
	
	my $map = $self->get_text_entry_map([$text_name]);
	
	return $map->{$text_name};
}

sub get_default_text_entry_map
{
	my ($self, $installation_id, $text_names) = @_;
	
	my $name_clauses = [];
	my $binds = [$installation_id, 'english'];
	
	foreach my $name (@$text_names)
	{
		push(@$name_clauses, "name = ?");
		push(@$binds, $name);
	}
	
	my $name_clause = join(' or ', @$name_clauses);
	
	my $clause=<<"+++";
	installation_id = ?
	and language = ?
	and
	(
		$name_clause
	)
	and
	(
		account_type IS NULL
		and
		account_id IS NULL
	)
+++
	
	$self->add_children('Webkit::Player::TextEntry', {
		table => 'player.text_entry',
		cols => 'text_entry.*',
		clause => $clause,
		binds => $binds });
		
	my $map = {};
		
	### this allocates each entry into its respective matching type
	foreach my $entry (@{$self->ensure_child_array('text_entry')})
	{
		$map->{$entry->name} = $entry->content;
	}
	
	return $map;		
}

sub get_text_entry_map
{
	my ($self, $text_names) = @_;
	
	my $name_clauses = [];
	my $binds = [$self->installation_id, 'english'];
	
	foreach my $name (@$text_names)
	{
		push(@$name_clauses, "name = ?");
		push(@$binds, $name);
	}
	
	push(@$binds, $self->get_id);
	
	my $account_type_map = {
		$self->account_type => 1 };
	
	#### this means cart level messages apply	
	if(!$self->is_open_access)
	{
		my $purchaser_or_subscriber = 'purchaser';
	
		if($self->has_got_subscription)
		{
			$purchaser_or_subscriber = 'subscriber';
		}
		
		$account_type_map->{$purchaser_or_subscriber} = 1;
	}
	
	my $account_type_clauses = [];
	
	foreach my $key (keys %$account_type_map)
	{
		push(@$account_type_clauses, "account_type = ?");
		push(@$binds, $key);
	}
	
	my $name_clause = join(' or ', @$name_clauses);
	my $account_type_clause = join(' or ', @$account_type_clauses);
	
	my $clause=<<"+++";
	installation_id = ?
	and language = ?
	and
	(
		$name_clause
	)
	and
	(
		account_id = ?
		or
		account_type IS NULL
		or
		$account_type_clause
	)
+++
	
	$self->add_children('Webkit::Player::TextEntry', {
		table => 'player.text_entry',
		cols => 'text_entry.*',
		clause => $clause,
		binds => $binds });
		
	my $map = {};
		
	### this allocates each entry into its respective matching type
	foreach my $entry (@{$self->ensure_child_array('text_entry')})
	{
		my $content = $entry->content;
		
		my $code = $self->account_flag;
		
		$content =~ s/---code---/$code/gi;
		
		if($entry->account_id=~/\d/)
		{
			if($entry->account_id == $self->get_id)
			{
				$map->{$entry->name}->{id} = $content;
			}
		}
		elsif($entry->account_type=~/\w/)
		{
			if($account_type_map->{$entry->account_type})
			{
				$map->{$entry->name}->{account_type} = $content;
			}
		}
		else
		{
			$map->{$entry->name}->{generic} = $content;
		}
	}
	
	#### This then selects each entry
	my $ret = {};
	
	foreach my $key (keys %$map)
	{
		my $word_entry_map = $map->{$key};
		
		if($word_entry_map->{id})
		{
			$ret->{$key} = $word_entry_map->{id};
		}
		elsif($word_entry_map->{account_type})
		{
			$ret->{$key} = $word_entry_map->{account_type};
		}
		elsif($word_entry_map->{generic})
		{
			$ret->{$key} = $word_entry_map->{generic};
		}
	}
	
	return $ret;
}

sub parse_account_flag
{
	my ($self) = @_;
	
	my @parts = split(/,/, $self->account_flag);
	
	foreach my $part (@parts)
	{
		my ($key, $value) = split(/=/, $part);

		if(!$value) { $value = $key; }
				
		$self->{account_flags}->{$key} = $value;
	}
}

sub add_account_flag
{
	my ($self, $key, $value) = @_;
	
	my $st = $key;
	
	if($value)
	{
		$st .= '='.$value;
	}
	
	my @parts = split(/,/, $self->account_flag);
	
	push(@parts, $st);
	
	$self->account_flag(join(',', @parts));
}

sub get_account_flag
{
	my ($self, $key) = @_;
	
	$self->parse_account_flag;
	
	return $self->{account_flags}->{$key};
}

sub parse_account_settings
{
	my ($self) = @_;
	
	my @parts = split(/,/, $self->account_settings);
	
	foreach my $part (@parts)
	{
		my ($key, $value) = split(/=/, $part);

		if(!$value) { $value = $key; }
				
		$self->{account_settings}->{$key} = $value;
	}
}

sub save_url
{
	my ($self, $url) = @_;

	$url =~ s/-//g;
	
	my @parts = split(/,/, $url);
	
	my $count = @parts;
	
	if($count<=1)
	{
		$self->url($url);
	}
	else
	{
		my $finalparts = [];
	
		foreach my $part (@parts)
		{
			push(@$finalparts, '-'.$part.'-');	
		}
	
		$url = join(',', @$finalparts);
		
		$self->url($url);
	}
}

sub starting_view
{
	my ($self) = @_;
	
	return $self->get_account_setting('starting_view');	
}

sub menu_to_use
{
	my ($self) = @_;
	
	return $self->get_account_setting('menu_to_use');	
}

sub remove_account_setting
{
	my ($self, $key) = @_;
	
	my @parts = split(/,/, $self->account_settings);
	my $new_parts = [];
	
	foreach my $part (@parts)
	{
		if($part!~/^$key/)
		{
			push(@$new_parts, $part);
		}
	}
	
	$self->account_settings(join(',', @$new_parts));
}

sub replace_account_setting
{
	my ($self, $key, $value) = @_;
	
	my @parts = split(/,/, $self->account_settings);
	my $new_parts = [];
	
	my $has_replaced = undef;
	
	foreach my $part (@parts)
	{
		if($part=~/^$key/)
		{
			$part = $key;
			
			if(defined($value))
			{
				$part .= '='.$value;
			}
			
			$has_replaced = 1;
		}
		
		if(defined($value))
		{
			push(@$new_parts, $part);
		}
	}
	
	if(!$has_replaced)
	{
		my $new_part = $key;
		
		if(defined($value))
		{
			$new_part .= '='.$value;
		}
		
		if(defined($value))
		{
			push(@$new_parts, $new_part);
		}
	}
	
	$self->account_settings(join(',', @$new_parts));
} 

sub add_account_setting
{
	my ($self, $key, $value) = @_;
	
	my $st = $key;
	
	if(defined($value))
	{
		$st .= '='.$value;
	}
	
	my @parts = split(/,/, $self->account_settings);
	
	push(@parts, $st);
	
	$self->account_settings(join(',', @parts));
}

sub get_account_setting
{
	my ($self, $key) = @_;
	
	$self->build_account_settings;
	
	return $self->{account_settings_map}->{$key};
}

sub build_account_settings
{
	my ($self, $default_map) = @_;

	if($self->{_account_settings_built}) { return; }
	$self->{_account_settings_built} = 1;
	
	if(!$default_map)
	{
		$default_map = Webkit::Player::Installation->get_default_account_settings_map;		
	}
		
	$self->parse_account_settings;
	
	my $map = {};
	
	my $default_values = $default_map->{$self->account_type};
	
	foreach my $key (keys %$default_values)
	{
		$map->{$key} = $default_values->{$key};
	}
	
	foreach my $key (keys %{$self->{account_settings}})
	{
		$map->{$key} = $self->{account_settings}->{$key};
	}
	
	$self->{account_settings_map} = $map;
}

sub get_registered_summary
{
	my ($self) = @_;
	
	if(!$self->registered) { return ''; }
	
	return Webkit::AppTools->get_date_formatted($self->registered);
}

1;
