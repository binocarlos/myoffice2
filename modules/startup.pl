use strict;

use lib qw(/home/webkitapps/modules);

use Apache2::compat ();

use Apache2::Request;
use Apache2::Cookie;

#use Apache ();
#use Apache::Reload ();
#use Apache::Constants ();
#use Apache::Request ();
#use Apache::DBI ();
#use Apache::File ();
#use Apache::URI ();
#use Apache::TempFile ();
#use Apache::Cookie ();
#use Apache::SSI ();

#use Apache::SizeLimit ();

#$Apache::SizeLimit::MAX_PROCESS_SIZE = 50000;	# 18Mb Total
#$Apache::SizeLimit::MAX_UNSHARED_SIZE = 20000;	# 6Mb Unshared each

#$Apache::SizeLimit::CHECK_EVERY_N_REQUESTS = 5;

use Data::Dumper ();
use DBI ();
use POSIX ();
use XML::DOM ();
use MIME::Entity ();
use JSON ();
use Captcha::reCAPTCHA ();

#use Apache::Session::Generate::MD5 ();
use Data::Dumper ();

use File::Copy ();

#use GD::Graph ();
#use GD::Graph::bars ();
#use GD::Graph::hbars ();
#use GD::Graph::lines ();

use HTML::Parse();
use HTML::FormatText();
use HTML::CalendarMonth ();
use HTML::ElementRaw ();
use LWP::Simple();


use Parse::RecDescent ();

use String::Approx ();
use String::Random ();

use Date::EzDate ();
use Time::Local ();
use Number::Format ();

use Text::Template ();

use Webkit::DB ();
use Webkit::DBObject ();
use Webkit::Application ();
use Webkit::WebApplication ();
use Webkit::ApplicationInfo ();
use Webkit::AppTools ();


use Webkit::ExcelSheet ();

use Webkit::Variable ();
use Webkit::Constants ();

use Webkit::Org ();
use Webkit::Department ();
use Webkit::User ();
use Webkit::Privilage ();

use Webkit::Session ();
use Webkit::Error ();
use Webkit::Page ();
use Webkit::JSMenu ();
use Webkit::Browser ();

use Webkit::BaseDate ();
use Webkit::DateTime ();
use Webkit::Date ();
use Webkit::Time ();

use Webkit::Apache::ApplicationHub ();
use Webkit::Apache::TemplateHub ();
use Webkit::Apache::PerlHandler ();
use Webkit::Apache::HTMLHub ();
use Webkit::Apache::HTMLResources ();

use Webkit::OrgAdmin::Admin ();

use Webkit::Player::App ();
use Webkit::Player::Session ();
use Webkit::Player::Installation ();
use Webkit::Player::User ();
use Webkit::Player::Account ();
use Webkit::Player::OU ();
use Webkit::Player::Keyword ();
use Webkit::Player::PurchaseRecord ();
use Webkit::Player::Invoice ();
use Webkit::Player::SearchWord ();
use Webkit::Player::Views ();
use Webkit::Player::ActivityFeedback ();
use Webkit::Player::BectaVocab ();
use Webkit::Player::BectaVocabLink ();
use Webkit::Player::TextEntry ();
use Webkit::Player::AccountLink ();
use Webkit::Player::Moderation ();
use Webkit::Player::Log ();
use Webkit::Player::Edubase ();

use Webkit::SkillsAudit::Admin ();
use Webkit::SkillsAudit::WebAdmin ();
use Webkit::SkillsAudit::Org ();
use Webkit::SkillsAudit::Answer ();
use Webkit::SkillsAudit::Audit ();
use Webkit::SkillsAudit::AuditTemplate ();
use Webkit::SkillsAudit::Question ();
use Webkit::SkillsAudit::QuestionGroup ();
use Webkit::SkillsAudit::School ();
use Webkit::SkillsAudit::Visitor ();
use Webkit::SkillsAudit::VisitorSession ();

use Webkit::SkillsAudit::QuestionTypes::MChoice ();
use Webkit::SkillsAudit::QuestionTypes::Score ();
use Webkit::SkillsAudit::QuestionTypes::Text ();
use Webkit::SkillsAudit::QuestionTypes::Radio ();
use Webkit::SkillsAudit::QuestionTypes::Resources ();
use Webkit::SkillsAudit::QuestionTypes::Checkbox ();

use Webkit::MyOffice2::Admin ();
use Webkit::MyOffice2::Venue ();
use Webkit::MyOffice2::Contact ();
use Webkit::MyOffice2::Tour ();
use Webkit::MyOffice2::Country ();
use Webkit::MyOffice2::User ();
use Webkit::MyOffice2::Org ();
use Webkit::MyOffice2::Showing ();
use Webkit::MyOffice2::Booking ();
use Webkit::MyOffice2::BookingNotes ();
use Webkit::MyOffice2::NoteEntry ();
use Webkit::MyOffice2::Tourdate ();
use Webkit::MyOffice2::Deal ();
use Webkit::MyOffice2::SalesFigures ();
use Webkit::MyOffice2::SalesFiguresEntry ();
use Webkit::MyOffice2::Print ();
use Webkit::MyOffice2::PrintRun ();
use Webkit::MyOffice2::PrintExcelSheet ();
use Webkit::MyOffice2::MyOfficeUser ();
use Webkit::MyOffice2::TourlistExcelSheet ();
use Webkit::MyOffice2::VenueStatusEntry ();


BEGIN
{
	DBI->install_driver("mysql");

	my $user = $ENV{MYSQL_USER};
	my $password = $ENV{MYSQL_PASSWORD};

	my $dbh = DBI->connect("dbi:mysql:webkit:localhost", $user, $password);
	$dbh->disconnect if ($dbh);

	Webkit::Apache::ApplicationHub->initialise_application_cache;
}

1;
