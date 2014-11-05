package Webkit::Player::Export;

use vars qw(@ISA);
use strict qw(vars);

use Webkit::Player::App;
use Webkit::Player::Account;
use Webkit::Player::User;
use Webkit::Player::Keyword;
use Webkit::Player::OU;
use Webkit::Player::Invoice;
use Webkit::Player::Views;
use Webkit::Player::TextEntry;
use Webkit::Player::PurchaseRecord;
use Webkit::Player::Installation;

use Webkit::Constants;
use Webkit::AppTools;
use LWP::Simple;
use XML::DOM ();
use JSON ();
use Text::Template ();

my $moodle_mode = 'buckslea';
my $flat_iboard_folder = '/home/webkit/sites/flatplayer/www/';

my @image_sizes = qw(100 180 350);

##################################################
##################################################

sub new
{
	my ($classname, $config) = @_;
	
	my $self = {};

	bless($self, $classname);
	
	$self->{classname} = $classname;
	
	foreach my $key (keys %$config)
	{
		$self->{$key} = $config->{$key};
	}
	
	if($self->{account_id}!~/\d/) { die "please provide an account id!;"; }
	if($self->{document_root}!~/\w/) { die "please provide a document_root!;"; }
	if($self->{hostname}!~/\w/) { die "please provide a hostname!;"; }
	
	$ENV{DOCUMENT_ROOT} = $self->{document_root};
	$ENV{HTTP_X_FORWARDED_HOST} = $self->{hostname};
	
	$self->{local_files_folder} = Webkit::Constants->get_constant('player_file_dir');
	$self->{local_folder} = Webkit::Constants->get_constant('player_file_dir').'temp/';
	
	my $db = Webkit::Player::App->get_static_db;
	
	$self->{db} = $db;
	
	$self->{installation} = Webkit::Player::Installation->load($self->{db}, {
		id => 1 });	
	
	$self->setup_data_objects;
	
	$self->{installation}->load_children('Webkit::Player::OU');

	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		my $parent = $self->{installation}->get_child('ou', $ou->ou_id);
	 
		if($parent)
		{
			$parent->add_child($ou);
		}
	}	
	
	return $self;
}

sub setup_data_objects
{
	my ($self, $subdomain_to_use) = @_;
	
	$self->{app} = Webkit::Player::App->new;
	$self->{app}->{_use_installation_id} = 1;
	$self->{app}->{json} = new JSON ();
	$self->{app}->{params}->{plain_thumbnails} = 'y';	
	
	if($subdomain_to_use =~ /\w/)
	{
		$self->{account} = Webkit::Player::Account->load($self->{db}, {
			clause => 'installation_id = ? and ( url = ? or url like ? )',
			binds => [1, $subdomain_to_use, '%-'.$subdomain_to_use.'-%'] });
	}
	else
	{
		$self->{account} = Webkit::Player::Account->load($self->{db}, {
			id => $self->{account_id} });
	}
			
	
	$self->{app}->{account} = $self->{account};
	
	$self->{views} = Webkit::Player::Views->new($self->{db}, $self->{installation}->get_id, $self->{account}->menu_to_use);
	
	$self->{account_url} = 'http://'.$self->{account}->url.'.'.$self->{hostname};
}

################################################################################
################################################################################

sub do_digital_brain_export
{
	my ($self) = @_;
	
	$self->create_folder;
	
	my $csv_data = [['iboard ID', 'iboard title', 'keyword name', 'becta vocab ID']];
	my $csv_iboard_data = [['iboard ID', 'iboard title', 'yeargroup', 'strand', 'objective']];	

	$self->{installation}->load_children('Webkit::Player::OU', {
		clause => 'ou_type = ? or ( ou_type = ? and ( item_type = ? or item_type = ? ) )',
		binds => ['teaching_resource', 'file', 'activity', 'thumbnail'],
		order => 'name' });	
		
	$self->{installation}->load_children('Webkit::Player::Keyword');
			
	foreach my $keyword (@{$self->{installation}->ensure_child_array('keyword')})
	{
		my $ou = $self->{installation}->get_child('ou', $keyword->ou_id);
		
		if($ou)
		{
			$ou->add_child($keyword);
		}
	}
	
	my $activity_array = [];
	
	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		if($ou->is_activity)
		{
			push(@$activity_array, $ou);
		}
		elsif($ou->is_file)
		{
			my $parent = $self->{installation}->get_child('ou', $ou->ou_id);
		
			if($parent)
			{
				if($ou->is_thumbnail)
				{
					$parent->{thumbnail} = $ou;
				}
				elsif($ou->is_activity_file)
				{
					$parent->{activity} = $ou;	
				}
			}	
		}
	}

	foreach my $ou (@{$activity_array})
	{		
		if(!$ou->has_keyword_value('subject', 'Numeracy')) { next; }
		
		if(!$ou->{activity}) { next; }
		
		print $ou->name."\n";
		
		my $id = $ou->get_id;
		my $activity_name = $ou->name;
		
		my $ou_folder = $self->{full_folder}.'/'.$ou->get_id;
		
		my $site_file_map = {
			"/exportTemplates/flashlib.js" => $id."/".$id."_flashlib.js",
			"/exportTemplates/icons/close.gif" => $id."/".$id."_close.gif",
			"/exportTemplates/icons/clear.gif" => $id."/".$id."_clear.gif",
			"/exportTemplates/icons/help.gif" => $id."/".$id."_help.gif",
			"/exportTemplates/icons/refresh.gif" => $id."/".$id."_refresh.gif"
		};
	
		foreach my $file (keys %$site_file_map)
		{
			$self->flatten_account_copy_site_file($file, $site_file_map->{$file});
		}
		
		if($ou->{thumbnail})
		{
			my $local_path = $ou->{thumbnail}->get_file_local_path;

			my @filename_parts = split(/\./, $local_path);
			my $ext = pop(@filename_parts);
			
			#$self->flatten_account_copy_file($local_path, $id."/".$id."_thumbnail.".$ext);
			
			my $max_size = 350;
			
				my $size_filename = join('.', @filename_parts);
				$size_filename .= '.'.$max_size.'.'.$ext;
			
				if(!-e $size_filename)
				{
					my $size_st = $max_size.'x'.$max_size;

					my $convert_path = $self->{app}->convert_path;

					my $commandline = "$convert_path $local_path -resize $size_st -quality 80 $size_filename";
			
					system($commandline);
				}
				my $size_name = 'large';
				
				if($max_size==100)
				{
					$size_name = 'small.';
				}
				
				$self->flatten_account_copy_file($size_filename, $id."/".$id."_thumbnail.".$ext);
		}
		
		if($ou->{activity})
		{
			$self->flatten_account_copy_file($ou->{activity}->get_file_local_path, $id."/".$id."_activity.swf");
		}
		
		$self->output_template('/home/webkit/sites/player/www/exportTemplates/help.htm', $id."/".$id."_help.htm", {
			playerid => $id,
			title => $ou->name,
			notes => $ou->comment
		});
		
		$self->output_template('/home/webkit/sites/player/www/exportTemplates/index.htm', $id."/".$id."_index.htm", {
			playerid => $id,
			title => $ou->name,
			notes => $ou->comment
		});
		
		$self->output_template('/home/webkit/sites/player/www/exportTemplates/activity.htm', $id."/".$id."_activity.htm", {
			playerid => $id,
			title => $ou->name,
			notes => $ou->comment
		});
		
		$self->output_template('/home/webkit/sites/player/www/exportTemplates/topbar.htm', $id."/".$id."_topbar.htm", {
			playerid => $id,
			title => $ou->name,
			notes => $ou->comment
		});
		
		foreach my $keyword (@{$ou->ensure_child_array('keyword')})
		{
			if($keyword->keyword_type eq 'becta')
			{
				my $word = $keyword->word;
				my $value = $keyword->value;
				
				push(@$csv_data, ["\"$id\"", "\"$activity_name\"", "\"$value\"", "\"$word\""]);
			}
		}
		
		my $year = $ou->get_keyword_value('numStrategy_year');
		my $strand = $ou->get_keyword_value('numStrategy_strand');
		my $objective = $ou->get_keyword_value('numStrategy_objective');
		
		push(@$csv_iboard_data, ["\"$id\"", "\"$activity_name\"", "\"$year\"", "\"$strand\"", "\"$objective\""]);
		
		#my $remove_folder = $self->{full_folder}.'/'.$id.'_thumbnail';
		
		#system("rm -rf $remove_folder");
	}
	
	my $csv_lines;
	my $csv_iboard_lines;
	
	foreach my $dataline (@$csv_data)
	{
		my $line = join(",", @$dataline);
		push(@$csv_lines, $line);
	}
	
	foreach my $dataline (@$csv_iboard_data)
	{
		my $line = join(",", @$dataline);
		push(@$csv_iboard_lines, $line);
	}	

	my $csv = join("\n", @$csv_lines);
	my $iboard_csv = join("\n", @$csv_iboard_lines);

	my $keyword_file = $self->{full_folder}.'/becta_keywords.csv';
	open(FILE, ">$keyword_file");
	print FILE $csv;
	close(FILE);

	my $iboard_keyword_file = $self->{full_folder}.'/iboard_keywords.csv';
	open(FILE, ">$iboard_keyword_file");
	print FILE $iboard_csv;
	close(FILE);	
	
	
	print "*Doing the zip (takes a while...) -> ".$self->{full_folder}."/digitalbrain.zip\n";

	chdir($self->{full_folder});

	system("zip -r digitalbrain.zip *");

	print $self->{foldername};	
}

