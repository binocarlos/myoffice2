use strict;

use lib qw(/home/webkitapps/modules);

use Apache2::compat ();

use Apache2::Request;
use Apache2::Cookie;

use Data::Dumper ();
use DBI ();
use POSIX ();
use XML::DOM ();
use MIME::Entity ();
use JSON ();
use Captcha::reCAPTCHA ();

use File::Copy ();

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

	my $user = "";
	my $password = "";
	open (USERFILE, '/etc/myofficeuser.conf'); while (<USERFILE>) { chomp; $user = $_; } close (USERFILE);
	open (PASSWORDFILE, '/etc/myofficepassword.conf'); while (<PASSWORDFILE>) { chomp; $password = $_; } close (PASSWORDFILE);
	my $dbh = DBI->connect("dbi:mysql:webkit:mysql", $user, $password);
	$dbh->disconnect if ($dbh);

	Webkit::Apache::ApplicationHub->initialise_application_cache;
}

1;
