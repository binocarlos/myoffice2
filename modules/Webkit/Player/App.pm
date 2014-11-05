package Webkit::Player::App;

use vars qw(@ISA);
use strict qw(vars);

use Webkit::WebApplication;
use Webkit::Error;

@ISA = qw(Webkit::WebApplication);

my $app_name = 'iboardplayer';
my $app_title = 'iboard Player';
my $manual_page_methods = { };

my $ignore_keyword_types_for_player = {
	becta => 1
};

my $words_folder = '/staticfiles/mrspryce/';

#'help@tes.co.uk'


my @admin_emails = ('jenny.field@tsleducation.co.uk', 'kai@wk1.net');

my @domains = ('dictionary.iboard.co.uk', 'iboard.co.uk', 'i-board.co.uk', 'iboardplayer.com', 'alicevm.wk1.net:8888', 'alicevm.wk1.net:5555', 'office.wk1.net:8888');

sub dev_mode
{
	my ($self) = @_;

	return undef;
	
	my $http_host = $self->hostname;

	if(lc($http_host) =~ /player\.iboard\.co\.uk/i)
	{
		return undef;
	}
	elsif(lc($http_host) =~ /alicevm\.wk1\.net\:5555/i)
	{
		return 1;
	}
	elsif(lc($http_host) =~ /alicevm\.wk1\.net\:8888/i)
	{
		return 1;
	}
	
	return undef;
}

sub is_referer_friendly
{
	my ($self) = @_;
	
	return 1;
	
	my $value = $ENV{HTTP_REFERER};
	
	if($value =~ /^(http:\/\/)?([\w\._-]+)\.?iboard\.co\.uk/i)
	{
		return 1;
	}
	elsif($value =~ /^(http:\/\/)?([\w\._-]+)\.?iboardplayer\.com/i)
	{
		return 1;
	}
	elsif($value =~ /^(http:\/\/)?([\w\._-]+)\.?alicevm\.wk1\.net\:5555/i)
	{
		return 1;
	}
	elsif($value =~ /^(http:\/\/)?([\w\._-]+)\.?alicevm\.wk1\.net\:8888/i)
	{
		return 1;
	}
	
	return undef;
}

sub convert_path
{
	my ($self) = @_;

	my $http_host = $self->hostname;

	if(lc($http_host) =~ /(.+\.)?iboard\.co\.uk$/)
	{
		return '/usr/bin/convert';
	}
	elsif(lc($http_host) =~ /alicevm.wk1.net:8888/)
	{
		return '/usr/local/bin/convert';
	}
	elsif(lc($http_host) =~ /alicevm.wk1.net:8888/)
	{
		return '/usr/local/bin/convert';
	}	
}

########################################################################################
########################################################################################
######################
# Boot
######################
########################################################################################
########################################################################################

sub app_name
{
	my ($self) = @_;
	return $app_name;
}

sub app_title
{
	my ($self) = @_;
	return $app_title;
}

sub manual_page_methods
{
	my ($self) = @_;
	return $manual_page_methods;
}

sub handler
{
	my ($r) = @_;
	return &Webkit::WebApplication::handler($r, 'Webkit::Player::App');
}

sub run_before_method
{
	my ($self) = @_;

	my $installation = Webkit::Player::Installation->constructor($self->{db});

	$installation->{data}->{id} = $self->installation_id;

	$self->{installation} = $installation;
	
	my $json = new JSON ();

	$self->{json} = $json;
	
	$self->{page_props}->{site_look_and_feel} = $self->site_look_and_feel;
	$self->{page_props}->{hostname} = $self->hostname;
	
	$self->{page_props}->{main_domain} = $self->main_domain;
	
	$self->{content_type} = 'text/html; charset=utf-8';
}

sub get_page_method
{
	my ($self) = @_;

	my $r = $self->{_r};

	my $method = $r->uri;
	
	if($method =~ /^\/activity\/([\w -_]+)\/(\.?\d+)\/?$/i)
	{
		$self->{view_id} = $1;
		$self->{activity_id} = $2;

		if($self->{activity_id} =~ /^\.(\d+)$/)
		{
			$self->{activity_id} = $1;
			
			return 'activity__id_handler';
		}
		else
		{
			return 'activity__id_launch_handler';
		}
	}
	elsif($method =~ /^\/activity\/(\.?\d+)\/?$/i)
	{
		$self->{view_id} = 'generic';
		$self->{activity_id} = $1;

		if($self->{activity_id} =~ /^\.(\d+)$/)
		{
			$self->{activity_id} = $1;
			
			return 'activity__id_handler';
		}
		else
		{
			return 'activity__id_launch_handler';
		}
	}
	elsif($method =~ /^\/activity\/([\w -_]+)\/(\.?\w+)\/?$/i)
	{
		$self->{view_id} = $1;
		
		my $activity_code = $2;
		
		my $method = 'activity__id_launch_handler';
		
		if($activity_code =~ /^\./)
		{
			$activity_code =~ s/^\.//;
			
			$method = 'activity__id_handler';
		}
		
		my $code_array = [];
		
		for(my $i=2; $i<length($activity_code); $i+=3)
		{
			push(@$code_array, substr($activity_code, $i, 1));
		}
		
		my $id = '';
		
		for(my $i=1; $i<=$code_array->[0]; $i++)
		{
			$id .= $code_array->[$i];
		}
		
		$self->{activity_id} = $id;
		
		return $method;
	}
	elsif($method =~ /^\/thumbnail\/(\w+)\/?$/i)
	{
		my $activity_code = $1;
		
		my $method = 'activity__thumbnail_handler';
		
		my $code_array = [];
		
		for(my $i=2; $i<length($activity_code); $i+=3)
		{
			push(@$code_array, substr($activity_code, $i, 1));
		}
		
		my $id = '';
		
		for(my $i=1; $i<=$code_array->[0]; $i++)
		{
			$id .= $code_array->[$i];
		}
		
		$self->{activity_id} = $id;
		
		return $method;
	}
	elsif($method =~ /^\/launch\/(.*?)$/i)
	{
		my $url = lc($1);
		$url =~ s/\/$//;
		
		$self->{launch_url} = $url;
		
		return 'launch__index_handler';
	}
	elsif($method =~ /^\/page\/(.*?)$/i)
	{
		my $url = lc($1);
		$url =~ s/\/$//;
		
		$self->{page_url} = $url;
		
		return 'page__index_handler';
	}
	else
	{
		return $self->SUPER::get_page_method;
	}
}

sub load_installation
{
	my ($self) = @_;
	
	return $self->fully_load_installation;
}

sub fully_load_installation
{
	my ($self) = @_;
	
	if($self->{_installation_loaded}) { return $self->{installation}; }
	$self->{_installation_loaded} = 1;
	
	$self->{installation} = Webkit::Player::Installation->load($self->{db}, {
		id => $self->installation_id });
	
	return $self->{installation};
}

########################################################################################
########################################################################################
######################
# VARIABLE METHODS
######################
########################################################################################
########################################################################################

sub apache_variable
{
	my ($self, $varname) = @_;

	my $r = Webkit::Application->r || return;

	return $r->dir_config($varname);
}

sub server_id
{
	my ($self) = @_;
	
	return $self->apache_variable('serverID');	
}

sub installation_id
{
	my ($self) = @_;
	
	if($self->{_use_installation_id}) { return $self->{_use_installation_id}; }

	return $self->apache_variable('installationID');
}

sub site_look_and_feel
{
	my ($self) = @_;
	
	my $default = 'standard';
	
	my $ret = $self->apache_variable('siteLookAndFeel');
	
	if($ret!~/\w/)
	{
		$ret = $default;
	}
	
	return $ret;
}

sub hostname
{
	my ($self) = @_;

	my $ret = $ENV{HTTP_X_FORWARDED_HOST};
	
	if($ret!~/\w/)
	{
		$ret = $ENV{SERVER_NAME};
	}
	
	return $ret;
}

########################################################################################
########################################################################################
######################
# APP TOOLS
######################
########################################################################################
########################################################################################

sub jsonize
{
	my ($self, $obj) = @_;

	my $json = $self->{json};

	$json->max_depth(512);
	$json->pretty;
	$json->ascii(1);
	
	return $json->encode($obj);
}

sub return_error
{
	my ($self, $error_text) = @_;

	my $ret = {
		code => 'error',
		text => $error_text };

	if($self->dev_mode)
	{
		$ret->{sql} = $self->{db}->get_log;
	}

	$self->return_response($ret);
}

sub return_response
{
	my ($self, $response) = @_;

	if(!defined($response))
	{
		$response = {};
	}

	if(ref($response) eq 'HASH')
	{
		if($response->{code}!~/\w/)
		{
			$response->{code} = 'ok';
		}

		if($self->dev_mode)
		{
			$response->{sql} = $self->{db}->get_log;
		}
	}

	my $ret = $self->jsonize($response);

	$self->{page_content} = $ret;
}

########################################################################################
########################################################################################
######################
# AUTH TOOLS
######################
########################################################################################
########################################################################################

### Provides a logical answer as to whether the user is logged in
sub do_login
{
	my ($self) = @_;

	my $session = Webkit::Player::Session->login({
		db => $self->{db},
		installation_id => $self->installation_id,
		username => $self->{params}->{username},
		password => $self->{params}->{password},
		session_id => $self->{params}->{session_id} });

	if(!$session) { return undef; }

	$self->{session_id} = $session->session_id;
	$self->{session} = $session;
	$self->{user} = $session->{user};
	$self->{account} = $session->{account};
	
	$self->{page_props}->{session_id} = $session->session_id;

	return 1;
}

sub do_teacher_login
{
	my ($self) = @_;
	
	my $school = $self->load_account_from_subdomain;
	
	if(!$school) { return undef; }

	my $session = Webkit::Player::Session->login({
		db => $self->{db},
		installation_id => $self->installation_id,
		account_id => $school->get_id,
		password => $self->{params}->{password},
		session_id => $self->{params}->{session_id} });

	if(!$session) { return undef; }

	$self->{session_id} = $session->session_id;
	$self->{session} = $session;
	$self->{user} = $session->{user};
	$self->{account} = $session->{account};
	
	$self->{page_props}->{session_id} = $session->session_id;

	return 1;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# ROOT APP
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub root__index_handler
{
	my ($self) = @_;

	my $js_dev = 'false';

	if($self->dev_mode)
	{
		$js_dev = 'true';
	}
	
	my $installation = $self->load_installation;

	$self->{page_props}->{installation_name} = $installation->name;	
	$self->{page_props}->{dev_mode} = $js_dev;
}

########################################################################################
########################################################################################
######################
# LOGIN

sub root_login
{
	my ($self) = @_;

	if($self->{logged_in}) { return 1; }

	if((!$self->do_login)||(!$self->{user}))
	{
		$self->return_error('Incorrect login details');

		return;
	}

	if(!$self->{account}->is_root)
	{
		$self->return_error('Insufficient access level');

		return;
	}

	$self->{logged_in} = 1;

	return 1;
}

sub root__login_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }

	my $user_data = $self->{user}->{data};
	delete($user_data->{password});

	my $account_data = $self->{account}->{data};

	$self->return_response({
		user_data => $user_data,
		account_data => $account_data,
		session_id => $self->{session}->session_id });
}


########################################################################################
########################################################################################
######################
# GENERIC DATA

sub root__load_accounts_handler
{
	my ($self, $account_type) = @_;

	if(!$self->root_login) { return; }

	if($account_type!~/\w/) { $account_type = 'seller'; }

	$self->{installation}->load_children('Webkit::Player::Account', {
		clause => 'account_type = ?',
		binds => [$account_type],
		order => 'name' });

	$self->{installation}->add_children('Webkit::Player::User', {
		table => 'player.user, player.account',
		cols => 'user.*',
		clause => 'user.account_id = account.id and account.account_type = ? and user.installation_id = ?',
		binds => [$account_type, $self->installation_id],
		order => 'user.firstname, user.surname' });

	my $data = [];

	foreach my $user (@{$self->{installation}->ensure_child_array('user')})
	{
		my $account = $self->{installation}->get_child('account', $user->account_id);

		$account->add_child($user);

		push(@$data, {
			account_id => $account->get_id,
			id => $user->get_id,
			account_name => $account->name,
			url => $account->url,
			users_name => $user->get_name,
			username => $user->username,
			password => $user->password });
	}

	foreach my $account (@{$self->{installation}->ensure_child_array('account')})
	{
		if($account->get_child_count('user')<=0)
		{
			push(@$data, {
				account_id => $account->get_id,
				user_id => 0,
				account_name => $account->name,
				url => $account->url,
				users_name => '',
				username => '',
				password => '' });
		}
	}

	my $count = @{$data};

	$self->return_response({
		itemCount => $count,
		items => $data });
}

sub root__flatten_account_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }
	
	my $account_id = $self->{params}->{account_id};
	my $hostname = $self->hostname;
	my $document_root = $ENV{DOCUMENT_ROOT};
	my $script_root = $document_root;
	
	$script_root =~ s/player\/www/player\/scripts/i;
	$script_root =~ s/\/$//;
	
	$| = 1;
	
	print "Content-type: text/html\n\n";

	my $prog = "perl $script_root/flatten_account.pl $account_id $document_root $hostname";

	print<<"+++";
<html>
<head>
<script>
	function r(st)
	{
		document.getElementById('messageSpan').innerHTML = st;
	}

	function a(st)
	{
		var newSt = st + document.getElementById('messageSpan').innerHTML;
		
		if(newSt.length>1024)
		{
			newSt = newSt.substring(0, 1024);
		}
		
		document.getElementById('messageSpan').innerHTML = newSt;
	}
</script>
</head>
<body>
<b>Generating Website:</b><p>
RUNNING $prog<p>
<span id="messageSpan" style="color:#880000;"></span>
+++

	$self->print_buffer;
	
	my $foldername = '';
	
	my $count = 0;

	open(README, "$prog |") or die "Can't run program: $!\n";

	while(<README>)
	{
		my $line = $_;
		
		chomp($line);
		
		if($line =~ /adding:/i) { next; }
		
		$foldername = $line;
		
		$count++;
		
		if(($count>=10)||($line =~ /^\*/))
		{
			print<<"+++";
<script>a("$line<br>");</script>
+++

			$count = 0;
			
			$self->print_buffer;
		}
	}

	close(README);

	print<<"+++";
<script>r("<a href='/files/temp/$foldername/player.zip'>Click here for the ZIP download!!!</a><br><br><a target='blank' href='/files/temp/$foldername/index.htm'>Click here to preview the flattened site</a>");</script>
+++

	$self->print_buffer;

	$self->{page_content} = '_no_header';
	return '_no_header';
}

sub root__flatten_activity_handler
{
	my ($self) = @_;
	
	if(!$self->admin_login) { return; }
	
	my $sourcefolder = '/home/pub/player/temp/currentexport';
	my $destfolder = '/home/webkit/sites/flatplayer';
	
	my $oldcopiesfolder = $destfolder.'/oldcopies';
	my $newcopiesfolder = $destfolder.'/newcopies';
	my $wwwfolder = $destfolder.'/www';
	
	my $datafolder = '/data';
	my $helpfolder = '/help';
	my $filesfolder = '/files';	
	
	use Webkit::Player::Export;
	
	my $id = $self->{params}->{id};
	
	my $account = $self->load_tes_account;
	
	my $account_id = $account->get_id;
	my $hostname = $self->hostname;
	my $document_root = $ENV{DOCUMENT_ROOT};
	my $script_root = $document_root;
	
	my $export = Webkit::Player::Export->new({
		account_id => $account_id,
		document_root => $document_root,
		hostname => $hostname });	
		
	$export->create_folder('currentexport');
	
	$export->{noprint} = 1;

	my $ou = $export->{installation}->get_child('ou', $id);
	
	my $fileinfo = $export->include_activity_files($ou);
	
	my $session_id = $self->session_id();
	my $ouname = $ou->name;
	my $remove = $export->{flatten_to_folder_full};
	
	my $st = '';
	
	foreach my $key (keys %$fileinfo)
	{
		my $path = $fileinfo->{$key};
		
		$path =~ s/$remove//;
		
		my $command .= 'cp -f '.$sourcefolder.'/'.$path.' '.$wwwfolder.'/'.$path;
		
		system($command);
		
		$st .= 'Copied - '.$key.' - '.$path.'<p>'.$command.'<hr>';
	}
	
	$self->{page_content} = $st;
	
}

sub root__flatten_wholesite_handler
{
	my ($self) = @_;
	
	$self->root__flatten_tes_handler('flatten_wholesite');
}

sub root__flatten_justdata_handler
{
	my ($self) = @_;
	
	
	$self->root__flatten_tes_handler('flatten_justdata');
}

sub root__undomakeflatsitelive_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $sourcefolder = '/home/pub/player/temp/currentexport';
	my $destfolder = '/home/webkit/sites/flatplayer';
	
	my $oldcopiesfolder = $destfolder.'/oldcopies';
	my $newcopiesfolder = $destfolder.'/newcopies';
	my $wwwfolder = $destfolder.'/www';
	
	my $datafolder = '/data';
	my $helpfolder = '/help';
	my $filesfolder = '/files';
	
	## move the data/help/files from the newcopies to the current site
	system('mv -f '.$wwwfolder.$datafolder.'/* '.$newcopiesfolder.$datafolder);
	system('mv -f '.$wwwfolder.$helpfolder.'/* '.$newcopiesfolder.$helpfolder);
	system('mv -f '.$wwwfolder.$filesfolder.'/* '.$newcopiesfolder.$filesfolder);
	
	## move the data/help/files from the current site
	system('mv -f '.$oldcopiesfolder.$datafolder.'/* '.$wwwfolder.$datafolder);
	system('mv -f '.$oldcopiesfolder.$helpfolder.'/* '.$wwwfolder.$helpfolder);
	system('mv -f '.$oldcopiesfolder.$filesfolder.'/* '.$wwwfolder.$filesfolder);
	
	$self->{page_content} = 'website live undone';
}

sub root__makeflatsitelive_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $sourcefolder = '/home/pub/player/temp/currentexport';
	my $destfolder = '/home/webkit/sites/flatplayer';
	
	my $oldcopiesfolder = $destfolder.'/oldcopies';
	my $newcopiesfolder = $destfolder.'/newcopies';
	my $wwwfolder = $destfolder.'/www';
	
	my $datafolder = '/data';
	my $helpfolder = '/help';
	my $filesfolder = '/files';
	
	## clear out any existing files
	system('rm -rf '.$newcopiesfolder.'/*');
	system('rm -rf '.$oldcopiesfolder.'/*');
	system('mkdir '.$oldcopiesfolder.$datafolder);
	system('mkdir '.$oldcopiesfolder.$helpfolder);
	system('mkdir '.$oldcopiesfolder.$filesfolder);
	
	## copy the data/help/files from the export
	system('cp -rf '.$sourcefolder.$datafolder.' '.$newcopiesfolder.$datafolder);
	system('cp -rf '.$sourcefolder.$helpfolder.' '.$newcopiesfolder.$helpfolder);
	system('cp -rf '.$sourcefolder.$filesfolder.' '.$newcopiesfolder.$filesfolder);
	
	## move the data/help/files from the current site
	system('mv -f '.$wwwfolder.$datafolder.'/* '.$oldcopiesfolder.$datafolder);
	system('mv -f '.$wwwfolder.$helpfolder.'/* '.$oldcopiesfolder.$helpfolder);
	system('mv -f '.$wwwfolder.$filesfolder.'/* '.$oldcopiesfolder.$filesfolder);
	
	## move the data/help/files from the newcopies to the current site
	system('mv -f '.$newcopiesfolder.$datafolder.'/* '.$wwwfolder.$datafolder);
	system('mv -f '.$newcopiesfolder.$helpfolder.'/* '.$wwwfolder.$helpfolder);
	system('mv -f '.$newcopiesfolder.$filesfolder.'/* '.$wwwfolder.$filesfolder);
	
	$self->{page_content} = 'website now live';
}

sub root__flatten_tes_handler
{
	my ($self, $scriptname) = @_;

	if(!$self->root_login) { return; }
	
	$self->{use_subdomain} = 'tes';
	
	if($scriptname!~/\w/)
	{
		$scriptname = 'flatten_site';
	}
	
	my $account = $self->load_tes_account;
	
	my $account_id = $account->get_id;
	my $hostname = $self->hostname;
	my $document_root = $ENV{DOCUMENT_ROOT};
	my $script_root = $document_root;
	
	$script_root =~ s/player\/www/player\/scripts/i;
	$script_root =~ s/\/$//;
	
	$| = 1;
	
	print "Content-type: text/html\n\n";

	my $prog = "perl $script_root/".$scriptname.".pl $account_id $document_root $hostname";

	my $session_id = $self->session_id();
	
	print<<"+++";
<html>
<head>
<script>
	function r(st)
	{
		document.getElementById('messageSpan').innerHTML = st;
	}

	function a(st)
	{
		var newSt = st + document.getElementById('messageSpan').innerHTML;
		
		if(newSt.length>1024)
		{
			newSt = newSt.substring(0, 1024);
		}
		
		document.getElementById('messageSpan').innerHTML = newSt;
	}
</script>
</head>
<body>
<b>Generating Website:</b><p>
RUNNING $prog<p>
<span id="messageSpan" style="color:#880000;"></span>
<div id="finishedDiv" style="display:none;">
<hr>
<a target="_blank" href="http://tesserver.wk1.net">Click here to preview the flattened site</a>
<hr>
<a target="_blank" href="/root/makeflatsitelive.app?session_id=$session_id">Click here to make the flattened site live</a> (takes a few moments - be patient)
<hr>
<a target="_blank" href="/root/undomakeflatsitelive.app?session_id=$session_id">Click here to UNDO the make live</a> (takes a few moments - be patient)
</div>
+++

	$self->print_buffer;
	
	my $foldername = '';
	
	my $count = 0;

	open(README, "$prog |") or die "Can't run program: $!\n";

	while(<README>)
	{
		my $line = $_;
		
		chomp($line);
		
		if($line =~ /adding:/i) { next; }
		
		$foldername = $line;
		
		$count++;
		
		if($count>=100)
		{
			print<<"+++";
<script>a("$line<br>");</script>
+++

			$count = 0;
			
			$self->print_buffer;
		}
	}

	close(README);

	print<<"+++";
<script>r("");document.getElementById('finishedDiv').style.display = 'block';</script>
+++

	$self->print_buffer;

	$self->{page_content} = '_no_header';
	return '_no_header';
}

sub root__flatten_moodle_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }
	
	my $statichost = $self->{params}->{statichost};
	my $account_id = $self->{params}->{account_id};
	my $hostname = $self->hostname;
	my $document_root = $ENV{DOCUMENT_ROOT};
	my $script_root = $document_root;
	
	$script_root =~ s/player\/www/player\/scripts/i;
	$script_root =~ s/\/$//;
	
	$| = 1;
	
	print "Content-type: text/html\n\n";

	my $prog = "perl $script_root/flatten_moodle.pl $account_id $document_root $hostname $statichost";

	print<<"+++";
<html>
<head>
<script>
	function r(st)
	{
		document.getElementById('messageSpan').innerHTML = st;
	}

	function a(st)
	{
		var newSt = st + document.getElementById('messageSpan').innerHTML;
		
		if(newSt.length>1024)
		{
			newSt = newSt.substring(0, 1024);
		}
		
		document.getElementById('messageSpan').innerHTML = newSt;
	}
</script>
</head>
<body>
<b>Generating Website:</b><p>
RUNNING $prog<p>
<span id="messageSpan" style="color:#880000;"></span>
+++

	$self->print_buffer;
	
	my $foldername = '';
	
	my $count = 0;

	open(README, "$prog |") or die "Can't run program: $!\n";

	while(<README>)
	{
		my $line = $_;
		
		chomp($line);
		
		if($line =~ /adding:/i) { next; }
		
		$foldername = $line;
		
		$count++;
		
		if(($count>=10)||($line =~ /^\*/))
		{
			print<<"+++";
<script>a("$line<br>");</script>
+++

			$count = 0;
			
			$self->print_buffer;
		}
	}

	close(README);

	print<<"+++";
<script>r("<a href='/files/temp/$foldername/moodlePackages.zip'>Click here for the ZIP download!!!</a><br><br><a href='/files/temp/$foldername/index.htm' target='_blank'>Click here for the index of the individual packages!!!</a>");</script>
+++

	$self->print_buffer;

	$self->{page_content} = '_no_header';
	return '_no_header';
}

sub root__flatten_literacy_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $hostname = $self->hostname;
	my $document_root = $ENV{DOCUMENT_ROOT};
	my $script_root = $document_root;
	
	$script_root =~ s/player\/www/player\/scripts/i;
	$script_root =~ s/\/$//;
	
	$| = 1;
	
	print "Content-type: text/html\n\n";

	my $prog = "perl $script_root/flatten_literacy.pl $document_root $hostname";

	print<<"+++";
<html>
<head>
<script>
	function r(st)
	{
		document.getElementById('messageSpan').innerHTML = st;
	}

	function a(st)
	{
		var newSt = st + document.getElementById('messageSpan').innerHTML;
		
		if(newSt.length>1024)
		{
			newSt = newSt.substring(0, 1024);
		}
		
		document.getElementById('messageSpan').innerHTML = newSt;
	}
</script>
</head>
<body>
<b>Generating Literacy Download:</b><p>
RUNNING $prog<p>
<span id="messageSpan" style="color:#880000;"></span>
+++

	$self->print_buffer;
	
	my $foldername = '';
	
	my $count = 0;

	open(README, "$prog |") or die "Can't run program: $!\n";

	while(<README>)
	{
		my $line = $_;
		
		if($line =~ /adding:/i) { next; }
		
		chomp($line);
		
		$foldername = $line;
		
		$count++;
		
		if(($count>=10)||($line =~ /^\*/))
		{
			print<<"+++";
<script>a("$line<br>");</script>
+++

			$count = 0;
			
			$self->print_buffer;
		}
	}

	close(README);

	print<<"+++";
<script>r("<a href='/files/temp/$foldername/literacy.zip'>Click here for the ZIP download!!!</a>");</script>
+++

	$self->print_buffer;

	$self->{page_content} = '_no_header';
	return '_no_header';	
}

sub root__flatten_ftp_sync_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $hostname = $self->hostname;
	my $document_root = $ENV{DOCUMENT_ROOT};
	my $script_root = $document_root;
	
	$script_root =~ s/player\/www/player\/scripts/i;
	$script_root =~ s/\/$//;
	
	$| = 1;
	
	print "Content-type: text/html\n\n";

	my $prog = "perl $script_root/sync_ftp.pl $document_root $hostname";

	print<<"+++";
