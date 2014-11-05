package Webkit::Apache::Authen;

use strict;

#use Apache::Constants qw(:common);
#use Apache::Request ();
#use Apache::File ();

use Webkit::SiteManager::Admin ();
use Webkit::Session ();

sub webkit_handler
{
	my $r = shift;
	
	my($res, $sent_pw) = $r->get_basic_auth_pw;

	return $res if $res != OK;

	my $user = $r->connection->user;

	unless($user and $sent_pw)
	{
		$r->note_basic_auth_failure;
		$r->log_reason("Both a username and password must be provided",$r->filename);

		return Apache2::Const::AUTH_REQUIRED;
	}

	my $app = Webkit::Application->new;

	my $userobj = Webkit::User->load($app->{db}, {
		clause => "username = ? and password = ?",
		binds => [$user, $sent_pw] });

	if(($userobj)&&($userobj->is_webkit))
	{
		return OK;
	}
	else
	{
		$r->note_basic_auth_failure;
		$r->log_reason("$user denied access with $sent_pw password",$r->filename);

		return Apache2::Const::AUTH_REQUIRED;
	}
}

1;

