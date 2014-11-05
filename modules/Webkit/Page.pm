package Webkit::Page;

############################
#  Webkit::Page
#
# This represents the content of one page,
# You can set the wrapper (to define what will appear around the content (head, script, css)
# You can add a template or get a template, if you add a template, its content will be
# appended to the page.

use strict;

############################
# New - simple constructor, sets the template dir from Application->get_constant

sub new
{
        my ($classname, $appname) = @_;

        my $self = {};

        bless($self, $classname);

        $self->{template_dir} = Webkit::Application->get_constant('template_dir');
	$self->{appname} = $appname;

        return $self;
}

#####################
# This simply removes the statics

sub DESTROY
{
	my ($self) = @_;

	$self->{statics} = undef;

	$self = undef;
}

sub set_appname
{
	my ($self, $appname) = @_;

	$self->{appname} = $appname;
}

sub set_org_id
{
	my ($self, $org_id) = @_;

	$self->{org_id} = $org_id;
}

########################
# Set Wrapper - calling this will make all content within in page
# appear within the wrapper template given.  The wrapper template
# must contain a {$c{content}} tag to bring in the rest of the page
# (or all you will have is the wrapper).  This is the new way of including
# Javascript and CSS into pages as opposed to listing the filenames in the App.

sub set_wrapper
{
        my ($self, $key, $attr) = @_;

	if($key!~/\w/)
	{
		Webkit::Error->wkerror("You cannot call Page->set_wrapper without a wrapper");
	}

	$self->{wrapper} = $key;
	$self->{wrapper_attr} = $attr;
}

############
# has_wrapper
# returns whether the page has a wrapper or not (1/undef)

sub has_wrapper
{
	my ($self) = @_;

	if($self->{wrapper}=~/\w/)
	{
		return 1;
	}
	else
	{
		return undef;
	}
}


############################
# Add Static
# This will add a parameter to the pages ->{static} values.
# These are merged with the values given to every template call.

sub add_static
{
        my ($self, $key, $value) = @_;

        $self->{statics}->{$key} = $value;
}

############################
# Get Template
# This will accept a relative file and properties.
# It will make the full path using $self->{template_dir}
# and then will merge all of the $self->{statics} into the
# hash given to the template.
# Within all templates, the passed attributes are contained within
# the global $c hash.

sub get_template
{
	my ($self, $key, $props) = @_;

	if($key!~/\w/)
	{
		Webkit::Error->wkerror("You cannot call Page->get_template without a template key");

		return undef;
	}

	my $content = Webkit::Apache::TemplateHub->get_template_contents($key, $self->{appname}, $self->{org_id});
	
	if($content!~/\w/)
	{
		Webkit::Error->wkerror("The template for - key - $key, App - $self->{appname}, Org Id - $self->{org_id} was not found");

		return undef;
	}

        my $template = new Text::Template(	TYPE => 'STRING',
						SOURCE => $content );

        foreach my $skey (keys %{$self->{statics}})
        {
                $props->{$skey} = $self->{statics}->{$skey};
        }

        my $master_hash = {        c => $props };

        my $result = $template->fill_in(HASH => $master_hash);

#	if(!$props->{no_replace})
#	{
#		if(Webkit::Application->https)
#		{
#			$result =~ s/http:\/\//https:\/\//g;
#		}
#	}

	$props = undef;

        return $result;
}

sub static_url
{
	my ($self) = @_;

	return Webkit::Application->http_host;
}

############################
# Add Template, this takes the local file and attr,
# creates a filled in template and then appends it to the body.

sub add_template
{
        my ($self, $key, $props) = @_;

        my $content = $self->get_template($key, $props);

        $self->{body} .= $content;
}

############################
# This will return the text contents of the relative template path

sub get_template_contents
{
	my ($self, $file) = @_;

	if($file!~/\w/)
	{
		Webkit::Error->wkerror("You cannot call Page->get_template_contents without a template file");
	}

	my $content = Webkit::Apache::TemplateHub->get_template_contents($file, $self->{appname}, $self->{org_id});

	return $content;
}

#########################
# get_string_template
# This works the sames as get_template except that the template is passed
# as content rather than file pointer.