<html>
<head>
<script>
	function r(st)
	{
		document.getElementById('messageSpan').innerHTML = st;
	}

	function a(st)
	{
		var newSt = st + document.getElementById('messageSpan').innerHTML;
		
		if(newSt.length>1024)
		{
			newSt = newSt.substring(0, 1024);
		}
		
		document.getElementById('messageSpan').innerHTML = newSt;
	}
</script>
</head>
<body>
<b>Generating Literacy Download:</b><p>
RUNNING $prog<p>
<span id="messageSpan" style="color:#880000;"></span>
+++

	$self->print_buffer;
	
	my $foldername = '';
	
	my $count = 0;

	open(README, "$prog |") or die "Can't run program: $!\n";

	while(<README>)
	{
		my $line = $_;
		
		if($line =~ /adding:/i) { next; }
		
		chomp($line);
		
		$foldername = $line;
		
		$count++;
		
		if(($count>=10)||($line =~ /^\*/))
		{
			print<<"+++";
<script>a("$line<br>");</script>
+++

			$count = 0;
			
			$self->print_buffer;
		}
	}

	close(README);

	print<<"+++";
<script>r("DONE!");</script>
+++

	$self->print_buffer;

	$self->{page_content} = '_no_header';
	return '_no_header';	
}

sub root__flatten_digital_brain_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $hostname = $self->hostname;
	my $document_root = $ENV{DOCUMENT_ROOT};
	my $script_root = $document_root;
	
	$script_root =~ s/player\/www/player\/scripts/i;
	$script_root =~ s/\/$//;
	
	$| = 1;
	
	print "Content-type: text/html\n\n";

	my $prog = "perl $script_root/flatten_digital_brain.pl $document_root $hostname";

	print<<"+++";
<html>
<head>
<script>
	function r(st)
	{
		document.getElementById('messageSpan').innerHTML = st;
	}

	function a(st)
	{
		var newSt = st + document.getElementById('messageSpan').innerHTML;
		
		if(newSt.length>1024)
		{
			newSt = newSt.substring(0, 1024);
		}
		
		document.getElementById('messageSpan').innerHTML = newSt;
	}
</script>
</head>
<body>
<b>Generating Digital Brain Download:</b><p>
RUNNING $prog<p>
<span id="messageSpan" style="color:#880000;"></span>
+++

	$self->print_buffer;
	
	my $foldername = '';
	
	my $count = 0;

	open(README, "$prog |") or die "Can't run program: $!\n";

	while(<README>)
	{
		my $line = $_;
		
		chomp($line);
		
		$foldername = $line;
		
		$count++;
		
		#if(($count>=10)||($line =~ /^\*/))
		#{
			print<<"+++";
<script>a("$line<br>");</script>
+++

			$count = 0;
			
			#$self->print_buffer;
		#}
	}

	close(README);

	print<<"+++";
<script>r("<a href='/files/temp/$foldername/digitalbrain.zip'>Click here for the ZIP download!!!</a>");</script>
+++

	$self->print_buffer;

	$self->{page_content} = '_no_header';
	return '_no_header';	
}

sub root__flatten_cd_account_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }
	
	my $account_id = $self->{params}->{account_id};
	my $hostname = $self->hostname;
	my $document_root = $ENV{DOCUMENT_ROOT};
	my $script_root = $document_root;
	
	$script_root =~ s/player\/www/player\/scripts/i;
	$script_root =~ s/\/$//;
	
	$| = 1;
	
	print "Content-type: text/html\n\n";

	my $prog = "perl $script_root/flatten_cd_account.pl $account_id $document_root $hostname";

	print<<"+++";
<html>
<head>
<script>
	function r(st)
	{
		document.getElementById('messageSpan').innerHTML = st;
	}

	function a(st)
	{
		var newSt = st + document.getElementById('messageSpan').innerHTML;
		
		if(newSt.length>1024)
		{
			newSt = newSt.substring(0, 1024);
		}
		
		document.getElementById('messageSpan').innerHTML = newSt;
	}
</script>
</head>
<body>
<b>Generating Website:</b><p>
RUNNING $prog<p>
<span id="messageSpan" style="color:#880000;"></span>
+++

	$self->print_buffer;
	
	my $foldername = '';
	
	my $count = 0;

	open(README, "$prog |") or die "Can't run program: $!\n";

	while(<README>)
	{
		my $line = $_;
		
		chomp($line);
		
		if($line =~ /\(deflated/) { next; }
		
		$foldername = $line;
		
		$count++;
		
		if(($count>=10)||($line =~ /^\*/))
		{
			print<<"+++";
<script>a("$line<br>");</script>
+++

			$count = 0;
			
			$self->print_buffer;
		}
	}

	close(README);

	print<<"+++";
<script>r("<a href='/files/temp/$foldername/playercd.zip'>Click here for the ZIP download!!!</a>");</script>
+++

	$self->print_buffer;

	$self->{page_content} = '_no_header';
	return '_no_header';
}

sub print_buffer
{
	my ($self) = @_;
	
	if($self->{_buffer})
	{
		print $self->{_buffer};
		return;
	}
	
	my $ret = '';
	my $buffer = '';
	
	for(my $i=0; $i<=1024; $i++)
	{
		$buffer .= ' ';
	}
	
	for(my $i=0; $i<=64; $i++)
	{
		$ret .=	$buffer;
	}
	
	$self->{_buffer} = $ret;
	print $ret;
}


sub root__duplicate_account_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $self->{params}->{account_id} });
			
	$account->load_children('Webkit::Player::PurchaseRecord');
	
	my $new_account = $account->clone;
	$new_account->name($self->{params}->{new_name});
	$new_account->org($self->{params}->{new_name});
	$new_account->registered(Webkit::DateTime->now);
	
	$self->{db}->begin_transaction;
	
	$new_account->create;
	
	foreach my $record (@{$account->ensure_child_array('purchase_record')})
	{
		my $new_record = $record->clone;
		$new_record->account_id($new_account->get_id);
		$new_record->set_value('invoice_id', '');
		
		$new_record->create;
	}
	
	$self->{db}->commit;
	
	$self->return_response;
}

sub root__save_account_handler
{
	my ($self, $account_type) = @_;

	if(!$self->root_login) { return; }

	if($account_type!~/\w/) { $account_type = 'seller'; }

	my $account;
	my $user;

	if($self->{params}->{user_id}>0)
	{
		$user = Webkit::Player::User->load($self->{db}, {
			id => $self->{params}->{user_id} });

		if($user->installation_id!=$self->installation_id)
		{
			$self->return_error("Wrong Installation");
			return;
		}
	}
	else
	{
		$user = Webkit::Player::User->constructor($self->{db});	
		$user->installation_id($self->installation_id);
		$user->created(Webkit::DateTime->now);
	}

	if($self->{params}->{account_id}>0)
	{
		$account = Webkit::Player::Account->load($self->{db}, {
			id => $self->{params}->{account_id} });

		if($account->installation_id!=$self->installation_id)
		{
			$self->return_error("Wrong Installation");
			return;
		}
	}
	else
	{
		if($user->exists)
		{
			$account = $user->load_account;
		}
		else
		{
			$account = Webkit::Player::Account->constructor($self->{db});
			$account->installation_id($self->installation_id);
			$account->account_type($account_type);
			$account->registered(Webkit::DateTime->now);
		}
	}

	$account->name($self->{params}->{account_name});
	$account->url($self->{params}->{url});

	$user->username($self->{params}->{username});
	$user->password($self->{params}->{password});
	
	my ($firstname, @surnames) = split(/ /, $self->{params}->{users_name});
	
	my $surname = join(' ', @surnames);
	
	if($surname !~ /\w/)
	{
		$surname = 'user';
	}

	$user->firstname($firstname);
	$user->surname($surname);

	if(!$self->{params}->{account_id}>0)
	{
		if($account->error)
		{
			$self->return_error($account->{error_text});
			return;
		}
	}

	if($user->error)
	{
		$self->return_error($user->{error_text});
		return;
	}

	$self->{db}->begin_transaction;

	$account->save_or_create;

	if(!$user->exists)
	{
		$user->account_id($account->get_id);
	}

	$user->save_or_create;

	$self->{db}->commit;

	$self->return_response;
}

sub root__delete_account_handler
{
	my ($self) = @_;

	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $self->{params}->{account_id} });

	if($account->installation_id!=$self->installation_id)
	{
		$self->return_error("Wrong Installation");
		return;
	}

	$self->{db}->begin_transaction;

	$account->delete_children('Webkit::Player::User');
	$account->delete_children('Webkit::Player::PurchaseRecord');
	
	my $account_id = $account->get_id;
	
	Webkit::Player::AccountLink->delete_with_clause($self->{db}, {
		clause => "child_id = $account_id" });

	$account->delete;

	$self->{db}->commit;

	$self->return_response;
}

sub root__delete_user_handler
{
	my ($self) = @_;

	my $user = Webkit::Player::User->load($self->{db}, {
		id => $self->{params}->{user_id} });
			
	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $user->account_id });
		
	$account->load_children('Webkit::Player::User');
	
	my $count = $account->get_child_count('user');

	if($user->installation_id!=$self->installation_id)
	{
		$self->return_error("Wrong Installation");
		return;
	}

	$self->{db}->begin_transaction;
	
	if($count<=1)
	{
		$account->delete_children('Webkit::Player::User');
		$account->delete_children('Webkit::Player::PurchaseRecord');
		$account->delete;
	}
	else
	{
		$user->delete;
	}

	$self->{db}->commit;

	$self->return_response;
}


########################################################################################
########################################################################################
######################
# SELLERS

sub root__load_sellers_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }

	$self->root__load_accounts_handler('seller');
}

sub root__save_seller_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }

	$self->root__save_account_handler('seller');
}

########################################################################################
########################################################################################
######################
# CUSTOMERS

sub root__load_customer_account_types_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }
	
	my $ret = [];
	
	my $refs = $self->{db}->get_select_refs({
		table => 'player.account',
		cols => 'count(*) as count, account_type',
		clause => 'installation_id = ? and (account_type != ? and account_type != ?)',
		binds => [$self->installation_id, 'root', 'seller'],
		group => 'account_type',
		order => 'account_type' });
		
	my $flag_refs = $self->{db}->get_select_refs({
		table => 'player.account',
		cols => 'count(*) as count, account_flag',
		clause => 'installation_id = ? and (account_type != ? and account_type != ?)',
		binds => [$self->installation_id, 'root', 'seller'],
		group => 'account_flag',
		order => 'account_flag' });
		
	foreach my $ref (@$refs)
	{
		push(@$ret, $ref);
	}
	
	foreach my $ref (@$flag_refs)
	{
		if($ref->{account_flag}!~/\w/) { next; }
		
		$ref->{account_type} = 'flag:'.$ref->{account_flag};
		
		push(@$ret, $ref);
	}
		
	$self->return_response($ret);
}

sub root__load_account_links_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $self->{params}->{account_id} });	
			
	$account->load_account_link_summary;
	
	my $data = [];
	
	foreach my $link (@{$account->ensure_child_array('account_link')})
	{
		push(@$data, {
			id => $link->get_id,
			linked_from => $link->{linked_from},
			linked_to => $link->{linked_to},
			link_created => $link->{link_created},
			link_type => $link->link_type });
	}
	
	my $count = @{$data};

	$self->return_response({
		itemCount => $count,
		items => $data });	
}

sub root__load_purchase_records_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $self->{params}->{account_id} });	
	
	my $views = Webkit::Player::Views->new($self->{db}, $self->installation_id, $account->menu_to_use);
	
	$account->load_purchase_record_summary($views);
	
	my $data = [];
	
	foreach my $record (@{$account->ensure_child_array('purchase_record')})
	{
		my $has_invoice = '';
		
		if($record->invoice_id>0)
		{
			$has_invoice = 'yes';
		}
		
		push(@$data, {
			id => $record->get_id,
			collection_id => $record->collection_id,
			invoice_id => $record->invoice_id,
			has_invoice => $has_invoice,
			product_name => $record->{data}->{product_name},
			purchase_type => $record->purchase_type,
			purchase_amount => $record->purchase_amount,
			purchase_date => $record->get_purchase_date_summary,
			subscription_start => $record->get_date_formatted($record->subscription_start),
			subscription_end => $record->get_date_formatted($record->subscription_end),
			subscription_dates => $record->get_subscription_dates_summary });
	}
	
	my $count = @{$data};

	$self->return_response({
		itemCount => $count,
		items => $data });	
}

sub root__load_invoices_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $self->{params}->{account_id} });	
	
	my $views = Webkit::Player::Views->new($self->{db}, $self->installation_id, $account->menu_to_use);
	
	$account->load_invoices_summary($views);
	
	my $data = [];
	
	foreach my $invoice (@{$account->ensure_child_array('invoice')})
	{
		push(@$data, {
			id => $invoice->get_id,
			product_name => $invoice->get_product_name_summary,
			date_sent => $invoice->get_date_sent_summary,
			date_paid => $invoice->get_date_paid_summary,
			amount_for => $invoice->amount_for,
			discount => $invoice->discount,
			order_number => $invoice->order_number,
			invoice_number => $invoice->invoice_number,
			notes => $invoice->notes });
	}
	
	my $count = @{$data};

	$self->return_response({
		itemCount => $count,
		items => $data });	
}

sub root__accept_moderation_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }

	$self->load_installation;
	
	my $moderation = Webkit::Player::Moderation->load($self->{db}, {
		id => $self->{params}->{moderation_id} });	
			
	$self->{db}->begin_transaction;
	
	$moderation->accept($self->{user}, $self->{account});
	
	$moderation->moderated_by($self->{user}->get_id);
	$moderation->moderated_date(Webkit::DateTime->now);
	
	$moderation->save;
	
	$self->{db}->commit;
	
	$self->return_response({
		moderation_id => $moderation->get_id });
}

sub root__load_moderation_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	$self->load_installation;
	
	$self->{installation}->add_children('Webkit::Player::Moderation', {
		table => 'player.moderation, player.user, player.account LEFT JOIN player.ou ON moderation.ou_id = ou.id',
		cols => 'moderation.*, user.firstname as firstname, user.surname as surname, account.name as account_name, ou.name as ou_name',
		clause => 'moderation.moderated_date IS NULL and moderation.user_id = user.id and moderation.account_id = account.id',
		group => 'moderation.id',
		order => 'moderation.created DESC' });
	
	my $data = [];
	
	foreach my $moderation (@{$self->{installation}->ensure_child_array('moderation')})
	{
		my $username_parts = [];
		
		if($moderation->{data}->{firstname}=~/\w/)
		{
			push(@$username_parts, $moderation->{data}->{firstname});
		}
		
		if($moderation->{data}->{surname}=~/\w/)
		{
			push(@$username_parts, $moderation->{data}->{surname});
		}
		
		my $username = join(' ', @$username_parts);
		
		push(@$data, {
			id => $moderation->get_id,
			user_id => $moderation->user_id,
			account_id => $moderation->account_id,
			username => $username,
			ou_id => $moderation->ou_id,
			ou_name => $moderation->{data}->{ou_name},
			account_name => $moderation->{data}->{account_name},
			created => $moderation->get_created_summary,
			action_type => $moderation->action_type,
			action_data => $moderation->action_data,
			summary => $moderation->get_summary
		});
	}
	
	my $count = @{$data};

	$self->return_response({
		itemCount => $count,
		items => $data });	
}

sub root__load_users_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $self->{params}->{account_id} });	
			
	$account->load_children('Webkit::Player::User');
				
	my $data = [];				
	
	foreach my $user (@{$account->ensure_child_array('user')})
	{
		push(@$data, {
			id => $user->get_id,
			fullname => $user->get_name,
			username => $user->username,
			jobtitle => $user->jobtitle,
			firstname => $user->firstname,
			surname => $user->surname,
			password => $user->password,
			title => $user->title });
	}
	
	my $count = @{$data};

	$self->return_response({
		itemCount => $count,
		items => $data });	
}

sub root__load_customers_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }
	
	my $binds = ['root', 'seller', $self->installation_id];
	
	my $clause=<<"+++";
(account_type != ? and account_type != ?) and account.installation_id = ?	
+++

	if($self->{params}->{account_type} =~ /\w/)
	{
		$clause.=<<"+++";
and account_type = ?
+++

		push(@$binds, $self->{params}->{account_type});
	}
	
	if($self->{params}->{account_flag} =~ /\w/)
	{
		$clause.=<<"+++";
and account_flag = ?
+++

		push(@$binds, $self->{params}->{account_flag});
	}	
	
	if($self->{params}->{name} =~ /\w/)
	{
		$clause.=<<"+++";
and name like ?
+++

		push(@$binds, '%'.$self->{params}->{name}.'%');
	}
	
	if($self->{params}->{start}!~/\w/)
	{
		$self->{params}->{start} = 0;
	}
	
	if($self->{params}->{limit}!~/\w/)
	{
		$self->{params}->{limit} = 25;
	}
	
	my $limit = $self->{params}->{start}.','.$self->{params}->{limit};

	$self->{installation}->load_children('Webkit::Player::Account', {
		clause => $clause,
		binds => $binds,
		limit => $limit,
		order => 'name' });
		
	my $count_ref = $self->{db}->get_select_ref({
		table => 'player.account',
		cols => 'count(*) as count',
		clause => $clause,
		binds => $binds });

	$self->{installation}->add_children('Webkit::Player::User', {
		table => 'player.user, player.account',
		cols => 'user.*',
		clause => "user.account_id = account.id and $clause",
		binds => $binds,
		order => 'user.firstname, user.surname' });

	my $data = [];

	foreach my $user (@{$self->{installation}->ensure_child_array('user')})
	{
		my $account = $self->{installation}->get_child('account', $user->account_id);

		if(!$account) { next; }
		
		$account->add_child($user);
	}
	
	my $default_map = Webkit::Player::Installation->get_default_account_settings_map;

	foreach my $account (@{$self->{installation}->ensure_child_array('account')})
	{
		$account->{_users_loaded} = 1;
		
		$account->build_account_settings($default_map);
		
		push(@$data, {
			id => $account->get_id,
			account_type => $account->account_type,
			registered => $account->get_registered_summary,
			display_name => $account->get_account_name,
			account_name => $account->name,
			org => $account->org,
			url => $account->url,
			address => $account->get_address_summary,
			city => $account->city,
			country => $account->country,
			postcode => $account->postcode,
			account_notes => $account->account_notes,
			small_school => $account->small_school,
			account_flag => $account->account_flag,
			menu_to_use => $account->get_account_setting('menu_to_use'),
			starting_view => $account->get_account_setting('starting_view'),
			users_names => $account->get_users_names });
	}

	my $count = @{$data};

	$self->return_response({
		itemCount => $count_ref->{count},
		items => $data });
}

sub root__save_user_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }	
	
	my $user = Webkit::Player::User->constructor($self->{db});
	
	if($self->{params}->{id}>0)
	{
		$user = Webkit::Player::User->load($self->{db}, {
			id => $self->{params}->{id} });
	}
	else
	{
		$user->installation_id($self->installation_id);
		$user->account_id($self->{params}->{account_id});		
		$user->created(Webkit::DateTime->now);
	}
	
	$user->firstname($self->{params}->{firstname});
	$user->surname($self->{params}->{surname});
	$user->username($self->{params}->{username});
	$user->password($self->{params}->{password});
	$user->jobtitle($self->{params}->{jobtitle});
	$user->title($self->{params}->{title});
	
	if($user->password!~/\w/)
	{
		$user->password('password');
	}
	
	if($user->username!~/\w/)
	{
		$user->username('username');
	}
	
	if($user->firstname!~/\w/)
	{
		$user->firstname('firstname');
	}
	
	if($user->surname!~/\w/)
	{
		$user->surname('surname');
	}		
	
	$self->{db}->begin_transaction;
	
	$user->save_or_create;
	
	$self->{db}->commit;
	
	$self->return_response({});
}

sub root__save_customer_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }

	my $customer = Webkit::Player::Account->constructor($self->{db});
	
	if($self->{params}->{id}>0)
	{
		$customer = Webkit::Player::Account->load($self->{db}, {
			id => $self->{params}->{id} });
	}
	else
	{
		$customer->installation_id($self->installation_id);
		$customer->registered(Webkit::DateTime->now);
	}
	
	$customer->account_type($self->{params}->{account_type});
	$customer->name($self->{params}->{name});
	$customer->org($self->{params}->{org});
	$customer->city($self->{params}->{city});
	$customer->country($self->{params}->{country});
	$customer->postcode($self->{params}->{postcode});
	
	$customer->account_notes($self->{params}->{account_notes});
	$customer->account_flag($self->{params}->{account_flag});
	$customer->small_school($self->{params}->{small_school});
	
	#$customer->url($self->{params}->{url});
	$customer->save_url($self->{params}->{url});
	
	my $val = $self->{params}->{menu_to_use};
	if(($val eq 'menu_to_use')||($val eq ''))
	{
		$customer->remove_account_setting('menu_to_use');
	}
	else
	{
		$customer->replace_account_setting('menu_to_use', $self->{params}->{menu_to_use});
	}
	
	$val = $self->{params}->{starting_view};
	if(($val eq 'starting_view')||($val eq ''))
	{
		$customer->remove_account_setting('starting_view');
	}
	else
	{
		$customer->replace_account_setting('starting_view', $self->{params}->{starting_view});
	}
	
	$self->{db}->begin_transaction;
	
	$customer->save_or_create;
	
	$self->{db}->commit;
	
	$self->return_response({});
}

sub root__list_subscriptions_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $views = Webkit::Player::Views->new($self->{db}, $self->installation_id);
	
	my $arr = $views->get_array_of_view_info;
	
	my $data = [];
	
	foreach my $entry (@$arr)
	{
		push(@$data, [$entry->{id},$entry->{name}]);
	}
	
	$self->return_response($data);
}

########################################################################################
########################################################################################
######################
# VIEWS

sub root__get_views_xml_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }

	my $installation = Webkit::Player::Installation->load($self->{db}, {
		id => $self->installation_id });

	$self->return_response({
		xml => $installation->views
	});
}

sub root__save_views_xml_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }

	my $installation = Webkit::Player::Installation->load($self->{db}, {
		id => $self->installation_id });

	$installation->views($self->{params}->{xml});

	$self->{db}->begin_transaction;

	$installation->save;

	$self->{db}->commit;

	$self->return_response;
}

sub root__get_default_account_settings_xml_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }

	my $installation = Webkit::Player::Installation->load($self->{db}, {
		id => $self->installation_id });

	$self->return_response({
		xml => $installation->default_account_settings
	});
}

sub root__save_default_account_settings_xml_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }

	my $installation = Webkit::Player::Installation->load($self->{db}, {
		id => $self->installation_id });

	$installation->default_account_settings($self->{params}->{xml});

	$self->{db}->begin_transaction;

	$installation->save;

	$self->{db}->commit;
	
	my $path = Webkit::Player::Installation->get_default_account_settings_path;
	
	open(OUT, ">$path");
	
	print OUT $self->{params}->{xml};
	
	close(OUT);

	$self->return_response;
}

sub root__feedback_entries_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	$self->load_installation;
	
	$self->{installation}->load_children('Webkit::Player::ActivityFeedback', {
		order => 'created' });
		
	$self->{installation}->add_children('Webkit::Player::OU', {
		table => 'player.ou, player.activity_feedback',
		cols => 'ou.*',
		clause => 'ou.installation_id = ? and activity_feedback.ou_id = ou.id',
		binds => [$self->{installation}->get_id] });
		
	my $arr = [];
	
	foreach my $feedback (@{$self->{installation}->ensure_child_array('activity_feedback')})
	{
		my $ou = $self->{installation}->get_child('ou', $feedback->ou_id);
		
		my $ou_name = '';
		
		if($ou)
		{
			$ou_name = $ou->name;
		}
		
		my $created = $feedback->created->get_string;
		
		$created =~ s/^(\d+)\/(\d+)\/(\d+) (.*?)$/$3\/$2\/$1 $4/;
		
		push(@$arr, {
			id => $feedback->get_id,
			ou_name => $ou_name,
			created => $created,
			name => $feedback->name,
			email => $feedback->email,
			rating => $feedback->rating,
			feedback => Webkit::AppTools->remove_non_standard_characters($feedback->feedback),
			feedback_type => $feedback->feedback_type });		
	}
	
	my $count = @$arr;
	
	$self->return_response({
		itemCount => $count,
		items => $arr });	
}

sub root__save_feedback_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $feedback = Webkit::Player::ActivityFeedback->constructor($self->{db});
	
	if($self->{params}->{id}>0)
	{
		$feedback = Webkit::Player::ActivityFeedback->load($self->{db}, {
			id => $self->{params}->{id} });
	}
	else
	{
		$feedback->installation_id($self->installation_id);
	}
	
	$feedback->name($self->{params}->{name});
	$feedback->email($self->{params}->{email});
	$feedback->feedback($self->{params}->{feedback});
	$feedback->rating($self->{params}->{rating});
	
	$self->{db}->begin_transaction;
	
	$feedback->save_or_create;
	
	$self->{db}->commit;
	
	$self->return_response({});
}

sub root__delete_feedback_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $feedback = Webkit::Player::ActivityFeedback->load($self->{db}, {
		id => $self->{params}->{feedback_id} });	
			
	$self->{db}->begin_transaction;
	
	$feedback->delete;
	
	$self->{db}->commit;
	
	$self->return_response({});
}


sub root__save_purchase_record_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $record = Webkit::Player::PurchaseRecord->constructor($self->{db});
	
	if($self->{params}->{id}>0)
	{
		$record = Webkit::Player::PurchaseRecord->load($self->{db}, {
			id => $self->{params}->{id} });
	}
	else
	{
		$record->installation_id($self->installation_id);
		$record->account_id($self->{params}->{account_id});
		$record->purchase_type('subscription');
	}
	
	$record->collection_id($self->{params}->{collection_id});
	$record->purchase_amount($self->{params}->{purchase_amount});
	$record->purchase_date($self->get_date_obj_from_param_value($self->{params}->{purchase_date}));
	$record->subscription_start($self->get_date_obj_from_param_value($self->{params}->{subscription_start}));
	$record->subscription_end($self->get_date_obj_from_param_value($self->{params}->{subscription_end}));
	
	$self->{db}->begin_transaction;
	
	$record->save_or_create;
	
	$self->{db}->commit;
	
	$self->return_response({});
}

sub root__delete_purchase_record_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $record = Webkit::Player::PurchaseRecord->load($self->{db}, {
		id => $self->{params}->{purchase_record_id} });	
			
	$self->{db}->begin_transaction;
	
	$record->delete;
	
	$self->{db}->commit;
	
	$self->return_response({});
}

