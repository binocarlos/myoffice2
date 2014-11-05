package Webkit::SkillsAudit::VisitorSession;

use strict;

@Webkit::SkillsAudit::VisitorSession::ISA = qw(Webkit::DBObject);

my $schema = {
			org_id => {		type => 'id',
						required => 1 },

			session_id => {		type => 'string',
						required => 1 },

			visitor_id => {		type => 'id',
						required => 1 },

			school_id => {		type => 'id',
						required => 1 },

			created => {		type => 'datetime',
						required => 1 },

			modified => {		type => 'datetime',
						required => 1 } };

#### This is the 30 minute time-out for the session

my $timeout = 60*60;

sub table
{
        return 'skillsaudit.visitor_session';
}

sub schema
{
        return $schema;
}

sub new_with_school_id
{
	my ($classname, $db, $org_id, $school_id, $visitor_id) = @_;

	if($visitor_id!~/\d/)
	{
		$visitor_id = 0;
	}

	my $session = Webkit::SkillsAudit::VisitorSession->constructor($db);

	$session->org_id($org_id);
	$session->set_value('visitor_id', $visitor_id);
	$session->set_value('school_id', $school_id);
	$session->created(Webkit::DateTime->now);
	$session->modified(Webkit::DateTime->now);
	
	use CGI::Session;

    my $cgisession = new CGI::Session("driver:File", undef, {Directory=>'/tmp'});
    
    #$self->{_session_id} = $cgisession->id();
    
	$session->session_id($cgisession->id());

	return $session;
}

sub new_with_visitor
{
	my ($classname, $visitor) = @_;

	my $session = Webkit::SkillsAudit::VisitorSession->constructor($visitor->{db});

	$session->org_id($visitor->org_id);
	$session->visitor_id($visitor->get_id);
	$session->school_id($visitor->school_id);
	$session->created(Webkit::DateTime->now);
	$session->modified(Webkit::DateTime->now);
	$session->session_id(Apache::Session::Generate::MD5::generate());

	return $session;
}

sub is_active
{
	my ($self) = @_;

	my $now_epoch = Webkit::DateTime->now->Epoch;
	my $modified_epoch = $self->modified->Epoch;

	#### Is now more than when it was changed plus the timeout ?

	if($now_epoch > ($modified_epoch + $timeout))
	{
		return undef;
	}
	else
	{
		return 1;
	}
}

1;