sub output_template
{
	my ($self, $template_file, $output_file, $props) = @_;
	
	$self->{app}->{page_props} = $props;

	my $contents = $self->{app}->get_template($template_file);
	
	$output_file = $self->{full_folder}.'/'.$output_file;

	open(FILE, ">$output_file");

	print FILE $contents;

	close(FILE);
}

################################################################################
################################################################################

sub do_cd_export
{
	my ($self) = @_;
	
	$self->create_folder;
	
	my $top_nodes = $self->{views}->get_array_of_view_nodes;
	
	foreach my $top_node (@$top_nodes)
	{
		$self->process_view_node($top_node);
	}

	$self->{app}->viewer__view_data_handler;

	$self->flatten_account_output_file_contents('data/treeData.xml', $self->{app}->{page_content});
		
	#$self->process_all_node;
	
	$self->{app}->viewer__account_data_handler('cd');

	$self->flatten_account_output_file_contents('data/accountData.xml', $self->{app}->{page_content});	
	
	my $site_files = [
			"/player/activityLaunch.swf",
			"/player/topBars/cd.swf"
	];
	
	my $site_file_map = {
		"/cd/player.exe" => "/player.exe",
		"/cd/icon.ico" => "/icon.ico",
		"/cd/autorun.inf" => "/autorun.inf"
	};
	
	foreach my $file (@$site_files)
	{
		$self->flatten_account_copy_site_file($file);
	}
	
	foreach my $file (keys %$site_file_map)
	{
		$self->flatten_account_copy_site_file($file, $site_file_map->{$file});
	}

	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		if(!$ou->is_activity) { next; }
		if(!$ou->{_include}) { next; }

		$self->include_activity_files($ou, 1);
	}

	print "*Doing the zip (takes a while...) -> ".$self->{full_folder}."/playercd.zip\n";

	chdir($self->{full_folder});

	system("zip -r playercd.zip *");

	print $self->{foldername};
}

sub do_ftp_sync
{
	my ($self) = @_;
	
	my $sync_folder_map = {
		'/dictionaryFiles/phonics' => '/staticfiles/mrspryce/phonics',
		'/dictionaryFiles/wordImages' => '/staticfiles/mrspryce/wordImages',
		'/dictionaryFiles/wordSounds' => '/staticfiles/mrspryce/wordSounds',
		'/dictionaryFiles/literacyGames' => '/staticfiles/literacyGames'
	};
	
	foreach my $remote (keys %$sync_folder_map)
	{
		my $local = $sync_folder_map->{$remote};
		
		chdir($self->{document_root}.$local);
		system("rm -rf *");
		system('wget -nH -m --passive-ftp --cut-dirs=2 ftp://kai:adin20_94Try@pat.wk1.net'.$remote);
	}
}

sub do_site_export
{
	my ($self) = @_;

	return;
	
	$self->{site_export} = 1;
	
	system("rm -rf ".$flat_iboard_folder."*");
	
	$self->{flatten_to_folder_full} = $flat_iboard_folder;
	
	$self->setup_data_objects('tes');
	$self->{data_folder} = 'tesdata';
	
	$self->do_full_export_data;
	
	$self->setup_data_objects('tess');
	$self->{data_folder} = 'tessdata';
	
	$self->do_full_export_data;
	
	$self->do_full_export_files;
	
	print $self->{flatten_to_folder_full};
}
################################################################################
################################################################################

sub do_justdata_export
{
	my ($self) = @_;
	
	$self->do_full_export('data');
}

sub do_wholesite_export
{
	my ($self) = @_;
	
	$self->do_full_export('wholesite');
}

sub do_full_export
{
	my ($self, $mode) = @_;
	
	if($mode!~/\w/)
	{
		$mode = 'data';
	}
	
	$self->create_folder('currentexport');
	
	$self->{data_folder} = 'data';
	$self->do_full_export_data;
	
	if($mode ne 'data')
	{
		$self->do_full_export_files;
	}
	
	#$self->do_full_export_zip;
}

sub do_full_export_zip
{
	my ($self) = @_;
	
	print "*Doing the zip (takes a while...) -> ".$self->{full_folder}."/player.zip\n";

	chdir($self->{full_folder});

	system("zip -r player.zip *");
	
	print $self->{foldername};	
}

sub do_full_export_data
{
	my ($self) = @_;	
	
	my $top_nodes = $self->{views}->get_array_of_view_nodes;
	
	my $all_tree = {
		data => 'root',
		attr  => { id => 'root' },
		child_count => 0,
		children => []	
	};
	
	foreach my $top_node (@$top_nodes)
	{
		$self->{current_view} = lc($top_node->getAttribute('id'));

		#if($self->{current_view} ne 'onlineclub')
		#if($self->{current_view} eq 'science')
		#{
			$self->process_view_node($top_node, $all_tree);
		#}
	}
	
	my $json = new JSON ();

	$json->max_depth(512);
	$json->pretty;
	$json->ascii(1);
	
	my $tree_json = $json->encode($all_tree->{children});

	$self->flatten_account_output_file_contents($self->{data_folder}.'/treeData.json', $tree_json);

	$self->{app}->viewer__view_data_handler;

	$self->flatten_account_output_file_contents($self->{data_folder}.'/treeData.xml', $self->{app}->{page_content});

	$self->{app}->viewer__account_data_handler;

	$self->flatten_account_output_file_contents($self->{data_folder}.'/accountData.xml', $self->{app}->{page_content});	
}