sub root__save_invoice_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $invoice = Webkit::Player::Invoice->constructor($self->{db});
	
	if($self->{params}->{id}>0)
	{
		$invoice = Webkit::Player::Invoice->load($self->{db}, {
			id => $self->{params}->{id} });
	}
	else
	{
		$invoice->installation_id($self->installation_id);
		$invoice->account_id($self->{params}->{account_id});
	}

	$invoice->amount_for($self->{params}->{amount_for});
	$invoice->discount($self->{params}->{discount});
	$invoice->invoice_number($self->{params}->{invoice_number});
	$invoice->order_number($self->{params}->{order_number});
	$invoice->notes($self->{params}->{notes});
	$invoice->date_sent($self->get_date_obj_from_param_value($self->{params}->{date_sent}));
	$invoice->date_paid($self->get_date_obj_from_param_value($self->{params}->{date_paid}));
	
	$self->{db}->begin_transaction;
	
	$invoice->save_or_create;
	
	if($self->{params}->{linked_purchase_record_id}>0)
	{
		my $purchase_record = Webkit::Player::PurchaseRecord->load($self->{db}, {
			id => $self->{params}->{linked_purchase_record_id} });
				
	
		$purchase_record->invoice_id($invoice->get_id);
		
		$purchase_record->save;			
	}
	
	$self->{db}->commit;
	
	$self->return_response({});
}

sub root__delete_invoice_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $invoice = Webkit::Player::Invoice->load($self->{db}, {
		id => $self->{params}->{invoice_id} });
			
	my $purchase_record = Webkit::Player::PurchaseRecord->load($self->{db}, {
		clause => 'invoice_id = ?',
		binds => [$invoice->get_id] });
			
	$self->{db}->begin_transaction;
	
	$invoice->delete;
	
	if($purchase_record)
	{
		$purchase_record->set_value('invoice_id', '');
		
		$purchase_record->save;
	}
	
	$self->{db}->commit;
	
	$self->return_response({});
}

########################################################################################
########################################################################################
######################
# LOGS

sub root__load_log_entries_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	$self->load_installation;

	my $binds = [$self->installation_id];
	my $date_clause = '';
	
	my $clause=<<"+++";
log.installation_id = ?
+++
	
	if(($self->{params}->{from}=~/\w/)&&($self->{params}->{to}=~/\w/))
	{
		$date_clause=<<"+++";
(
	log.event_date >= ?
	and
	log.event_date <= ?
)
+++

		my $from_date_obj = $self->get_date_obj_from_param_value($self->{params}->{from});
		my $to_date_obj = $self->get_date_obj_from_param_value($self->{params}->{to});

		push(@$binds, Webkit::Date->parse_to_sql($from_date_obj));
		push(@$binds, Webkit::Date->parse_to_sql($to_date_obj));
	}
	elsif($self->{params}->{to}=~/\w/)
	{
		$date_clause=<<"+++";
	log.event_date <= ?
+++

		my $to_date_obj = $self->get_date_obj_from_param_value($self->{params}->{to});

		push(@$binds, Webkit::Date->parse_to_sql($to_date_obj));		
	}
	elsif($self->{params}->{from}=~/\w/)
	{
		$date_clause=<<"+++";
	log.event_date >= ?
+++

		my $from_date_obj = $self->get_date_obj_from_param_value($self->{params}->{from});

		push(@$binds, Webkit::Date->parse_to_sql($from_date_obj));		
	}
	
	if($date_clause=~/\w/)
	{
		$clause.=<<"+++";
and
(
	$date_clause
)	
+++
	}
	
	$self->{installation}->add_children('Webkit::Player::Log', {
		table => 'player.log LEFT JOIN player.ou ON log.ou_id = ou.id',
		cols => 'log.*, ou.name as activity_name',
		clause => $clause,
		binds => $binds,
		group => 'log.id',
		order => 'log.event_date DESC' });
		
	$self->{installation}->load_children('Webkit::Player::Account', {
		table => 'player.account' });
		
	$self->{installation}->load_children('Webkit::Player::User', {
		table => 'player.user' });
		
	foreach my $user (@{$self->{installation}->ensure_child_array('user')})
	{
		my $account = $self->{installation}->get_child('account', $user->account_id);
		
		if(!$account)
		{
			$account->add_child($user);
			$account->{_users_loaded} = 1;		
		}
	}
		
	my $arr = [[
		'id',
		'account_name',
		'activity_name',
		'event_date',
		'referer',
		'ip_address',
		'event_type' ]];
	
	foreach my $log (@{$self->{installation}->ensure_child_array('log')})
	{
		my $account_name = '';
		
		if($log->account_id>0)
		{
			my $account = $self->{installation}->get_child('account', $log->account_id);
			
			if($account)
			{
				$account_name = $account->get_account_name;
			}
		}
		
		push(@$arr, [
			$log->get_id,
			$account_name,
			$log->{data}->{activity_name},
			$log->get_event_date_summary,
			$log->referer,
			$log->ip_address,
			$log->event_type ]);
	}
	
	my $csv = "";
	
	foreach my $entry (@$arr)
	{
		my $line = join(',', @$entry);
		
		$csv .= "$line\n";
	}
	
	my $length = length($csv);

	print "Content-length: $length\n";
	print "Content-Disposition: attachment; filename=logs.csv;\n";
	print "Content-type: text/csv\n\n";

	print $csv;

	$self->{page_content} = '_no_header';
	return '_no_header';	
}

########################################################################################
########################################################################################
######################
# TEXT ENTRIES

sub root__load_text_entries_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	$self->load_installation;
	
	$self->{installation}->load_children('Webkit::Player::TextEntry', {
		order => 'name, language' });
		
	$self->{installation}->add_children('Webkit::Player::Account', {
		table => 'player.account, player.text_entry',
		cols => 'account.*',
		clause => 'text_entry.account_id = account.id and text_entry.installation_id = ?',
		binds => [$self->installation_id] });
		
	my $arr = [];
	
	foreach my $text_entry (@{$self->{installation}->ensure_child_array('text_entry')})
	{
		my $account_name = '';
		
		if($text_entry->account_id>0)
		{
			my $account = $self->{installation}->get_child('account', $text_entry->account_id);
			
			$account_name = $account->get_account_name;
		}
		
		push(@$arr, {
			id => $text_entry->get_id,
			name => $text_entry->name,
			language => $text_entry->language,
			account_type => $text_entry->account_type,
			content => $text_entry->content,
			account_id => $text_entry->account_id,
			account_name => $account_name });
	}
	
	my $count = @$arr;
	
	$self->return_response({
		itemCount => $count,
		items => $arr });		
}

sub root__save_text_entry_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $entry = Webkit::Player::TextEntry->constructor($self->{db});
	
	if($self->{params}->{id}>0)
	{
		$entry = Webkit::Player::TextEntry->load($self->{db}, {
			id => $self->{params}->{id} });
	}
	else
	{
		$entry->installation_id($self->installation_id);
	}
	
	$entry->name($self->{params}->{name});
	$entry->account_type($self->{params}->{account_type});
	$entry->language($self->{params}->{language});
	$entry->account_id($self->{params}->{account_id});
	$entry->content($self->{params}->{content});
	
	$self->{db}->begin_transaction;
	
	$entry->save_or_create;
	
	$self->{db}->commit;
	
	$self->return_response({});
}

sub root__delete_text_entry_handler
{
	my ($self) = @_;
	
	if(!$self->root_login) { return; }
	
	my $entry = Webkit::Player::TextEntry->load($self->{db}, {
		id => $self->{params}->{text_entry_id} });	
			
	$self->{db}->begin_transaction;
	
	$entry->delete;
	
	$self->{db}->commit;
	
	$self->return_response;
}

sub root__text_entry_names_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }
	
	my $data = $self->{db}->get_select_refs({
		table => 'player.text_entry',
		cols => 'text_entry.name as name',
		clause => "installation_id = ?",
		binds => [$self->installation_id],
		group => 'text_entry.name',
		order => 'text_entry.name' });

	my $arr = [];

	if(!$data) { $data = []; }

	foreach my $ref (@$data)
	{
		push(@$arr, [$ref->{name}]);
	}

	$self->return_response($arr);
}

sub root__text_entry_account_types_handler
{
	my ($self) = @_;

	if(!$self->root_login) { return; }
	
	my $account_types_array = Webkit::Player::Account->get_array_of_account_types;
	
	my $arr = [];
	
	foreach my $type (@$account_types_array)
	{
		push(@$arr, [$type]);
	}

	$self->return_response($arr);
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# ADMIN APP
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub admin__index_handler
{
	my ($self) = @_;

	my $js_dev = 'false';

	if($self->dev_mode)
	{
		$js_dev = 'true';
	}
	
	my $installation = $self->load_installation;

	$self->{page_props}->{dev_mode} = $js_dev;
	$self->{page_props}->{installation_name} = $installation->name;
}

########################################################################################
########################################################################################
######################
# LOGIN

sub admin_login
{
	my ($self) = @_;

	if($self->{logged_in}) { return 1; }

	if((!$self->do_login)||(!$self->{user}))
	{
		$self->return_error('Incorrect login details');

		return;
	}

	if(!$self->{account}->is_seller)
	{
		$self->return_error('Insufficient access level');

		return;
	}

	$self->{logged_in} = 1;

	return 1;
}

sub admin__login_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $user_data = $self->{user}->{data};
	delete($user_data->{password});

	my $account_data = $self->{account}->{data};

	$self->return_response({
		user_data => $user_data,
		account_data => $account_data,
		session_id => $self->{session}->session_id });
}

########################################################################################
########################################################################################
######################
# GENERAL DATA TOOLS

sub get_sub_ous
{
	my ($self, $ou_obj, $arr) = @_;

	if(!$arr) { $arr = []; }

	foreach my $child (@{$ou_obj->ensure_child_array('ou')})
	{
		$self->get_sub_ous($child, $arr);
	}

	push(@$arr, $ou_obj);

	return $arr;
}

sub load_ou_tree
{
	my ($self) = @_;

	if($self->{ou_tree_loaded}) { return; }
	$self->{ou_tree_loaded} = 1;

	$self->{account}->load_children('Webkit::Player::OU');

	foreach my $ou (@{$self->{account}->ensure_child_array('ou')})
	{
		if($ou->ou_id>0)
		{
			my $parent_ou = $self->{account}->get_child('ou', $ou->ou_id);

			$parent_ou->add_child($ou);
		}
		else
		{
			push(@{$self->{account}->{root_ous}}, $ou);
		}
	}
}

sub load_ou_tree_with_keywords
{
	my ($self) = @_;

	if($self->{ou_tree_keywords_loaded}) { return; }
	$self->{ou_tree_keywords_loaded} = 1;

	$self->load_ou_tree;

	$self->{account}->load_children('Webkit::Player::Keyword');

	foreach my $keyword (@{$self->{account}->ensure_child_array('keyword')})
	{
		my $ou = $self->{account}->get_child('ou', $keyword->ou_id);

		if($ou)
		{
			$ou->add_child($keyword);
		}
	}
}

########################################################################################
########################################################################################
######################
# TREE DATA

sub admin__ou_tree_data_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $clause=<<"+++";
installation_id = ?
and ou_id = ?
+++

	my $account_id = $self->{params}->{account_id};
	my $ou_id = $self->{params}->{node};

	if($ou_id eq 'root')
	{
		$ou_id = 0;
	}

	my $binds = [$self->installation_id, $ou_id];

	#### lets load the actual ou's
	$self->{installation}->load_children('Webkit::Player::OU', {
		clause => $clause,
		binds => $binds,
		order => 'name' });

	my $count_clause=<<"+++";
	ou.installation_id = ?
and
	ou.account_id = ?
and
	ou.ou_id = ?
and
	ou2.ou_id = ou.id
and
	ou2.ou_type != ?
+++

	my $count_binds = [$self->installation_id, $account_id, $ou_id, 'file'];

	#### now lets load the child count for each ou
	my $refs = $self->{db}->get_select_refs({
		cols => 'ou.id as id, count(*) as count',
		table => 'player.ou as ou, player.ou as ou2',
		clause => $count_clause,
		binds => $count_binds,
		group => 'ou.id' });

	if(!$refs) { $refs = []; }

	foreach my $ref (@$refs)
	{
		my $ou = $self->{installation}->get_child('ou', $ref->{id});

		$ou->{child_count} = $ref->{count};
	}

	my $tree = [];

	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		if($ou->is_playlist) { next; }
		
		my $leaf = $self->{json}->true;

		if($ou->{child_count}>0)
		{
			$leaf = $self->{json}->false;
		}

		push(@$tree, {
			id => $ou->get_id,
			ou_id => $ou->ou_id,
			text => $ou->name,
			leaf => $leaf,
			ou_type => $ou->ou_type,
			item_type => $ou->item_type });
	}

	$self->return_response($tree);
}

sub admin__report_no_storycode_handler
{
	my ($self) = @_;
	
	$self->{params}->{nostorycode} = 'y';
	
	my $ret = $self->load_ou_contents_data;
	
	my $t = [];
	
	foreach my $ou (@{$ret->{items}})
	{
		push(@$t, {
			id => $ou->{id},
			name => $ou->{name}
		});
	}
	
	$self->return_response($t);
}

sub admin__report_no_tag_handler
{
	my ($self) = @_;
	
	$self->{params}->{notag} = 'y';
	
	my $ret = $self->load_ou_contents_data;
	
	my $keyword_map = {
		'numStrategy_year' => '*',
		'maths_year_ks2' => '*',
		'history_year' => '*',
		'litStrategy_Year' => '*',
		'earlyYearsArea' => '*',
		'ict_year' => '*',
		're_year' => '*',
		'geog_year' => '*',
		'history_year' => '*',
		'sci_year' => '*',
		'literacy_topic_ks2' => '*',
		'literacy_topic' => '*'
	};
	
	my $keyword_value_map = {
		'subject' => 'Numeracy'
	};

	my $t = [];
	
	my $count = 0;
	
	foreach my $ou (@{$ret->{items}})
	{
		my $haskeyword = undef;
		
		foreach my $keyword_group (%{$ou->{keywords}})
		{
			foreach my $keyword_name (%{$ou->{keywords}->{$keyword_group}})
			{
				my $keyword_value = $ou->{keywords}->{$keyword_group}->{$keyword_name};
				
				if($keyword_map->{$keyword_name} eq '*' || ($keyword_name eq 'subject' && $keyword_value eq 'Numeracy'))
				{
					$haskeyword = 1;
					$ou->{_has_keyword} = $keyword_name;
				}
			}
		}
		
		$count++;
		
		if(!$haskeyword)
		{
			push(@$t, {
				id => $ou->{id},
				hit => $ou->{_has_keyword},
				name => $ou->{name}
			});
		}
	}
	
	$self->return_response($t);	
}

########################################################################################
########################################################################################
######################
# DATA VIEW

sub admin__ou_contents_data_handler
{
	my ($self) = @_;
	
	my $ret = $self->load_ou_contents_data;
	
	$self->return_response($ret);	
}

sub load_ou_contents_data
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }
	
	if($self->{params}->{view_id} =~ /\w/)
	{
		$self->admin__ou_view_contents_data_handler;

		return;	
	}
	
	$self->fully_load_installation;

	my $account_id = $self->{params}->{account_id};
	my $ou_id = $self->{params}->{ou_id};

	if($ou_id eq 'root')
	{
		$ou_id = 0;
	}
	
	my $binds = [$self->installation_id];

	my $clause=<<"+++";
ou.installation_id = ?
+++

	if($self->{params}->{id}=~/^\d+$/)
	{
		push(@$binds, $self->{params}->{id});
		push(@$binds, 'teaching_resource');
		
		$clause.=<<"+++";
and ou.id = ?
and ou.ou_type = ?
+++
	}
	elsif($self->{params}->{nostorycode}=~/\w/)
	{
		push(@$binds, 'teaching_resource');
		
		$clause.=<<"+++";
and ou.tes_url IS NULL
and ou.ou_type = ?
+++
	}
	elsif($self->{params}->{notag}=~/\w/)
	{
		push(@$binds, 'teaching_resource');
		
		$clause.=<<"+++";
and ou.ou_type = ?
+++
	}
	elsif($self->{params}->{search}=~/\w/)
	{
		push(@$binds, '%'.$self->{params}->{search}.'%');
		push(@$binds, 'teaching_resource');
		
		$clause.=<<"+++";
and ou.name like ?
and ou.ou_type = ?
+++
	}
	else
	{
		push(@$binds, $ou_id);
	
		$clause.=<<"+++";
and ou.ou_id = ?
+++
	}
	
	my $parent_type = 'teaching_resource';
		
	my $cols = "ou.*, ou2.item_path as thumbnail_url";
	my $table = "player.ou as ou LEFT JOIN player.ou as ou2 ON ou2.ou_id = ou.id and ou2.item_type = 'thumbnail' and ou.ou_type = 'teaching_resource'";
		
	if($self->{installation}->is_dictionary)
	{
		$parent_type = 'definition';
		$cols .= ", user.firstname as firstname, user.surname as surname, user.id as user_id";
		$table = "player.ou as ou LEFT JOIN player.ou as ou2 ON ou2.ou_id = ou.id and ou2.item_type = 'thumbnail' and ou.ou_type = 'definition' LEFT JOIN player.user on ou.user_id = user.id";
	}
		
	#### lets load the actual ou's + keywords
	$self->{installation}->add_children('Webkit::Player::OU', {
		cols => $cols,
		table => $table,
		clause => $clause,
		binds => $binds,
		order => 'name' });

	my $keyword_clause=<<"+++";
$clause
and keyword.ou_id = ou.id
+++

	$self->{installation}->add_children('Webkit::Player::Keyword', {
		table => 'player.ou, player.keyword',
		cols => 'keyword.*',
		clause => $keyword_clause,
		binds => $binds,
		group => 'keyword.id' });

	foreach my $keyword (@{$self->{installation}->ensure_child_array('keyword')})
	{
		my $ou = $self->{installation}->get_child('ou', $keyword->ou_id);

		$ou->add_child($keyword);
	}
	
	if(!$self->{installation}->is_dictionary)
	{
		my $searchword_clause=<<"+++";
$clause
and searchword.ou_id = ou.id
and searchword.word_type = 'searchword'
+++

		$self->{installation}->add_children('Webkit::Player::SearchWord', {
			table => 'player.ou, player.searchword',
			cols => 'searchword.*',
			clause => $searchword_clause,
			binds => $binds,
			group => 'searchword.id' });

		foreach my $searchword (@{$self->{installation}->ensure_child_array('searchword')})
		{
			my $ou = $self->{installation}->get_child('ou', $searchword->ou_id);

			$ou->add_child($searchword);
		}
	}

	my $ous = [];

	$self->{db}->begin_transaction;

	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		if($ou->is_playlist) { next; }
		#### lets get rid of any stray file ous that are hanging around with no parent
		if(($ou_id eq 'root')&&($ou->is_file))
		{
			$ou->delete;	
		}
		else
		{
			my $thumbnail = '';
				
			if($ou->{data}->{thumbnail_url}=~/\w/)
			{
				$thumbnail = '/files/'.$ou->{data}->{thumbnail_url};

				$thumbnail = '/images/image_content.app?image_path='.$thumbnail.'&size=100';
			}
			elsif($ou->item_type eq 'thumbnail')
			{
				$thumbnail = $ou->get_file_web_path;
				
				if($thumbnail=~/\.jpg$/i)
				{
					$thumbnail = '/images/image_content.app?image_path='.$thumbnail.'&size=100';
				}
			}
							
			if($self->{installation}->is_dictionary)
			{
				if($thumbnail=~/\w/)
				{
					
				}
				elsif($ou->get_keyword_value('use_image_in_dictionary'))
				{
					my $local_folder = $ENV{DOCUMENT_ROOT}.$words_folder;
					
					my $image_to_use = $ou->get_keyword_value('alternative_image');
					my $default_image = $ou->get_keyword_value('default_image');
					
					if($image_to_use!~/\w/)
					{
						if($ou->get_keyword_value('default_image') ne 'no')
						{
							$image_to_use = lc($ou->name).'.swf';
						}
					}
					
					if($image_to_use =~ /\w/)
					{
						my $web_thumbnail = $words_folder.'wordImages/'.$image_to_use;
				
						my $local_thumbnail = $ENV{DOCUMENT_ROOT}.$web_thumbnail;
				
						if(-e $local_thumbnail)
						{
							$thumbnail = $web_thumbnail;
						}
					}
				}
				
				push(@$ous, {
						id => $ou->get_id,
						ou_id => $ou->ou_id,
						keywords => $ou->get_keyword_hash,
						firstname => $ou->{data}->{firstname},
						surname => $ou->{data}->{surname},
						user_id => $ou->{data}->{user_id},
						name => $ou->name,
						ou_type => $ou->ou_type,
						thumbnail_url => $thumbnail,
						help => $ou->comment,
						item_type => $ou->item_type,
						item_path => $ou->get_file_web_path
				});				
			}
			else
			{
				

				push(@$ous, {
					id => $ou->get_id,
					ou_id => $ou->ou_id,
					keywords => $ou->get_keyword_hash,
					searchwords => $ou->get_searchwords_string,
					name => $ou->name,
					tes_url => $ou->tes_url,
					thumbnail_url => $thumbnail,
					author => $ou->get_keyword_value('author'),
					owner => $ou->get_keyword_value('owner'),
					pricing_model => $ou->get_keyword_value('pricing_model'),
					pricing_level => $ou->get_keyword_value('pricing_level'),
					price => $ou->get_keyword_value('price'),
					help => $ou->comment,
					quick_comment => $ou->quick_comment,
					teacher_quote => $ou->teacher_quote,
					pupil1_quote => $ou->pupil1_quote,
					pupil2_quote => $ou->pupil2_quote,
					ou_type => $ou->ou_type,
					item_type => $ou->item_type,
					item_path => $ou->get_file_web_path
				});
			}
		}
	}

	$self->{db}->commit;

	my $count = @$ous;

	my $ret = {
		items => $ous,
		totalCount => $count };

	return $ret;
}

sub admin__ou_data_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	if($self->{params}->{id} eq 'root')
	{
		$self->return_response;

		return;
	}

	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $self->{params}->{id} });

	$ou->load_keywords;

	my $ou_data = {
		id => $ou->get_id,
		ou_id => $ou->ou_id,
		item_type => $ou->item_type,
		name => $ou->name,
		author => $ou->get_keyword_value('author'),
		owner => $ou->get_keyword_value('owner'),
		tes_url => $ou->tes_url,
		pricing_model => $ou->get_keyword_value('pricing_model'),
		pricing_level => $ou->get_keyword_value('pricing_level'),
		price => $ou->get_keyword_value('price'),
		help => $ou->comment,
		ou_type => $ou->ou_type,
		item_path => $ou->get_file_web_path };

	$self->return_response({
		ou_data => $ou_data });
}

########################################################################################
########################################################################################
######################
# SAVE FOLDER

sub admin__ou_save_folder_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $folder;

	if($self->{params}->{id}>0)
	{
		$folder = Webkit::Player::OU->load($self->{db}, {
			id => $self->{params}->{id} });
	}
	else
	{
		$folder = Webkit::Player::OU->constructor($self->{db});

		$folder->installation_id($self->installation_id);
		$folder->account_id($self->{account}->get_id);
		$folder->ou_id($self->{params}->{ou_id});
		$folder->ou_type($self->{params}->{ou_type});
		$folder->user_id($self->{user}->get_id);
	}
	
	
	$folder->name($self->{params}->{name});

	if($folder->error)
	{
		$self->return_error($folder->{error_text});
		return;
	}

	$self->{db}->begin_transaction;
	
	my $did_exist = undef;

	if($folder->exists)
	{
		$did_exist = 1;
		$folder->delete_keywords;
	}
	
	$folder->save_or_create;

	$folder->save_keywords($self->{params});
	
	if(!$did_exist)
	{
		if($folder->ou_id>0)
		{
			my $parent_ou = Webkit::Player::OU->load($self->{db}, {
				id => $folder->ou_id });
			
			$folder->copy_keywords_from_ou($parent_ou);
		}
	}

	$self->{db}->commit;

	$self->return_response;
}

########################################################################################
########################################################################################
######################
# SAVE TEACHING RESOURCE

sub admin__ou_save_teaching_resource_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }
	
	$self->fully_load_installation;
	
	my $ou_type = 'teaching_resource';
	
	if($self->{installation}->is_dictionary)
	{
		$ou_type = 'definition';
	}

	my $teaching_resource;

	if($self->{params}->{id}>0)
	{
		$teaching_resource = Webkit::Player::OU->load($self->{db}, {
			id => $self->{params}->{id} });
	}
	else
	{
		$teaching_resource = Webkit::Player::OU->constructor($self->{db});

		$teaching_resource->installation_id($self->installation_id);
		$teaching_resource->account_id($self->{account}->get_id);
		$teaching_resource->ou_id($self->{params}->{ou_id});
		$teaching_resource->ou_type($ou_type);
		$teaching_resource->user_id($self->{user}->get_id);
	}
	
	if($self->{installation}->is_dictionary)
	{
		$teaching_resource->name($self->{params}->{name});
		$teaching_resource->comment($self->{params}->{comment});
	}
	else
	{
		$teaching_resource->name($self->{params}->{name});
		$teaching_resource->tes_url($self->{params}->{tes_url});
		$teaching_resource->comment($self->{params}->{help});
		$teaching_resource->quick_comment($self->{params}->{quick_comment});
		$teaching_resource->teacher_quote($self->{params}->{teacher_quote});
		$teaching_resource->pupil1_quote($self->{params}->{pupil1_quote});
		$teaching_resource->pupil2_quote($self->{params}->{pupil2_quote});
		$teaching_resource->item_type($self->{params}->{item_type});
	}

	if($teaching_resource->error)
	{
		$self->return_error($teaching_resource->{error_text});
		return;
	}

	$self->{db}->begin_transaction;
	
	my $did_exist = undef;

	if($teaching_resource->exists)
	{
		$did_exist = 1;
		$teaching_resource->delete_keywords;
		$teaching_resource->delete_searchwords;
	}

	$teaching_resource->save_or_create;

	if($self->{installation}->is_dictionary)
	{
		
	}
	else
	{
		$teaching_resource->create_keyword('author', $self->{params}->{author});
		$teaching_resource->create_keyword('owner', $self->{params}->{owner});
		$teaching_resource->create_keyword('pricing_model', $self->{params}->{pricing_model});
		$teaching_resource->create_keyword('pricing_level', $self->{params}->{pricing_level});
		#$teaching_resource->create_keyword('price', $self->{params}->{price});
		#$teaching_resource->create_keyword('comment', $self->{params}->{comment});
		
		$teaching_resource->save_searchwords($self->{params}->{searchwords});
	}

	$teaching_resource->save_keywords($self->{params});
	
	if(!$did_exist)
	{
		if($teaching_resource->ou_id>0)
		{
			my $parent_ou = Webkit::Player::OU->load($self->{db}, {
				id => $teaching_resource->ou_id });
			
			$teaching_resource->copy_keywords_from_ou($parent_ou);
		}
	}
	
	$self->{db}->commit;

	$self->return_response;
}

