package Webkit::Player::Invoice;

use strict;

@Webkit::Player::Invoice::ISA = qw(Webkit::DBObject);

my $schema = {
			installation_id =>	{	type => 'id',
									required => 1 },
									
			account_id => {			type => 'id',
									required => 1 },
			date_sent =>	{	type => 'datetime' },
			
			date_paid =>	{	type => 'datetime' },

			amount_for => 	{	type => 'float' },
			
			discount => 	{	type => 'float' },									
			
			invoice_number => {	type => 'string' },
			
			order_number => {	type => 'string' },
			
			notes =>		{	type => 'string' }																															
};

sub table
{
        return 'player.invoice';
}

sub schema
{
        return $schema;
}

sub get_date_formatted
{
	my ($self, $date_obj) = @_;
	
	#return Webkit::AppTools->get_date_formatted($date_obj);
	
	if(!$date_obj) { return ''; }
	
	return &Webkit::Date::get_string($date_obj);
}

sub get_date_sent_summary
{
	my ($self) = @_;

	return $self->get_date_formatted($self->date_sent);
}

sub get_date_paid_summary
{
	my ($self) = @_;

	return $self->get_date_formatted($self->date_paid);
}

sub get_product_name_summary
{
	my ($self) = @_;

	my $names = [];
	
	foreach my $record (@{$self->ensure_child_array('purchase_record')})
	{
		push(@$names, $record->{data}->{product_name});
	}
	
	my $ret = join(', ', @$names);
	
	return $ret;
}

sub load_purchase_records
{
	my ($self) = @_;

	if($self->{_purchase_records_loaded})
	{
		return;
	}
	
	$self->{_purchase_records_loaded} = 1;
	
	$self->load_children('Webkit::Player::PurchaseRecord', {
		order => 'purchase_date' });
}

1;