sub do_full_export_files
{
	my ($self) = @_;
	
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/player_index.htm', 'player/index.htm');
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/frameset.htm', 'player/frameset.htm');
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/topbar.htm', 'player/topbar.htm');
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/swf.htm', 'player/swf.htm');
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/feedback.htm', 'player/feedback.htm');
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/gateway.htm', 'index.htm');
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/contact.htm', 'contact.htm');	
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/contact.htm', 'contact.htm');
	
	
	
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/homeindex.htm', 'home.htm');
	
	#$self->flatten_account_copy_file($self->{document_root}.'/flat/homeabout.htm', 'about.htm');

	my $site_folders = [
		"/scripts",
		"/img",
		"/js" ];
		
		
	my $site_files = [
		#"/js/lib.js",
		#"/scripts/site.css",
		#"/scripts/functions.js",
		#"/img/links/transWidth500.gif",
		#"/img/links/transWidth410.gif",
		#"/img/topBar/topBar_Contact.jpg",
		#"/img/topBar/topBar_Home.jpg",
		#"/img/topBar/topBar_Logo.jpg",
		#"/img/topBar/topBar_Info.jpg",
		"/player/player.swf",
		"/player/activityLaunch.swf",
		"/player/evaluationText.swf",
		"/player/topBars/barefoot.swf",
		"/player/topBars/dictionary.swf",
		"/player/topBars/moodle.swf",
		"/player/topBars/generic.swf",
		"/player/topBars/geography.swf",
		"/player/topBars/history.swf",
		"/player/topBars/literacy.swf",
		"/player/topBars/magicschool.swf",
		"/player/topBars/mrspryce.swf",
		"/player/topBars/numeracy.swf",
		"/player/topBars/re.swf",
		"/player/topBars/science.swf"
	];
	
	foreach my $folder (@$site_folders)
	{
		$self->flatten_account_copy_site_folder($folder);
	}
	
	foreach my $file (@$site_files)
	{
		$self->flatten_account_copy_site_file($file);
	}

	foreach my $ou (@{$self->{installation}->ensure_child_array('ou')})
	{
		if(!$ou->is_activity) { next; }
		if(!$ou->{_include}) { next; }

		$self->include_activity_files($ou);
	}
}

################################################################################
################################################################################
	
sub create_folder
{
	my ($self, $foldername) = @_;

	my $mode = undef;
	
	if($foldername =~ /\w/)
	{
		$mode = 1;	
	}
	
	while(!$mode)
	{
		my $randst = new String::Random;

		$foldername = $randst->randpattern("CCCCCCCCCCCC");
		
		my $check = $self->{local_folder}.$foldername;

		if(-e $check)
		{
			$mode = undef;
		}
		else
		{
			$mode = 1;
		}
	}
	
	$self->{foldername} = $foldername;
	
	$self->{full_folder} = $self->{local_folder}.$self->{foldername}.'/';
	
	$self->{flatten_to_folder} = $self->{foldername};
	$self->{flatten_to_folder_full} = $self->{full_folder};
	
	if(!-e $self->{full_folder})
	{
		mkdir($self->{full_folder});
	}

	if(!$self->{noprint})
	{
		print "Making output folder: ".$self->{full_folder}."\n";	
	}
}

################################################################################
################################################################################

################################################################################
################################################################################

sub do_literacy_export
{
	my ($self) = @_;
	
	$self->create_folder;
	
	$self->{jsfl} = '';
	my $tree = {};
	
	$self->flatten_account_copy_site_folder('/staticfiles/mrspryce/phonics');
	$self->flatten_account_copy_site_folder('/staticfiles/mrspryce/wordImages');
	$self->flatten_account_copy_site_folder('/staticfiles/mrspryce/wordSounds');
	
	my $site_file_map = {
		"/player/generic.as" => "/player/generic.as",
		"/literacyFlash/compile.jsfl" => "/compile.jsfl",
		"/literacyFlash/words.as" => "/words.as"
	};
	
	foreach my $file (keys %$site_file_map)
	{
		$self->flatten_account_copy_site_file($file, $site_file_map->{$file});
	}
	
	my $readme=<<"+++";
You must copy all of the games to this folder!!!	
+++

	$self->flatten_account_output_file_contents("/games/README.txt", $readme);
	
	my $views = Webkit::Player::Views->new_with_installation($self->{installation}, $self->{account}->menu_to_use);
	
	my $doc = $views->parse_structure('/viewXML/dictionary.xml');
	
	my $phase_nodes = $doc->getElementsByTagName('phase');
	
	my $compile_jsfl = '';
		
	foreach my $phase_node (@$phase_nodes)
	{
		my $phase = $phase_node->getAttribute('value');
		
		$self->flatten_literacy_xml({
			phase => $phase });
		
		my $title_nodes = $phase_node->getElementsByTagName('title');
		
		foreach my $title_node (@$title_nodes)
		{
			my $title = $title_node->getAttribute('value');
			
			my $params = {
				phase => $phase,
				title => $title };
				
			my $jswords = $self->flatten_literacy_xml($params);
				
			my $allsubtitlejswordsarray = [];
			my $allsubtitledataarray = [];
			
			my $subtitle_nodes = $title_node->getElementsByTagName('subtitle');
			
			my $total = @$subtitle_nodes;
			my $counter = 0;
			
			foreach my $subtitle_node (@$subtitle_nodes)
			{
				my $subtitle = $subtitle_node->getAttribute('value');
				
				my $subtitlejswords = $self->flatten_literacy_xml({
					phase => $phase,
					title => $title,
					subtitle => $subtitle });
					
				my $subtitlejs = "+'{title:\"$subtitle\", words:[$subtitlejswords]}";
				my $subtitlejs2 = "{title:\"$subtitle\", words:[$subtitlejswords]}";
				
				if($counter < $total-1)
				{
					$subtitlejs .= ",";
					$subtitlejs2 .= ",";
				}
				
				$counter++;

				$subtitlejs .= "'";
				
				push(@$allsubtitlejswordsarray, $subtitlejs);
				push(@$allsubtitledataarray, $subtitlejs2);
			}
			
			my $allsubtitlejswords = join("\n", @$allsubtitlejswordsarray);
			my $allsubtitlejswords2 = join("\n", @$allsubtitledataarray);
			
			my $foldername = $self->get_foldername($params);
			
			$self->{jsfl}->{'worddata'.$phase}.=<<"+++";

allWordData['$foldername'] = [
$allsubtitlejswords2
];
			
+++

			$self->{jsfl}->{$phase}.=<<"+++";
subsetAS = ''
+'var subsetTitle = "Phase $phase: $title";'
+'var subsetArray = ['
$allsubtitlejswords
+ '];';

processFolder('/xml/$foldername', subsetAS, [$jswords]);




+++
		}
	}
	
	foreach my $phase (keys %{$self->{jsfl}})
	{
		my $jsfl = $self->{jsfl}->{$phase};
		my $jsfl2 = $self->{jsfl}->{'worddata'.$phase};
		
		$self->flatten_account_output_file_contents('phase'.$phase.'.jsfl', $jsfl);
		$self->flatten_account_output_file_contents('worddata'.$phase.'.jsfl', $jsfl2);
	}
	
	print "*Doing the zip (takes a while...) -> ".$self->{full_folder}."/literacy.zip\n";

	chdir($self->{full_folder});

	system("zip -r literacy.zip *");

	print $self->{foldername};
}