########################################################################################
########################################################################################
######################
# TEACHING RESOURCE KEYWORDS DATA HANDLER

sub get_keyword_ignore_map
{
	my ($self, $ignore_text) = @_;

	my $map = {};

	if($self->{params}->{ignore}=~/\w/)
	{
		my @ignore_arr = split(/:/, $self->{params}->{ignore});

		foreach my $ignore (@ignore_arr)
		{
			$map->{$ignore} = 1;
		}
	}

	return $map;
}

sub admin__ou_keyword_data_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $ignore_word_map = $self->get_keyword_ignore_map($self->{params}->{ignore});

	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $self->{params}->{ou_id} });

	$ou->load_keywords;

	my $data = [];

	foreach my $keyword (@{$ou->ensure_child_array('keyword')})
	{
		if($keyword->word =~ /\w/)
		{
			if($ignore_word_map->{$keyword->word}) { next; }
		}

		push(@$data, {
			id => $keyword->get_id,
			word => $keyword->word,
			value => $keyword->value,
			keyword_type => $keyword->keyword_type });
	}

	my $count = 0;

	if($data)
	{
		$count = @$data;
	}

	my $ret = {
		itemCount => $count,
		items => $data };

	$self->return_response($ret);
}

sub admin__account_keyword_type_data_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $clause=<<"+++";
account_id = ?
+++

	my $data = $self->{db}->get_select_refs({
		table => 'player.keyword',
		cols => 'keyword.keyword_type as keyword_type',
		clause => "account_id = ? and word IS NOT NULL",
		binds => [$self->{account}->get_id],
		group => 'keyword.keyword_type',
		order => 'keyword.keyword_type' });

	my $arr = [];

	if(!$data) { $data = []; }

	foreach my $ref (@$data)
	{
		push(@$arr, [$ref->{keyword_type}]);
	}

	$self->return_response($arr);
}

sub admin__account_keyword_word_data_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $ignore_word_map = $self->get_keyword_ignore_map($self->{params}->{ignore});

	my $clause=<<"+++";
account_id = ?
+++

	my $data = $self->{db}->get_select_refs({
		table => 'player.keyword',
		cols => 'keyword.word as word',
		clause => "account_id = ? and word IS NOT NULL and keyword_type = ?",
		binds => [$self->{account}->get_id, $self->{params}->{keyword_type}],
		group => 'keyword.word',
		order => 'keyword.word' });

	my $arr = [];

	if(!$data) { $data = []; }

	foreach my $ref (@$data)
	{
		if($ignore_word_map->{$ref->{word}}) { next; }

		push(@$arr, [$ref->{word}]);
	}

	$self->return_response($arr);
}

sub admin__account_keyword_value_data_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $data = $self->{db}->get_select_refs({
		table => 'player.keyword',
		cols => 'keyword.value as value',
		clause => "account_id = ? and word = ?",
		binds => [$self->{account}->get_id, $self->{params}->{word}],
		group => 'keyword.value',
		order => 'keyword.value' });

	my $arr = [];

	if(!$data) { $data = []; }

	foreach my $ref (@$data)
	{
		push(@$arr, [$ref->{value}]);
	}

	$self->return_response($arr);
}

########################################################################################
########################################################################################
######################
# DELETE OU

sub admin__ou_delete_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	$self->load_ou_tree_with_keywords;

	my $ou_to_delete = $self->{account}->get_child('ou', $self->{params}->{ou_id});

	my $ous_to_delete_array = $self->get_sub_ous($ou_to_delete);

	$self->{db}->begin_transaction;

	foreach my $ou (@$ous_to_delete_array)
	{
		$ou->delete;
	}

	$self->{db}->commit;

	$self->return_response;
}

########################################################################################
########################################################################################
######################
# Files

sub admin__ou_save_file_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $ou;

	if($self->{params}->{file_id}>0)
	{
		$ou = Webkit::Player::OU->load($self->{db}, {
			id => $self->{params}->{file_id} });
	}
	else
	{
		$ou = Webkit::Player::OU->constructor($self->{db});
		$ou->installation_id($self->installation_id);
		$ou->account_id($self->{account}->get_id);
		$ou->ou_id($self->{params}->{ou_id});
		$ou->ou_type('file');
		$ou->name('file');
		$ou->user_id($self->{user}->get_id);
	}

	$ou->item_type($self->{params}->{fileType});

	my $fileref = Webkit::AppTools->get_upload_ref($self->{params}, 'file');

	my $response;

	if((!$fileref->{size}>0)&&(!$ou->exists))
	{
		$response = $self->jsonize({
			code => 'notok',
			text => 'please choose a file to upload',
			success => $self->{json}->true
		});
	}
	elsif($ou->error)
	{
		$response = $self->jsonize({
			code => 'notok',
			text => $ou->{error_text},
			success => $self->{json}->true
		});
	}
	else
	{
		$self->{db}->begin_transaction;

		$ou->save_or_create($fileref);

		$self->{db}->commit;

		$response = $self->jsonize({
			code => 'ok',
			name => $ou->name,
			success => $self->{json}->true
		});
	}

	$self->{page_content} = "<html><body>$response</body></html>";
}

sub admin__ou_file_data_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $self->{params}->{ou_id} });

	$ou->load_ou_children;

	my $data = [];

	foreach my $ou (@{$ou->ensure_child_array('ou')})
	{
		if(!$ou->is_file) { next; }

		push(@$data, {
			id => $ou->get_id,
			type => $ou->item_type,
			name => $ou->name });
	}

	my $count = 0;

	if($data)
	{
		$count = @$data;
	}

	my $ret = {
		itemCount => $count,
		items => $data };

	$self->return_response($ret);
}

########################################################################################
########################################################################################
######################
# MOVE OU

sub admin__ou_move_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $move_ou = Webkit::Player::OU->load($self->{db}, {
		id => $self->{params}->{move_id} });

	$move_ou->ou_id($self->{params}->{to_id});

	$self->{db}->begin_transaction;

	$move_ou->save;

	$self->{db}->commit;

	my $ret = {};

	$self->return_response($ret);
}

########################################################################################
########################################################################################
######################
# BULK KEYWORDS

sub admin__save_bulk_keywords_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $word = $self->{params}->{word};
	my $value = $self->{params}->{value};
	my $type = $self->{params}->{keyword_type};

	$self->load_ou_tree;

	my $ou_array = [];

	if($self->{params}->{ou_id}==0)
	{
		$ou_array = $self->{account}->{root_ous};
	}
	else
	{
		my $parent_ou = $self->{account}->get_child('ou', $self->{params}->{ou_id});

		$ou_array = $parent_ou->ensure_child_array('ou');
	}

	$self->{db}->begin_transaction;

	foreach my $ou (@$ou_array)
	{
		$self->save_bulk_keywords($ou, $word, $value, $type);
	}

	$self->{db}->commit;

	my $ret = {};

	$self->return_response($ret);
}

sub admin__save_bulk_becta_keywords_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $type = 'becta';

	$self->load_ou_tree;

	my $ou_array = [];

	if($self->{params}->{ou_id}==0)
	{
		$ou_array = $self->{account}->{root_ous};
	}
	else
	{
		my $parent_ou = $self->{account}->get_child('ou', $self->{params}->{ou_id});

		$ou_array = $parent_ou->ensure_child_array('ou');
	}

	$self->{db}->begin_transaction;

	for(my $i=0; $i<$self->{params}->{keywordCount}; $i++)
	{
		my $word = $self->{params}->{'word'.$i};
		my $value = $self->{params}->{'value'.$i};

		foreach my $ou (@$ou_array)
		{
			$self->save_bulk_keywords($ou, $word, $value, $type);
		}
	}

	$self->{db}->commit;

	my $ret = {};

	$self->return_response($ret);
}

sub admin__save_bulk_structured_keywords_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	$self->load_ou_tree;

	my $ou_array = [];

	if($self->{params}->{ou_id}==0)
	{
		$ou_array = $self->{account}->{root_ous};
	}
	else
	{
		my $parent_ou = $self->{account}->get_child('ou', $self->{params}->{ou_id});

		$ou_array = $parent_ou->ensure_child_array('ou');
	}

	$self->{db}->begin_transaction;

	for(my $i=0; $i<$self->{params}->{keywordCount}; $i++)
	{
		my $word = $self->{params}->{'word'.$i};
		my $value = $self->{params}->{'value'.$i};
		my $type = $self->{params}->{'type'.$i};

		foreach my $ou (@$ou_array)
		{
			$self->save_bulk_keywords($ou, $word, $value, $type);
		}
	}

	$self->{db}->commit;

	my $ret = {};

	$self->return_response($ret);
}

sub save_bulk_keywords
{
	my ($self, $ou, $word, $value, $type) = @_;

	foreach my $child_ou (@{$ou->ensure_child_array('ou')})
	{
		$self->save_bulk_keywords($child_ou, $word, $value, $type);
	}

	if($ou->is_activity)
	{
		$ou->create_keyword($word, $value, $type);
	}
}

########################################################################################
########################################################################################
######################
# Becta Vocab

sub admin__becta_vocab_tree_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $vocab_id = $self->{params}->{node};

	if($vocab_id eq 'root')
	{
		$vocab_id = 0;
	}

	my $obj_tree = $self->{installation}->get_becta_vocab_tree_dump($vocab_id);

	$self->return_response($obj_tree);	
}

########################################################################################
########################################################################################
######################
# Structured Keyword Tree

sub admin__structured_keyword_tree_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }
	
	$self->fully_load_installation;

	my $vocab_id = $self->{params}->{node};

	if($vocab_id eq 'root')
	{
		$vocab_id = 0;
	}

	my $tree = $self->{installation}->get_structured_vocab_tree_dump;

	$self->return_response($tree);	
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# IMAGES
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub images__image_content_handler
{
	my ($self) = @_;

	my $max_size = $self->{params}->{size};
	my $image_path = $self->{params}->{image_path};

	if($image_path!~/\w/)
	{
		my $ou_id = $self->{params}->{ou_id};

		if($ou_id=~/^\d+$/)
		{
			my $ou = Webkit::Player::OU->load($self->{db}, {
				id => $ou_id });

			$image_path = $ou->get_file_web_path;
		}
	}

	my $local_path = Webkit::Constants->get_constant('player_file_dir');

	$image_path =~ s/^\/files\///i;
	$local_path .= $image_path;

	my $contents = '';

	if($max_size=~/^\d+$/)
	{
		my @filename_parts = split(/\./, $local_path);
		my $ext = pop(@filename_parts);

		my $size_filename = join('.', @filename_parts);
		$size_filename .= '.'.$max_size.'.'.$ext;

		if(!-e $size_filename)
		{
			my $size_st = $max_size.'x'.$max_size;

			my $convert_path = $self->convert_path;

			my $commandline = "$convert_path $local_path -resize $size_st -quality 80 $size_filename";
			
			system($commandline);
		}

		$contents = Webkit::AppTools->read_file_contents($size_filename);
	}
	else
	{
		$contents = Webkit::AppTools->read_file_contents($local_path);
	}

	my $length = length($contents);
	
	print "Content-length: $length\n";
	
	if($self->{params}->{download} eq 'y')
	{
		print "Content-Disposition: attachment; filename=thumbnail.jpg;\n";
	}
	
	print "Content-type: image/jpeg\n\n";

	print $contents;

	$self->{page_content} = '_no_header';
	return '_no_header';
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# EXPORT
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub admin__export__db_export_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	print "Content-type: text/html\n\n";

	print "Making content<p>";

	my $player_dir = Webkit::Player::OU->get_player_folder;
	my $site_dir = $ENV{DOCUMENT_ROOT};

	my $db_folder = $player_dir.'/dbexport';
	my $files_folder = $db_folder.'/files';

	if(-e $db_folder)
	{
		system("rm -rf $db_folder");
	}

	system("mkdir $db_folder");

	$self->load_ou_tree_with_keywords;

	my $icons = ['close.gif', 'help.gif', 'refresh.gif', 'clear.gif'];

	foreach my $ou (@{$self->{account}->ensure_child_array('ou')})
	{
		if(!$ou->is_activity) { next; }

		print "Making ".$ou->name."<p>";

		for(my $u=0; $u<=100; $u++)
		{
			print "                                                                                    ";
		}

		my $playerid = $ou->get_keyword_value('playerid');
		my $activity_folder = "$db_folder/$playerid";

		system("mkdir $activity_folder");

		system("cp $site_dir/exportTemplates/flashlib.js $activity_folder/".$playerid."_flashlib.js");

		foreach my $icon (@$icons)
		{
			my $new_url = $playerid.'_'.$icon;

			system("cp $site_dir/exportTemplates/icons/$icon $activity_folder/$new_url");
		}

		my $swfpath = '';

		foreach my $fileou (@{$ou->ensure_child_array('ou')})
		{
			if(!$fileou->is_file) { next; }

			my $filename = $fileou->get_file_local_path;
			my $ext = '';

			if($filename=~/\.(\w+)$/)
			{
				$ext = $1;
			}

			my $orig_path = $filename;
			my $new_path = $activity_folder.'/'.$playerid.'_'.$ou->item_type.'.'.$ext;

			if(-e $orig_path)
			{
				system("cp $orig_path $new_path");
			}

			if($fileou->is_activity_file)
			{
				$swfpath = $playerid.'_'.$ou->item_type.'.'.$ext;
			}
		}

		$self->admin_export_write_template("$site_dir/exportTemplates/help.htm", "$activity_folder/".$playerid."_help.htm", {
			playerid => $playerid,
			title => $ou->name,
			notes => $ou->comment
		});

		$self->admin_export_write_template("$site_dir/exportTemplates/index.htm", "$activity_folder/index.htm", {
			playerid => $playerid,
			title => $ou->name
		});

		$self->admin_export_write_template("$site_dir/exportTemplates/activity.htm", "$activity_folder/".$playerid."_activity.htm", {
			playerid => $playerid,
			title => $ou->name,
			swf => $swfpath
		});

		$self->admin_export_write_template("$site_dir/exportTemplates/topbar.htm", "$activity_folder/".$playerid."_topbar.htm", {
			playerid => $playerid,
			title => $ou->name,
			notes => $ou->comment
		});
	}

	$self->{page_content} = '_no_header';
	return '_no_header';
}

sub admin_export_write_template
{
	my ($self, $template_file, $output_file, $props) = @_;
	
	$self->{page_props} = $props;

	my $contents = $self->get_template($template_file);

	open(FILE, ">$output_file");

	print FILE $contents;

	close(FILE);
}



########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# VIEWS
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub admin__view_tree_data_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $views = Webkit::Player::Views->new($self->{db}, $self->installation_id);

	my $tree = [];

	my $node_id = $self->{params}->{node};

	if($node_id eq 'root-view')
	{
		my $child_nodes = $views->get_array_of_view_nodes;

		foreach my $child_node (@$child_nodes)
		{
			my $children_array = $views->get_child_elements($child_node);

			my $children_count = @$children_array;

			my $is_leaf = $self->{json}->true;

			if($children_count>0)
			{
				$is_leaf = $self->{json}->false;
			}

			push(@$tree, {
				id => $child_node->getAttribute('id'),
				text => $child_node->getAttribute('name'),
				node_type => $child_node->getNodeName,
				leaf => $is_leaf
			});
		}
	}
	else
	{
		my $ignore_params = {
			account_id => 1,
			node => 1,
			session_id => 1 };

		my $keyword_params = {};

		foreach my $key (keys %{$self->{params}})
		{
			if(!$ignore_params->{$key})
			{
				$keyword_params->{$key} = $self->{params}->{$key};
			}
		}

		my $grouping_results = $views->get_node_groups({
			view_id => $node_id,
			params => $keyword_params,
			json => $self->{json} });

		foreach my $result (@$grouping_results)
		{
			push(@$tree, $result);
		}
	}

	$self->return_response($tree);
}

