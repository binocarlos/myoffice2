package Webkit::Apache::ApplicationHub;

################################
## Webkit::Apache::ApplicationHub
#
# This module creates an in memory cache of all Webkit Applications
# shared across all apache children.
#
# If you change this module, YOU MUST RESTART APACHE
# (login to ssh as admin, su, then 'sh httpd/restart.sh')

use strict;

my $application_hash = {};
my $application_array = [];


my $default_logo = '/images/logos/budgethub_icon.gif';

my $application_xml=<<"+++";
<applications>
	<application id="wk1net" title="Wk1 Website" module="Webkit::Wk1net::Admin" standalone="n">
		Webkit Website Module
	</application>

	<application id="budgethub" title="BudgetHub" module="Webkit::BudgetHub::Admin" standalone="y" sub_applications="clientms">
		Manage production budgets.
	</application>

	<application id="clientms" title="Client Management System" module="Webkit::ClientMS::Admin" standalone="y">
		Manage your client list.
	</application>

	<application id="client_list" title="Client List" module="Webkit::Components::Admin" standalone="n">
		Edit the client list on your website.
	</application>

	<application id="emailmanager" title="Email Manager" module="Webkit::SiteManager::Admin" standalone="n">
		Create, Edit and Delete email accounts and aliases.
	</application>

	<application id="contact_us_handler" title="Contact Us Handler" module="Webkit::Components::Admin" standalone="n">
		Automatically emails you response from your website
	</application>

	<application id="easemail" title="Easemail" module="Webkit::Easemail::Admin" standalone="y">
		Manage email lists and send emails
	</application>

	<application id="faqs" title="FAQs" module="Webkit::Components::Admin" standalone="n">
		Manage Frequently Asked Questions on your website or Intranet.
	</application>

	<application id="contact" title="Contacts Database" module="Webkit::Contact::Admin" standalone="y">
		Manage your contact list
	</application>

	<application id="fileshare" title="File Sharing" module="Webkit::FileShare::Admin" standalone="y">
		Share files with your colleagues.
	</application>

	<application id="login" title="Login" module="Webkit::Login::Admin" standalone="n">
	</application>

	<application id="news" title="Updateable News" module="Webkit::Components::Admin" standalone="n">
		Update news on your website or intranet.
	</application>

	<application id="orgadmin" title="OrgAdmin" module="Webkit::OrgAdmin::Admin" standalone="n">
	</application>

	<application id="queryhandler" title="Query Handler" module="Webkit::QueryHandler::Admin" standalone="y">
		Archive and respond to client queries.
	</application>

	<application id="rbgcadmin" title="RBGC Admin" module="Webkit::RBGCAdmin::Admin" standalone="y">
		Royal Blackheath Golf Club administration area.
	</application>

	<application id="rk" title="Robin Kirby Admin" module="Webkit::RK::Admin" standalone="y" sub_applications="clientms:faqs:fileshare:news:queryhandler:sitestatistics:emailmanager:client_list">
		Robin Kirby's administration area.
	</application>

	<application id="siteeditor" title="Site Editor" module="Webkit::SiteManager::Admin" standalone="n">
		Edit the content of your website.
	</application>

	<application id="sitemanager" title="Site Manager" module="Webkit::SiteManager::Admin" standalone="y" sub_applications="sitestatistics:emailmanager:siteeditor">
		View your website statistics, edit your website and manage your email accounts.
	</application>

	<application id="sitestatistics" title="Site Statistics" module="Webkit::SiteManager::Admin" standalone="n">
		View statistics on the visitors to your website.
	</application>

	<application id="timesheet" title="Time Sheets" module="Webkit::TimeSheet::Admin" standalone="y">
		Manage and present company timesheets.
	</application>

	<application id="holiday" title="Attendance Manager" module="Webkit::Holiday::Admin" standalone="y">
		Manage staff holidays and sick days.
	</application>

	<application id="vm" title="VM" module="Webkit::VM::Admin" standalone="y" sub_applications="clientms">
		In Production
	</application>

	<application id="va" title="VA" module="Webkit::VA::Admin" standalone="y" sub_applications="clientms">
		In Production
	</application>

	<application id="clubhouse" title="ClubHouse" module="Webkit::ClubHouse::Admin" standalone="y" sub_applications="news:clubhouse_course_status:clubhouse_rotating_icons:calendar:siteeditor:emailmanager:sitestatistics">
		ClubHouse Golf Package
	</application>

	<application id="clubhouse_course_status" title="Course Status" module="Webkit::ClubHouse::Admin" standalone="n">
		Change the opening status of your course
	</application>

	<application id="clubhouse_rotating_icons" title="Roating Icons" module="Webkit::ClubHouse::Admin" standalone="n">
		Manage your homepage icons
	</application>

	<application id="calendar" title="Events Calendar" module="Webkit::Components::Admin" standalone="y">
		Manage your events on a calendar
	</application>

	<application id="resourceshare" title="Resource Share" module="Webkit::ResourceShare::Admin" standalone="y" sub_applications="resourceshare_clientms">
		Share resources with colleagues.
	</application>

	<application id="resourceshare_clientms" title="Resource Share School Manager" module="Webkit::ResourceShare::ClientMSAdmin" standalone="n">
		Manage schools within the resourceshare
	</application>

	<application id="resourceshare_web" title="Web Resource Share" module="Webkit::ResourceShare::WebAdmin" standalone="y">
		Share resources with colleagues via a web-page.
	</application>

	<application id="resourceshare_webupload" title="Web Resource Upload" module="Webkit::ResourceShare::WebUploadAdmin" standalone="y">
		Upload Resources from a simplified web form
	</application>

	<application id="dbtutor" title="Database Tutor" module="Webkit::DBTutor::Admin" standalone="y">
		Database Tutor
	</application>

	<application id="nctest" title="Testing Tool" module="Webkit::NcTest::AppMethods::Bridge" standalone="y" sub_applications="nctest_tests:nctest_pupils:nctest_exams:nctest_invigilators:nctest_analysis:nctest_marking">
		Testing Tool
	</application>

	<application id="pnctest" title="Pupil Test Completion" module="Webkit::NcTest::PupilAdmin" standalone="y">
		Pupil Test Completion
	</application>

	<application id="nctest_tests" title="Test Management" module="Webkit::NcTest::AppMethods::Bridge" standalone="n">
		Test Management
	</application>

	<application id="nctest_pupils" title="Pupil Management" module="Webkit::NcTest::AppMethods::Bridge" standalone="n">
		Pupil Management
	</application>

	<application id="nctest_invigilators" title="Invigilate Exams" module="Webkit::NcTest::AppMethods::Bridge" standalone="n">
		Invigilate Exams
	</application>

	<application id="nctest_exams" title="Exam Management" module="Webkit::NcTest::AppMethods::Bridge" standalone="n">
		Exam Management
	</application>

	<application id="nctest_analysis" title="Analysis" module="Webkit::NcTest::AppMethods::Bridge" standalone="n">
		Analysis
	</application>

	<application id="nctest_marking" title="Test Marking" module="Webkit::NcTest::AppMethods::Bridge" standalone="n">
		Test Marking
	</application>

	<application id="eb" title="Electronic Blackboard Admin" module="Webkit::EB::Admin" standalone="y">
		Manage EB Activities and Invoices
	</application>

	<application id="myoffice2" title="MyOffice V2.0" module="Webkit::MyOffice2::Admin" standalone="y">
		Sing-A-Long MyOffice V2.0
	</application>

	<application id="skillsaudit" title="Skills Audit" module="Webkit::SkillsAudit::Admin" standalone="y">
		Carry out audits of skill levels amoung your users
	</application>
	<application id="firstcontact" title="First Contact" module="Webkit::FirstContact::Admin" standalone="y">
		Museums 4 Schools Database
	</application>
	<application id="wkfolders" title="Webkit Folders" module="Webkit::WKFolders::Admin" standalone="y">
		Webkit Folders
	</application>
	<application id="testcontact" title="Test Contact List" module="Webkit::ContactTest::Admin" standalone="y">
		Test
	</application>