sub get_string_template
{
	my ($self, $content, $props) = @_;

	if($content!~/\w/)
	{
		Webkit::Error->wkerror("You cannot call Page->get_string_template without any template content");
	}	

	my $template = new Text::Template(TYPE => 'STRING', SOURCE => $content);

	foreach my $skey (keys %{$self->{statics}})
        {
                $props->{$skey} = $self->{statics}->{$skey};
        }

        my $master_hash = {        c => $props };

        my $result = $template->fill_in(HASH => $master_hash);

        return $result;
}

########################
# Because the Excel templates require a stylesheet
# Embedded into the template (and you want the stylesheet intact
# within Dreamweaver i.e. no \{ ), you must call get_template_for_excel
# on these templates.  This method will search for a <style></style> block
# and replace any {, }'s with \{ and \}.
# It then returns get_string_template on the processed template.

sub get_template_for_excel
{
	my ($self, $file, $props) = @_;

	my $content = $self->get_template_contents($file);

	if($content=~/<style.*?>(.*?)<\/style>/si)
	{
		my $orig = $1;

		my $copy = $orig;

		$copy =~ s/{/\\{/g;
		$copy =~ s/}/\\}/g;

		$content=~s/$orig/$copy/si;		
	}

	return $self->get_string_template($content, $props);
}

###########################################
# Add Body - simply adds the given content to the body of this page

sub add_body
{
	my ($self, $text) = @_;

	$self->{body}.=$text;
}

sub ab
{
	my ($self, $text) = @_;

	$self->add_body($text);
}

#################################
# Print - this will return the current content of this page.
# It does this by checking if there is a wrapper and if so, integrating
# the current content with the wrapper. If there is no wrapper, it
# simply returns the current page content

sub print
{
	my ($self) = @_;

	my $content;

	if($self->{wrapper})
	{
		$self->{wrapper_attr}->{body} = $self->{body};

		$content = $self->get_template($self->{wrapper}, $self->{wrapper_attr})
	}
	else
	{
		$content = $self->{body};
	}

	return $content;
}

########################
# Add Simple Redir
# This will add a re-director to the page (using javascript - document.location).
# It accepts simple a url and redirects to there (hence the simple).

sub add_simple_redir
{
        my ($self, $url) = @_;

        my $redir=<<"+++";
Re-directing
<script>
        var new_loc = '$url';

        document.location = new_loc;
</script>
+++

        $self->ab($redir);
}

################################
# Add Redir
# This will accept a hash reference that is used to re-construct a url
# It will create a query string out of the hash reference ignoring the
# session id if present.  It will then append this query string onto
# the href property.

sub add_redir
{
	my ($self, $attr) = @_;

	$self->ab($self->get_redir($attr));
}

sub get_redir
{
        my ($self, $attr) = @_;

	my $ignore_keys = {
		session_id => 1,
		message => 1 };

        my @pairs;

        foreach my $key (keys %$attr)
        {
		if(!$ignore_keys->{$key})
		{
                	my $st = $key.'='.$attr->{$key};

	                push(@pairs, $st);
		}
        }

	my $alert_string;

	if($attr->{message})
	{
		$alert_string=<<"+++";
alert('$attr->{message}');
+++
	}

        my $query_st = join('&', @pairs);

        $query_st = '&'.$query_st;

	my $extra_js = $attr->{extra_js};

	my $redir=<<"+++";
<script>
if(document.getElementById('loadingdiv'))
{
	document.getElementById('loadingdiv').style.display = 'none';
}
</script>
Re-directing
<script>
        var new_loc = href + '$query_st';

	$alert_string

	$extra_js

        document.location = new_loc;
</script>
+++

	return $redir;
}

################################
# Add Iframe Update
# This will add javascript to the page to update the location
# of the given frame to the iframe_title method with the given title

sub add_iframe_update
{
	my ($self, $frame, $title) = @_;

	$title =~ s/'/\\'/g;
	my $new_loc = 

	my $js=<<"+++";
<script>
var new_loc = href + '&method=iframe_title&title=$title';

if(parent.$frame)
{
	parent.$frame.location = new_loc;
}
</script>
+++

	$self->ab($js);
}

1;
