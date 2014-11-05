package Webkit::Apache::SSI;

use strict qw(vars);
use vars qw(@ISA);
#use Apache::SSI ();
#use Apache::URI ();

use Webkit::ClientMS::Admin ();

#@ISA = qw(Apache::SSI);

sub new
{
	my ($pack, $text, $r) = @_;

	$text =~ s/&lab;/</gi;
	$text =~ s/&rab;/>/gi;

	#return Apache::SSI::new($pack, $text, $r);
}

sub ssi_include {
  my ($self, $args) = @_;
  unless (exists $args->{file} or exists $args->{virtual}) {
    return $self->error("No 'file' or 'virtual' attribute found in SSI 'include' tag");
  }
  my $subr = $self->find_file($args);
  unless ($subr->run == OK) {
    $self->error("Include of '@{[$subr->filename()]}' failed: $!");
  }
  
  ## Make sure that all of the variables set in the include are present here.
  my $env = $subr->subprocess_env();
  foreach ( keys %$env ) {
    $self->{_r}->subprocess_env($_, $env->{$_});
  }
  
  return '';
}

sub ssi_startresources
{
	my ($self, $args) = @_;

	$self->{_in_resources} = 1;


}

sub ssi_wkcomponent
{
	my ($self, $args) = @_;

	my $app;

	if(!$self->{_wkapp})
	{
		my $request = Apache::Request->new($self->{_r});

		my $params;

		foreach my $key ($request->param)
		{
			$params->{$key} = $request->param($key);
		}

		eval {
			$app = Webkit::SiteManager::Admin->new;

			my $hostname = $self->{_r}->headers_in->get('X-Forwarded-Host');

			$hostname =~ s/\/$//;

			if($hostname!~/^http:\/\//i)
			{
				$hostname = 'http://'.$hostname;
			}

			$app->siteeditor_initialise_external_run($hostname, $params);

			if($app->{params}->{session_id}=~/\w/)
			{
				my $session = Webkit::Session->new($app);

				$session->login;

				$app->{session} = $session;
			}

			$app->siteeditor_load_page($self->{_r}->uri);

			$app->{_siteeditor_current_page}->load_components;
		};

		if($@)
		{
			return "SSI error - $@";
		}
		else
		{
			$self->{_wkapp} = $app;
		}
	}

	$app = $self->{_wkapp};

	$args->{uri} = $self->{_r}->uri;

	my $output = $app->siteeditor_get_component($args);

	return $output;
}

sub ssi_wkapp
{
	my ($self, $args) = @_;

	my @reqs = qw(app method);

	foreach my $req (@reqs)
	{
		if($args->{$req}!~/\w/)
		{
			return $self->error("You must supply a '$req' argument");
		}
	}

	my $app;

	my $content;

	my $request = Apache::Request->new($self->{_r});

	foreach my $key ($request->param)
	{
		$args->{$key} = $request->param($key);
	}

	eval {
		my $eval_st = '$app = Webkit::'.$args->{app}.'::Admin->new;';

		eval($eval_st);

		$app->initialise_external_run($self->{_r}->dir_config('RunOrgId'), $args);

		my $method = $args->{method};

		$content = $app->$method;
	};

	if($@)
	{
		return "SSI error - $@";
	}
	else
	{
		return $content;
	}
}

1;