sub get_foldername
{
	my ($self, $params) = @_;
	
	my $folder_parts = [$params->{phase}];
	
	if($params->{title} =~ /\w/)
	{
		my $value = $params->{title};
		
		$value =~ s/\//_slash_/g;
		
		push(@$folder_parts, $value);
	}
	
	if($params->{subtitle} =~ /\w/)
	{
		my $value = $params->{subtitle};
		
		$value =~ s/\//_slash_/g;
		
		push(@$folder_parts, $value);
	}
	
	my $foldername = join('/', @$folder_parts);
	
	$foldername =~ s/ /_/g;
	
	return $foldername;
}

################################################################################
################################################################################

sub flatten_literacy_xml
{
	my ($self, $params) = @_;
	
	my $folder_parts = [$params->{phase}];
	
	if($params->{title} =~ /\w/)
	{
		my $value = $params->{title};
		
		$value =~ s/\//_slash_/g;
		
		push(@$folder_parts, $value);
	}
	
	if($params->{subtitle} =~ /\w/)
	{
		my $value = $params->{subtitle};
		
		$value =~ s/\//_slash_/g;
		
		push(@$folder_parts, $value);
	}
	
	my $foldername = $self->get_foldername($params);
	
	$foldername =~ s/ /_/g;
	
	my $xml_path = '/xml/'.$foldername.'/data.xml';
	my $as_path = '/xml/'.$foldername.'/data.as';
	my $plain_path = '/xml/'.$foldername.'/words.txt';
	
	my $xml = $self->get_search_xml($params, 'yes');
	
	my $ret = '';
	
	if($xml=~/\w/)
	{
		my $parser = XML::DOM::Parser->new;

		my $doc = $parser->parse($xml);
	
		my $topNode = $doc->getDocumentElement;
	
		my $activity_data_nodes = $topNode->getElementsByTagName('activity_data');
		my $activity_data_node = $activity_data_nodes->[0];
	
		my $activity_children_nodes = $activity_data_node->getChildNodes;
		
		my $words_found = [];
		my $plain_words = [];
	
		for(my $i=0; $i<@$activity_children_nodes; $i++)
		{
			my $child_node = $activity_children_nodes->[$i];
		
			if($child_node->getNodeType != 1) { next; }
		
			my $id = $child_node->getAttribute('id');
			my $name = $child_node->getAttribute('name');
			
			push(@$words_found, '"'.$name.'"');
			push(@$plain_words, $name);
		}
		
		my $js_words = join(', ', @$words_found);
		my $plain_words_string = join(', ', @$plain_words);

		$self->{jsfl}->{$params->{phase}}.=<<"+++";
processFolder('/xml/$foldername', [$js_words]);
+++
		
		my $style = $params->{phase} - 1;
		
		my $replace_mode = 'vowel';
		
		if($params->{phase}==3)
		{
			my $phase3vowels = {
				'Words using sets 1-6 GPCs' => 1,
				'Words using sets 1-7 GPCs' => 1,
				'Words using the 4 consonant digraphs' => 1
			};
			
			if(!$phase3vowels->{$params->{title}})
			{
				$replace_mode = 'consonant';
			}
		}

		my $as_xml=<<"+++";
var style = $style;
var replaceMode = '$replace_mode';	

var chunks = [];

var chunk = '';

chunk = ''
+++
		
		my @xml_lines = split(/\n/, $xml);
		
		my $line_count = 0;
		
		foreach my $line (@xml_lines)
		{
			$line_count++;
			
			$line =~ s/'/\\'/g;
			
			if($line_count>=30)
			{
				$line_count = 0;
				
				$as_xml.=<<"+++";
+	'$line';

chunks.push(chunk);

chunk = ''				
+++
			}
			else
			{
				$as_xml.=<<"+++";
+ 	'$line'
+++
			}
		}
		
		$as_xml.=<<"+++";
+	'';

chunks.push(chunk);

_root.sourceXML = chunks.join('');
+++
		
		print "Found $xml_path\n";
	
		$self->flatten_account_output_file_contents($xml_path, $xml);
		$self->flatten_account_output_file_contents($as_path, $as_xml);
		$self->flatten_account_output_file_contents($plain_path, $plain_words_string);
	}
	
	return $ret;
}

sub get_search_xml
{
	my ($self, $params, $is_dictionary) = @_;
	
	my $app = Webkit::Player::App->new;
	$app->{_use_installation_id} = $self->{account}->installation_id;
	$app->{json} = new JSON ();
	$app->{account} = $self->{account};
	$app->{params}->{plain_thumbnails} = 'y';
	$app->{use_all_dictionary_images} = $is_dictionary;
	
	foreach my $key (keys %$params)
	{
		$app->{params}->{$key} = $params->{$key};
	}
	
	$app->viewer__search_data_handler;
	
	my $results = $app->{activity_results};
	
	my $count = 0;
	
	if($results)
	{
		$count = @$results;
	}
	
	if($count>0)
	{
		return $app->{page_content};
	}
	else
	{
		return '';
	}
}

################################################################################
################################################################################