sub admin__ou_view_contents_data_handler
{
	my ($self) = @_;

	if(!$self->admin_login) { return; }

	my $views = Webkit::Player::Views->new($self->{db}, $self->installation_id);

	my $node_id = $self->{params}->{view_id};

	my $ous = [];

	if($node_id eq 'root-view')
	{
		my $child_nodes = $views->get_array_of_view_nodes;

		foreach my $child_node (@$child_nodes)
		{
			my $children_array = $views->get_child_elements($child_node);

			my $children_count = @$children_array;

			my $is_leaf = $self->{json}->true;

			if($children_count>0)
			{
				$is_leaf = $self->{json}->false;
			}

			push(@$ous, {
				id => $child_node->getAttribute('id'),
				ou_id => $node_id,
				ou_type => 'view',
				#keywords => $ou->get_keyword_hash,
				name => $child_node->getAttribute('name'),
				#thumbnail_url => $thumbnail,
				#author => $ou->get_keyword_value('author'),
				#pricing_model => $ou->get_keyword_value('pricing_model'),
				#price => $ou->get_keyword_value('price'),
				#help => $ou->comment,
				#ou_type => $ou->ou_type,
				#item_type => $ou->item_type,
				#item_path => $ou->get_file_web_path
			});
		}
	}
	else
	{
		my $ignore_params = {
			show_activities => 1,
			maxNumberActivities => 1,
			account_id => 1,
			node => 1,
			session_id => 1 };

		my $keyword_params = {};

		foreach my $key (keys %{$self->{params}})
		{
			if(!$ignore_params->{$key})
			{
				$keyword_params->{$key} = $self->{params}->{$key};
			}
		}

		my $grouping_results = $views->get_node_groups({
			return_activities => 1,
			view_id => $node_id,
			params => $keyword_params,
			json => $self->{json} });

		#### This means that we have reached the last grouping node and there are
		#### actual activites being returned now
		if($views->{has_activities})
		{
			foreach my $ou (@$grouping_results)
			{
				my $thumbnail = '';

				if($ou->{data}->{thumbnail_url}=~/\w/)
				{
					$thumbnail = '/files/'.$ou->{data}->{thumbnail_url};

					$thumbnail = '/images/image_content.app?image_path='.$thumbnail.'&size=100';
				}
				elsif($ou->item_type eq 'thumbnail')
				{
					$thumbnail = $ou->get_file_web_path;

					$thumbnail = '/images/image_content.app?image_path='.$thumbnail.'&size=100';
				}

				push(@$ous, {
					id => $ou->get_id,
					ou_id => $ou->ou_id,
					keywords => $ou->get_keyword_hash,
					name => $ou->name,
					tes_url => $ou->tes_url,
					thumbnail_url => $thumbnail,
					author => $ou->get_keyword_value('author'),
					owner => $ou->get_keyword_value('owner'),
					pricing_model => $ou->get_keyword_value('pricing_model'),
					pricing_level => $ou->get_keyword_value('pricing_level'),
					price => $ou->get_keyword_value('price'),
					help => $ou->comment,
					ou_type => $ou->ou_type,
					item_type => $ou->item_type,
					item_path => $ou->get_file_web_path
				});
			}
		}
		else
		{
			foreach my $result (@$grouping_results)
			{
				push(@$ous, {
					id => $result->{id},
					ou_id => $node_id,
					ou_type => 'view_group',
					#keywords => $ou->get_keyword_hash,
					name => $result->{text},
					#thumbnail_url => $thumbnail,
					#author => $ou->get_keyword_value('author'),
					#pricing_model => $ou->get_keyword_value('pricing_model'),
					#price => $ou->get_keyword_value('price'),
					#help => $ou->comment,
					#ou_type => $ou->ou_type,
					#item_type => $ou->item_type,
					#item_path => $ou->get_file_web_path
				});
			}
		}
	}

	my $count = @$ous;

	my $ret = {
		items => $ous,
		totalCount => $count };

	$self->return_response($ret);
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# HOME APP
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub main_domain
{
	my ($classname) = @_;
	my $r = Webkit::Application->r || return;
	return $r->dir_config('MainDomain');
}

sub get_subdomain
{
	my ($self) = @_;
	
	if($self->{use_subdomain} =~ /\w/)
	{
		return $self->{use_subdomain};
	}

	my $hostname = lc($self->hostname);
	my $main_domain = $self->main_domain;
	
	#if($hostname =~ /i-board\.co\.uk$/)
	#{
	#	return 'tes';	
	#}
	
	foreach my $domain (@domains)
	{
		$hostname =~ s/$domain//i;
	}
	
	$hostname =~ s/$main_domain//i;
	$hostname =~ s/^www\.//i;
	$hostname =~ s/\.$//i;
	
	if($hostname!~/\w/)
	{
		my $val = $self->get_cookie('playerurl');
	
		$hostname = $val;
	}
	
	return $hostname;
}

sub load_club_account_from_subdomain
{
	my ($self) = @_;
	
	my $subdomain = $self->get_subdomain;
	
	my $account = Webkit::EB::School->load($self->{db}, {
		clause => 'url = ?',
		binds => [$subdomain] });
		
	return $account;
}

sub load_specific_subdomain_account
{
	my ($self, $subdomain) = @_;
	
	my $ret_account = Webkit::Player::Account->load($self->{db}, {
		clause => 'installation_id = ? and ( url = ? or url like ? )',
		binds => [$self->installation_id, $subdomain, '%-'.$subdomain.'-%'] });
	
	$self->{account} = $ret_account;
	
	return $ret_account;
}

sub load_tes_account
{
	my ($self) = @_;
	
	my $replace_url = 'tes';
	
	my $ret_account = Webkit::Player::Account->load($self->{db}, {
		clause => 'installation_id = ? and ( url = ? or url like ? )',
		binds => [$self->installation_id, $replace_url, '%-'.$replace_url.'-%'] });
	
	$self->{account} = $ret_account;
	
	return $ret_account;
}
				
sub load_account_from_subdomain
{
	my ($self, $load_real_account) = @_;
	
	if($self->{account}) { return $self->{account}; }
	
	my $subdomain = $self->get_subdomain;
	
	if($subdomain !~ /\w/)
	{
		return;
	}
	
	my $account = Webkit::Player::Account->load($self->{db}, {
		clause => 'installation_id = ? and ( url = ? or url like ? )',
		binds => [$self->installation_id, $subdomain, '%-'.$subdomain.'-%'] });
		
	if($self->installation_id != 1)
	{
		$self->{account} = $account;
		
		return $account;	
	}
	
	if($load_real_account)
	{
		$self->{account} = $account;
		
		return $account;	
	}
	else
	{
		my $replace_url = 'tes';
		
		if($account)
		{
			if(lc($account->menu_to_use eq 'scotland'))
			{
				$replace_url = 'tess';
			}
			elsif($account->menu_to_use eq 'phonics')
			{
				$replace_url = 'phonics.test';	
			}
		}
			
		my $ret_account = Webkit::Player::Account->load($self->{db}, {
			clause => 'installation_id = ? and ( url = ? or url like ? )',
			binds => [$self->installation_id, $replace_url, '%-'.$replace_url.'-%'] });
				
		$self->{account} = $ret_account;
			
		return $ret_account;
	}
}

sub index_handler
{
	my ($self) = @_;
	
	$self->fully_load_installation;
	
	my $account = $self->load_account_from_subdomain;
	
	if($account)
	{
		my $id = $account->get_id;
		
		$self->set_page('/player');	
		
#		$self->{page_content}=<<"+++";
#<html>
#	<meta http-equiv="refresh" content="0;url=/player/">
#</html>	
#+++
	}
	else
	{
		if($self->{installation}->is_dictionary)
		{
			$self->set_page('/dictionary_main.htm');
			return;
		}
		else
		{
			my $subdomain = $self->get_subdomain;
			
			if($subdomain =~ /\w/)
			{
				$account = $self->load_tes_account;
				
				my $id = $account->get_id;
		
				$self->set_page('/player');
			}
		
#			if($online_club_account)
#			{
#				$self->{params}->{club_domain} = $self->get_subdomain;
#				$self->set_page('/club.htm');
#			}
#			elsif($self->get_subdomain =~ /\w/)
#			{
#				$self->set_page('/catchaccount.htm');
#			}
		}
	}
}

sub home__register_account_handler
{
	my ($self) = @_;

	my $school_name = $self->{params}->{schoolname};

	my $account = Webkit::Player::Account->constructor($self->{db});

	$account->installation_id($self->installation_id);
	$account->account_type('customer');
	$account->name($school_name);
	
	$self->{db}->begin_transaction;
	
	$account->create;
	
	$self->{db}->commit;
	
	$self->{page_props}->{account_id} = $account->get_id;
	
	$self->set_page('/registered.htm');
}

sub free__register_handler
{
	my ($self) = @_;
	
	my $school_name = $self->{params}->{school_name};
	my $user_name = $self->{params}->{user_name};
	my $email = $self->{params}->{email};
	my $city = $self->{params}->{city};
	my $postcode = $self->{params}->{postcode};
	my $password = $self->{params}->{password};
	
	if(!Webkit::AppTools->check_email_address($email))
	{
		$self->{page_props}->{error_text} = $email.' is not a valid email address - please enter another';
		$self->set_page('/free/index.htm');
		
		return;
	}
	
	my $account = Webkit::Player::Account->constructor($self->{db});

	$account->installation_id($self->installation_id);
	$account->account_type('customer');
	$account->name($school_name);
	$account->city($city);
	$account->postcode($postcode);
	
	my $user = Webkit::Player::User->constructor($self->{db});
	
	$user->installation_id($self->installation_id);
	$user->username($email);
	$user->password('password');
	$user->name($user_name);
	$user->created(Webkit::DateTime->now);

	my $url = $self->generate_account_url($school_name, $city);

	$account->url($url);
	
	$self->{db}->begin_transaction;
	
	$account->create;
	
	$user->account_id($account->get_id);
	
	$user->create;
	
	$self->{db}->commit;
	
	$self->{page_props}->{account_id} = $account->get_id;
	
	$self->set_page('/registered.htm');
	
	$self->send_new_account_emails($account, $user, $url);
		
	return;	
}

sub get_linked_account_from_code
{
	my ($self, $code) = @_;

	my $account = Webkit::Player::Account->load($self->{db}, {
		clause => "installation_id = ? and LOWER(account_flag) = ?",
		binds => [$self->installation_id, lc($code)] });
		
	return $account;
}

sub free__register_school_handler
{
	my ($self) = @_;
	
	my $account_type = 'school';
	
	my $la = $self->{params}->{school_la};
	my $account_name = $self->{params}->{school_school_name};
	
	my $country = $self->{params}->{school_country};
	
	my $city = '';
	
	my $firstpart = '';
	my $secondpart = '';
	
	if($country eq 'United Kingdom')
	{
		$city = $self->{params}->{school_postcode};
		
		$firstpart = $account_name;
		$secondpart = $la;
	}
	else
	{
		$city = $self->{params}->{school_area};
		
		$firstpart = $account_name;
		$secondpart = $city;	
	}
	
	$self->fully_load_installation;
	
	my $account_notes = $self->{params}->{school_additional_info};
	
	my $firstname = $self->{params}->{school_firstname};
	my $surname = $self->{params}->{school_surname};
	my $email = $self->{params}->{school_email};
	my $jobtitle = $self->{params}->{school_jobtitle};
	my $title = $self->{params}->{school_title};	
	my $school_size = $self->{params}->{school_size};
	
	if(!Webkit::AppTools->check_email_address($email))
	{
		$self->{page_props}->{objs}->{error_fields} = ['school_email'];
		$self->{page_props}->{school_error_text} = $email.' is not a valid email address...';
		$self->set_page('/free/index.htm');
		
		return;
	}

	my $linked_account;
	
	my $ignore_codes = {
		ib23 => 1 };
		
	my $code = lc($self->{params}->{school_promotional_code});
	
	if($code=~/\w/)
	{
		if(!$ignore_codes->{$code})
		{
			$linked_account = $self->get_linked_account_from_code($self->{params}->{school_promotional_code});
		
			if((!$linked_account)||(!$linked_account->is_upseller))
			{
				$self->{page_props}->{objs}->{error_fields} = ['school_promotional_code'];
				$self->{page_props}->{school_error_text} = $self->{params}->{school_promotional_code}.' is not a valid promotional code...';
				$self->set_page('/free/index.htm');
			
				return;
			}
		}
	}
	
	my $account = Webkit::Player::Account->constructor($self->{db});

	$account->installation_id($self->installation_id);
	$account->account_type($account_type);
	$account->org($la);
	$account->name($account_name);
	$account->city($city);
	$account->country($country);
	$account->account_notes($account_notes);
	$account->small_school($school_size);
	$account->registered(Webkit::DateTime->now);
	
	if($self->{params}->{school_scotland} eq 'yes')
	{
		$account->add_account_setting('menu_to_use', 'scotland');
	}
	
	my $user = Webkit::Player::User->constructor($self->{db});
	
	$user->installation_id($self->installation_id);
	$user->username($email);
	$user->firstname($firstname);
	$user->surname($surname);
	$user->title($title);
	$user->jobtitle($jobtitle);
	$user->created(Webkit::DateTime->now);
	
	my $password = 'password';
	
	if($self->{params}->{password}=~/\w/)
	{
		$password = $self->{params}->{password};
	}
	
	$user->password($password);
	
	my $url = $self->generate_account_url($firstpart, $secondpart);

	$account->url($url);
	
	$self->{db}->begin_transaction;
	
	$account->create;
	
#	if($account->can_have_free_subscription)
#	{
#		if($self->{params}->{school_free_mode} eq 'subscription')
#		{
#			my $purchase_record = Webkit::Player::PurchaseRecord->constructor($self->{db});
#			
#			$purchase_record->installation_id($self->installation_id);
#			$purchase_record->account_id($account->get_id);
#			$purchase_record->purchase_date(Webkit::DateTime->now);
#			$purchase_record->purchase_amount(0);
#			$purchase_record->collection_id('all');
#			$purchase_record->purchase_type('free_subscription');
#			
#			my $start_date = Webkit::DateTime->now;
#			my $end_date = $start_date->clone;
#			$end_date->epoch_days(92);
#			
#			$purchase_record->subscription_start($start_date);
#			$purchase_record->subscription_end($end_date);
#			
#			$purchase_record->create;
#			
#			$account->add_account_flag('free_subscription');
#			$account->save;			
#		}
#	}

	if($linked_account)
	{
		my $account_link = Webkit::Player::AccountLink->constructor($self->{db});
		$account_link->installation_id($self->installation_id);
		$account_link->parent_id($linked_account->get_id);
		$account_link->child_id($account->get_id);
		$account_link->link_type('upsell');
		$account_link->created(Webkit::DateTime->now);
		
		$account_link->create;
		
		$account->add_account_setting('free_allowed', 30);
		$account->save;
	}
	elsif(!$self->{installation}->is_dictionary)
	{	
		if($account->can_have_trial)
		{
			my $purchase_record = Webkit::Player::PurchaseRecord->constructor($self->{db});
			
			$purchase_record->installation_id($self->installation_id);
			$purchase_record->account_id($account->get_id);
			$purchase_record->purchase_date(Webkit::DateTime->now);
			$purchase_record->purchase_amount(0);
			$purchase_record->collection_id('all');
			$purchase_record->purchase_type('6month_subscription');
			
			my $start_date = Webkit::DateTime->now;
			my $end_date = $start_date->clone;
			$end_date->epoch_days(184);
			
			$purchase_record->subscription_start($start_date);
			$purchase_record->subscription_end($end_date);
				
			$purchase_record->create;
			
			$account->add_account_flag('6month_subscription');
			$account->save;
		}
	}
	
	$user->account_id($account->get_id);
	
	$user->create;
	
	$self->{db}->commit;
	
	my $account_id = $account->get_id;
	$account_name = $url;
	my $host = $self->hostname;
	
	$self->{page_props}->{account_id} = $account->get_id;
	$self->{page_props}->{email} = $email;
	$self->{page_props}->{account_name} = $url;
	$self->{page_props}->{host} = $host;
	
	my $summary_text = $account->get_text_entry('registration_summary');
	
	$summary_text =~ s/---email---/$email/gi;
	$summary_text =~ s/---password---/$password/gi;
	$summary_text =~ s/---account_name---/$account_name/gi;
	$summary_text =~ s/---host---/$host/gi;
	
	if($linked_account)
	{
		my $upsell_summary = $account->get_text_entry('upsell_confirmation');
		
		my $linked_name = $linked_account->get_account_name;
		
		$upsell_summary =~ s/---name---/$linked_name/g;
		
		$summary_text .= $upsell_summary;
	}	
	
	$self->{page_props}->{summary_text} = $summary_text;
	$self->{page_props}->{objs}->{linked_account} = $linked_account;
	
	if($self->{installation}->is_dictionary)
	{
		$self->set_page('/dictionary_registered.htm');
	}
	else
	{
		$self->set_page('/registered.htm');
	}
	
	$self->send_new_account_emails($account, $user, $url, $linked_account);
		
	return;	
}

sub free__register_individual_handler
{
	my ($self) = @_;
	
	my $account_type = $self->{params}->{individual_accounttype};
	my $city = $self->{params}->{individual_city};
	my $country = $self->{params}->{individual_country};
	my $account_notes = $self->{params}->{individual_additional_info};
	
	my $la = $self->{params}->{individual_la};
	my $org = $self->{params}->{individual_organisation};
	
	my $firstname = $self->{params}->{individual_firstname};
	my $surname = $self->{params}->{individual_surname};
	my $email = $self->{params}->{individual_email};
	
	my $firstpart = $firstname;
	my $secondpart = $surname;
	
	$self->fully_load_installation;
	
	if($account_type eq 'la_adviser')
	{
		$city = 'United Kingdom';
		$country = 'United Kingdom';
		
		$org = $la;
	}
	
	my $account_name = '';
	
	if($self->{installation}->is_dictionary)
	{
		$account_name = $org;
		$org = $la;
		
		$firstpart = $account_name;
		$secondpart = $la;
	}
	
	if(!Webkit::AppTools->check_email_address($email))
	{
		$self->{page_props}->{objs}->{error_fields} = ['individual_email'];
		$self->{page_props}->{individual_error_text} = $email.' is not a valid email address...';
		
		if($self->{installation}->is_dictionary)
		{
			$self->set_page('/free/dictionary.htm');
		}
		else
		{
			$self->set_page('/free/index.htm');
		}
		
		return;
	}
	
	if($self->{installation}->is_dictionary)
	{
		my $existing_account = Webkit::Player::User->load($self->{db}, {
			clause => "installation_id = ? and username = ?",
			binds => [$self->installation_id, $email] });
		
		if($existing_account)
		{
			$self->{page_props}->{objs}->{error_fields} = ['individual_email'];
			$self->{page_props}->{individual_error_text} = $email.' is an account that already exists...';
			$self->set_page('/free/dictionary.htm');
		
			return;
		}
	}
	
	my $linked_account;
	
	my $ignore_codes = {
		ib23 => 1 };
		
	my $code = lc($self->{params}->{individual_promotional_code});
	
	if($code=~/\w/)
	{
		if(!$ignore_codes->{$code})
		{
			$linked_account = $self->get_linked_account_from_code($self->{params}->{individual_promotional_code});
		
			if((!$linked_account)||(!$linked_account->is_upseller))
			{
				$self->{page_props}->{objs}->{error_fields} = ['individual_promotional_code'];
				$self->{page_props}->{individual_error_text} = $self->{params}->{individual_promotional_code}.' is not a valid promotional code...';
				$self->set_page('/free/index.htm');
			
				return;
			}
		}
	}	
	
	my $account = Webkit::Player::Account->constructor($self->{db});

	$account->installation_id($self->installation_id);
	$account->account_type($account_type);
	
	if($account_type eq 'school')
	{
		$account->name('school_school_name');
	}
	
	if($self->{installation}->is_dictionary)
	{
		$account->name($account_name);
	}
	
	$account->org($org);
	$account->city($city);
	$account->country($country);
	$account->account_notes($account_notes);
	$account->registered(Webkit::DateTime->now);
	
	if($self->{params}->{individual_scotland} eq 'yes')
	{
		$account->add_account_setting('menu_to_use', 'scotland');
	}	
	
	my $user = Webkit::Player::User->constructor($self->{db});
	
	$user->installation_id($self->installation_id);
	$user->username($email);
	$user->firstname($firstname);
	$user->surname($surname);
	$user->yeargroup($self->{params}->{yeargroup});
	$user->created(Webkit::DateTime->now);

	my $password = 'password';
	
	if($self->{params}->{individual_password}=~/\w/)
	{
		$password = $self->{params}->{individual_password};
	}
	
	$user->password($password);
	
	my $url = $self->generate_account_url($firstpart, $secondpart);

	$account->url($url);
	
	$self->{db}->begin_transaction;
	
	$account->create;
	
#	if($account->can_have_free_subscription)
#	{
#		if($self->{params}->{individual_free_mode} eq 'subscription')
#		{
#			my $purchase_record = Webkit::Player::PurchaseRecord->constructor($self->{db});
#			
#			$purchase_record->installation_id($self->installation_id);
#			$purchase_record->account_id($account->get_id);
#			$purchase_record->purchase_date(Webkit::DateTime->now);
#			$purchase_record->purchase_amount(0);
#			$purchase_record->collection_id('all');
#			$purchase_record->purchase_type('free_subscription');
#			
#			my $start_date = Webkit::DateTime->now;
#			my $end_date = $start_date->clone;
#			$end_date->epoch_days(92);
#			
#			$purchase_record->subscription_start($start_date);
#			$purchase_record->subscription_end($end_date);
#			
#			$purchase_record->create;
#			
#			$account->add_account_flag('free_subscription');
#			$account->save;
#		}
#	}

	if($linked_account)
	{
		my $account_link = Webkit::Player::AccountLink->constructor($self->{db});
		$account_link->installation_id($self->installation_id);
		$account_link->parent_id($linked_account->get_id);
		$account_link->child_id($account->get_id);
		$account_link->link_type('upsell');
		$account_link->created(Webkit::DateTime->now);
		
		$account_link->create;
		
		$account->add_account_setting('free_allowed', 30);
		$account->save;
	}
	elsif(!$self->{installation}->is_dictionary)
	{
		if($account->can_have_trial)
		{
			my $purchase_record = Webkit::Player::PurchaseRecord->constructor($self->{db});
			
			$purchase_record->installation_id($self->installation_id);
			$purchase_record->account_id($account->get_id);
			$purchase_record->purchase_date(Webkit::DateTime->now);
			$purchase_record->purchase_amount(0);
			$purchase_record->collection_id('all');
			$purchase_record->purchase_type('6month_subscription');
			
			my $start_date = Webkit::DateTime->now;
			my $end_date = $start_date->clone;
			$end_date->epoch_days(184);
			
			$purchase_record->subscription_start($start_date);
			$purchase_record->subscription_end($end_date);
				
			$purchase_record->create;
			
			$account->add_account_flag('6month_subscription');
			$account->save;
		}
	}
	
	$user->account_id($account->get_id);
	
	$user->create;
	
	$self->{db}->commit;
	
	my $account_id = $account->get_id;
	$account_name = $url;
	my $host = $self->hostname;
	
	$self->{page_props}->{account_id} = $account->get_id;
	$self->{page_props}->{email} = $email;
	$self->{page_props}->{account_name} = $url;
	$self->{page_props}->{host} = $host;
	
	my $summary_text = $account->get_text_entry('registration_summary');
	
	$summary_text =~ s/---email---/$email/gi;
	$summary_text =~ s/---password---/$password/gi;
	$summary_text =~ s/---account_name---/$account_name/gi;
	$summary_text =~ s/---host---/$host/gi;
	$summary_text =~ s/---url---/$url/gi;
	
	if($linked_account)
	{
		my $upsell_summary = $account->get_text_entry('upsell_confirmation');
		
		my $linked_name = $linked_account->get_account_name;
		
		$upsell_summary =~ s/---name---/$linked_name/g;
		
		$summary_text .= $upsell_summary;
	}
	
	$self->{page_props}->{summary_text} = $summary_text;
	
	if($self->{installation}->is_dictionary)
	{
		$self->set_page('/dictionary_registered.htm');
	}
	else
	{
		$self->set_page('/registered.htm');
	}
	
	$self->send_new_account_emails($account, $user, $url, $linked_account);
		
	return;	
}

sub send_new_account_emails
{
	my ($self, $account, $user, $url, $linked_account) = @_;
	
	if($self->dev_mode) { return; }
	
	my $email_content = $account->get_text_entry('registration_email');
	
	my $email = $user->username;
	my $password = $user->password;	
	my $host = $self->hostname;
	
	$email_content =~ s/<br>/\n/gi;
	$email_content =~ s/---url---/$url/gi;
	$email_content =~ s/---email---/$email/gi;
	$email_content =~ s/---password---/$password/gi;
	$email_content =~ s/---host---/$host/gi;

	my $account_name = $account->name;
	my $account_city = $account->city;
	my $account_country = $account->country;
	my $account_type = $account->account_type;
	my $account_notes = $account->account_notes;
	my $la = $account->org;
	my $small_school = $account->small_school;
	
	my $firstname = $user->firstname;
	my $surname = $user->surname;
	
	my $linked_text = "";
	
	if($linked_account)
	{
		my $name = $linked_account->get_account_name;
		my $url = $linked_account->url;
		
		my $upsell_email_content = $account->get_text_entry('upsell_email_confirmation');
		
		$upsell_email_content =~ s/---name---/$name/gi;
		
		$email_content .= $upsell_email_content;
		
		$linked_text=<<"+++";
LINKED TO ACCOUNT:

$name
$url

+++
	}
	
	if($self->{installation}->is_dictionary)
	{
		my $admin_email_content=<<"+++";
A new DICTIONARY account has been registered:

name: 		$account_name
la:			$la

firstname:	$firstname
surname:	$surname
email:		$email
password: 	$password

$account_notes
+++

		if(!$self->dev_mode)
		{
			Webkit::AppTools->send_email({
				from => 'dictionary@iboard.co.uk',
				to => $email,
				subject => 'Your SWGfL Dictionary Account',
				message => $email_content });
		}

		foreach my $admin_email (@admin_emails)
		{
			if(!$self->dev_mode)
			{
				Webkit::AppTools->send_email({
					from => 'dictionary@iboard.co.uk',
					to => $admin_email,
					subject => 'New dictionary account',
					message => $admin_email_content });
			}
		}
	}
	else
	{
		my $admin_email_content=<<"+++";
A new player account has been registered:

URL:		http://$url.iboard.co.uk

type:		$account_type
name: 		$account_name
la:			$la
city:		$account_city
country:	$account_country
small:		$small_school

firstname:	$firstname
surname:	$surname
email:		$email

$linked_text

$account_notes
+++

		if(!$self->dev_mode)
		{
			Webkit::AppTools->send_email({
				from => 'info@iboard.co.uk',
				to => $email,
				subject => 'Your i-board player account',
				message => $email_content });
		}

		foreach my $admin_email (@admin_emails)
		{
			if(!$self->dev_mode)
			{
				Webkit::AppTools->send_email({
					from => 'info@iboard.co.uk',
					to => $admin_email,
					subject => 'New player account',
					message => $admin_email_content });
			}
		}
	}
}

sub generate_account_url
{
	my ($self, $firstpart, $secondpart) = @_;

	$firstpart =~ s/\W//g;
	$secondpart =~ s/\W//g;
	
	my $url = lc($firstpart.'.'.$secondpart);
	
	$url =~ s/school//;
	$url =~ s/primary//;
	
	$url =~ s/^\.//;
	$url =~ s/\.$//;

	my $existing = Webkit::Player::Account->load($self->{db}, {
		clause => 'url = ? and installation_id = ?',
		binds => [$url, $self->installation_id]
	});

	my $count = 1;
	my $orig_url = $url;

	while($existing)
	{
		$count++;

		$url = $orig_url.$count;

		$existing = Webkit::Player::Account->load($self->{db}, {
			clause => 'url = ? and installation_id = ?',
			binds => [$url, $self->installation_id]
		});		
	}

	return $url;
}

sub viewer__update_details_handler
{
	my ($self) = @_;
	
	my $account_id = $self->{params}->{account_id};
	my $city = $self->{params}->{city};
	my $postcode = $self->{params}->{postcode};
	my $user_name = $self->{params}->{user_name};
	my $email = $self->{params}->{email};
	
	if(!Webkit::AppTools->check_email_address($email))
	{
		$self->{page_content}=<<"+++";
<error>
	$email is not a valid email address
</error>
+++
	}
	
	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $self->{params}->{account_id} });
			
	$account->city($city);
	$account->postcode($postcode);
	
	my $user = Webkit::Player::User->constructor($self->{db});
	
	$user->installation_id($self->installation_id);
	$user->username($email);
	$user->password('password');
	$user->name($user_name);
	$user->created(Webkit::DateTime->now);	
	
	my $url = $self->generate_account_url($account->name, $city);

	$account->url($url);
	
	$self->{db}->begin_transaction;
	
	$account->save;
	
	$user->account_id($account->get_id);
	
	$user->create;
	
	$self->{db}->commit;
	
	$self->{page_content}=<<"+++";
<success/>
+++

	$self->send_new_account_emails($account, $user, $url);
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# FRONT END APP
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################


########################################################################################
######################
# ACCOUNT MANAGEMENT
######################
########################################################################################

sub get_school_name
{
	my ($self) = @_;
	
	my $account = $self->load_account_from_subdomain;
	
	if(!$account) { return 'Demo School'; }
	
	return $account->get_account_name;
}

########################################################################################
######################
# FLASH
######################
########################################################################################

sub viewer__activity_help_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{ou_id};

	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
	
	my $help = Webkit::AppTools->xml_quote($ou->comment);
	my $quick_comment = Webkit::AppTools->xml_quote($ou->ensure_quick_comment);
	my $teacher_quote = Webkit::AppTools->xml_quote($ou->teacher_quote);
	
	#$help =~ s/\r//g;
	#$help =~ s/\n+/\n/g;
	
	my $ret=<<"+++";
<activity id="$id">
	<comment>$help</comment>
	<quick_comment>$quick_comment</quick_comment>
	<teacher_quote>$teacher_quote</teacher_quote>
</activity>
+++

	$self->{page_content} = $ret;
}

sub viewer__activity_data_handler
{
	my ($self) = @_;

	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $self->{params}->{ou_id} });
			
	$ou->load_keywords;
	
	my $thumbnail = $ou->load_thumbnail_path;
			
	my $help = Webkit::AppTools->xml_quote($ou->comment);
	my $quick_comment = Webkit::AppTools->xml_quote($ou->ensure_quick_comment);
	my $teacher_quote = Webkit::AppTools->xml_quote($ou->teacher_quote);
	
	my $id = $ou->get_id;
	my $name = $ou->name;
	
	$thumbnail = '/images/image_content.app?image_path='.$thumbnail;
	
	my $ret=<<"+++";
<activity id="$id" name="$name" thumbnail="$thumbnail">
	<comment>$help</comment>
	<quick_comment>$quick_comment</quick_comment>
	<teacher_quote>$teacher_quote</teacher_quote>
</activity>
+++

	$self->{page_content} = $ret;
}

sub viewer__account_data_handler
{
	my ($self, $mode) = @_;
	
	my $account = $self->load_account_from_subdomain;
	
	my $text_entries_needed = [
		'blank_text_shop',
		'blank_text_library',
		'account_type_description',
		'account_type_intro',
		'copyright_message',
		'cart_type_message',
		'welcome_message',
		'welcome_message_pupil',
		'welcome_message_teacher' ];
		
	my $text_entry_map;
	
	if($account)
	{
		$text_entry_map = $account->get_text_entry_map($text_entries_needed);
	}
	else
	{
		my $default_account = Webkit::Player::Account->constructor($self->{db});
		
		$text_entry_map = $default_account->get_default_text_entry_map($self->installation_id, $text_entries_needed);
	}
	
	my $text_entry_string = "";
	
	foreach my $name (keys %$text_entry_map)
	{
		my $content = Webkit::AppTools->xml_quote($text_entry_map->{$name});
		
		$text_entry_string.=<<"+++";
	<text_entry name="$name">$content</text_entry>
+++
	}		
	
	my $xml = '';	
	
	if(!$account)
	{
		$xml=<<"+++";
<account_data id="0" name="Demo School" isDemoSchool="y" has_pupils="n">
$text_entry_string
</account_data>
+++
	}
	elsif($mode eq 'cd')
	{
		my $id = $account->get_id;
		my $name = Webkit::AppTools->xml_quote($account->get_account_name);
		my $account_flag = $account->account_flag;
		my $account_type = $account->account_type;
		
		$xml=<<"+++";
<account_data run_mode="cd" id="$id" name="$name" free_allowed="0" account_flag="$account_flag" account_type="$account_type" open_access="n" has_pupils="n" upseller="n" can_link="n" disable_shop="y">		
</account_data>
+++
	}
	else
	{
		my $id = $account->get_id;
		
		############## Purchase records
		my $number_of_free_activities = $account->get_free_activities_allowed;
		
		$account->load_viewer_purchase_records;
		$account->load_teachers_with_playlist;
		
		##############
		
		my $name = Webkit::AppTools->xml_quote($account->get_account_name);
	
		my $account_flag = $account->account_flag;
		my $account_type = $account->account_type;
		
		my $open_access_st = 'n';
		
		if($account->is_open_access)
		{
			$open_access_st = 'y';
		}
		
		my $has_pupils = 'n';
		
		if($account->has_pupils)
		{
			$has_pupils = 'y';
		}
		
		my $upseller = 'n';
		
		if($account->is_upseller)
		{
			$upseller = 'y';
		}
		
		my $can_link = 'n';
		
		if($account->can_link)
		{
			$can_link = 'y';
		}
		
		my $disable_shop = 'n';
		
		if($account->is_shop_disabled)
		{
			$disable_shop = 'y';
		}
		
		my $init_view = '';
		
		if($account->is_online_club_current)
		{
			$init_view = 'start';
		}
		
		if($account->starting_view =~ /\w/)
		{
			$init_view = $account->starting_view;
		}
			
		$xml=<<"+++";
<account_data id="$id" init_view="$init_view" name="$name" free_allowed="$number_of_free_activities" account_flag="$account_flag" account_type="$account_type" open_access="$open_access_st" has_pupils="$has_pupils" upseller="$upseller" can_link="$can_link" disable_shop="$disable_shop">
$text_entry_string
+++

		foreach my $user (@{$account->ensure_child_array('user')})
		{
			my $id = $user->get_id;
			my $fullname = $user->get_name;
			my $yeargroup = $user->yeargroup;
			my $firstname = $user->firstname;
			my $surname = $user->surname;
			my $title = $user->title;
			
			$xml.=<<"+++";
	<teacher id="$id" fullname="$fullname" firstname="$firstname" surname="$surname" yeargroup="$yeargroup" title="$title" />
+++
		}

		my $views;

		foreach my $record (@{$account->ensure_child_array('purchase_record')})
		{
			if(!$record->is_active)
			{
				next;
			}
			
			my $type = $record->purchase_type;
			my $ou_id = $record->ou_id;
			my $collection_id = $record->collection_id;
			my $amount = $record->purchase_amount;
			my $days_left = $record->get_days_left;
			
			my $keywords_string = "";
			
			if($record->is_subscription)
			{
				if(!$views)
				{
					$views = Webkit::Player::Views->new($self->{db}, $self->installation_id, $account->menu_to_use);
				}
				
				my $collection_keywords = $views->get_collection_keywords($record->collection_id);
				
				foreach my $key (keys %$collection_keywords)
				{
					my $value = $collection_keywords->{$key};
					
					$keywords_string.=<<"+++";
		<keyword word="$key" value="$value" />
+++
				}
			}
			
			if($type eq '6month_subscription')
			{
				$type = 'subscription';
			}
		
			$xml.=<<"+++";
	<purchase_record type="$type" ou_id="$ou_id" collection_id="$collection_id" amount="$amount" days_left="$days_left">
$keywords_string	
+++

			$xml.=<<"+++";
	</purchase_record>		
+++
		}
	
		$xml.=<<"+++";
</account_data>
+++
	}
	
	$self->{page_content} = $xml;
}

sub viewer__purchase_cart_handler
{
	my ($self) = @_;

	my $account_id = $self->{params}->{account_id};
	my $ou_ids = $self->{params}->{ou_ids};

	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $account_id });

	my $free_left = $account->free_activities_left;

	my @id_prices = split(/_/, $ou_ids);

	my $xml=<<"+++";