</applications> 
+++

sub initialise_application_cache
{
        my $parser = new XML::DOM::Parser;

        my $doc = $parser->parse($application_xml);

	my $object_nodes = $doc->getElementsByTagName('application');

        for (my $i = 0; $i < $object_nodes->getLength; $i++)
	{
                my $object_node = $object_nodes->item($i);

		my $app = Webkit::ApplicationInfo->blank;

		$app->{data}->{id} = $object_node->getAttribute('id');

		my $logo = $object_node->getAttribute('logo');

		if(!$logo)
		{
			$logo = $default_logo;
		}

		$app->set_value('logo', $logo);

		$app->set_value('title', $object_node->getAttribute('title'));
		$app->set_value('module', $object_node->getAttribute('module'));
		$app->set_value('standalone', $object_node->getAttribute('standalone'));
		$app->set_value('sub_applications', $object_node->getAttribute('sub_applications'));

		my $desc = '';

		for my $kid ($object_node->getChildNodes)
		{
			if($kid->getNodeType==XML::DOM::TEXT_NODE)
			{
				$desc .= $kid->getNodeValue;
			}
		}

		$app->set_value('description', $desc);

		$application_hash->{$app->get_id} = $app;
		push(@$application_array, $app);
	}
}

sub get_application_array
{
	return $application_array;
}

sub get_application_hash
{
	return $application_hash;
}

sub get_application
{
	my ($classname, $id) = @_;

	return $application_hash->{$id};
}
	

1;
