package Webkit::Constants;

use vars qw(@ISA);

use strict;

my $local_dir = '/home/webkitapps/';
my $web_dir = $local_dir.'www/';
my $pub_dir = '/home/pub/';

my $CONSTANTS = {	local_dir => $local_dir,
	         	web_dir => $web_dir,
			pub_dir => $pub_dir,
			file_dir => $web_dir.'pub/',
			template_dir => $web_dir.'templates/',
			snapshot_dir => $web_dir.'snapshots/',
			sessions_dir => $local_dir.'sessions/',
			home_method => 'login',
			easemail_dbm_dir => '/home/easemailDBMS/',
			fileshare_upload_dir => $pub_dir.'fileshare/',
			resourceshare_upload_dir => $pub_dir.'resourceshare/',
			resourceshare_temp_upload_dir => $pub_dir.'resourceshare_uploads/',
			clubhouse_rotating_icon_dir => $pub_dir.'clubhouse/rotating_icons/',
			cib_home_dir => '/home/cib/www/',
			cib_press_release_dir => 'press_releases/',
			nctest_upload_dir => $pub_dir.'nctest/',
			eb_file_dir => '/home/pub/eb/',
			eb_flatten_dir => '/home/pub/eb_flattens/',
			player_file_dir => '/home/pub/player/',
			steeler_file_dir => '/home/pub/steeler/',
			misc_file_dir => '/home/pub/misc/',
			gavinevans_file_dir => '/home/pub/gavinevans/',
			panmms_file_dir => '/home/pub/panmms/',
			winesite_picture_dir => '/home/winesite/images/',
			sendmail_path => '/usr/sbin/sendmail',
	                vat => 0.175 };

my $domain_variables = {
	'default' => {
		help_domain => 'help.wk1.net',
		easemail_reply_to_domain => 'wk1.net' },

	'testingtool.wk1.net:8080' => {
		mp3_hostname => 'https://wk1.net',
		real_hostname => 'testingtool.net' },

	'testingtool.net' => {
		mp3_hostname => 'https://wk1.net',
		real_hostname => 'testingtool.net' },


	'www.singalongaserver2.com' => {
		help_domain => 'help.wk1.net',
		easemail_app_domain => 'www.singalongaserver2.com',
		easemail_reply_to_domain => 'lisa.wk1.net' },

	'lisa.wk1.net' => {
		help_domain => 'help.wk1.net',
		easemail_app_domain => 'www.singalongaserver2.com',
		easemail_reply_to_domain => 'lisa.wk1.net' },

	'wk1.net' => {
		help_domain => 'help.wk1.net' },

	'localhost:8080' => {
		real_hostname => 'testingtool.net' },

	'bella.wk1.net:8080' => {
		easemail_reply_to_domain => 'bella.wk1.net',
		help_domain => 'bella.wk1.net:8081' },

	'192.168.1.8:8080' => {
		easemail_reply_to_domain => 'daisy.wk1.net',
		help_domain => 'help.wk1.net' },

	'192.168.0.3:8080' => {
		easemail_reply_to_domain => 'bella.wk1.net',
		real_hostname => 'bella.wk1.net',
		help_domain => 'bella.wk1.net:8081' } };

sub get_constant
{
	my ($classname, $key) = @_;

	return $CONSTANTS->{$key};
}

sub get_domain_variable
{
	my ($classname, $hostname, $key) = @_;

	my $variable = $domain_variables->{$hostname}->{$key};

	if(!$variable)
	{
		$variable = $domain_variables->{default}->{$key};
	}

	return $variable;
}

1;