<account_data from_purchase="y">
+++

	my $activity_names = [];
	
	$self->{db}->begin_transaction;
	
	foreach my $id_price (@id_prices)
	{
		my ($id, $price) = split(/:/, $id_price);
		
		if($account->has_purchased_activity_by_id($id)) { next; }
		
		my $record = Webkit::Player::PurchaseRecord->constructor($self->{db});
		my $ou = Webkit::Player::OU->load($self->{db}, {
			id => $id });
			
		push(@$activity_names, $ou->name);
		
		$record->installation_id($self->installation_id);
		$record->account_id($account_id);
		$record->purchase_date(Webkit::DateTime->now);
		$record->ou_id($id);
		
		my $type = 'purchase';
		my $amount = $price;
		
		if($free_left>0)
		{
			if($amount<=0)
			{
				$type = 'free';
			
				$free_left--;
			}
		}
		
		$record->purchase_type($type);
		$record->purchase_amount($amount);	
		
		$record->create;
		
		$xml.=<<"+++";
	<purchase_record type="$type" ou_id="$id" collection_id="" amount="$amount" />
+++
	}
	
	$account->set_value('cart_ids', '');
	
	$account->save;
	
	$self->{db}->commit;
	
	$xml.=<<"+++";
</account_data>	
+++

	my $subdomain = $account->url;
	my $activity_names_string = join("\n", @$activity_names);
	
	if(!$self->dev_mode)
	{
		my $emails = $account->get_user_emails || [];
	
		my $email_message=<<"+++";
You have just purchased some i-board activities.

These activities are accessible via your i-board player located at:

http://$subdomain.iboard.co.uk

A list of the activities purchased are shown below:

$activity_names_string
+++

		if(!$self->dev_mode)
		{
			foreach my $email (@$emails)
			{
				Webkit::AppTools->send_email({
					from => 'info@iboard.co.uk',
					to => $email,
					subject => 'Your iboard activities have been added...',
					message => $email_message });
			}
		}
	}

	$self->{page_content} = $xml;
}

sub get_dictionary_homepage_xml
{
	my ($self) = @_;
	
	#my $image_files = $self->get_list_of_word_images;
	
	#my $installation = $self->load_installation;
	
	my $clause=<<"+++";
keyword1.ou_id = keyword2.ou_id
and keyword1.installation_id = ?
and keyword1.word = ?
and keyword2.word = ?
+++

	my $refs = $self->{db}->get_select_refs({
		table => 'player.keyword as keyword1, player.keyword as keyword2',
		cols => 'keyword2.value as image',
		clause => $clause,
		binds => [$self->installation_id, 'use_image_in_dictionary', 'final_dictionary_image'],
		group => 'keyword1.ou_id'
	});
	
	my $letter_map = {};
	my $final_letter_map = {};
	
	foreach my $ref (@$refs)
	{
		my $file = $ref->{image};
		
		$file =~ /^(\w)/;
		
		my $letter = lc($1);
		
		push(@{$letter_map->{$letter}}, $file);
	}
	
	my $xml=<<"+++";
<activity_data>
+++
	
	foreach my $letter (sort keys %$letter_map)
	{
		my $arr = $letter_map->{$letter};
		
		my $randomelement = $arr->[rand @$arr];
		
		my $thumbnail = $words_folder.'wordImages/'.$randomelement;
		
		$xml.=<<"+++";
<activity id="$letter" name="$letter words" thumbnail="$thumbnail" sound="">		
	<k t="normal" w="dictionary_homepage" v="yes" />
</activity>
+++
	}
	
	$xml.=<<"+++";
</activity_data>
+++

	return $xml;
}

sub viewer__dictionary_homepage_data_handler
{
	my ($self) = @_;

	$self->fully_load_installation;
	
	my $xml = $self->get_dictionary_homepage_xml;
	
	$self->{page_content} = $xml;
}

sub viewer__view_data_handler
{
	my ($self) = @_;
	
	$self->fully_load_installation;
	$self->load_account_from_subdomain;

	if(!$self->{views})
	{
		my $menu_to_use = undef;
		
		if($self->{account})
		{
			$menu_to_use = $self->{account}->menu_to_use;
		}
		
		$self->{views} = Webkit::Player::Views->new_with_installation($self->{installation}, $menu_to_use);
	}

	my $views = $self->{views};
	my $tree = [];

	my $node_id = $self->{params}->{node};
	
	if($node_id !~ /\w/)
	{
		$node_id = 'root-view';	
	}
	
	my $library_mode = undef;
	
	if($self->{params}->{library_load_all} ne 'y')
	{
		if($node_id eq 'library-all')
		{
			$library_mode = 'all';
		}
		elsif($self->{params}->{library_mode} eq 'y')
		{
			$library_mode = 'purchased';
		}
	}
	
	my $xml=<<"+++";
<data>
	<view_data>
+++

	if($node_id eq 'root-view')
	{
		my $child_nodes = $views->get_array_of_view_nodes(1);

		foreach my $child_node (@$child_nodes)
		{
			if($child_node->getNodeName eq 'divider')
			{
				$xml.=<<"+++";
		<divider />
+++
			}
			else
			{
				my $children_array = $views->get_child_elements($child_node);

				my $children_count = @$children_array;

				my $is_leaf = $self->{json}->true;

				if($children_count>0)
				{
					$is_leaf = $self->{json}->false;
				}
			
				my $id = $child_node->getAttribute('id');
				my $text = $child_node->getAttribute('name');
				my $filter_on = $child_node->getAttribute('filter_on');
				my $filter_config = $child_node->getAttribute('filter_config');
				my $auto_expand = $child_node->getAttribute('auto_expand');
				my $node_type = $child_node->getNodeName;
				my $leaf = $is_leaf;
				
				my $description_text = $views->get_description_text($child_node);
			
				my $extra = "";
			
				if($filter_on =~ /\w/)
				{
					$extra .= " filter_on=\"$filter_on\"";
				}
			
				if($filter_config =~ /\w/)
				{
					$extra .= " filter_config=\"$filter_config\"";
				}
				
				if($auto_expand =~ /\w/)
				{
					$extra .= " auto_expand=\"$auto_expand\"";
				}
			
				$text = Webkit::AppTools->xml_quote($text);
			
				$xml.=<<"+++";
		<view id="$id" name="$text" node_type="$node_type" leaf="$leaf" show_activities="false" $extra>
			<description>$description_text</description>
		</view>
+++
			}
		}
	}
	elsif($library_mode eq 'all')
	{	
		if($self->{account})
		{
			$self->{account}->load_all_library_activities($self->{installation});
			$self->{activity_results} = $self->{account}->ensure_child_array('ou');
		}
		else
		{
			$self->{activity_results} = [];
		}
	}
	else
	{
		my $ignore_params = {
			show_activities => 1,
			maxNumberActivities => 1,
			account_id => 1,
			node => 1,
			session_id => 1 };

		my $keyword_params = {};

		foreach my $key (keys %{$self->{params}})
		{
			if(!$ignore_params->{$key})
			{
				$keyword_params->{$key} = $self->{params}->{$key};
			}
		}
		
		my $ou_types = ['teaching_resource'];
		
		if($self->{installation}->is_dictionary)
		{
			$ou_types = ['definition'];
		}

		my $grouping_results = $views->get_node_groups({
			player_mode => 1,
			ou_types => $ou_types,
			view_id => $node_id,
			params => $keyword_params,
			json => $self->{json} });

		$self->{activity_results} = [];
		
		$self->{activity_results} = $views->get_activity_results($self->{params}->{maxNumberActivities});
		$views->load_keywords_for_ous($self->{activity_results});
		
		#die $self->{db}->get_log;
		
		if($self->{installation}->is_dictionary)
		{
			$views->load_thumbnails_and_sounds_for_ous($self->{activity_results});
		}
		else
		{
			$views->load_thumbnails_for_ous($self->{activity_results});	
		}

		foreach my $result (@$grouping_results)
		{	
			my $id = $result->{id};
			my $text = $result->{text};
			my $node_type = $result->{node_type};
			my $leaf = $result->{leaf};
			
			$text = Webkit::AppTools->xml_quote($text);
			
			$xml.=<<"+++";
		<view id="$id" name="$text" node_type="$node_type" leaf="$leaf">	
+++

			foreach my $key (keys %{$result->{params}})
			{
				my $value = $result->{params}->{$key};
				
				$xml.=<<"+++";
			<param name="$key" value="$value" />
+++
			}
			
			$xml.=<<"+++";
		</view>
+++
		}
	}
	
	$xml.=<<"+++";
	</view_data>
+++

	if(($self->{installation}->is_dictionary)&&($node_id eq 'root-view'))
	{
		$xml .= $self->get_dictionary_homepage_xml;
	}
	else
	{
		$xml.=<<"+++";
	<activity_data>	
+++

		if($library_mode eq 'purchased')
		{
			
		
			if($self->{account})
			{
				$self->{account}->load_viewer_purchase_record_map;
			}
		}

		my $activity_array = [];
	
		foreach my $activity (@{$self->{activity_results}})
		{
			if(($library_mode ne 'all')&&(!$self->{installation}->is_dictionary))
			{
				#### THIS IS IMPORTANT - it makes sure that the activity actually belongs to the
				#### path choosen rather than because it crosses its keywords
				if(!$views->does_activity_have_required_structure_keywords($activity))
				{
					next;
				}
		
				#### This means that only purchased activities will be shown
				if($library_mode eq 'purchased')
				{
					if($self->{account})
					{
						if(!$self->{account}->has_purchased_activity($activity))
						{
							next;
						}
					}
				}
			}
		
			$activity->{filter_on} = $views->{filter_on};
		
			push(@$activity_array, $activity);
		}
		
		$self->{library_activities} = $activity_array;
	
		$xml .= $self->get_activity_data_xml($activity_array);
		
		$xml.=<<"+++";
</activity_data>		
+++
	}
	
	$xml.=<<"+++";
</data>
+++

	$self->{page_content} = $xml;
}

sub get_activity_data_xml
{
	my ($self, $activity_array) = @_;
	
	if(!$activity_array) { $activity_array = []; }
	
	my $xml = '';
	
	foreach my $activity (@$activity_array)
	{
		my $id = $activity->get_id;
		my $name = Webkit::AppTools->xml_quote($activity->name);
		my $tes_url = Webkit::AppTools->xml_quote($activity->tes_url);
		my $thumbnail = '';
		my $sound = '';
		
		if($activity->{data}->{thumbnail_url}=~/\w/)
		{
			$thumbnail = '/files/'.$activity->{data}->{thumbnail_url};
			
			if(($thumbnail =~ /\.jpg$/i)&&($self->{params}->{plain_thumbnails}!~/\w/))
			{
				$thumbnail = '/images/image_content.app?image_path='.$thumbnail;	
			}
		}
		
		if($activity->{data}->{sound_url}=~/\w/)
		{
			$sound = '/files/'.$activity->{data}->{sound_url};
		}
		
		if(($self->{installation}->is_dictionary)&&(!$activity->is_playlist))
		{
			if(($self->{use_all_dictionary_images} eq 'yes')||($activity->get_keyword_value('use_image_in_dictionary')))
			{
				my $local_folder = $ENV{DOCUMENT_ROOT}.$words_folder;
					
				#my $image_to_use = $activity->get_keyword_value('alternative_image');
				#my $default_image = $activity->get_keyword_value('default_image');
					
				#if($image_to_use!~/\w/)
				#{
				#	if($activity->get_keyword_value('default_image') ne 'no')
				#	{
				#		$image_to_use = lc($activity->name).'.swf';
				#	}
				#}
				
				my $image_to_use = $activity->get_keyword_value('final_dictionary_image');
					
				if($image_to_use =~ /\w/)
				{
					my $web_thumbnail = $words_folder.'wordImages/'.$image_to_use;
				
					my $local_thumbnail = $ENV{DOCUMENT_ROOT}.$web_thumbnail;
				
					if(-e $local_thumbnail)
					{
						$thumbnail = $web_thumbnail;
					}
				}
			}				
			
			if($sound!~/\w/)
			{
				my $sound_to_use = $activity->get_keyword_value('alternative_sound');
				
				if($sound_to_use!~/\w/)
				{
					$sound_to_use = lc($activity->name).'.mp3';
				}
						
				if(lc($activity->get_keyword_value('initial_capital')) eq 'yes')
				{
					my $sound_name = lc($activity->name);
					
					$sound_name =~ /^(\w)/;
						
					my $upper = uc($1);
						
					$sound_name =~ s/^(\w)/$upper/;
					
					$sound_to_use = $sound_name.'.mp3';
				}
					
				my $web_sound = $words_folder.'wordSounds/'.$sound_to_use;
				my $local_sound = $ENV{DOCUMENT_ROOT}.$web_sound;
				
				if(-e $local_sound)
				{
					$sound = $web_sound;
				}
			}
		}			

		$thumbnail = Webkit::AppTools->xml_quote($thumbnail);
		$sound = Webkit::AppTools->xml_quote($sound);
		
		my $help = Webkit::AppTools->xml_quote($activity->ensure_quick_comment);
		my $full_comment = '';
		
		if($self->{installation}->is_dictionary)
		{
			$help = Webkit::AppTools->xml_quote($activity->comment);
		}
		else
		{
			my $full_comment_text = $activity->comment;
			
			$full_comment=<<"+++";
	
	<full_comment>$full_comment_text</full_comment>

+++
		}
		
		$help =~ s/[^\w\.]+$//;
		
		my $extra = "";
		
		if($activity->{filter_on} =~ /\w/)
		{
			my $filter_on = $activity->{filter_on};
			
			$extra .= " filter_on=\"$filter_on\"";
		}
		
		if($activity->is_playlist)
		{
			my $item_path = $activity->item_path;
			
			$extra .= " item_path=\"$item_path\"";
		}
		
		$xml.=<<"+++";
		<activity id="$id" tes_url="$tes_url" name="$name" thumbnail="$thumbnail" sound="$sound" $extra >
			<comment>$help</comment>
			$full_comment
+++

		if($activity->is_word)
		{
			foreach my $definition (@{$activity->get_definitions})
			{
				my $t = $definition->comment;
				
				$t =~ s/[^\w\.]+$//;
				
				my $definition_text = Webkit::AppTools->xml_quote($t);
				
				$xml.=<<"+++";
			<definition>$definition_text</definition>		
+++
			}
		}
		
		if($activity->is_definition)
		{
			my $t = $activity->comment;
				
			$t =~ s/[^\w\.]+$//;
				
			my $definition_text = Webkit::AppTools->xml_quote($t);
			
			$xml.=<<"+++";
			<definition>$definition_text</definition>		
+++
		}

		my $keyword_hash = $activity->get_keyword_hash;

		foreach my $keyword_type (keys %$keyword_hash)
		{
			if($ignore_keyword_types_for_player->{$keyword_type}) { next; }
			
			foreach my $key (keys %{$keyword_hash->{$keyword_type}})
			{
				my $value = $keyword_hash->{$keyword_type}->{$key};
				my $use_arr = [];
				
				if(ref($value) eq 'ARRAY')
				{
					$use_arr = $value;
				}
				else
				{
					$use_arr = [$value];	
				}
				
				$key = Webkit::AppTools->xml_quote($key);
				
				foreach my $use_val (@$use_arr)
				{
					$use_val = Webkit::AppTools->xml_quote($use_val);
					
					$xml.=<<"+++";
			<k t="$keyword_type" w="$key" v="$use_val" />
+++
				}
			}
		}
		
		$xml.=<<"+++";
		</activity>
+++
	}
	
	return $xml;
}

###################################################################
### Load Cart

sub viewer__save_cart_data_handler
{
	my ($self) = @_;

	my $account = $self->load_account_from_subdomain;
	
	if($account)
	{
		$account->cart_ids($self->{params}->{cart_ids});
		
		$self->{db}->begin_transaction;
		
		$account->save;
		
		$self->{db}->commit;
	}
	
	$self->{page_content}=<<"+++";
<success/>
+++
}

sub viewer__playlists_data_handler
{
	my ($self) = @_;
	
	$self->fully_load_installation;
	my $account = $self->load_account_from_subdomain;
	
	my $menu_to_use = undef;
	
	if($account)
	{
		$menu_to_use = $account->menu_to_use;
	}
	
	my $views = Webkit::Player::Views->new($self->{db}, $self->installation_id, $menu_to_use);

	if($account)
	{
		my $user_id = $self->{params}->{user_id};
		my $yeargroup = $self->{params}->{yeargroup};
		
		if($user_id!~/\d/)
		{
			$self->do_login;
			
			if($self->{user})
			{
				$user_id = $self->{user}->get_id;
			}
		}
		
		if(($user_id=~/\w/)||($yeargroup=~/\w/)||($self->{params}->{from_homepage} eq 'y'))
		{
			$account->load_playlists($user_id, $yeargroup);
		}
	}
	
	my $xml=<<"+++";
<data>
	<activity_data>
+++
	
	$xml .= $self->get_activity_data_xml($account->ensure_child_array('ou'));
	
	$xml.=<<"+++";
	</activity_data>
</data>
+++

	$self->{page_content} = $xml;
}