sub include_activity_files
{
	my ($self, $activity, $minimal) = @_;
	
	if($self->{copied_ou_files_done}->{$activity->get_id})
	{
		return;	
	}
	
	$self->{copied_ou_files_done}->{$activity->get_id} = 1;
	
	if(!$self->{noprint})
	{
		print "Copying files for: ".$activity->name."\n";
	}
	
	my $help = Webkit::AppTools->xml_quote($activity->comment);
	
	$help =~ s/\r//g;
	$help =~ s/\n+/\n/g;
	
	my $help_xml=<<"+++";
<comment>$help</comment>
+++

	my $ret_info = {};

	$ret_info->{helpxml} = $self->flatten_account_output_file_contents('help/'.$activity->get_id.'.xml', $help_xml);
	
	if(!$minimal)
	{
		my $name = $activity->name;
		my $help_text = $activity->comment;
	
		$help_text =~ s/\n/<br>/g;

		my $help_html=<<"+++";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>$name</title>
<script type="text/javascript" src="../js/lib.js"></script>
<style type="text/css">
body,html {
    margin:0px;
    padding:0px;
    height:100%;
}

td { font-family:Tahoma;font-size:11pt; }

</style>
<script>
	function init()
	{
		var bg = getURLParameter('bg');
		
		document.body.style.backgroundColor = '#' + bg;		
	}
</script>
</head>
<body>
<table width=100% height=100% border=0 cellpadding="10" cellspacing="0">
<tr width=100% height=100%>
<td width=100% height=100% align=left valign=top>
$help_text
<br><br>
<a href="javascript:top.close();" style="color:#000000;">close window</a>
</td>
</tr>
</table>
<script>
	init();
</script>
</body>
</html>	
+++

		$ret_info->{helphtml} = $self->flatten_account_output_file_contents('help/'.$activity->get_id.'.htm', $help_html);
	}
	
	#if($self->{site_export})
	#{
	#	return;	
	#}
	
	foreach my $child (@{$activity->ensure_child_array('ou')})
	{
		if(!$child->is_file) { next; }
		if((!$child->is_activity_file)&&(!$child->is_thumbnail)) { next; }
		
		my $source = $self->{local_files_folder}.$child->item_path;
		my $dest = 'files/'.$child->item_path;
		my $full_dest = $self->{flatten_to_folder_full}.$dest;
		
		if(!-e $source) { next; }
		
		if($child->is_thumbnail)
		{
			if(!$self->{noprint})
			{
				print "		Thumbnail: ".$dest."\n";
			}
			
			$ret_info->{thumbnail} = $self->flatten_account_copy_file($source, $dest);
			
			foreach my $size (@image_sizes)
			{
				my $exists_path = $source;
				my $size_dest_path = $dest;
				
				$exists_path =~ s/\.jpg$/\.$size\.jpg/;
				$size_dest_path =~ s/\.jpg$/\.$size\.jpg/;
				
				if(!$self->{noprint})
				{
					print "		checking $size: ".$exists_path."\n";
				}
				
				if(!-e $exists_path)
				{
					my $file = $child->item_path;
				
					my @filename_parts = split(/\./, $file);
					my $ext = pop(@filename_parts);

					my $size_filename = join('.', @filename_parts);
					$size_filename .= '.'.$size.'.'.$ext;
				
					my $local_size_path = $self->{flatten_to_folder_full}.'files/'.$size_filename;
				
					my $size_st = $size.'x'.$size;

					my $convert_path = $self->{app}->convert_path;

					my $commandline = "$convert_path $full_dest -resize $size_st -quality 80 $local_size_path";
			
					$ret_info->{'thumbnail'.$size} = $local_size_path;
					
					if(!$self->{noprint})
					{
						print "				Convert\n";
					}
					
					system($commandline);
				}
				else
				{
					if(!$self->{noprint})
					{
						print "				Exists - copied\n";
					}
					
					$ret_info->{'thumbnail'.$size} = $self->flatten_account_copy_file($exists_path, $size_dest_path);
				}
			}
			
			#system("unlink $full_dest");
		}
		elsif($child->is_activity_file)
		{
			$dest = 'files/swfs/'.$activity->get_id.'.swf';
			
			$ret_info->{swf} = $self->flatten_account_copy_file($source, $dest);
		}
	}
	
	return $ret_info;
}

