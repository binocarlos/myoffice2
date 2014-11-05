package Webkit::RootClient;

use strict;

sub new
{
	my ($classname, $noerror) = @_;

	my $self = {};

	bless($self, $classname);

	$self->{noerror} = $noerror;

	return $self;
}

sub add_instruction
{
	my ($self, $action, $attr) = @_;

	if($action!~/\w/)
	{
		my $text = "You must give an action to add an instruction";

		if(!$self->{noerror})
		{
			Webkit::Error->wkerror($text);
		}
		else
		{
			$self->{error} = $text;
		}

		return undef;
	}

	my $instruction = {
		action => $action,
		properties => $attr };

	push(@{$self->{instructions}}, $instruction);

	return 1;
}

sub generate_message
{
	my ($self) = @_;

	my $password = Webkit::RootServer->get_password;

	my $message=<<"+++";
<?xml version="1.0" encoding="UTF-8" ?>
<message>
	<password value="$password"/>
+++

	foreach my $instruction (@{$self->{instructions}})
	{
		my $action = $instruction->{action};
		my $properties = $instruction->{properties};

		$message.=<<"+++";
	<instruction action="$action">
+++

		foreach my $key (keys %$properties)
		{
			my $value = $properties->{$key};

			$message.=<<"+++";
		<property key="$key" value="$value"/>
+++
		}

		$message.=<<"+++";
	</instruction>
+++
	}

	$message.=<<"+++";
</message>
+++

	return $message;
}

sub send_message
{
	my ($self) = @_;

	if(!$self->{instructions})
	{
		my $text = "You need to have added instructions to call send_message";

		if(!$self->{noerror})
		{
			Webkit::Error->wkerror($text);
		}
		else
		{
			$self->{error} = $text;
		}

		return;
	}

	my $message = $self->generate_message;

	my $host = Webkit::RootServer->host;
	my $port = Webkit::RootServer->port;

	my $conn = Webkit::Msg->connect($host, $port, \&server_reponse);

	if(!$conn)
	{
		if(!$self->{noerror})
		{
			Webkit::Error->wkerror("The Server is not currently running on $host:$port");
		}

		return undef;
	}

	$conn->send_now($message);

	my ($msg, $err) = $conn->rcv_now();

	$conn->disconnect;

	return $msg;
}

sub create_pop_account
{
	my ($self, $attr) = @_;

	$self->add_instruction('create_pop_account', $attr);
}

sub edit_pop_account
{
	my ($self, $attr) = @_;

	$self->add_instruction('edit_pop_account', $attr);
}

sub delete_pop_account
{
	my ($self, $attr) = @_;

	$self->add_instruction('delete_pop_account', $attr);
}

sub create_email_address
{
	my ($self, $attr) = @_;

	$self->add_instruction('create_email_address', $attr);
}

sub edit_email_address
{
	my ($self, $attr) = @_;

	$self->add_instruction('edit_email_address', $attr);
}

sub delete_email_address
{
	my ($self, $attr) = @_;

	$self->add_instruction('delete_email_address', $attr);
}

sub send_easemail_queue
{
	my ($self, $attr) = @_;

	$self->add_instruction('send_easemail_queue', $attr);
}

1;