sub viewer__add_word_handler
{
	my ($self) = @_;
	
	if(!$self->do_login)
	{
		$self->{page_content}=<<"+++";
<add_word_response code="notok" error_text="Invalid Login Details...">
</add_word_response>
+++

		return;
	}
	
	$self->load_installation;
	
	my $views = Webkit::Player::Views->new_with_installation($self->{installation});
	
	my $code = 'ok';
	my $error_text = '';
	my $data_type = 'word';
	
	my $word = $self->{params}->{word};
	my $activities = [];
	
	if($word =~ /[^\w\']/)
	{
		$code = 'notok';
		$error_text = '[a-z], [1-9] and \' only are allowed in the word';
	}
	else
	{
		$self->{installation}->load_children('Webkit::Player::OU', {
			clause => '(ou_type = ? or ou_type = ?) and name = ?',
			binds => ['definition', 'word', $word] });
		
		my $ou_array = $self->{installation}->ensure_child_array('ou');
	
		my $count = @$ou_array;
		
		my $definitions = [];
		my $words = [];
	
		if($count>0)
		{
			foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
			{
				if($ou->is_definition)
				{
					push(@$definitions, $ou);
				}
				elsif($ou->is_word)
				{
					push(@$words, $ou);
				}
			}
			
			if($definitions)
			{
				$views->load_thumbnails_for_ous($definitions);
				$views->load_keywords_for_ous($definitions);
				
				$activities = $definitions;
			}
			else
			{
				my $activity = Webkit::Player::OU->constructor($self->{db});
				$activity->{data}->{id} = 'newWord_'.$word;
				$activity->name($word);
				$activity->ou_type('definition');
				
				$activities = [$activity];
			}
		}
		else
		{
			#### insert moderation
			
			my $existing_moderation = Webkit::Player::Moderation->load($self->{db}, {
				clause => 'user_id = ? and action_type = ? and action_data = ?',
				binds => [$self->{user}->get_id, 'add_word', $word] });
					
			if(!$existing_moderation)
			{
				my $moderation = Webkit::Player::Moderation->constructor($self->{db});
				$moderation->installation_id($self->{installation}->get_id);
				$moderation->account_id($self->{account}->get_id);
				$moderation->user_id($self->{user}->get_id);
				$moderation->created(Webkit::DateTime->now);
				$moderation->action_type('add_word');
				$moderation->action_data($word);
				
				$self->{db}->begin_transaction;
				
				$moderation->create;
				
				$self->{db}->commit;
			}
			
			my $activity = Webkit::Player::OU->constructor($self->{db});
			$activity->{data}->{id} = 'newWord_'.$word;
			$activity->name($word);
			$activity->ou_type('definition');
			
			$activities = [$activity];
		}
	}
	
	my $activity_xml = $self->get_activity_data_xml($activities);
	
	$self->{page_content}=<<"+++";
<add_word_response code="$code" error_text="$error_text" word="$word">
	<activity_data>
		$activity_xml
	</activity_data>
</add_word_response>
+++
}

sub viewer__update_password_handler
{
	my ($self) = @_;
	
	my $code = 'ok';
	my $error_text = '';
	
	if(!$self->do_login)
	{
		$code = 'notok';
		$error_text = 'Invalid Login Details...';	
	}
	else
	{
		if($self->{user}->get_id!=$self->{params}->{user_id})
		{
			$code = 'notok';
			$error_text = 'User Mismatch...';	
		}
		else
		{
			my $password = $self->{params}->{password};
			my $yeargroup = $self->{params}->{yeargroup};
			
			my $user = Webkit::Player::User->load($self->{db}, {
				id => $self->{user}->get_id });
		
			$self->{db}->begin_transaction;

			if($password=~/\w/)
			{
				$user->password($password);
			}
				
			$user->yeargroup($yeargroup);
				
			$user->save;
		
			$self->{db}->commit;
				
			$error_text = 'Details Updated...';
		}
	}
	
	$self->{page_content}=<<"+++";
<update_password_response code="$code" error_text="$error_text">
</update_password_response>
+++
}

sub viewer__teacher_login_handler
{
	my ($self) = @_;
	
	my $code = 'ok';
	my $error_text = '';
	my $session_id = '';
	my $fullname = '';
	my $user_id = '';
	my $yeargroup = '';
	
	if(!$self->do_teacher_login)
	{
		$code = 'notok';
		$error_text = 'Incorrect details - please try again...';
	}
	else
	{
		$session_id = $self->{session_id};
		$user_id = $self->{user}->get_id;
		$fullname = $self->{user}->get_name;
		$yeargroup = $self->{user}->yeargroup;
	}
	
	$self->{page_content}=<<"+++";
<login_response code="$code" error_text="$error_text" session_id="$session_id" user_id="$user_id" fullname="$fullname" yeargroup="$yeargroup">
</login_response>
+++
}

sub viewer__teacher_reminder_handler
{
	my ($self) = @_;
	
	$self->load_installation;
	
	my $code = 'ok';
	my $error_text = '';
	
	my $email = $self->{params}->{email};

	if(!Webkit::AppTools->check_email_address($email))
	{
		$code = 'notok';
		$error_text = $email.' is not a valid email address';
	}
	else
	{
		my $account = $self->load_account_from_subdomain;
	
		if($account)
		{
			my $user = Webkit::Player::User->load($self->{db}, {
				clause => 'account_id = ? and username = ?',
				binds => [$account->get_id, lc($email)] });
					
			if($user)
			{		
				my $password = $user->password;
					
				my $email_text=<<"+++";
Your password for the Word Wizard is:

$password		
+++

				if(!$self->dev_mode)
				{
					Webkit::AppTools->send_email({
						from => 'dictionary@swgfl.org.uk',
						to => $user->username,
						subject => 'Word Wizard Password',
						message => $email_text });
				}
				
				$error_text = 'a reminder has been emailed to '.$email;
			}
			else
			{
				$code = 'notok';
				$error_text = 'No user found for '.$email;
			}
		}
		else
		{
			$code = 'notok';
			$error_text = 'no school account found';
		}
	}
	
	$self->{page_content}=<<"+++";
<reminder_response code="$code" error_text="$error_text">
</reminder_response>
+++
}

sub viewer__save_playlist_handler
{
	my ($self) = @_;
	
	if(!$self->do_login)
	{
		$self->{page_content}=<<"+++";
0	
+++

		return;
	}
	
	my $playlist = Webkit::Player::OU->constructor($self->{db});
	my $account = $self->load_account_from_subdomain;
	
	if($self->{params}->{id}>0)
	{
		$playlist = Webkit::Player::OU->load($self->{db}, {
			id => $self->{params}->{id} });	
	}
	else
	{
		$playlist->installation_id($self->installation_id);
		$playlist->ou_type('playlist');
		$playlist->set_value('ou_id', 0);
		$playlist->user_id($self->{user}->get_id);
		$playlist->account_id($self->{account}->get_id);
	}
	
	if($self->{params}->{no_form_data}!~/\w/)
	{
		$playlist->name($self->{params}->{name});
		$playlist->comment($self->{params}->{comment});
	}
	
	$playlist->item_path($self->{params}->{ids});
	
	$self->{db}->begin_transaction;
	
	$playlist->save_or_create;
	
	$playlist->load_keywords;
	
	if($self->{params}->{no_form_data}!~/\w/)
	{
		my $teacher_keyword = $playlist->get_keyword('teacher');
	
		if(!$teacher_keyword)
		{
			$playlist->create_keyword('teacher', $self->{params}->{teacher});
		}
		else
		{
			$teacher_keyword->value($self->{params}->{teacher});
			$teacher_keyword->save;
		}
	}
	
	$self->{db}->commit;
	
	my $id = $playlist->get_id;
	
	$self->{content_type} = "application/x-www-form-urlencoded";
	
	$self->{page_content}=<<"+++";
$id
+++
}

sub viewer__delete_playlist_handler
{
	my ($self) = @_;
	
	my $playlist = Webkit::Player::OU->load($self->{db}, {
			id => $self->{params}->{playlist_id} });
	
	$self->{db}->begin_transaction;
	
	$playlist->delete;
	
	$self->{db}->commit;
	
	$self->{page_content}=<<"+++";
<success/>
+++
}

sub viewer__playlist_data_handler 
{
	my ($self) = @_;
	
	$self->fully_load_installation;
	my $account = $self->load_account_from_subdomain;
	
	my $menu_to_use = undef;
	
	if($account)
	{
		$menu_to_use = $account->menu_to_use;
	}
	
	my $views = Webkit::Player::Views->new($self->{db}, $self->installation_id, $menu_to_use);
	
	my $id_string = '';
	
	if($self->{params}->{id}>0)
	{
		my $playlist = Webkit::Player::OU->load($self->{db}, {
			id => $self->{params}->{id} });
				
		$id_string = $playlist->item_path;
	}
	elsif($self->{params}->{ids}=~/\d/)
	{
		$id_string = $self->{params}->{ids};
	}
	
	if($id_string=~/\w/)
	{
		$views->load_playlist_activities($id_string);
	
		$self->{activity_results} = $views->get_activity_results($self->{params}->{maxNumberActivities});
		$views->load_thumbnails_for_ous($self->{activity_results});
		$views->load_keywords_for_ous($self->{activity_results});	
		#$views->load_definitions_for_ous($self->{activity_results});	
	}
	else
	{
		$self->{activity_results} = [];
	}
	
	my $arr = $self->{activity_results};
	my $length = @$arr;
	
	my $use_length = $length;
	
	if($self->{params}->{limit}>0)
	{
		$use_length = $self->{params}->{limit};
	}
	
	if($self->{params}->{random} eq 'y')
	{	
		my $newarr = [];
		my $inserted = 0;
		my $unique_inserted = 0;
		my $inserted_map = {};
		
		while($inserted<$use_length)
		{
			my $next_elem_index = rand($length);
		
			my $next_elem = $arr->[$next_elem_index];
		
			if($unique_inserted<$length)
			{
				if(!$inserted_map->{$next_elem->get_id})
				{
					$inserted_map->{$next_elem->get_id} = $next_elem;
					$unique_inserted++;
			
					push(@$newarr, $next_elem);
					$inserted++;
				}
			}
			else
			{
				push(@$newarr, $next_elem);
				$inserted++;
			}
		}
		
		$self->{activity_results} = $newarr;
	}
	elsif($self->{params}->{limit}>0)
	{
		my $inserted = 0;
		my $newarr = [];
		
		while($inserted<$use_length)
		{
			for(my $i=0; $i<$length; $i++)
			{
				my $next_elem = $arr->[$i];
				
				if($inserted<$use_length)
				{
					push(@$newarr, $next_elem);
					$inserted++;
				}
			}
		}
		
		$self->{activity_results} = $newarr;
	}
	
	my $xml=<<"+++";
<data>
	<activity_data>
+++
	
	$xml .= $self->get_activity_data_xml($self->{activity_results});
	
	$xml.=<<"+++";
	</activity_data>
</data>
+++

	$self->{page_content} = $xml;
}

sub viewer__cart_data_handler 
{
	my ($self) = @_;
	
	my $account = $self->load_account_from_subdomain;
	
	my $menu_to_use = undef;
	
	if($account)
	{
		$menu_to_use = $account->menu_to_use;
	}
	
	my $views = Webkit::Player::Views->new($self->{db}, $self->installation_id, $menu_to_use);
	
	if($account)
	{
		$views->load_cart_activities($account->cart_ids);
	
		$self->{activity_results} = $views->get_activity_results($self->{params}->{maxNumberActivities});
		$views->load_thumbnails_for_ous($self->{activity_results});
		$views->load_keywords_for_ous($self->{activity_results});	
	}
	else
	{
		$self->{activity_results} = [];
	}
	
	my $xml=<<"+++";
<data>
	<activity_data>
+++
	
	foreach my $activity (@{$self->{activity_results}})
	{
		my $id = $activity->get_id;
		my $name = Webkit::AppTools->xml_quote($activity->name);
		my $thumbnail = '';

		if($activity->{data}->{thumbnail_url}=~/\w/)
		{
			$thumbnail = '/files/'.$activity->{data}->{thumbnail_url};

			$thumbnail = '/images/image_content.app?image_path='.$thumbnail;
		}
		
		$thumbnail = Webkit::AppTools->xml_quote($thumbnail);
		
		my $help = Webkit::AppTools->xml_quote($activity->quick_comment);		
		
		$xml.=<<"+++";
		<activity id="$id" name="$name" thumbnail="$thumbnail">
			<comment>$help</comment>
+++

		my $keyword_hash = $activity->get_keyword_hash;

		foreach my $keyword_type (keys %$keyword_hash)
		{
			if($ignore_keyword_types_for_player->{$keyword_type}) { next; }
			
			foreach my $key (keys %{$keyword_hash->{$keyword_type}})
			{
				my $value = $keyword_hash->{$keyword_type}->{$key};
				my $use_arr = [];
				
				if(ref($value) eq 'ARRAY')
				{
					$use_arr = $value;
				}
				else
				{
					$use_arr = [$value];	
				}
				
				$key = Webkit::AppTools->xml_quote($key);
				
				foreach my $use_val (@$use_arr)
				{
					$use_val = Webkit::AppTools->xml_quote($use_val);
					
					$xml.=<<"+++";
			<k t="$keyword_type" w="$key" v="$use_val" />
+++
				}
			}
		}
		
		$xml.=<<"+++";
		</activity>
+++
	}
	
	$xml.=<<"+++";
	</activity_data>
</data>
+++

	$self->{page_content} = $xml;
}

###################################################################
### Search


sub viewer__search_keywords_data_handler
{
	my ($self) = @_;
	
	my $account = $self->load_account_from_subdomain;
	
	my $menu_to_use = undef;
	
	if($account)
	{
		$menu_to_use = $account->menu_to_use;
	}
	
	$self->fully_load_installation;
	
	my $views = Webkit::Player::Views->new_with_installation($self->{installation}, $menu_to_use);
	
	my $doc = $views->parse_structure('/viewXML/dictionary.xml');
	
	my $refs = [];
	
	if($self->{params}->{field} !~ /\w/)
	{
		$self->{params}->{field} = 'phase';
	}
	
	if($self->{params}->{field} eq 'phase')
	{
		my $phase_nodes = $doc->getElementsByTagName('phase');
		
		foreach my $phase_node (@$phase_nodes)
		{
			push(@$refs, $phase_node->getAttribute('value'));
		}
	}
	elsif($self->{params}->{field} eq 'title')
	{
		my $phase_nodes = $doc->getElementsByTagName('phase');
		
		foreach my $phase_node (@$phase_nodes)
		{
			if($phase_node->getAttribute('value') eq $self->{params}->{phase})
			{
				my @title_nodes = $phase_node->getChildNodes;
				
				foreach my $title_node (@title_nodes)
				{
					if($title_node->getNodeType != 1) { next; }
					
					push(@$refs, $title_node->getAttribute('value'));
				}
			}
		}
	}
	elsif($self->{params}->{field} eq 'subtitle')
	{
		my $phase_nodes = $doc->getElementsByTagName('phase');
		
		foreach my $phase_node (@$phase_nodes)
		{
			if($phase_node->getAttribute('value') eq $self->{params}->{phase})
			{
				my @title_nodes = $phase_node->getChildNodes;
				
				foreach my $title_node (@title_nodes)
				{
					if($title_node->getNodeType != 1) { next; }
					
					if($title_node->getAttribute('value') eq $self->{params}->{title})
					{
						my @subtitle_nodes = $title_node->getChildNodes;
						
						foreach my $subtitle_node (@subtitle_nodes)
						{
							if($subtitle_node->getNodeType != 1) { next; }
							
							push(@$refs, $subtitle_node->getAttribute('value'));
						}
					}
				}
			}
		}
	}
	
	my $option_xml = '';
	
	foreach my $ref (@$refs)
	{
		my $value = Webkit::AppTools->xml_quote($ref);
		
		$option_xml.=<<"+++";
	<option value="$value" />
+++
	}
	
	my $xml=<<"+++";
<options>
$option_xml
</options>
+++

	$self->{page_content} = $xml;
}

sub viewer__search_keywords_data_handler2
{
	my ($self) = @_;
	
	my $refs = [];
	
	if($self->{params}->{field} eq 'phase')
	{
		$refs = $self->{db}->get_select_refs({
			table => 'player.keyword',
			cols => 'keyword.value',
			clause => 'keyword.installation_id = ? and keyword.word = ?',
			binds => [$self->installation_id, 'phase'],
			group => 'keyword.value',
			order => 'keyword.value' });
	}
	elsif($self->{params}->{field} eq 'title')
	{
		my $clause=<<"+++";
keyword.installation_id = ? 
and keyword.word = ? 
and keyword2.ou_id = keyword.ou_id 
and keyword2.word = ? 
and keyword2.value = ?		
+++

		$refs = $self->{db}->get_select_refs({
			table => 'player.keyword as keyword, player.keyword as keyword2',
			cols => 'keyword.value',
			clause => $clause,
			binds => [$self->installation_id, 'title', 'phase', $self->{params}->{phase}],
			group => 'keyword.value',
			order => 'keyword.value' });
	}
	elsif($self->{params}->{field} eq 'subtitle')
	{
		my $clause=<<"+++";
keyword.installation_id = ? 
and keyword.word = ? 
and keyword2.ou_id = keyword.ou_id 
and keyword2.word = ? 
and keyword2.value = ?		
+++

		$refs = $self->{db}->get_select_refs({
			table => 'player.keyword as keyword, player.keyword as keyword2',
			cols => 'keyword.value',
			clause => $clause,
			binds => [$self->installation_id, 'subtitle', 'title', $self->{params}->{title}],
			group => 'keyword.value',
			order => 'keyword.value' });
	}	
	
	my $option_xml = '';
	
	foreach my $ref (@$refs)
	{
		my $value = Webkit::AppTools->xml_quote($ref->{value});
		
		$option_xml.=<<"+++";
	<option value="$value" />
+++
	}
	
	my $xml=<<"+++";
<options>
$option_xml
</options>
+++

	$self->{page_content} = $xml;	
}

sub viewer__save_link_handler
{
	my ($self) = @_;
	
	my $session = Webkit::Player::Session->constructor($self->{db});
	
	$session->session_id($session->get_session_id);
	$session->created(Webkit::DateTime->now);
	$session->modified(Webkit::DateTime->now);
	$session->set('the_link', $self->{params}->{the_link});
	
	$self->{db}->begin_transaction;
	
	$session->create;
	
	$self->{db}->commit;
	
	my $id = $session->session_id;
	
	$self->{page_content}=<<"+++";
<success session_id="$id" />
+++
}

sub viewer__load_link_handler
{
	my ($self) = @_;
	
	my $session = Webkit::Player::Session->load($self->{db}, {
		clause => 'session_id = ?',
		binds => [$self->{params}->{session_id}] });
			
	my $link = Webkit::AppTools->xml_quote($session->get('the_link'));
	
	$self->{page_content}=<<"+++";
<success link="$link" />
+++
}

sub viewer__search_data_handler 
{
	my ($self) = @_;
	
	$self->fully_load_installation;
	
	my $maxNumberActivities = $self->{params}->{maxNumberActivities};
	
	delete($self->{params}->{maxNumberActivities});
	
	my $namesearch = $self->{params}->{name};
	
	delete($self->{params}->{name});
	
	if($namesearch =~ /\w/)
	{
		$self->{params}->{namesearch} = $namesearch;
	}
	
	foreach my $key (keys %{$self->{params}})
	{
		if($self->{params}->{$key} !~ /\w/)
		{
			delete($self->{params}->{$key});
		}
	}
	
	my $account = $self->load_account_from_subdomain;
	
	my $menu_to_use = undef;
	
	if($account)
	{
		$menu_to_use = $account->menu_to_use;
	}	
	
	my $views = Webkit::Player::Views->new_with_installation($self->{installation}, $menu_to_use);
	
	my $ou_type = 'teaching_resource';
	
	if($self->{installation}->is_dictionary)
	{
		$ou_type = 'definition';
	}
	
	my $search_params = {};
	
	foreach my $key (keys %{$self->{params}})
	{
		if($key eq 'plain_thumbnails') { next; }
		
		$search_params->{$key} = $self->{params}->{$key};	
	}
	
	$views->load_search_activities($search_params, [$ou_type]);
	
	$self->{activity_results} = $views->get_activity_results($maxNumberActivities);
	$views->load_thumbnails_for_ous($self->{activity_results});
	$views->load_keywords_for_ous($self->{activity_results});
	
	if($self->{installation}->is_dictionary)
	{
		#$views->load_definitions_for_ous($self->{activity_results});
	}
	
	my $xml=<<"+++";
<data>
	<activity_data>
+++
	
	$xml .= $self->get_activity_data_xml($self->{activity_results});
	
	$xml.=<<"+++";
	</activity_data>
</data>
+++

	$self->{page_content} = $xml;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# ACTIVITY HTML
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub activity__frameset_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{id};
	my $view_id = $self->{params}->{viewID};
	my $same_window = $self->{params}->{same_window};
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
		
	my $name = $ou->name;

	$self->{page_content}=<<"+++";
<html>
<head>
<title>$name</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<frameset rows="80,*" frameborder="NO" border="0" framespacing="0">
    <frame name="top_bar" scrolling="no" noresize src="/activity/topbar.app?id=$id&view_id=$view_id&same_window=$same_window" >
    <frame name="swf" scrolling="no" noresize src="/activity/swf.app?id=$id" >
</frameset>
</html>
+++
}

sub activity__topbar_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{id};
	my $view_id = $self->{params}->{view_id};
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
		
	my $name = $ou->name;
	my $school_name = $self->get_school_name;
	my $has_help = 'no';
	
	if($ou->has_help)
	{
		$has_help = 'yes';
	}
	
	my $top_bar_name = $view_id;
	my $top_bar_path = $ENV{DOCUMENT_ROOT}.'/player/topBars/'.$top_bar_name.'.swf';
	my $arguments = "has_help=$has_help&activityName=$name&schoolName=$school_name";
	
	if(!-e $top_bar_path)
	{
		$top_bar_name = 'generic';

		my $account = $self->load_account_from_subdomain;
	
		my $menu_to_use = undef;
	
		if($account)
		{
			$menu_to_use = $account->menu_to_use;
		}
		
		my $views = Webkit::Player::Views->new($self->{db}, $self->installation_id, $menu_to_use);
		
		my $view_node = $views->get_node_by_id($view_id);
		
		if($view_node)
		{
			$arguments .= "&topBarTitle=".$view_node->getAttribute('name');
		}
	}
	
	my $swf_path = "/player/topBars/$top_bar_name.swf?$arguments";
	
	my $close_code=<<"+++";
		top.close();	
+++

	if($self->{params}->{same_window} eq 'y')
	{
		$close_code=<<"+++";
		top.history.back(1);
+++
	}
		
	$self->{page_content}=<<"+++";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>$name</title>
<script type="text/javascript" src="/js/lib.js"></script>
<script>
	function closeActivity()
	{
$close_code
	}
	
	function reloadActivity()
	{
		top.swf.location.reload();
	}
	
	function openHelp(bg)
	{
		openWindow('/activity/help.app?id=$id&bg=' + bg, 550, 350);
	}
	
	function openFeedback(bg)
	{
		openWindow('/activity/feedback_frameset.app?id=$id&bg=' + bg, 550, 350);		
	}
</script>
<style type="text/css">
body,html {
    margin:0px;
    padding:0px;
    height:100%;
}

div { font-family:Tahoma;font-size:10pt; }

</style>
</head>
<body bgcolor="#ffffff">
<table width=100% height=100% border=0 cellpadding="0" cellspacing="0">
<tr width=100% height=100%>
<td width=100% height=100% align=center valign=middle>
<script>
	writeFlashToPage("$swf_path", "100%", "100%", null, 'helpSWF');
</script>
</td>
</tr>
</table>
</body>
</html>
+++
}

sub activity__swf_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{id};
	my $evaluation_mode = $self->{params}->{evaluationMode};	
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
		
	$ou->load_keywords;
		
	my $name = $ou->name;
	
	my $timestamp = time;
	
	my $swf_path = "/player/loadMovie.swf?id=$id&timestamp=$timestamp";
	
	my $swf_ou = $ou->load_child_ou('file', 'activity');
	
	if($swf_ou)
	{
		if($swf_ou->item_path =~ /^http:\/\//i)
		{
			$swf_path = $swf_ou->item_path;
		}	
	}
	
	my $evaluation_script = '';
	
#	my $evaluation_script=<<"+++";
#function applyEvaluationText()
#	{
#		var isIE = (navigator.appVersion.indexOf("MSIE") != -1);
#		
#		var swf = null;
#		
#		if(isIE)
#		{
#			swf = document.getElementById('activitySWF');
#		}
#		else
#		{
#			swf = document['activitySWF'];
#		}
#		
#		swf.LoadMovie(5, "/player/evaluationText.swf")
#	}
#	
#	setTimeout("applyEvaluationText();", 3000);	
#+++

	my $account = $self->load_account_from_subdomain(1);
	
	#if(($account)&&($account->has_purchased_activity($ou)))
	#{
	#	$evaluation_script = '';
	#}
	
	#if($ou->has_keyword_value('pricing_model', 'freethismonth'))
	#{
	#	$evaluation_script = '';
	#}
	
	my $log_props = {
		ou_id => $id,
		event_type => 'activity_launch' };
		
	if($account)
	{
		$log_props->{account_id} = $account->get_id;
	}
	
	$self->create_log($log_props);
	
	$self->{page_content}=<<"+++";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>$name</title>
<script type="text/javascript" src="/js/lib.js"></script>
<style type="text/css">
body,html {
    margin:0px;
    padding:0px;
    height:100%;
}

div { font-family:Tahoma;font-size:10pt; }

</style>
<script>	
	$evaluation_script
</script>
</head>
<body bgcolor="#FFFFFF">
<table width=100% height=100% border=0 cellpadding="0" cellspacing="0">
<tr width=100% height=100%>
<td width=100% height=100% align=center valign=middle>
<script>
	writeFlashToPage("$swf_path", "100%", "100%", null, 'activitySWF');
</script>
</td>
</tr>
</table>
</body>
</html>
+++
}

sub activity__load_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{id};
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
		
	$ou->load_keywords;
	
	my $swf_ou = $ou->load_child_ou('file', 'activity');
	my $path = '';
	
	if($swf_ou)
	{
		if($swf_ou->item_path =~ /^http:\/\//i)
		{
			$path = $swf_ou->item_path;
		}
		else
		{
			$path = '/files/'.$swf_ou->item_path;
		}
	}

	my $account = $self->load_account_from_subdomain(1);
	
#	if(($account)&&($account->has_purchased_activity($ou)))
#	{
#		
#	
#	}
#	else
#	{
#		if(!$ou->has_keyword_value('pricing_model', 'freethismonth'))
#		{
#			return;
#		}
#	}

	my $log_props = {
		ou_id => $id,
		event_type => 'activity_launch' };
		
	if($account)
	{
		$log_props->{account_id} = $account->get_id;
	}
	
	$self->create_log($log_props);
	
	print "Location: $path\n\n";

	$self->{page_content} = '_no_header';
	return '_no_header';
}

sub activity__get_swf_path_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{id};
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
		
	if(!$ou)
	{
		$self->{page_content}=<<"+++";
<error>
	There is no activity with that id...
</error>		
+++

		return;
	}
		
	my $swf_ou = $ou->load_child_ou('file', 'activity');
	
	if(!$swf_ou)
	{
		$self->{page_content}=<<"+++";
<error>
	There is no swf file for that activity
</error>		
+++

		return;
	}	
	
	my $local_path = $swf_ou->get_file_local_path;
	
	if(!-e $local_path)
	{
		$self->{page_content}=<<"+++";
<error>
	The swf file cannot be found - $local_path
</error>		
+++

		return;
	}
	
	my $web_path = $swf_ou->get_file_web_path;
	
	$self->{page_content}=<<"+++";
<activity path="$web_path" />
+++

	return;
}

sub activity__help_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{id};
	my $bg = $self->{params}->{bg};
	
	if($bg =~ /\w/)
	{
		
	}
	else
	{
		$bg = 'ffffff';
	}
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
		
	my $name = $ou->name;
	my $help_text = $ou->comment;
	
	$help_text =~ s/\n/<br>/g;
		
	$self->{page_content}=<<"+++";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>$name</title>
<script type="text/javascript" src="/js/lib.js"></script>
<style type="text/css">
body,html {
    margin:0px;
    padding:0px;
    height:100%;
}

td { font-family:Tahoma;font-size:11pt; }

</style>
</head>
<body bgcolor="#$bg">
<table width=100% height=100% border=0 cellpadding="10" cellspacing="0">
<tr width=100% height=100%>
<td width=100% height=100% align=left valign=top>
$help_text
<br><br>
<a href="javascript:top.close();" style="color:#000000;">close window</a>
</td>
</tr>
</table>
</body>
</html>
+++
}

sub activity__feedback_frameset_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{id};
	my $bg = $self->{params}->{bg};
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
		
	my $name = $ou->name;
		
	$self->{page_content}=<<"+++";
	<html>
<head>
<title>$name</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<frameset rows="0,*" frameborder="NO" border="0" framespacing="0">
    <frame name="blank" scrolling="no" noresize src="/blank.htm" >
    <frame name="form" scrolling="no" noresize src="/activity/feedback.app?id=$id&bg=$bg" >
</frameset>
</html>
+++
}

sub activity__feedback_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{id};
	my $bg = $self->{params}->{bg};
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
		
	my $name = $ou->name;
		
	$self->{page_content}=<<"+++";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>$name</title>
<script type="text/javascript" src="/js/lib.js"></script>
<script>
	function submitForm()
	{
		var formObj = document.feedbackForm;

		if(formObj.name.value=='')
		{
			alert('Please enter your name...');
			return false;
		}
		
		if(formObj.feedback.value=='')
		{
			alert('Please enter some comments...');
			return false;
		}
		
		formObj.submit();

		return true;
	}
</script>
<style type="text/css">
body,html {
    margin:0px;
    padding:0px;
    height:100%;
}

td { font-family:Tahoma;font-size:10pt; }

input,textarea,select { font-family:Tahoma;font-size:10pt;width:100%; }

</style>
</head>
<body bgcolor="#$bg">
<table width=100% height=100% border=0 cellpadding="10" cellspacing="0">
<tr width=100% height=100%>
<td width=100% height=100% align=left valign=top>

<form method="POST" action="/activity/feedback_submit.app" name="feedbackForm" style="padding:0px;margin:0px;">
<input type="hidden" name="id" value="$id">
<input type="hidden" name="bg" value="$bg">
<table width=100% border=0 cellpadding=7 cellspacing=0>
<tr>
<td width=120 align=right valign=top>Your Name</td>
<td align=left width=400><input type="text" name="name" value=""></td>
<td width=20></td>
</tr>
<tr>
<td width=120 align=right valign=top>Your Email</td>
<td align=left width=400><input type="text" name="email" value=""></td>
<td width=20></td>
</tr>
<tr>
<td width=120 align=right valign=top>Rating (10=best)</td>
<td align=left width=400>
<select name="rating" style="width:100px;">
<option value=""></option>
<option value="1">1</option>
<option value="2">2</option>
<option value="3">3</option>
<option value="4">4</option>
<option value="5">5</option>
<option value="6">6</option>
<option value="7">7</option>
<option value="8">8</option>
<option value="9">9</option>
<option value="10">10</option>
</select>
</td>
<td width=20></td>
</tr>
<tr>
<td width=120 align=right valign=top>Feedback</td>
<td align=left width=400><textarea name="feedback" style="height:120px;"></textarea></td>
<td width=20></td>
</tr>
<tr>
<td colspan=3 align=center height=10></td>
</tr>
<tr>
<td colspan=2 align=right><input type="button" value="Send Feedback..." onClick="submitForm();" style="width:200px;"></td>
<td width=20></td>
</tr>
</table>
</form>
</td>
</tr>
</table>
</body>
</html>
+++
}

sub activity__feedback_submit_handler
{
	my ($self) = @_;
	
	my $id = $self->{params}->{id};
	my $bg = $self->{params}->{bg};
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });

	my $feedback = Webkit::Player::ActivityFeedback->constructor($self->{db});
	$feedback->installation_id($self->installation_id);
	$feedback->ou_id($id);
	$feedback->created(Webkit::DateTime->now);
	$feedback->feedback_type('comment');
	$feedback->name($self->{params}->{name});
	$feedback->rating($self->{params}->{rating});
	$feedback->email($self->{params}->{email});
	$feedback->feedback($self->{params}->{feedback});
	
	my $name = $self->{params}->{name};
	my $email = $self->{params}->{email};
	my $feedbacktext = $self->{params}->{feedback};
	my $ou_name = $ou->name;
	
	my $email_message=<<"+++";
Name: 		$name
Email: 		$email

Activity: 	$ou_name

$feedbacktext
+++

	foreach my $admin_email (@admin_emails)
	{
		if(!$self->dev_mode)
		{
			Webkit::AppTools->send_email({
				from => 'info@iboard.co.uk',
				to => $admin_email,
				subject => 'Player Feedback Entry',
				message => $email_message });
		}
	}

	$self->{db}->begin_transaction;
	
	$feedback->create;
	
	$self->{db}->commit;
	
	$self->{page_content}=<<"+++";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>$ou_name</title>
<script type="text/javascript" src="/js/lib.js"></script>
<style type="text/css">
body,html {
    margin:0px;
    padding:0px;
    height:100%;
}

td { font-family:Tahoma;font-size:10pt; }

</style>
</head>
<body bgcolor="#$bg">
<table width=100% height=100% border=0 cellpadding="10" cellspacing="0">
<tr width=100% height=100%>
<td width=100% height=100% align=left valign=top>
Thank you for taking your time to comment on '$ou_name'...
<br><br>
<a href="javascript:top.close();" style="color:#000000;">close window</a>
</td>
</tr>
</table>
</body>
</html>
+++
}

sub gateway_handler
{
	my ($self) = @_;

	if($self->{params}->{club_domain}=~/\w/)
	{
		if(lc($self->{params}->{club_domain}) eq 'demo')
		{
			##$self->set_page('/player/index.htm');
			
			my $http_host = $self->hostname;
			
			$self->{page_content}=<<"+++";
	<meta http-equiv="refresh" content="0;url=http://$http_host/player">	
+++
		}
		else
		{
			$self->set_page('/club.htm');
		}
	}
	else
	{
		$self->set_page('/index.htm');
	}	
}

sub contact_handler
{
	my ($self) = @_;
	
	$self->fully_load_installation;
	
	if($self->{installation}->is_dictionary)
	{
		$self->set_page('/contact_dictionary.htm');
	}
}

sub contact_submit_handler
{
	my ($self) = @_;
	
	my $name = $self->{params}->{name};
	my $email = $self->{params}->{email};
	my $phone = $self->{params}->{phone};
	my $message = $self->{params}->{message};
	
	if($message=~/\w/)
	{
		my $account = $self->load_account_from_subdomain(1);
	
		my $account_name = 'Demo School';
		my $account_type = 'demo school';
	
		if($account)
		{
			$account_name = $account->get_account_name;
			$account_type = $account->account_type;
		}
	
		my $admin_email_content=<<"+++";
A contact form has been sent from the player website:

account_name: $account_name
account_type: $account_type

name: $name
email: $email
phone: $phone

-------------------------------------------------------
$message
-------------------------------------------------------
+++
	
		foreach my $admin_email (@admin_emails)
		{
			if(!$self->dev_mode)
			{
				if($message !~ /<a href=/)
				{
					Webkit::AppTools->send_email({
						from => 'info@iboard.co.uk',
						to => $admin_email,
						subject => 'Player Contact Form',
						message => $admin_email_content });
				}
			}
		}
	}
	
	$self->fully_load_installation;
	
	if($self->{installation}->is_dictionary)
	{
		$self->set_page('/contactthanks_dictionary.htm');
	}
	else
	{
		$self->{page_content}=<<"+++";
<meta http-equiv="refresh" content="0; url=http://newserver.iboard.co.uk/contactthanks.htm">
+++
		
#		$self->{page_content}=<<<"+++";
#	<meta http-equiv="refresh" content="0; url=http://newserver.iboard.co.uk/contact.htm">
#+++
	}
}