sub is_bucks
{
	my ($self) = @_;
	
	if($moodle_mode eq 'buckslea')
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub process_all_node
{
	my ($self) = @_;

	my $id = 'library-all';
	
	my $app = Webkit::Player::App->new;
	$app->{_use_installation_id} = $self->{account}->installation_id;
	$app->{json} = new JSON ();
	$app->{account} = $self->{account};
	$app->{params}->{plain_thumbnails} = 'y';
	
	$app->{params}->{node} = $id;
	
	$app->viewer__view_data_handler;

	$self->flatten_account_output_file_contents('data/treeData.xml', $app->{page_content});
	
	my $parser = XML::DOM::Parser->new;

	my $doc = $parser->parse($app->{page_content});
	
	my $topNode = $doc->getDocumentElement;
	
	my $activity_data_nodes = $topNode->getElementsByTagName('activity_data');
	my $activity_data_node = $activity_data_nodes->[0];
	
	my $activity_children_nodes = $activity_data_node->getChildNodes;
	
	for(my $i=0; $i<@$activity_children_nodes; $i++)
	{
		my $child_node = $activity_children_nodes->[$i];
		
		if($child_node->getNodeType != 1) { next; }
		
		my $id = $child_node->getAttribute('id');
		my $thumbnail = $child_node->getAttribute('thumbnail');
		
		my $ou = $self->{installation}->get_child('ou', $id);
		
		if($ou)
		{
			$ou->{_include} = 1;
		}
	}		
}

sub do_moodle_export
{
	my ($self) = @_;
	
	$self->create_folder;
	
	my $top_nodes = $self->{views}->get_array_of_view_nodes;
	
	$self->{moodle_link_html} = '';
	$self->{moodle_link_depth} = 0;
	
	my $app = Webkit::Player::App->new;
	$app->{_use_installation_id} = $self->{account}->installation_id;
	$app->{json} = new JSON ();
	$app->{account} = $self->{account};
	$app->{params}->{plain_thumbnails} = 'y';	
	
	$self->{template_app} = $app;
	
	foreach my $top_node (@$top_nodes)
	{
		$self->{current_view} = lc($top_node->getAttribute('id'));

		if($self->{current_view} ne 'onlineclub')
		{
			print "DOing ".$self->{current_view}."\n\n";
			
			my $top_moodle = $self->process_moodle_view_node($top_node);
			
			print "Have Top Moodle\n";

			$self->output_moodle_node($top_moodle);
			
			$self->{moodle_link_html} .= '<br><br>';
		}
	}
	
	$self->flatten_account_output_file_contents('index.htm', $self->{moodle_link_html});

	#print "*Doing the zip (takes a while...) -> ".$self->{full_folder}."/moodlePackages.zip\n";

	#chdir($self->{full_folder});

	#system("zip -r moodlePackages.zip *");

	print $self->{foldername};
}

sub do_activity_summary_export
{
	my ($self) = @_;
	
	my $top_nodes = $self->{views}->get_array_of_view_nodes;
	
	my $app = Webkit::Player::App->new;
	$app->{_use_installation_id} = $self->{account}->installation_id;
	$app->{json} = new JSON ();
	$app->{account} = $self->{account};
	$app->{params}->{plain_thumbnails} = 'y';	
	
	$self->{template_app} = $app;
	
	foreach my $top_node (@$top_nodes)
	{
		$self->{current_view} = lc($top_node->getAttribute('id'));

		if($self->{current_view} ne 'onlineclub')
		{
			print "DOing ".$self->{current_view}."\n\n";
			
			my $summary = $self->process_activity_summary_node($top_node);
				
			$self->get_activity_summary_lines($summary, $self->{current_view});
		}
	}
	
	my $csv = join("\n", @{$self->{csv_lines}});
	
	my $filename = "/home/webkit/sites/player/scripts/activity_summary.csv";

	open(CSV, ">$filename");
	
	print CSV "Name, Link, Help, Subject, Year, Strand, Objective\n";
	print CSV $csv;
	
	close(CSV);

	print "Done";
}

sub get_activity_summary_lines
{
	my ($self, $summary, $view) = @_;

	my $count = @{$summary->{children}};
	
	if($count>0)
	{
		foreach my $child_summary (@{$summary->{children}})
		{
			$self->get_activity_summary_lines($child_summary, $view);
		}
	}
	else
	{
		my @parts = split(/:/, $summary->{name});
		
		foreach my $activity (@{$summary->{activities}})
		{
			my $link = 'http://tes.iboard.co.uk/activity/'.$view.'/'.$activity->get_id;
			my $name = $activity->name;
			my $help = $activity->comment;
			
			$help =~ s/\n//g;
			$help =~ s/\r//g;
			$help =~ s/<br\/?>/\n/g;
			$help =~ s/\"//g;
			$name =~ s/\"//g;
			$help =~ s/<.*?>//g;
	
			my @values = ($name, $link, $help);
			my $final_values = [];
			
			foreach my $part (@parts)
			{
				push(@values, $part);	
			}
			
			foreach my $part (@values)
			{
				push(@$final_values, '"'.$part.'"');
			}
			
			my $line = join(',', @$final_values);
			
			#print $line."\n";
			
			push(@{$self->{csv_lines}}, $line);
		}
	}
}

sub process_activity_summary_node
{
	my ($self, $node, $parent_name) = @_;
	
	my $id = $node->getAttribute('id');
	my $main_name = $node->getAttribute('name');
	
	if($parent_name =~ /\w/)
	{
		$main_name = $parent_name.':'.$main_name;
	}
	
	my $file_id = $id;
	
	$file_id =~ s/://g;	
	
	#print "Processing view: $id - $main_name\n\n";
	
	my $summary = {
		id => $id,
		file_id => $file_id,
		children => [],
		name => $main_name };
	
	my $app = Webkit::Player::App->new;
	$app->{_use_installation_id} = $self->{account}->installation_id;
	$app->{json} = new JSON ();
	$app->{account} = $self->{account};
	$app->{params}->{plain_thumbnails} = 'y';
	
	$app->{params}->{node} = $id;
	
	my $param_parts = ['node='.$id];
	
	my $param_nodes = $node->getChildNodes;
	
	for(my $i=0; $i<@$param_nodes; $i++)
	{
		my $param_node = $param_nodes->[$i];
		
		if($param_node->getNodeType != 1) { next; }
		
		my $name = $param_node->getAttribute('name');
		my $value = $param_node->getAttribute('value');
		
		if(($name!~/\w/)||($value!~/\w/)) { next; }
		
		$app->{params}->{$name} = $value;
		push(@$param_parts, $name.'='.$value);
	}
	
	$app->viewer__view_data_handler;
	
	$summary->{activities} = $app->{library_activities};
	$summary->{view} = $self->{current_view};
	
	my $parser = XML::DOM::Parser->new;

	my $doc = $parser->parse($app->{page_content});
	
	my $topNode = $doc->getDocumentElement;
	
	my $view_data_nodes = $topNode->getElementsByTagName('view_data');
	my $view_data_node = $view_data_nodes->[0];
	
	my $children_nodes = $view_data_node->getChildNodes;
	
	for(my $i=0; $i<@$children_nodes; $i++)
	{
		my $child_node = $children_nodes->[$i];
		
		if($child_node->getNodeType != 1) { next; }
		
		$self->{moodle_link_depth}++;
		
		my $child_summary = $self->process_activity_summary_node($child_node, $main_name);
		
		push(@{$summary->{children}}, $child_summary);
		
		$self->{moodle_link_depth}--;
	}
	
	return $summary;
}

sub output_moodle_node_page
{
	my ($self, $moodle, $file_id) = @_;
	
	my $node_id = $moodle->{file_id};
	
	print "OUTPUTTING -> $file_id\n\n";
	
	$self->{template_app}->{page_props}->{objs}->{library_activities} = $moodle->{activities};
	
	my $template_name = 'index.htm';
	
	if($self->is_bucks)
	{
		$template_name = 'buckinghamshireIndex.htm';
	}
	
	my $page = $self->{template_app}->get_template($self->{document_root}.'/exportTemplates/moodle/'.$template_name);
	
	my $htm_page_name = $node_id;
	
	if($self->is_bucks)
	{
		$htm_page_name = 'index';
	}
	
	$self->flatten_account_output_file_contents($file_id.'/'.$htm_page_name.'.htm', $page);
	
	foreach my $child_moodle (@{$moodle->{children}})
	{
		$self->output_moodle_node_page($child_moodle, $file_id);
	}
}

sub output_moodle_node
{
	my ($self, $moodle) = @_;
	
	my $file_id = $moodle->{file_id};
	my $main_name = $moodle->{name};
	
	$self->{template_app}->{page_props}->{statichost} = $self->{statichost};
	$self->{template_app}->{page_props}->{view} = $self->{current_view};
	$self->{template_app}->{page_props}->{package_title} = $moodle->{name};
	
	foreach my $activity (@{$moodle->{activities}})
	{
		my $thumbnail_path = $activity->{data}->{thumbnail_url};

		if($thumbnail_path !~ /\w/)
		{
			$activity->{has_no_thumbnail} = 1;
			next;
		}
		
		my $full_thumbnail_path = Webkit::Constants->get_constant('player_file_dir').$thumbnail_path;
		my $copy_to_thumbnail_path = $file_id.'/'.$activity->get_id.'.jpg';
		
		if(!-e $full_thumbnail_path)
		{
			$activity->{has_no_thumbnail} = 1;
			next;
		}
		
		my $size_path = $full_thumbnail_path;
		my $size = 100;
		
		$size_path =~ s/\.jpg$/\.$size\.jpg/i;
		
		if($self->is_bucks)
		{
			$size_path = $full_thumbnail_path;
			my $size_to = 150;
		
			$size_path =~ s/\.jpg$/\.$size_to\.jpg/i;
			
			my $size_st = $size_to.'x'.$size_to;

			my $convert_path = $self->{template_app}->convert_path;
			
			my $output_path = '/home/pub/player/moodle/thumbnails/'.$activity->get_id.'.jpg';

			my $commandline = "$convert_path $full_thumbnail_path -resize $size_st -quality 80 $output_path";
			
			system($commandline);
		}
		else
		{
#			if(!-e $size_path)
#			{
#				my $size_to = $size;
#		
#				my $size_st = $size_to.'x'.$size_to;
#
#				my $convert_path = $self->{template_app}->convert_path;
#
#				my $commandline = "$convert_path $size_path -resize $size_st -quality 80 $full_thumbnail_path";
#			
#				system($commandline);
#			}
			
			$self->flatten_account_copy_file($size_path, $copy_to_thumbnail_path);
		}
		
		#if($self->is_bucks)
		#{
		#	my $swf_ou = Webkit::Player::OU->load($self->{db}, {
		#		clause => 'ou_id = ? and ou_type = ? and item_type = ?',
		#		binds => [$activity->get_id, 'file', 'activity']
		#	});
		#	
		#	if($swf_ou)
		#	{
		#		my $full_swf_path = Webkit::Constants->get_constant('player_file_dir').$swf_ou->item_path;
		#		my $copy_to_swf_path = $file_id.'/'.$activity->get_id.'.swf';
		#
		#		$self->flatten_account_copy_file($full_swf_path, $copy_to_swf_path);
		#	}
		#}
	}
	
	$self->output_moodle_node_page($moodle, $file_id);
	
	$self->{template_app}->{page_props}->{objs}->{top_moodle} = $moodle;
	
	my $jsLibName = 'moodleLib.js';
	
	if($self->is_bucks)
	{
		$jsLibName = 'buckinghamshireMoodleLib.js';
	}

	
		
	## if we are not bucks mode then lets make a moodle zip file
	if(!$self->is_bucks)
	{
		$self->flatten_account_copy_site_file('/exportTemplates/moodle/'.$jsLibName, $file_id.'/moodleLib.js');
		$self->flatten_account_copy_site_file('/player/topBars/moodle.swf', $file_id.'/moodle.swf');
		
		my $manifest = $self->{template_app}->get_template($self->{document_root}.'/exportTemplates/moodle/imsmanifest.htm');
		$self->flatten_account_output_file_contents($file_id.'/imsmanifest.xml', $manifest);
		$self->flatten_account_copy_site_file('/exportTemplates/moodle/dublincore.xml', $file_id.'/dublincore.xml');
		$self->flatten_account_copy_site_file('/exportTemplates/moodle/ims_xml.xsd', $file_id.'/ims_xml.xsd');
		$self->flatten_account_copy_site_file('/exportTemplates/moodle/imscp_v1p1.xsd', $file_id.'/imscp_v1p1.xsd');
		$self->flatten_account_copy_site_file('/exportTemplates/moodle/imsmd_v1p2p2.xsd', $file_id.'/imsmd_v1p2p2.xsd');
	
		chdir($self->{full_folder}.'/'.$file_id);

		system("zip -rq $file_id.zip *");
	
		system("mv $file_id.zip ../");
	
		chdir($self->{full_folder});
	
		system("rm -rf $file_id");
	}
	else
	{
		if(!$self->{_has_copied_one_off_files})
		{
			$self->{_has_copied_one_off_files} = 1;
			
			#$self->flatten_account_copy_site_file('/exportTemplates/moodle/'.$jsLibName, 'moodleLib.js');
			#$self->flatten_account_copy_site_file('/player/topBars/moodle.swf', 'moodle.swf');	
			
			#$self->moodle_copy_flattened_folder($self->{statichost}, 'help');
			#$self->moodle_copy_flattened_folder($self->{statichost}, 'js');
			#$self->moodle_copy_flattened_folder($self->{statichost}, 'scripts');
			#$self->moodle_copy_flattened_folder($self->{statichost}, 'img');
			#$self->flatten_account_copy_site_file("/img/topBar/topBar_curve.jpg",);
			#$self->flatten_account_copy_site_file("/img/topBar/topBar_repeat.jpg",);
			#$self->flatten_account_copy_site_file("/img/topBar/button_start.jpg",);
		}
	}
	
	my $padding = '';
	
	for(my $i=0; $i<$self->{moodle_link_depth}; $i++)
	{
		$padding .= '----';
	}
	
	$padding .= '&gt;';
	
	my $link = $file_id;
	
	if($self->is_bucks)
	{
		$link .= '/index.htm';
	
		my $child_count = @{$moodle->{children}};
	
		if($child_count>0)
		{
			$self->{moodle_link_html}.=<<"+++";
$padding <b>$main_name</b><br>
+++
		}
		else
		{
			$self->{moodle_link_html}.=<<"+++";
$padding <a href="$link">$main_name</a><br>
+++
		}
	}
	else
	{
		$link .= '.zip';
		
		$self->{moodle_link_html}.=<<"+++";
$padding <a href="$link">$main_name</a><br>
+++
	}

	foreach my $child (@{$moodle->{children}})
	{
		$self->{moodle_link_depth}++;
		
		$self->output_moodle_node($child);
		
		$self->{moodle_link_depth}--;
	}
}

sub moodle_copy_flattened_folder
{
	my ($self, $source, $folder) = @_;
	
	my $full_source = '/home/pub/player/temp/'.$source.'/'.$folder;
	my $full_dest = $self->{flatten_to_folder_full}.'/'.$folder;
	
	if(!-e $full_source) { return; }
	
	system("cp -r $full_source $full_dest");
	
	print "COPY FOLDER: $source -> $full_dest\n";		
}

sub process_moodle_view_node
{
	my ($self, $node, $parent_name) = @_;
	
	my $id = $node->getAttribute('id');
	my $main_name = $node->getAttribute('name');
	
	if($parent_name =~ /\w/)
	{
		$main_name = $parent_name.' > '.$main_name;
	}
	
	my $file_id = $id;
	
	$file_id =~ s/://g;	
	
	print "Processing view: $id - $main_name\n\n";
	
	my $moodle = {
		id => $id,
		file_id => $file_id,
		children => [],
		name => $main_name };
	
	my $app = Webkit::Player::App->new;
	$app->{_use_installation_id} = $self->{account}->installation_id;
	$app->{json} = new JSON ();
	$app->{account} = $self->{account};
	$app->{params}->{plain_thumbnails} = 'y';
	
	$app->{params}->{node} = $id;
	
	my $param_parts = ['node='.$id];
	
	my $param_nodes = $node->getChildNodes;
	
	for(my $i=0; $i<@$param_nodes; $i++)
	{
		my $param_node = $param_nodes->[$i];
		
		if($param_node->getNodeType != 1) { next; }
		
		my $name = $param_node->getAttribute('name');
		my $value = $param_node->getAttribute('value');
		
		if(($name!~/\w/)||($value!~/\w/)) { next; }
		
		$app->{params}->{$name} = $value;
		push(@$param_parts, $name.'='.$value);
	}
	
	$app->viewer__view_data_handler;
	
	$moodle->{activities} = $app->{library_activities};
	$moodle->{view} = $self->{current_view};
	
	my $parser = XML::DOM::Parser->new;

	my $doc = $parser->parse($app->{page_content});
	
	my $topNode = $doc->getDocumentElement;
	
	my $view_data_nodes = $topNode->getElementsByTagName('view_data');
	my $view_data_node = $view_data_nodes->[0];
	
	my $children_nodes = $view_data_node->getChildNodes;
	
	for(my $i=0; $i<@$children_nodes; $i++)
	{
		my $child_node = $children_nodes->[$i];
		
		if($child_node->getNodeType != 1) { next; }
		
		$self->{moodle_link_depth}++;
		
		my $child_moodle = $self->process_moodle_view_node($child_node, $main_name);
		
		push(@{$moodle->{children}}, $child_moodle);
		
		$self->{moodle_link_depth}--;
	}
	
	return $moodle;
}

sub process_view_node
{
	my ($self, $node, $parent_tree) = @_;
	
	my $id = $node->getAttribute('id');
	
	if($self->{account}->url eq 'lgfl' && $id eq 'literacyks2') { return; }
	
	my $app = Webkit::Player::App->new;
	$app->{_use_installation_id} = $self->{account}->installation_id;
	$app->{json} = new JSON ();
	$app->{account} = $self->{account};
	$app->{params}->{plain_thumbnails} = 'y';
	$app->{params}->{library_mode} = 'y';
	
	$app->{params}->{node} = $id;
	
	my $param_parts = ['node='.$id];
	
	my $param_nodes = $node->getChildNodes;
	
	my $json_id = $id;
	my $json_name = $node->getAttribute('name');
	
	$json_id =~ s/://g;
	$json_name =~ s/:::.*?$//g;
	
	my $tree_node = {
		data => $json_name,
		attr => { id => $json_id },
		children => []
	};
	
	for(my $i=0; $i<@$param_nodes; $i++)
	{
		my $param_node = $param_nodes->[$i];
		
		if($param_node->getNodeType != 1) { next; }
		
		my $name = $param_node->getAttribute('name');
		my $value = $param_node->getAttribute('value');
		
		if(($name!~/\w/)||($value!~/\w/)) { next; }
		
		$app->{params}->{$name} = $value;
		push(@$param_parts, $name.'='.$value);
	}
	
	$app->viewer__view_data_handler;
	
	my $file_id = $id;
	
	$file_id =~ s/://g;

	$self->flatten_account_output_file_contents($self->{data_folder}.'/'.$file_id.'.xml', $app->{page_content});
	
	my $parser = XML::DOM::Parser->new;

	my $doc = $parser->parse($app->{page_content});
	
	my $topNode = $doc->getDocumentElement;
	
	my $view_data_nodes = $topNode->getElementsByTagName('view_data');
	my $view_data_node = $view_data_nodes->[0];
	
	my $children_nodes = $view_data_node->getChildNodes;
	
	for(my $i=0; $i<@$children_nodes; $i++)
	{
		my $child_node = $children_nodes->[$i];
		
		if($child_node->getNodeType != 1) { next; }
		
		$self->process_view_node($child_node, $tree_node);
	}
	
	push(@{$parent_tree->{children}}, $tree_node);
	
	my $json_activities = [];
	
	my $activity_data_nodes = $topNode->getElementsByTagName('activity_data');
	my $activity_data_node = $activity_data_nodes->[0];
	
	my $activity_children_nodes = $activity_data_node->getChildNodes;
	
	for(my $i=0; $i<@$activity_children_nodes; $i++)
	{
		my $child_node = $activity_children_nodes->[$i];
		
		if($child_node->getNodeType != 1) { next; }
		
		my $id = $child_node->getAttribute('id');
		my $thumbnail = $child_node->getAttribute('thumbnail');
		
		my $ou = $self->{installation}->get_child('ou', $id);
		
		if($ou)
		{
			$ou->{_include} = 1;
		}
		
		my $short_comment = '';
		my $full_comment = '';
		
		my $comment_nodes = $child_node->getElementsByTagName('comment');
		
		for(my $j=0; $j<@$comment_nodes; $j++)
		{
			my $comment_node = $comment_nodes->[$j];
			
			my $comment_node_text_node = $comment_node->getFirstChild;
			
			if($comment_node_text_node)
			{
				$short_comment = $comment_node_text_node->getNodeValue;
			}
		}
		
		my $full_comment_nodes = $child_node->getElementsByTagName('full_comment');
		
		for(my $j=0; $j<@$full_comment_nodes; $j++)
		{
			my $full_comment_node = $full_comment_nodes->[$j];
			
			my $full_comment_text_node = $full_comment_node->getFirstChild;
			
			if($full_comment_text_node)
			{
				$full_comment = $full_comment_text_node->getNodeValue;
			
				$full_comment =~ s/\n+$//;
				$full_comment =~ s/\n/<br>/g;
			}
		}
		
		my $small_thumb = $thumbnail;
		my $medium_thumb = $thumbnail;
		my $large_thumb = $thumbnail;
		
		$small_thumb =~ s/\.jpg$/\.100\.jpg/;
		$medium_thumb =~ s/\.jpg$/\.180\.jpg/;
		$large_thumb =~ s/\.jpg$/\.350\.jpg/;
		
		my $json_activity = {
			id => $id,
			name => $child_node->getAttribute('name'),
			tes_url => $child_node->getAttribute('tes_url'),
			small_thumb => $small_thumb,
			medium_thumb => $medium_thumb,
			large_thumb => $large_thumb,
			short_comment => $short_comment,
			full_comment => $full_comment
		};
		
		my $oujson = new JSON ();

		$oujson->max_depth(512);
		$oujson->pretty;
		$oujson->ascii(1);	
		
		my $single_activity_json = $oujson->encode($json_activity);	
		
		$self->flatten_account_output_file_contents($self->{data_folder}.'/'.$id.'.json', $single_activity_json);		
		
		push(@$json_activities, $json_activity);		
	}
	
	my $json = new JSON ();

	$json->max_depth(512);
	$json->pretty;
	$json->ascii(1);
	
	my $activity_json = $json->encode($json_activities);

	$self->flatten_account_output_file_contents($self->{data_folder}.'/'.$file_id.'.json', $activity_json);
}

sub flatten_account_output_file_contents
{
	my ($self, $filename, $content) = @_;
	
	my $folder = $filename;
	$folder =~ s/\/?[:-\w]+\.\w+$//;
	
	if($folder=~/\w/)
	{
		Webkit::AppTools->ensure_folder_exists($self->{flatten_to_folder_full}.$folder);
	}
	
	my $full_dest = $self->{flatten_to_folder_full}.$filename;
	
	open(OUT, ">$full_dest");
	
	print OUT $content;
	
	close(OUT);
	
	print "OUTPUT FILE: $full_dest\n";	
	
	return $full_dest;
}

sub flatten_account_copy_file
{
	my ($self, $source, $dest, $noprint) = @_;

	if(!-e $source) { return; }
	
	my $folder = $dest;
	$folder =~ s/\/?[:-\w]+\.\w+$//;
	
	if($folder=~/\w/)
	{
		Webkit::AppTools->ensure_folder_exists($self->{flatten_to_folder_full}.$folder);
	}
	
	my $full_dest = $self->{flatten_to_folder_full}.$dest;
	
	system("cp -f $source $full_dest");
	
	if(!$noprint && !$self->{noprint})
	{
		print "COPY FILE: $source - $full_dest\n";
	}
	
	return $full_dest;
}



sub flatten_account_copy_site_folder
{
	my ($self, $source, $dest) = @_;
	
	my $local_folder = $self->{document_root};

	my $folder = $source;
	
	if($dest=~/\w/)
	{
		$folder = $dest;
	}
	
	if($folder=~/\w/)
	{
		Webkit::AppTools->ensure_folder_exists($self->{flatten_to_folder_full}.$folder);
	}
	
	my $target = $source;
	
	if($dest =~ /\w/)
	{
		$target = $dest;
	}
	
	my $full_source = $local_folder.$source;
	my $full_dest = $self->{flatten_to_folder_full}.$target;
	
	if(!-e $full_source) { return; }
	
	system("cp -r $full_source/* $full_dest");
	
	print "COPY FOLDER: $source -> $full_dest\n";	
	
	return $full_dest;	
}

sub flatten_account_copy_site_file
{
	my ($self, $source, $dest) = @_;
	
	my $local_folder = $self->{document_root};

	my $folder = $source;
	
	if($dest=~/\w/)
	{
		$folder = $dest;
	}
	
	$folder =~ s/\/?[:-\w]+\.\w+$//;
	
	if($folder=~/\w/)
	{
		Webkit::AppTools->ensure_folder_exists($self->{flatten_to_folder_full}.$folder);
	}
	
	my $target = $source;
	
	if($dest =~ /\w/)
	{
		$target = $dest;
	}
	
	my $full_source = $local_folder.$source;
	my $full_dest = $self->{flatten_to_folder_full}.$target;
	
	if(!-e $full_source) { return; }
	
	system("cp $full_source $full_dest");
	
	print "COPY FILE: $source -> $target\n";
	
	return $full_dest;
}

sub flatten_account_output_page
{
	my ($self, $uri, $output_file_relative) = @_;
	
	if($uri!~/http/)
	{
		$uri = 'http://'.$self->{hostname}.$uri;	
	}

	my $content = get($uri);
	
	my $output_text = $content;
	
	my $folder = $output_file_relative;
	$folder =~ s/\/?[:-\w]+\.\w+$//;
	
	if($folder=~/\w/)
	{
		Webkit::AppTools->ensure_folder_exists($self->{flatten_to_folder_full}.$folder);
	}
	
	print "GET URL: $uri -> $output_file_relative\n";
	
	my $full_path = $self->{flatten_to_folder_full}.$output_file_relative;

	open(OUT, ">$full_path");
	print OUT $output_text;
	close(OUT);
	
	return $full_path;
}

1;