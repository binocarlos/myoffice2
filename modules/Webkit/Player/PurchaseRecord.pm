package Webkit::Player::PurchaseRecord;

use strict;

@Webkit::Player::PurchaseRecord::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>	{	type => 'id',
									required => 1 },
									
			account_id => {			type => 'id',
									required => 1 },
									
			invoice_id => {			type => 'id',
									required => 1 },

			purchase_type => 	{	type => 'string',
									required => 1 },
									
			purchase_date =>	{	type => 'datetime',
									required => 1 },

			purchase_amount => 	{	type => 'float',
									required => 1 },
									
			ou_id =>			{	type => 'id',
									required => 1 },

			collection_id => 	{	type => 'string' },
									
			subscription_start =>	{	type => 'datetime',
										required => 1 },
									
			subscription_end =>	{	type => 'datetime',
									required => 1 }																																	
};

sub table
{
        return 'player.purchase_record';
}

sub schema
{
        return $schema;
}

sub get_purchase_date_summary
{
	my ($self) = @_;

	return $self->get_date_formatted($self->purchase_date);
}

sub get_date_formatted
{
	my ($self, $date_obj) = @_;
	
	if(!$date_obj) { return ''; }
	
	#return Webkit::AppTools->get_date_formatted($date_obj);
	
	return &Webkit::Date::get_string($date_obj);
}

sub get_subscription_dates_summary
{
	my ($self) = @_;

	if(!$self->is_subscription) { return 'n/a'; }

	my $st = $self->get_date_formatted($self->subscription_start).' to '.$self->get_date_formatted($self->subscription_end);
	
	return $st;
}

sub is_subscription
{
	my ($self) = @_;
	
	if($self->collection_id=~/\w/)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub is_active
{
	my ($self) = @_;
	
	if(!$self->is_subscription)
	{
		return 1;
	}
	
	my $now_date = Webkit::DateTime->now;
	
	if($now_date->Epoch>$self->subscription_end->Epoch)
	{
		return undef;
	}
	
	return 1;
}

sub get_days_left
{
	my ($self) = @_;

	if(!$self->is_subscription) { return 0; }
	if(!$self->is_active) { return 0; }
	
	my $now_date = Webkit::DateTime->now;
	
	my $now_days = $now_date->epoch_days;
	
	my $end_days = $self->subscription_end->epoch_days;
	
	my $days_left = $end_days - $now_days;
	
	return $days_left;
}

1;