sub dictionary__remind_address_handler
{
	my ($self) = @_;
	
	my $email = $self->{params}->{remind_email_address};
	
	if(!Webkit::AppTools->check_email_address($email))
	{
		$self->{page_props}->{error_message} = $email.' is not a valid email address';
		$self->set_page('/dictionary.htm');
		return;
	}

	my $user = Webkit::Player::User->load($self->{db}, {
		clause => 'installation_id = ? and username = ?',
		binds => [$self->installation_id, $email] });	
		
	if(!$user)
	{
		$self->{page_props}->{error_message} = 'No account found for that email address';
		$self->set_page('/dictionary.htm');
		return;
	}
	
	my $account = Webkit::Player::Account->load($self->{db}, {
		id => $user->account_id });
		
	my $url = $account->url;
	my $hostname = $self->hostname;
		
	if(!$self->dev_mode)
	{
		my $email_text=<<"+++";
Your Word Wizard Address is:

----------------------------------------
$url
----------------------------------------

You can go straight to your account using this address:

----------------------------------------
http://hostname/launch/$url
----------------------------------------
+++

		Webkit::AppTools->send_email({
			from => 'dictionary@swgfl.org.uk',
			to => $user->username,
			subject => 'Word Wizard Address Reminder',
			message => $email_text });
	}
	
	$self->{page_props}->{error_message} = 'A reminder has been emailed to '.$email;
	$self->set_page('/dictionary.htm');
}
	


sub dictionary__launch_account_handler
{
	my ($self) = @_;
	
	my $url = $self->{params}->{word_wizard_address};
	
	my $account = Webkit::Player::Account->load($self->{db}, {
		clause => 'url = ? and installation_id = ?',
		binds => [$url, $self->installation_id] });	
			
	if($account)
	{
		$self->{page_content}=<<"+++";
<meta http-equiv="refresh" content="0;url=/launch/$url">
+++
	}
	else
	{
		$self->{page_props}->{error_message} = 'There is no account with that Word Wizard Address...';
		$self->set_page('/dictionary.htm');
	}
}

sub dictionary__save_word_definition_handler
{
	my ($self) = @_;
	
	if(!$self->do_login)
	{
		$self->{page_content}=<<"+++";
status=error
+++

		return;
	}
	
	my $text = $self->{params}->{value};
	
	$text =~ s/::://g;
	
	my $word = Webkit::Player::OU->load($self->{db}, {
		id => $self->{params}->{id} });	
	
	my @data =  ($self->{params}->{id}, $word->name, $self->{params}->{type}, $text);
	
	my $data_string = join(':::', @data);
	
	my $moderation = Webkit::Player::Moderation->constructor($self->{db});
	$moderation->installation_id($self->installation_id);
	$moderation->account_id($self->{account}->get_id);
	$moderation->user_id($self->{user}->get_id);
	$moderation->created(Webkit::DateTime->now);
	$moderation->action_type('add_definition');
	$moderation->action_data($data_string);
	
	$self->{db}->begin_transaction;
	
	$moderation->create;
	
	$self->{db}->commit;
	
	$self->{page_content} = 'status=ok';
}

sub get_list_of_word_images
{
	my ($self) = @_;
	
	my $local_folder = $ENV{DOCUMENT_ROOT}.$words_folder.'wordImages';
	
	my $image_files = [];
	
	opendir(DIR, $local_folder) or die "can't opendir $local_folder: $!";
	
	while (defined(my $file = readdir(DIR)))
	{
		if($file!~/\w/) { next; }
		
		push(@$image_files, $file);
	}
	
	return $image_files;
}

sub get_list_of_phonetics
{
	my ($self) = @_;
	
	my $folder = $ENV{DOCUMENT_ROOT}.$words_folder.'phonics/';	
	
	my $phonics = [];
	
	opendir(DIR, $folder) or die "can't opendir $folder: $!";
	
	while (defined(my $file = readdir(DIR)))
	{
		$file =~ s/\..*?$//;
		
		if($file!~/\w/) { next; }
		
		push(@$phonics, $file);
	}
	
	@$phonics = sort @$phonics;
	
	return $phonics;
}

sub dictionary__save_definition_phonic_map_handler
{
	my ($self) = @_;
	
	if(!$self->do_login)
	{
		$self->{page_content}=<<"+++";
<error value="Incorrect Login Details" />	
+++

		return;
	}
	
	$self->load_installation;
	
	my $text = $self->{params}->{value};
	
	$text =~ s/::://g;
	
	my $data_string = $self->{params}->{phonics};
	
	my $word = Webkit::Player::OU->load($self->{db}, {
		id => $self->{params}->{id} });	
			
	$self->{installation}->load_children('Webkit::Player::OU', {
		clause => 'ou_type = ? and name = ?',
		binds => ['definition', $word->name] });
		
	$self->{installation}->add_children('Webkit::Player::Keyword', {
		table => 'player.ou, player.keyword',
		cols => 'keyword.*',
		clause => 'ou.installation_id = ? and ou.ou_type = ? and ou.name = ? and keyword.ou_id = ou.id',
		binds => [$self->installation_id, 'definition', $word->name],
		group => 'keyword.id' });
		
	foreach my $keyword (@{$self->{installation}->ensure_child_array('keyword')})
	{
		my $ou = $self->{installation}->get_child('ou', $keyword->ou_id);
		
		if($ou)
		{
			$ou->add_keyword($keyword);
		}
	}
		
	$self->{db}->begin_transaction;		
		
	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		if(($self->{account}->is_root)||($self->{account}->is_seller))
		{		
			my $existing_keyword = $ou->get_keyword('phonic_sequence');
			
			if(!$existing_keyword)
			{
				$ou->create_keyword('phonic_sequence', $data_string);
			}
			else
			{
				$existing_keyword->value($data_string);
				$existing_keyword->save;
			}
		}
		else
		{
			my $moderation = Webkit::Player::Moderation->constructor($self->{db});
			$moderation->installation_id($self->installation_id);
			$moderation->account_id($self->{account}->get_id);
			$moderation->user_id($self->{user}->get_id);
			$moderation->ou_id($self->{params}->{id});
			$moderation->created(Webkit::DateTime->now);
			$moderation->action_type('phonic_sequence');
			$moderation->action_data($data_string);
	
			$moderation->create;
		}
	}
	
	$self->{db}->commit;
	
	$self->{page_content}=<<"+++";
<status value="ok" />	
+++
}

sub dictionary__get_definition_with_no_phonic_handler
{
	my ($self) = @_;
	
	if(!$self->do_login)
	{
		$self->{page_content}=<<"+++";
<error value="Incorrect Login Details" />	
+++

		return;
	}
	
	$self->load_installation;
	
	if($self->{params}->{word}=~/\w/)
	{
		$self->dictionary__get_definition_with_no_phonic_word_handler;
	}
	else
	{
		$self->dictionary__get_definition_with_no_phonic_random_handler;
	}
}

sub dictionary__get_definition_with_no_phonic_word_handler
{
	my ($self) = @_;

	$self->{installation}->load_children('Webkit::Player::OU', {
		clause => 'ou_type = ? and name = ?',
		binds => ['definition', lc($self->{params}->{word})] });
			
	if($self->{installation}->get_child_count('ou')<=0)
	{
		my $word = $self->{params}->{word};
		
		$self->{page_content}=<<"+++";
<error value="No definition found for $word" />	
+++

		return;
	}
	
	my $definition;
	my $comments = [];
	my $sequence;
	my $count = 0;
	
	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		$ou->load_keywords;
		
		push(@$comments, $ou->comment);
		
		if(!$ou->has_keyword('phonetic_pattern')) { next; }
		if($ou->has_keyword('phonic_sequence'))
		{
			$sequence = $ou->get_keyword_value('phonic_sequence');
		}
		
		#my $moderation = Webkit::Player::Moderation->load($self->{db}, {
		#	clause => 'ou_id = ? and action_type = ?',
		#	binds => [$ou->get_id, 'phonic_sequence'] });

		#if($moderation) { next; }
		
		$definition = $ou;
		$count++;
	}
	
#	if(!$definition)
#	{
#		my $word = $self->{params}->{word};
#		
#		$self->{page_content}=<<"+++";
#<error value="All definitions have already been given a sequence" />	
#+++
#
#		return;
#	}
	
	my $id = $definition->get_id;
	my $word = $definition->name;
	my $pattern = $definition->get_keyword_value('phonetic_pattern');
	
	my $phonetics = $self->get_list_of_phonetics;
	
	my $phonetics_string = join(':', @$phonetics);
	
	my $definition_text = join(', ', @$comments);
	
	$self->{page_content}=<<"+++";
<definition id="$id" word="$word" count="$count" pattern="$pattern" pattern_value="$sequence" phonetics="$phonetics_string">$definition_text</definition>
+++
}

sub dictionary__get_definition_with_no_phonic_random_handler
{
	my ($self) = @_;

	my $table=<<"+++";
player.ou, player.keyword
+++

	my $clause=<<"+++";
ou.installation_id = ? and ou.ou_type = ? and keyword.ou_id = ou.id and keyword.word = ?
+++

	$self->{installation}->add_children('Webkit::Player::OU', {
		table => 'player.ou, player.keyword',
		cols => 'ou.*, keyword.value as pattern',
		clause => $clause,
		binds => [$self->installation_id, 'definition', 'phonetic_pattern'],
		group => 'ou.id',
		order => 'rand()' });
		
	$self->{installation}->add_children('Webkit::Player::Keyword', {
		clause => 'installation_id = ? and word =?',
		binds => [$self->installation_id, 'phonic_sequence'],
		group => 'keyword.id' });
		
	$self->{installation}->add_children('Webkit::Player::Moderation', {
		clause => 'installation_id = ? and action_type = ?',
		binds => [$self->installation_id, 'phonic_sequence'],
		group => 'moderation.id' });
		
	foreach my $keyword (@{$self->{installation}->ensure_child_array('keyword')})
	{
		my $ou = $self->{installation}->get_child('ou', $keyword->ou_id);
		
		if($ou)
		{
			$ou->{_phonic_keyword} = $keyword;
		}
	}
	
	foreach my $moderation (@{$self->{installation}->ensure_child_array('moderation')})
	{
		my $ou = $self->{installation}->get_child('ou', $moderation->ou_id);
		
		if($ou)
		{
			$ou->{_phonic_moderation} = $moderation;
		}
	}
	
	my $definition;
	
	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		if((!$ou->{_phonic_keyword})&&(!$ou->{_phonic_moderation}))
		{
			$definition = $ou;
			last;
		}
	}
	
	if(!$definition)
	{
		$self->{page_content}=<<"+++";
<error value="No Word Found" />	
+++

		return;
	}
	
	$definition->load_keywords;
	
	my $count_refs = $self->{db}->get_select_refs({
		table => 'player.ou',
		cols => 'comment as comment',
		clause => 'installation_id = ? and ou_type = ? and name = ?',
		binds => [$self->installation_id, 'definition', $definition->name] });
		
	my $comments = [];
	my $count = 0;
	
	if($count_refs)
	{
		foreach my $ref (@$count_refs)
		{
			push(@$comments, $ref->{comment});
			$count++;
		}
	}
	
	my $id = $definition->get_id;
	my $word = $definition->name;
	my $pattern = $definition->get_keyword_value('phonetic_pattern');
	my $pattern_value = $definition->get_keyword_value('phonic_sequence');
	
	my $phonetics = $self->get_list_of_phonetics;
	
	my $phonetics_string = join(':', @$phonetics);
	
	my $definition_text = join(', ', @$comments);
	
	$self->{page_content}=<<"+++";
<definition id="$id" word="$word" count="$count" pattern="$pattern" pattern_value="$pattern_value" phonetics="$phonetics_string">$definition_text</definition>
+++
}

sub dictionary__get_word_with_no_definition_handler
{
	my ($self) = @_;
	
	if(!$self->do_login)
	{
		$self->{page_content}=<<"+++";
<error value="Incorrect Login Details" />	
+++

		return;
	}
	
	$self->fully_load_installation;
		
	$self->{installation}->load_children('Webkit::Player::OU', {
		clause => 'ou_type = ? or ou_type = ?',
		binds => ['word', 'definition'] });
	
	my $no_defs_array = [];
	
	my $word_array = [];
	
	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		if($ou->ou_type eq 'definition')
		{
			my $word = $self->{installation}->get_child('ou', $ou->ou_id);
			
			if(!$word) { next; }
			
			$word->{definition} = $ou;
		}
		elsif($ou->ou_type eq 'word')
		{
			push(@$word_array, $ou);
		}
	}
	
	foreach my $word (@$word_array)
	{
		if(!$word->{definition})
		{
			push(@$no_defs_array, $word);
		}
	}
	
	my $length = @$no_defs_array;
	
	my $rand_pos = int(rand($length));
	
	my $word_obj = $no_defs_array->[$rand_pos];
	
	my $word = $word_obj->name;
	my $id = $word_obj->get_id;
	
	$self->{page_content}=<<"+++";
<word id="$id" word="$word" />	
+++
}

sub dictionary__login_handler
{
	my ($self) = @_;
	
	if(!$self->do_login)
	{
		$self->{page_props}->{error_message} = 'Incorrect details - please try again...';
		
		$self->set_page('/dictionary.htm');
		return;
	}
	
	$self->dictionary_home_handler;
	$self->set_page('/dictionary_home.htm');
}

sub dictionary_home_handler
{
	my ($self) = @_;

	if($self->{user})
	{
		$self->{page_props}->{users_name} = $self->{user}->get_name;
	}
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
######################
# ACTIVITY URL
######################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

sub activity__thumbnail_handler
{
	my ($self) = @_;
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $self->{activity_id} });
			
	my $thumbnail = $ou->load_thumbnail_path;
			
	$self->{params}->{size} = 350;
	$self->{params}->{image_path} = $thumbnail;
	$self->{params}->{download} = 'y';
	
	$self->images__image_content_handler;
}

sub activity__id_handler
{
	my ($self) = @_;

	$self->{params}->{viewID} = $self->{view_id};
	$self->{params}->{id} = $self->{activity_id};
	
	$self->activity__frameset_handler;
}

sub activity__id_launch_handler
{
	my ($self) = @_;
	
	my $id = $self->{activity_id};
	my $viewID = $self->{view_id};
	
	my $ou = Webkit::Player::OU->load($self->{db}, {
		id => $id });
		
	my $name = $ou->name;
	
	my $host = $self->hostname;
	
	my $swf_path = "/player/activityLaunch.swf?id=$id&viewID=$viewID&hostname=$host";
	
	my $account = $self->load_account_from_subdomain(1);
	
	my $log_props = {
		ou_id => $id,
		event_type => 'external_link'
	};
		
	if($account)
	{
		$log_props->{account_id} = $account->get_id;
	}
	
	$self->create_log($log_props);
	
	$self->{page_content}=<<"+++";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>$name</title>
<script type="text/javascript" src="/js/lib.js"></script>
<style type="text/css">
body,html {
    margin:0px;
    padding:0px;
    height:100%;
}

div { font-family:Tahoma;font-size:10pt; }

</style>
</head>
<body bgcolor="#FFFFFF">
<table width=100% height=100% border=0 cellpadding="0" cellspacing="0">
<tr width=100% height=100%>
<td width=100% height=100% align=center valign=middle>
<script>
	writeFlashToPage("$swf_path", "100%", "100%", null, 'activitySWF');
</script>
</td>
</tr>
</table>
</body>
</html>
+++
}

sub screens__cd_launch_website_handler
{
	my ($self) = @_;

	#school_id=153&set_id=1
	
	$self->{page_content}=<<"+++";
<meta http-equiv="refresh" content="0;url=http://cdaccess.iboard.co.uk">
+++
}

sub screens__thread_home_handler
{
	my ($self) = @_;

	my $id = $self->{params}->{thread_id};
	
	$self->{page_content}=<<"+++";
<meta http-equiv="refresh" content="0;url=http://demo.onlineclub.iboard.co.uk/screens/thread_home.htm?thread_id=$id">
+++
}

sub register__index_handler
{
	my ($self) = @_;
	
	$self->fully_load_installation;
	
	if($self->{installation}->is_dictionary)
	{
		$self->set_page('/free/dictionary.htm');
	}
	else
	{
		$self->set_page('/free/index.htm');
	}
}

sub page__index_handler
{
	my ($self) = @_;
	
	my $viewID = $self->{page_url};
	
	$self->{page_content}=<<"+++";
<meta http-equiv="refresh" content="1;url=/player/?initViewID=$viewID">	
+++
}

sub launch__index_handler
{
	my ($self) = @_;
	
	my $url = $self->{launch_url};
	
	$self->bake_cookie('playerurl', $self->{launch_url});
	
	$self->{page_content}=<<"+++";
<meta http-equiv="refresh" content="1;url=/">	
+++
}

sub get_date_obj_from_param_value
{
	my ($self, $value) = @_;
	
	if($value=~/^(\d+)\/(\d+)\/(\d+)$/)
	{
		my $date_obj = Webkit::DateTime->now;
	
		$date_obj->Day($1);
		$date_obj->Month($2);
		$date_obj->Year($3);
		
		return $date_obj;
	}
	else
	{
		return undef;
	}	
}

sub create_log
{
	my ($self, $props) = @_;
	
	my $log = Webkit::Player::Log->constructor($self->{db});
	$log->installation_id($self->installation_id);
	
	if($props->{account_id}>0)
	{
		$log->account_id($props->{account_id});
	}
	
	if($props->{ou_id}>0)
	{
		$log->ou_id($props->{ou_id});
	}
	
	$log->event_type($props->{event_type});
	$log->referer($ENV{HTTP_REFERER});
	$log->ip_address($ENV{HTTP_X_FORWARDED_FOR});
	$log->event_date(Webkit::DateTime->now);
	
	$self->{db}->begin_transaction;

	$log->create;

	$self->{db}->commit;	
}

sub viewer__visuwords_handler
{
	my ($self) = @_;
	
	$self->fully_load_installation;
	
	my $word = $self->{params}->{find};
	
	if($word !~ /\w/)
	{
		my $definition_ref = $self->{db}->get_select_ref({
			table => 'player.ou',
			cols => 'ou.*',
			clause => 'installation_id = ? and ou_type = ?',
			binds => [$self->{installation}->get_id, 'definition'],
			group => 'ou.id',
			order => 'rand()',
			limit => 1
		});
		
		if($definition_ref)
		{
			$word = $definition_ref->{name};
		}
	}

	$self->{installation}->load_children('Webkit::Player::OU', {
		clause => 'ou_type = ? and name = ?',
		binds => ['definition', lc($word)] });
		
	$self->{installation}->add_children('Webkit::Player::Keyword', {
		table => 'player.ou, player.keyword',
		cols => 'keyword.*',
		clause => 'keyword.installation_id = ? and keyword.ou_id = ou.id and ou.ou_type = ? and ou.name = ?',
		binds => [$self->{installation}->get_id, 'definition', lc($word)],
		group => 'keyword.id' });
		
	foreach my $keyword (@{$self->{installation}->ensure_child_array('keyword')})
	{
		my $ou = $self->{installation}->get_child('ou', $keyword->ou_id);
		
		if($ou)
		{
			$ou->add_keyword($keyword);
		}
	}
		
		
	my $word_id = $word;
	$word_id =~ s/ /_/g;
	
	my $ret=<<"+++";
<worddata>
	<node id="$word_id" text="$word" type="word" is_root="y">
+++

	my $master_word_map = {};

	foreach my $definition (@{$self->{installation}->ensure_child_array('ou')})
	{
		my $definition_text = $definition->comment;
		$definition_text =~ s/[^\w ]//g;
		my @words = split(/ /, $definition_text);
		
		foreach my $word (@words)
		{
			if(!Webkit::AppTools->is_simple_stopword($word))
			{
				$master_word_map->{lc($word)} = lc($word);
				$definition->{linked_words}->{lc($word)} = lc($word);
			}
		}
	}
	
	my $clone_installation = $self->{installation}->clone;
	$clone_installation->{data}->{id} = $self->{installation}->get_id;
	
	my $id_clauses = [];
	my $id_binds = ['definition'];
	
	foreach my $word (keys %$master_word_map)
	{
		push(@$id_clauses, "name = ?");
		push(@$id_binds, lc($word));
	}
	
	my $id_clause_st = join(" or ", @$id_clauses);
	
	my $id_clause=<<"+++";
ou_type = ?
+++

	if($id_clause_st =~ /\w/)
	{
		$id_clause.=<<"+++";
	and
(
	$id_clause_st
)
+++
	}
	
	$clone_installation->load_children('Webkit::Player::OU', {
		clause => $id_clause,
		binds => $id_binds });
		
	my $linked_word_objects = {};
		
	foreach my $linked_definition (@{$clone_installation->ensure_child_array('ou')})
	{
		$linked_word_objects->{lc($linked_definition->name)} = $linked_definition;
	}
		
	foreach my $definition (@{$self->{installation}->ensure_child_array('ou')})
	{
		my $id = $definition->get_id;
		my $definition_text = $definition->comment;
		my $text = $definition->name;
		my $word_type = $definition->get_keyword_value('word_type');
		
		if(!$word_type)
		{
			$word_type = 'noun';
		}
		
		$ret.=<<"+++";
		<node id="$id" text="$text" type="$word_type">
			<definition>$definition_text</definition>
+++

		foreach my $linked_word (keys %{$definition->{linked_words}})
		{
			my $linked_object = $linked_word_objects->{lc($linked_word)};
			
			my $is_linked = "n";
			
			if($linked_object)
			{
				$is_linked = "y";
			}
			
			my $subnodeid = $definition->get_id.':'.$linked_word;
			
			$ret.=<<"+++";
			<node id="$subnodeid" text="$linked_word" type="word" link_type="definition" is_linked="$is_linked" />
+++
		}

		$ret.=<<"+++";
		</node>
+++
	}

	$ret.=<<"+++";
	</node>
</worddata>
+++

	$self->{page_content} = $ret;
}

sub bdoemailer__contact_handler
{
	my ($self) = @_;

	my $name = $self->{params}->{name};
	my $email = $self->{params}->{from_email};
	my $message = $self->{params}->{message};
	my $school_name = $self->{params}->{school_name};

	my $to_email = $self->{params}->{to_email};

	my $email_message=<<"+++";
You have been sent a contact form from the Big Day Out Website - the message is as follows:

From: $name
Email: $email
Schoool: $school_name

---------------------------
$message
---------------------------
+++

	if(!Webkit::AppTools->check_email_address($email))
	{
		$email = 'noreply@bdo.swgfl.org.uk';
	}

	Webkit::AppTools->send_email({
		from => $email,
		to => $to_email,
		subject => 'Big Day Out Contact Form',
		message => $email_message });

	$self->{page_content} = 'yes';
	
	return;
}

sub bdoemailer__password_handler
{
	my ($self) = @_;

	my $email = $self->{params}->{email};
	my $name = $self->{params}->{name};
	my $password = $self->{params}->{password};

	my $host = $self->{params}->{host};

	if($host!~/\w/)
	{
		$host = 'www.bigdayout.swgfl.org.uk';
	}

	if(!Webkit::AppTools->check_email_address($email))
	{
		$self->{page_content} = 'no';
		return;
	}	

	my $message=<<"+++";
Dear $email,

You have requested the password for the Big Day Out to be sent to this email address.

The password for $name is shown below:

--------------------------------------------------------
$password
--------------------------------------------------------
+++

	Webkit::AppTools->send_email({
		from => 'noreply@bdo.swgfl.org.uk',
		to => $email,
		subject => 'Big Day Out Teachers Password',
		message => $message });

	$self->{page_content} = 'yes';
	
	return;
}

sub bdoemailer__password_request_handler
{
	my ($self) = @_;

	my $name = $self->{params}->{name};
	my $school_name = $self->{params}->{school_name};
	my $position = $self->{params}->{position};
	my $email = $self->{params}->{email};
	my $phone = $self->{params}->{phone};
	my $dfes = $self->{params}->{dfes};
	my $password = $self->{params}->{password};

	my $to_email = $self->{params}->{to_email};

	my $host = $self->{params}->{host};

	if($host!~/\w/)
	{
		$host = 'www.bigdayout.swgfl.org.uk';
	}

	if(!Webkit::AppTools->check_email_address($email))
	{
		$self->{page_content} = 'no';
		return;
	}	

	my $message=<<"+++";
A request has been made for a password to be issued from the Big Day Out system.

The request is shown as follows:

--------------------------------------------------------
name: $name

position: $position

school: $school_name

email: $email

phone: $phone

dfes: $dfes
--------------------------------------------------------

The PASSWORD IS:

--------------------------------------------------------
$password
--------------------------------------------------------
+++

	Webkit::AppTools->send_email({
		from => 'noreply@bdo.swgfl.org.uk',
		to => $to_email,
		subject => 'Big Day Out Password Request',
		message => $message });

	$self->{page_content} = 'yes';
	
	return;
}

sub bdoemailer__index_handler
{
	my ($self) = @_;

	my $email = $self->{params}->{email};
	my $name = $self->{params}->{name};
	my $id = $self->{params}->{id};

	my $host = $self->{params}->{host};

	if($host!~/\w/)
	{
		$host = 'www.bigdayout.swgfl.org.uk';
	}

	if(!Webkit::AppTools->check_email_address($email))
	{
		$self->{page_content} = 'no';
		return;
	}

	my $message=<<"+++";
Dear $email,

$name has sent you a postcard from 'The Big Day Out' on the National Education Network.

Click the link below to view it:

--------------------------------------------------------
http://$host/postcard?$id
--------------------------------------------------------

(or copy and paste the text into a browser)...
+++

	Webkit::AppTools->send_email({
		from => 'noreply@bdo.swgfl.org.uk',
		to => $email,
		subject => 'Big Day Out Postcard',
		message => $message });

	$self->{page_content} = 'yes';
	
	return;
}

sub redirect__admin_handler
{
	my ($self) = @_;
	
	my $dir = "/home/webkit/sites/flatplayer/www";
	my $status_file = $dir.'/redirect_status.txt';
	
	my $status = Webkit::AppTools->read_file_contents($status_file);
	
	my $set_status = $self->{params}->{set_status};
	my $do_change = undef;
	
	if($set_status =~ /\w/ && ($set_status eq 'new' || $set_status eq 'normal'))
	{
		$status = $set_status;
		$do_change = 1;
	}
	
	my $button_title = 'NEW server redirect';
	my $button_value = 'new';
	
	if($status eq 'new')
	{
		$button_title = 'NORMAL server redirect';
		$button_value = 'normal';
	}
	
	my $page=<<"+++";
	
	<script>
		function changeValue(val)
		{
			document.location='?set_status=' + val;
		}
	</script>
the redirect status is currently: <b style="color:#ff0000;">$status</b><hr>

set to: <button onClick="changeValue('$button_value');">$button_title</button>
+++

	if($do_change)
	{
		open(STATUSFILE, ">$status_file");
	
		print STATUSFILE $status;
	
		close(STATUSFILE);
		
		my $echo_from = $dir.'/redirect_'.$status.'.htm';
		my $echo_to = $dir.'/index.htm';
		
		system("cat $echo_from > $echo_to");
	}
	
	$self->{page_content} = $page;
}

1;