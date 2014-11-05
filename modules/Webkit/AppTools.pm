package Webkit::AppTools;

#################
# Webkit::AppTools
#################
#
# General Tools for use Class Wide
#

use strict;
#use Apache::File;

my @letters = qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);

my $stopwords = {
  "a" => 1,
  "as" => 1,
  "able" => 1,
  "about" => 1,
  "above" => 1,
  "according" => 1,
  "accordingly" => 1,
  "across" => 1,
  "actually" => 1,
  "after" => 1,
  "afterwards" => 1,
  "again" => 1,
  "against" => 1,
  "aint" => 1,
  "all" => 1,
  "allow" => 1,
  "allows" => 1,
  "almost" => 1,
  "alone" => 1,
  "along" => 1,
  "already" => 1,
  "also" => 1,
  "although" => 1,
  "always" => 1,
  "am" => 1,
  "among" => 1,
  "amongst" => 1,
  "an" => 1,
  "and" => 1,
  "another" => 1,
  "any" => 1,
  "anybody" => 1,
  "anyhow" => 1,
  "anyone" => 1,
  "anything" => 1,
  "anyway" => 1,
  "anyways" => 1,
  "anywhere" => 1,
  "apart" => 1,
  "appear" => 1,
  "appreciate" => 1,
  "appropriate" => 1,
  "are" => 1,
  "arent" => 1,
  "around" => 1,
  "as" => 1,
  "aside" => 1,
  "ask" => 1,
  "asking" => 1,
  "associated" => 1,
  "at" => 1,
  "available" => 1,
  "away" => 1,
  "awfully" => 1,
  "b" => 1,
  "be" => 1,
  "became" => 1,
  "because" => 1,
  "become" => 1,
  "becomes" => 1,
  "becoming" => 1,
  "been" => 1,
  "before" => 1,
  "beforehand" => 1,
  "behind" => 1,
  "being" => 1,
  "believe" => 1,
  "below" => 1,
  "beside" => 1,
  "besides" => 1,
  "best" => 1,
  "better" => 1,
  "between" => 1,
  "beyond" => 1,
  "both" => 1,
  "brief" => 1,
  "but" => 1,
  "by" => 1,
  "c" => 1,
  "cmon" => 1,
  "cs" => 1,
  "came" => 1,
  "can" => 1,
  "cant" => 1,
  "cannot" => 1,
  "cant" => 1,
  "cause" => 1,
  "causes" => 1,
  "certain" => 1,
  "certainly" => 1,
  "changes" => 1,
  "clearly" => 1,
  "co" => 1,
  "com" => 1,
  "come" => 1,
  "comes" => 1,
  "concerning" => 1,
  "consequently" => 1,
  "consider" => 1,
  "considering" => 1,
  "contain" => 1,
  "containing" => 1,
  "contains" => 1,
  "corresponding" => 1,
  "could" => 1,
  "couldnt" => 1,
  "course" => 1,
  "currently" => 1,
  "d" => 1,
  "definitely" => 1,
  "described" => 1,
  "despite" => 1,
  "did" => 1,
  "didnt" => 1,
  "different" => 1,
  "do" => 1,
  "does" => 1,
  "doesnt" => 1,
  "doing" => 1,
  "dont" => 1,
  "done" => 1,
  "down" => 1,
  "downwards" => 1,
  "during" => 1,
  "e" => 1,
  "each" => 1,
  "edu" => 1,
  "eg" => 1,
  "eight" => 1,
  "either" => 1,
  "else" => 1,
  "elsewhere" => 1,
  "enough" => 1,
  "entirely" => 1,
  "especially" => 1,
  "et" => 1,
  "etc" => 1,
  "even" => 1,
  "ever" => 1,
  "every" => 1,
  "everybody" => 1,
  "everyone" => 1,
  "everything" => 1,
  "everywhere" => 1,
  "ex" => 1,
  "exactly" => 1,
  "example" => 1,
  "except" => 1,
  "f" => 1,
  "far" => 1,
  "few" => 1,
  "fifth" => 1,
  "first" => 1,
  "five" => 1,
  "followed" => 1,
  "following" => 1,
  "follows" => 1,
  "for" => 1,
  "former" => 1,
  "formerly" => 1,
  "forth" => 1,
  "four" => 1,
  "from" => 1,
  "further" => 1,
  "furthermore" => 1,
  "g" => 1,
  "get" => 1,
  "gets" => 1,
  "getting" => 1,
  "given" => 1,
  "gives" => 1,
  "go" => 1,
  "goes" => 1,
  "going" => 1,
  "gone" => 1,
  "got" => 1,
  "gotten" => 1,
  "greetings" => 1,
  "h" => 1,
  "had" => 1,
  "hadnt" => 1,
  "happens" => 1,
  "hardly" => 1,
  "has" => 1,
  "hasnt" => 1,
  "have" => 1,
  "havent" => 1,
  "having" => 1,
  "he" => 1,
  "hes" => 1,
  "hello" => 1,
  "help" => 1,
  "hence" => 1,
  "her" => 1,
  "here" => 1,
  "heres" => 1,
  "hereafter" => 1,
  "hereby" => 1,
  "herein" => 1,
  "hereupon" => 1,
  "hers" => 1,
  "herself" => 1,
  "hi" => 1,
  "him" => 1,
  "himself" => 1,
  "his" => 1,
  "hither" => 1,
  "hopefully" => 1,
  "how" => 1,
  "howbeit" => 1,
  "however" => 1,
  "i" => 1,
  "id" => 1,
  "ill" => 1,
  "im" => 1,
  "ive" => 1,
  "ie" => 1,
  "if" => 1,
  "ignored" => 1,
  "immediate" => 1,
  "in" => 1,
  "inasmuch" => 1,
  "inc" => 1,
  "indeed" => 1,
  "indicate" => 1,
  "indicated" => 1,
  "indicates" => 1,
  "inner" => 1,
  "insofar" => 1,
  "instead" => 1,
  "into" => 1,
  "inward" => 1,
  "is" => 1,
  "isnt" => 1,
  "it" => 1,
  "itd" => 1,
  "itll" => 1,
  "its" => 1,
  "its" => 1,
  "itself" => 1,
  "j" => 1,
  "just" => 1,
  "k" => 1,
  "keep" => 1,
  "keeps" => 1,
  "kept" => 1,
  "know" => 1,
  "knows" => 1,
  "known" => 1,
  "l" => 1,
  "last" => 1,
  "lately" => 1,
  "later" => 1,
  "latter" => 1,
  "latterly" => 1,
  "least" => 1,
  "less" => 1,
  "lest" => 1,
  "let" => 1,
  "lets" => 1,
  "like" => 1,
  "liked" => 1,
  "likely" => 1,
  "little" => 1,
  "look" => 1,
  "looking" => 1,
  "looks" => 1,
  "ltd" => 1,
  "m" => 1,
  "mainly" => 1,
  "many" => 1,
  "may" => 1,
  "maybe" => 1,
  "me" => 1,
  "mean" => 1,
  "meanwhile" => 1,
  "merely" => 1,
  "might" => 1,
  "more" => 1,
  "moreover" => 1,
  "most" => 1,
  "mostly" => 1,
  "much" => 1,
  "must" => 1,
  "my" => 1,
  "myself" => 1,
  "n" => 1,
  "name" => 1,
  "namely" => 1,
  "nd" => 1,
  "near" => 1,
  "nearly" => 1,
  "necessary" => 1,
  "need" => 1,
  "needs" => 1,
  "neither" => 1,
  "never" => 1,
  "nevertheless" => 1,
  "new" => 1,
  "next" => 1,
  "nine" => 1,
  "no" => 1,
  "nobody" => 1,
  "non" => 1,
  "none" => 1,
  "noone" => 1,
  "nor" => 1,
  "normally" => 1,
  "not" => 1,
  "nothing" => 1,
  "novel" => 1,
  "now" => 1,
  "nowhere" => 1,
  "o" => 1,
  "obviously" => 1,
  "of" => 1,
  "off" => 1,
  "often" => 1,
  "oh" => 1,
  "ok" => 1,
  "okay" => 1,
  "old" => 1,
  "on" => 1,
  "once" => 1,
  "one" => 1,
  "ones" => 1,
  "only" => 1,
  "onto" => 1,
  "or" => 1,
  "other" => 1,
  "others" => 1,
  "otherwise" => 1,
  "ought" => 1,
  "our" => 1,
  "ours" => 1,
  "ourselves" => 1,
  "out" => 1,
  "outside" => 1,
  "over" => 1,
  "overall" => 1,
  "own" => 1,
  "p" => 1,
  "particular" => 1,
  "particularly" => 1,
  "per" => 1,
  "perhaps" => 1,
  "placed" => 1,
  "please" => 1,
  "plus" => 1,
  "possible" => 1,
  "presumably" => 1,
  "probably" => 1,
  "provides" => 1,
  "q" => 1,
  "que" => 1,
  "quite" => 1,
  "qv" => 1,
  "r" => 1,
  "rather" => 1,
  "rd" => 1,
  "re" => 1,
  "really" => 1,
  "reasonably" => 1,
  "regarding" => 1,
  "regardless" => 1,
  "regards" => 1,
  "relatively" => 1,
  "respectively" => 1,
  "right" => 1,
  "s" => 1,
  "said" => 1,
  "same" => 1,
  "saw" => 1,
  "say" => 1,
  "saying" => 1,
  "says" => 1,
  "second" => 1,
  "secondly" => 1,
  "see" => 1,
  "seeing" => 1,
  "seem" => 1,
  "seemed" => 1,
  "seeming" => 1,
  "seems" => 1,
  "seen" => 1,
  "self" => 1,
  "selves" => 1,
  "sensible" => 1,
  "sent" => 1,
  "serious" => 1,
  "seriously" => 1,
  "seven" => 1,
  "several" => 1,
  "shall" => 1,
  "she" => 1,
  "should" => 1,
  "shouldnt" => 1,
  "since" => 1,
  "six" => 1,
  "so" => 1,
  "some" => 1,
  "somebody" => 1,
  "somehow" => 1,
  "someone" => 1,
  "something" => 1,
  "sometime" => 1,
  "sometimes" => 1,
  "somewhat" => 1,
  "somewhere" => 1,
  "soon" => 1,
  "sorry" => 1,
  "specified" => 1,
  "specify" => 1,
  "specifying" => 1,
  "still" => 1,
  "sub" => 1,
  "such" => 1,
  "sup" => 1,
  "sure" => 1,
  "t" => 1,
  "ts" => 1,
  "take" => 1,
  "taken" => 1,
  "tell" => 1,
  "tends" => 1,
  "th" => 1,
  "than" => 1,
  "thank" => 1,
  "thanks" => 1,
  "thanx" => 1,
  "that" => 1,
  "thats" => 1,
  "thats" => 1,
  "the" => 1,
  "their" => 1,
  "theirs" => 1,
  "them" => 1,
  "themselves" => 1,
  "then" => 1,
  "thence" => 1,
  "there" => 1,
  "theres" => 1,
  "thereafter" => 1,
  "thereby" => 1,
  "therefore" => 1,
  "therein" => 1,
  "theres" => 1,
  "thereupon" => 1,
  "these" => 1,
  "they" => 1,
  "theyd" => 1,
  "theyll" => 1,
  "theyre" => 1,
  "theyve" => 1,
  "think" => 1,
  "third" => 1,
  "this" => 1,
  "thorough" => 1,
  "thoroughly" => 1,
  "those" => 1,
  "though" => 1,
  "three" => 1,
  "through" => 1,
  "throughout" => 1,
  "thru" => 1,
  "thus" => 1,
  "to" => 1,
  "together" => 1,
  "too" => 1,
  "took" => 1,
  "toward" => 1,
  "towards" => 1,
  "tried" => 1,
  "tries" => 1,
  "truly" => 1,
  "try" => 1,
  "trying" => 1,
  "twice" => 1,
  "two" => 1,
  "u" => 1,
  "un" => 1,
  "under" => 1,
  "unfortunately" => 1,
  "unless" => 1,
  "unlikely" => 1,
  "until" => 1,
  "unto" => 1,
  "up" => 1,
  "upon" => 1,
  "us" => 1,
  "use" => 1,
  "used" => 1,
  "useful" => 1,
  "uses" => 1,
  "using" => 1,
  "usually" => 1,
  "v" => 1,
  "value" => 1,
  "various" => 1,
  "very" => 1,
  "via" => 1,
  "viz" => 1,
  "vs" => 1,
  "w" => 1,
  "want" => 1,
  "wants" => 1,
  "was" => 1,
  "wasnt" => 1,
  "way" => 1,
  "we" => 1,
  "wed" => 1,
  "well" => 1,
  "were" => 1,
  "weve" => 1,
  "welcome" => 1,
  "well" => 1,
  "went" => 1,
  "were" => 1,
  "werent" => 1,
  "what" => 1,
  "whats" => 1,
  "whatever" => 1,
  "when" => 1,
  "whence" => 1,
  "whenever" => 1,
  "where" => 1,
  "wheres" => 1,
  "whereafter" => 1,
  "whereas" => 1,
  "whereby" => 1,
  "wherein" => 1,
  "whereupon" => 1,
  "wherever" => 1,
  "whether" => 1,
  "which" => 1,
  "while" => 1,
  "whither" => 1,
  "who" => 1,
  "whos" => 1,
  "whoever" => 1,
  "whole" => 1,
  "whom" => 1,
  "whose" => 1,
  "why" => 1,
  "will" => 1,
  "willing" => 1,
  "wish" => 1,
  "with" => 1,
  "within" => 1,
  "without" => 1,
  "wont" => 1,
  "wonder" => 1,
  "would" => 1,
  "would" => 1,
  "wouldnt" => 1,
  "x" => 1,
  "y" => 1,
  "yes" => 1,
  "yet" => 1,
  "you" => 1,
  "youd" => 1,
  "youll" => 1,
  "youre" => 1,
  "youve" => 1,
  "your" => 1,
  "yours" => 1,
  "yourself" => 1,
  "yourselves" => 1,
  "z" => 1,
  "zero" => 1 };
  
my $simple_stopwords = {
  "with" => 1,
  "not" => 1,
  "into" => 1,
  "you" => 1,
  "may" => 1,
  "can" => 1,
  "between" => 1,
  "being" => 1,
  "you" => 1,
  "do" => 1,
  "like" => 1,
  "a" => 1,
  "as" => 1,
  "aint" => 1,
  "am" => 1,
  "an" => 1,
  "and" => 1,
  "any" => 1,
  "are" => 1,
  "arent" => 1,
  "as" => 1,
  "at" => 1,
  "b" => 1,
  "be" => 1,
  "but" => 1,
  "by" => 1,
  "c" => 1,
  "co" => 1,
  "com" => 1,
  "d" => 1,
  "e" => 1,
  "else" => 1,
  "et" => 1,
  "etc" => 1,
  "f" => 1,
  "for" => 1,
  "g" => 1,
  "h" => 1,
  "i" => 1,
  "im" => 1,
  "ive" => 1,
  "ie" => 1,
  "if" => 1,
  "in" => 1,
  "is" => 1,
  "isnt" => 1,
  "it" => 1,
  "itd" => 1,
  "itll" => 1,
  "its" => 1,
  "its" => 1,
  "itself" => 1,
  "j" => 1,
  "k" => 1,
  "l" => 1,
  "m" => 1,
  "n" => 1,
  "o" => 1,
  "of" => 1,
  "on" => 1,
  "or" => 1,
  "p" => 1,
  "q" => 1,
  "r" => 1,
  "s" => 1,
  "so" => 1,
  "t" => 1,
  "than" => 1,
  "that" => 1,
  "thats" => 1,
  "thats" => 1,
  "the" => 1,
  "their" => 1,
  "theirs" => 1,
  "them" => 1,
  "then" => 1,
  "there" => 1,
  "theres" => 1,
  "these" => 1,
  "they" => 1,
  "theyd" => 1,
  "theyll" => 1,
  "theyre" => 1,
  "theyve" => 1,
  "think" => 1,
  "third" => 1,
  "to" => 1,
  "too" => 1,
  "u" => 1,
  "un" => 1,
  "us" => 1,
  "v" => 1,
  "w" => 1,
  "we" => 1,
  "were" => 1,
  "weve" => 1,
  "well" => 1,
  "what" => 1,
  "who" => 1,
  "whos" => 1,
  "whom" => 1,
  "whose" => 1,
  "x" => 1,
  "y" => 1,
  "youd" => 1,
  "youll" => 1,
  "youre" => 1,
  "youve" => 1,
  "your" => 1,
  
  "z" => 1 };

my $countries = {
	afghanistan => 'Afghanistan',
	albania => 'Albania',
	algeria => 'Algeria',
	american => 'American Samoa',
	andorra => 'Andorra',
	angola => 'Angola',
	anguilla => 'Anguilla',
	antarctica => 'Antarctica',
	antigua => 'Antigua and Barbuda',
	argentina => 'Argentina',
	armenia => 'Armenia',
	aruba => 'Aruba',
	australia => 'Australia',
	austria => 'Austria',
	azerbaijan => 'Azerbaijan',
	bahamas => 'Bahamas',
	bahrain => 'Bahrain',
	bangladesh => 'Bangladesh',
	barbados => 'Barbados',
	belarus => 'Belarus',
	belgium => 'Belgium',
	belize => 'Belize',
	benin => 'Benin',
	bermuda => 'Bermuda',
	bhutan => 'Bhutan',
	bolivia => 'Bolivia',
	bosnia => 'Bosnia and Herzegovina',
	botswana => 'Botswana',
	bouvet => 'Bouvet Island',
	brazil => 'Brazil',
	british => 'British Indian Ocean Territory',
	brunei => 'Brunei Darussalam',
	bulgaria => 'Bulgaria',
	burkina => 'Burkina Faso',
	burundi => 'Burundi',
	cambodia => 'Cambodia',
	cameroon => 'Cameroon',
	canada => 'Canada',
	cape => 'Cape Verde',
	cayman => 'Cayman Islands',
	central => 'Central African Republic',
	chad => 'Chad',
	chile => 'Chile',
	china => 'China',
	christmas => 'Christmas Island',
	cocos => 'Cocos (Keeling) Islands',
	colombia => 'Colombia',
	comoros => 'Comoros',
	congo => 'Congo',
	congo => 'Congo, the Democratic Republic of the',
	cook => 'Cook Islands',
	costa => 'Costa Rica',
	cote => 'Cote D\'Ivoire',
	croatia => 'Croatia',
	cuba => 'Cuba',
	cyprus => 'Cyprus',
	czech => 'Czech Republic',
	denmark => 'Denmark',
	djibouti => 'Djibouti',
	dominica => 'Dominica',
	dominican => 'Dominican Republic',
	ecuador => 'Ecuador',
	egypt => 'Egypt',
	el => 'El Salvador',
	equatorial => 'Equatorial Guinea',
	eritrea => 'Eritrea',
	estonia => 'Estonia',
	ethiopia => 'Ethiopia',
	falkland => 'Falkland Islands (Malvinas)',
	faroe => 'Faroe Islands',
	fiji => 'Fiji',
	finland => 'Finland',
	france => 'France',
	guiana => 'French Guiana',
	polynesia => 'French Polynesia',
	territories => 'French Southern Territories',
	gabon => 'Gabon',
	gambia => 'Gambia',
	georgia => 'Georgia',
	germany => 'Germany',
	ghana => 'Ghana',
	gibraltar => 'Gibraltar',
	greece => 'Greece',
	greenland => 'Greenland',
	grenada => 'Grenada',
	guadeloupe => 'Guadeloupe',
	guam => 'Guam',
	guatemala => 'Guatemala',
	guinea => 'Guinea',
	guinea => 'Guinea-Bissau',
	guyana => 'Guyana',
	haiti => 'Haiti',
	heard => 'Heard Island and Mcdonald Islands',
	holy => 'Holy See (Vatican City State)',
	honduras => 'Honduras',
	hong => 'Hong Kong',
	hungary => 'Hungary',
	iceland => 'Iceland',
	india => 'India',
	indonesia => 'Indonesia',
	iran => 'Iran, Islamic Republic of',
	iraq => 'Iraq',
	ireland => 'Ireland',
	israel => 'Israel',
	italy => 'Italy',
	jamaica => 'Jamaica',
	japan => 'Japan',
	jordan => 'Jordan',
	kazakhstan => 'Kazakhstan',
	kenya => 'Kenya',
	kiribati => 'Kiribati',
	democratic => 'Korea, Democratic People\'s Republic of',
	korea => 'Korea, Republic of',
	kuwait => 'Kuwait',
	kyrgyzstan => 'Kyrgyzstan',
	lao => 'Lao People\'s Democratic Republic',
	latvia => 'Latvia',
	lebanon => 'Lebanon',
	lesotho => 'Lesotho',
	liberia => 'Liberia',
	libyan => 'Libyan Arab Jamahiriya',
	liechtenstein => 'Liechtenstein',
	lithuania => 'Lithuania',
	luxembourg => 'Luxembourg',
	macao => 'Macao',
	macedonia => 'Macedonia, the Former Yugoslav Republic of',
	madagascar => 'Madagascar',
	malawi => 'Malawi',
	malaysia => 'Malaysia',
	maldives => 'Maldives',
	mali => 'Mali',
	malta => 'Malta',
	marshall => 'Marshall Islands',
	martinique => 'Martinique',
	mauritania => 'Mauritania',
	mauritius => 'Mauritius',
	mayotte => 'Mayotte',
	mexico => 'Mexico',
	micronesia => 'Micronesia, Federated States of',
	moldova => 'Moldova, Republic of',
	monaco => 'Monaco',
	mongolia => 'Mongolia',
	montserrat => 'Montserrat',
	morocco => 'Morocco',
	mozambique => 'Mozambique',
	myanmar => 'Myanmar',
	namibia => 'Namibia',
	nauru => 'Nauru',
	nepal => 'Nepal',
	netherlands => 'Netherlands',
	caledonia => 'New Caledonia',
	zealand => 'New Zealand',
	nicaragua => 'Nicaragua',
	niger => 'Niger',
	nigeria => 'Nigeria',
	niue => 'Niue',
	norfolk => 'Norfolk Island',
	northern => 'Northern Mariana Islands',
	norway => 'Norway',
	oman => 'Oman',
	pakistan => 'Pakistan',
	palau => 'Palau',
	palestinian => 'Palestinian Territory, Occupied',
	palestine => 'Palestinian Territory, Occupied',
	panama => 'Panama',
	papua => 'Papua New Guinea',
	paraguay => 'Paraguay',
	peru => 'Peru',
	philippines => 'Philippines',
	pitcairn => 'Pitcairn',
	poland => 'Poland',
	portugal => 'Portugal',
	puerto => 'Puerto Rico',
	qatar => 'Qatar',
	reunion => 'Reunion',
	romania => 'Romania',
	russian => 'Russian Federation',
	rwanda => 'Rwanda',
	helena => 'Saint Helena',
	kitts => 'Saint Kitts and Nevis',
	lucia => 'Saint Lucia',
	pierre => 'Saint Pierre and Miquelon',
	grenadines => 'Saint Vincent and the Grenadines',
	samoa => 'Samoa',
	san => 'San Marino',
	sao => 'Sao Tome and Principe',
	saudi => 'Saudi Arabia',
	senegal => 'Senegal',
	serbia => 'Serbia and Montenegro',
	seychelles => 'Seychelles',
	sierra => 'Sierra Leone',
	singapore => 'Singapore',
	slovakia => 'Slovakia',
	slovenia => 'Slovenia',
	solomon => 'Solomon Islands',
	somalia => 'Somalia',
	africa => 'South Africa',
	south => 'South Georgia and the South Sandwich Islands',
	spain => 'Spain',
	sri => 'Sri Lanka',
	sudan => 'Sudan',
	suriname => 'Suriname',
	svalbard => 'Svalbard and Jan Mayen',
	swaziland => 'Swaziland',
	sweden => 'Sweden',
	switzerland => 'Switzerland',
	syrian => 'Syrian Arab Republic',
	taiwan => 'Taiwan, Province of China',
	tajikistan => 'Tajikistan',
	tanzania => 'Tanzania, United Republic of',
	thailand => 'Thailand',
	timor => 'Timor-Leste',
	togo => 'Togo',
	tokelau => 'Tokelau',
	tonga => 'Tonga',
	trinidad => 'Trinidad and Tobago',
	tunisia => 'Tunisia',
	turkey => 'Turkey',
	turkmenistan => 'Turkmenistan',
	turks => 'Turks and Caicos Islands',
	tuvalu => 'Tuvalu',
	uganda => 'Uganda',
	ukraine => 'Ukraine',
	uk => '_britain',
	wales => 'Wales',
	england => 'England',
	scotland => 'Scotland',
	britain => 'United Kingdom',
	emirates => 'United Arab Emirates',
	kingdom => '_britain',
	united => 'United States',
	uruguay => 'Uruguay',
	uzbekistan => 'Uzbekistan',
	vanuatu => 'Vanuatu',
	venezuela => 'Venezuela',
	vietnam => 'Viet Nam',
	viet => 'Viet Nam',
	virgin => 'Virgin Islands',
	virgin => 'Virgin Islands',
	wallis => 'Wallis and Futuna',
	western => 'Western Sahara',
	yemen => 'Yemen',
	zambia => 'Zambia',
	zimbabwe => 'Zimbabwe'
 };

use Number::Format ();

my $formatter = new Number::Format;

#############
# Print Header
# This will print the HTTP back to the browser 

sub print_header
{
	my ($classname) = @_;

	print<<"+++";
Content-type:	text/html
Pragma:		no-cache

+++
}

sub print_location
{
	my ($classname, $url) = @_;

	print<<"+++";
Location:	$url

+++
}

###############
# Will return the params from CGI
# Never used so lets no bring CGI into the equation

sub get_params
{
	my ($classname) = @_;

#	my $cgi = new CGI;
#
#	my $params;
#
#	foreach my $k ($cgi->param)
#	{
##		$params->{$k} = $cgi->param($k);
#	}

	my $params;
	return $params;
}

################
# Checks that all @$reqs are defined in %$args and throws an error if not

sub ensure_args
{
	my ($classname, $reqs, $args) = @_;

	my $caller = caller();

	foreach my $req (@$reqs)
	{
		if($args->{$req}!~/\w/)
		{
			Webkit::Error->wkerror("You must give a $req from $caller");

			return $req;
		}
	}

	return 1;
}

################
# Returns a collection of <options> from the @$data and %$attr

sub get_select_options
{
        my ($classname, $data, $attr) = @_;

        if($attr->{key_field}!~/\w/) { return "Key field needed"; }
        if($attr->{value_field}!~/\w/) { return "Value field needed"; }

        my $ret;

        if($attr->{null_title}=~/[^ ]/)
        {
                my $select;

                if(!$attr->{selected}) { $select = " SELECTED"; }

                $ret.=<<"+++";
<option value="-1"$select>$attr->{null_title}</option>
+++
        }

        if(!$attr->{sorted})
        {
#                @$data = sort { $a->{$attr->{value_field}} cmp $b->{$attr->{value_field}} } @$data;
        }

        foreach my $item (@$data)
        {
                my $select;

                if($item->{$attr->{key_field}} eq $attr->{selected}) { $select = " SELECTED"; }

                $ret.=<<"+++";
<option value="$item->{$attr->{key_field}}"$select>$item->{$attr->{value_field}}</option>
+++
        }

        return $ret;
}

################
# Returns a collection of <options> from the @$data and %$attr
# The values are obtained via get_ methods

sub get_object_select_options
{
        my ($classname, $data, $attr) = @_;

        if($attr->{value_field}!~/\w/) { return "Value field needed"; }

        my $ret;

        if($attr->{null_title}=~/[^ ]/)
        {
                my $select;

                if(!$attr->{selected}) { $select = " SELECTED"; }

                $ret.=<<"+++";
<option value="-1"$select>$attr->{null_title}</option>
+++
        }

        foreach my $obj (@$data)
        {
                my $select;

		my $id = $obj->get_id;

		my $value = $obj->get_value($attr->{value_field});

                if($id eq $attr->{selected}) { $select = " SELECTED"; }

                $ret.=<<"+++";
<option value="$id"$select>$value</option>
+++
        }

        return $ret;
}

################
# Returns a select containing numbers speified by min, max and gap

sub get_number_select_options
{
	my ($classname, $attr) = @_;

        my @data;

	if($attr->{reverse}!~/\w/)
	{
        	for(my $i=$attr->{min}; $i<=$attr->{max}; $i+=$attr->{gap})
        	{
	                push(@data, {        id => $i, value => $i.$attr->{append} });
	        }
	}
	else
	{
        	for(my $i=$attr->{max}; $i>=$attr->{min}; $i-=$attr->{gap})
        	{
	                push(@data, {        id => $i, value => $i.$attr->{append} });
	        }
	}

#        @data = sort { $a->{id} <=> $b->{id} } @data;

        $attr->{key_field} = 'id';
        $attr->{value_field} = 'value';
        $attr->{sorted} = 1;

	return Webkit::AppTools->get_select_options(\@data, $attr);
}

sub get_number_select
{
        my ($classname, $attr) = @_;

        my @data;

        for(my $i=$attr->{min}; $i<=$attr->{max}; $i+=$attr->{gap})
        {
                push(@data, {        id => $i, value => $i });
        }

        @data = sort { $a->{id} <=> $b->{id} } @data;

        $attr->{key_field} = 'id';
        $attr->{value_field} = 'value';
        $attr->{sorted} = 1;

        return &get_select($classname, \@data, $attr);
}

###############
# Returns a <select> with options based on @$data and %$attr

sub get_select
{
        my ($classname, $data, $attr) = @_;

        if($attr->{key_field}!~/\w/) { return "Key field needed"; }
        if($attr->{value_field}!~/\w/) { return "Value field needed"; }

        if($attr->{name}!~/\w/) { $attr->{name} = "select"; }
        if($attr->{onChange}=~/\w/) { $attr->{onChange} = " onChange=\"$attr->{onChange}\" "; }

        if($attr->{disabled}) { $attr->{disabled} = " DISABLED"; }

        if($attr->{class}=~/\w/) { $attr->{class} = " class=\"$attr->{class}\""; }

        $attr->{width} =  " style=\"width: 100%;\" ";

        if($attr->{no_width}) { $attr->{width} = ''; }

        if($attr->{id}) { $attr->{id} = " id=\"$attr->{id}\""; }

        my $ret=<<"+++";
<select $attr->{width} name="$attr->{name}"$attr->{class}$attr->{id}$attr->{onChange}$attr->{disabled}>
+++

        $ret.=&get_select_options($classname, $data, $attr);

        $ret.=<<"+++";
</select>
+++

        return $ret;
}

sub check_phone_number
{
	my ($self, $number) = @_;

	$number =~ s/\W//g;

	if($number !~ /^\d+$/)
	{
		return undef;
	}
	else
	{
		return 1;
	}
}

sub checkbox_checked
{
	my ($classname, $value) = @_;

	if($value=~/\w/)
	{
		return ' CHECKED';
	}
	else
	{
		return '';
	}
}

####################
# Checks the validity of an email address
# returns true/false

sub check_email_address
{
        my ($classname, $address) = @_;

        if($address !~ /^[^@]+@([-\w]+\.)+[A-Za-z]{2,4}$/)
        {
                return undef;
        }
        else
        {
                return 1;
        }
}

sub check_password
{
	my ($classname, $password) = @_;

	if(length($password)<5) { return undef; }

	if($password =~ /[^\w\d_]/)
	{
		return undef;
	}

	return 1;
}

################
# Sends an email based on
# ---------
# mime
# from
# to
# subject
# message
# odq (Whether to put onto the queue)

sub send_email
{
        my ($classname, $hash) = @_;

        my @reqs = qw(from to subject message);

        foreach my $req (@reqs)
        {
                if($hash->{$req}!~/\w/)
                {
                        return undef;
                }
        }

        if(!Webkit::AppTools->check_email_address($hash->{from}))
        {
                return undef;
        }

        if(!Webkit::AppTools->check_email_address($hash->{to}))
        {
                return undef;
        }

	use Mail::Sendmail;

	my %mail = ( 	To      => $hash->{to},
            		From    => $hash->{from},
            		"Reply-To" => $hash->{from},
					Subject => $hash->{subject},
					"Content-Type" => 'text/plain',
            		Message => $hash->{message},
            		smtp => "pat.wk1.net"
	);

	sendmail(%mail);# or die $Mail::Sendmail::error;
#
#	print "OK. Log says:\n", $Mail::Sendmail::log;
#
#        open(SENDMAIL, "|/usr/sbin/sendmail -t$hash{odq} -f \"$hash{from}\" ");
#
#        print SENDMAIL<<"EOT";
#MIME-Version: 1.0
#Content-type: $hash{mime}
#Content-Transfer-Encoding: 7bit
#From: $hash{from}
#To: $hash{to}
#Subject: $hash{subject}
#
#$hash{message}
#
#EOT

        #close(SENDMAIL);

}

sub get_list_of_files_in_directory
{
	my ($classname, $dir) = @_;

	if(!-e $dir) { return []; }
	
	opendir DIR, $dir or die "error: cannot open directory \"$dir\" $!";

	my @files = sort grep (!/^\.$|^\.\.$/, readdir(DIR));
	
	closedir (DIR);	
	
	return \@files;
}

############
# Returns the contents of the given file

sub read_file_contents
{
	my ($classname, $filename) = @_;

	if(!-e $filename)
	{
		return undef;
	}

#	my $fh = Apache::File->new($filename);
	open(FH, $filename);

	my $file = do {local $/; <FH>};

	close(FH);
	
	#print $file;
	
	return $file;
}

sub get_upload_ext
{
	my ($classname, $params, $key) = @_;

	my $ref = $params->{_uploads}->{$key};

	return $ref->{ext};
}

#############
# returns the contents of an uploaded file,
# specified by the value of the param.
# i.e. ->read_upload_contents($params->{file})

sub read_upload_contents
{
        my ($classname, $params, $key) = @_;

	my $ref = $params->{_uploads}->{$key};

	return $ref->{content};
}

sub save_dated_uploaded_file
{
	my ($classname, $basedir, $params, $key, $dated) = @_;

	return Webkit::AppTools->save_uploaded_file($basedir, $params, $key, 1);
}

sub save_uploaded_file
{
	my ($classname, $basedir, $params, $key, $dated) = @_;

	my $contents = Webkit::AppTools->read_upload_contents($params, $key);

	my $ext = Webkit::AppTools->get_upload_ext($params, $key);

	my $filepath = Webkit::AppTools->generate_file_name($basedir, $ext, $dated);

	my $path = $basedir.$filepath;

	Webkit::AppTools->output_upload_contents($path, $contents);

	return $filepath;
}

sub output_upload_contents
{
	my ($classname, $path, $contents) = @_;

	open(OUT, ">$path");

	binmode(OUT);

	print OUT $contents;

	close(OUT);
}

sub generate_file_name
{
	my ($classname, $basedir, $ext, $dated) = @_;

	my $today_dir = '';

	if($dated)
	{
		my $today = Webkit::Date->now;

		$today_dir = $today->get_string({
			delimeter => '_' });

		$basedir.=$today_dir.'/';
	}

	if(!(-e $basedir))
	{
		mkdir($basedir);
	}

	my $mode = undef;
	my $details = '';

	while(!$mode)
	{
		my $randst = new String::Random;

		my $filename = $randst->randpattern("CCCCCCCCCCCC");

		$details = $filename.'.'.$ext;

		if(-e $basedir.$details)
		{
			$mode = undef;
		}
		else
		{
			$mode = 1;
		}
	}

	if($today_dir=~/\w/) { $today_dir .= '/'; }

	return $today_dir.$details;
}

sub get_upload_ref
{
	my ($classname, $params, $key) = @_;

	return $params->{_uploads}->{$key};
}

sub get_hash_string
{
	my ($classname, $hash) = @_;

	my $st = '';

	foreach my $key (keys %$hash)
	{
		$st .= $key.' = '.$hash->{$key}."<p>\n\n";
	}

	return $st;
}

sub round_number
{
	my ($classname, $value) = @_;

	my $val = $formatter->round($value);

	return $val;
}

sub js_hash
{
	my ($classname, $data) = @_;

	my @pairs;

	foreach my $key (keys %$data)
	{
		my $value = $data->{$key};

		if($key=~/^_(\w+)$/)
		{
			$key = $1;
			if($value!~/\w/)
			{
				$value = '0';
			}
		}
		else
		{
			$value =~ s/'/\\'/g;
			$value = "'$value'";
			$value =~ s/\\\\'/\\'/g;
			$value =~ s/\r?\n/\\n/g;
			$value =~ s/\r/\\n/g;
		}

		push(@pairs, $key.':'.$value);
	}

	my $data_st = '{'.join(', ', @pairs).'}';

	return $data_st;
}

sub html_quote
{
	my ($classname, $value) = @_;

	$value =~ s/\r?\n/<br>/g;
	$value =~ s/\r/<br>/g;

	return $value;
}

sub xml_quote
{
	my ($classname, $value) = @_;
	
	$value =~ s/\&/\&amp\;/g;	
	$value =~ s/\>/&gt\;/g;
	$value =~ s/\</&lt\;/g;
	$value =~ s/\'/\&apos\;/g;
	$value =~ s/\"/\&quot\;/g;
	
	return $value;
}

sub js_quote
{
	my ($classname, $value) = @_;

	$value =~ s/\r?\n/\\n/g;
	$value =~ s/\r/\\n/g;
	$value =~ s/(')/\\'/g;
	$value =~ s/\t+/\t/g;
	$value =~ s/\\\\/\\/g;

	return $value;
}

sub format_price
{
        my ($classname, $value) = @_;

        my $val = $formatter->round($value, 2);

        return sprintf("%.2f", $val);
}

sub comma_format_price
{
	my ($classname, $value) = @_;

	my $ret = '';
	my $commacount = 0;
	my $bitcount = 0;

	my @bits = split(//, $value);

	@bits = reverse(@bits);

	foreach my $char (@bits)
	{
		$bitcount++;
		$commacount++;

		$ret = $char.$ret;

		if($commacount>=3)
		{
			if($bitcount<length($value))
			{
				$ret = ','.$ret;
				$commacount = 0;
			}
		}
	}

	return $ret;
}

sub calendar_gui
{
	my ($classname, $id, $value) = @_;

	my $jsdate = "";
	my $storedate = "";

	if($value)
	{
		$jsdate = $value->get_calendar_string;
		$storedate = $value->Epoch;
	}

	my $storeid = $id.'_store';

	my $text=<<"+++";
<input type="hidden" name="$storeid" value="$storedate">
<input class="text_field" 
	type="TEXT" name="$id" id="$id" style="width:149px;" readonly="READONLY"
	value="$jsdate"><img src="/images/clear.gif" width="5" height="1"
	border="0" align="ABSMIDDLE"><a onClick="generate_calendar_window('$id', document.getElementById('$storeid').value);"><img
	src="/images/holiday/but_date.gif" width="26" height="20" border="0"
	align="ABSMIDDLE"></a>
+++

	return $text;
}

sub check_password_params
{
	my ($self, $password1, $password2) = @_;

	if($password1!~/\w/)
	{
		return undef;
	}

	if($password1=~/[^\w]/)
	{
		return undef;
	}

	if($password1 ne $password2)
	{
		return undef;
	}

	return 1;
}

sub get_id_hash
{
	my ($classname, $array) = @_;

	my $hash;

	foreach my $obj (@$array)
	{
		my $id = $obj->get_id;

		$hash->{$id} = $obj;
	}

	return $hash;
}

sub get_hash_from_array
{
	my ($classname, $key, $array) = @_;

	if(!$key)
	{
		return undef;
	}

	my $hash;

	foreach my $obj (@$array)
	{
		my $id = $obj->{$key};

		$hash->{$id} = $obj;
	}

	return $hash;
}

sub get_xml_nodes
{
	my ($self, $attr) = @_;

	if($attr->{packet}!~/\w/)
	{
		die "You must give a packet to call parse_simple_xml";
	}

	if($attr->{object_tag}!~/\w/)
	{
		die "You must give an object tag to call parse_simple_xml";
	}

        my $parser = new XML::DOM::Parser;

        my $doc = $parser->parse($attr->{packet});

	my $object_nodes = $doc->getElementsByTagName($attr->{object_tag});

        my $object_refs;

        for (my $i = 0; $i < $object_nodes->getLength; $i++)
        {
                my $object_node = $object_nodes->item($i);

                if($object_node)
                {
			push(@$object_refs, $object_node);
                }
        }

	return $object_refs;
}

sub get_params_st
{
	my ($self, $params) = @_;

	my @values;

	foreach my $key (keys %$params)
	{
		if($key ne 'session_id')
		{
			my $value = $params->{$key};

			push(@values, "$key=$value");
		}
	}

	my $ret = join('&', @values);

	return $ret;
}

sub randomize_array
{
	my ($classname, $array) = @_;

	if(!$array)
	{
		return;
	}

        my $i;

        for ($i = @$array; --$i; ) 
	{
            my $j = int rand ($i+1);

            @$array[$i,$j] = @$array[$j,$i];
        }

	return $array;
}

sub get_month_options
{
	my ($self, $selected) = @_;

	if(!$selected)
	{
		my $now = Webkit::Date->now;
		$selected = $now->Month;
	}

	my $data;

	for(my $i=1; $i<=12; $i++)
	{
		my $monthname = Webkit::BaseDate->get_full_monthname($i);

		push(@$data, {
			title => $monthname,
			index => $i });
	}

	return Webkit::AppTools->get_select_options($data, {
		key_field => 'index',
		value_field => 'title',
		selected => $selected });
}

sub get_year_options
{
	my ($self, $selected) = @_;

	if(!$selected)
	{
		my $now = Webkit::Date->now;
		$selected = $now->Year;
	}

	my $data;

	for(my $i=2000; $i<=2010; $i++)
	{
		push(@$data, {
			title => $i,
			index => $i });
	}

	return Webkit::AppTools->get_select_options($data, {
		key_field => 'index',
		value_field => 'title',
		selected => $selected });
}

sub get_params_string
{
	my ($classname, $params, $join) = @_;

	if(!$join)
	{
		$join = "\n";
	}

	my $arr;

	foreach my $key (keys %$params)
	{
		push(@$arr, $key.' = '.$params->{$key});
	}

	my $st = join($join, @$arr);

	return $st;
}

sub get_letter_array
{
	my ($classname) = @_;

	return \@letters;
}

sub get_letter_from_number
{
	my ($classname, $index) = @_;

	return $letters[$index];
}

sub get_multidate_note_title
{
	my ($self, $value, $delim, $notestyle) = @_;

	my @parts = split(/\+\+\+/, $value);
	my @dates;
	my $finalnote;

	if(!defined($delim))
	{
		$delim = '<br>';
	}

	foreach my $part (@parts)
	{
		if($part!~/^[\w \/]{2,16}=/)
		{
			$part = 'na='.$part;
		}

		my ($date, $note) = split(/=/, $part);

		push(@dates, $date);

		$finalnote = $note;
	}

	my $joined = join(','.$delim, @dates);

	my $ret="$joined $delim <span style=\"$notestyle\">$finalnote</span>";

	return $ret;
}

sub get_webpage_word_map
{
	my ($self, $url) = @_;

	my $content = LWP::Simple::get($url);

	unless (defined($content))
	{
    		return {};
	}

	my $plain_text = HTML::FormatText->new->format(HTML::Parse::parse_html($content));

	my @parts = split(/[^\w']/, $plain_text);
	my $ret;

	foreach my $part (@parts)
	{
		$part = lc($part);
		$part =~ s/\W//g;

		if($part!~/\w/) { next; }
		if(length($part)>24) { next; }

		$ret->{$part}++;
	}

	return $ret;
}

sub get_doc_word_map
{
	my ($self, $filepath) = @_;

	my $output_file = Apache::TempFile::tempname();

	my $text;

	system("catdoc $filepath > $output_file");

	open(IN, $output_file);

	while(<IN>)
	{
		$text .= $_;
	}

	close(IN);

	my @parts = split(/[^\w']/, $text);
	my $ret;

	foreach my $part (@parts)
	{
		$part = lc($part);
		$part =~ s/\W//g;

		if($part!~/\w/) { next; }
		if(length($part)>24) { next; }

		$ret->{$part}++;
	}

	return $ret;
}

sub get_pdf_word_map
{
	my ($self, $filepath) = @_;

	my $output_file = Apache::TempFile::tempname();

	my $text;

	system("pdftotext $filepath $output_file");

	open(IN, $output_file);

	while(<IN>)
	{
		$text .= $_;
	}

	close(IN);

	my @parts = split(/[^\w\']/, $text);
	my $ret;

	foreach my $part (@parts)
	{
		$part = lc($part);
		$part =~ s/\W//g;

		if($part!~/\w/) { next; }
		if(length($part)>24) { next; }

		$ret->{$part}++;
	}

	return $ret;
}

sub is_stopword
{
	my ($classname, $word) = @_;

	if($stopwords->{lc($word)}) { return 1; }
	else { return undef; }
}

sub is_simple_stopword
{
	my ($classname, $word) = @_;

	if($simple_stopwords->{lc($word)}) { return 1; }
	else { return undef; }
}

sub ensure_folder_exists
{
	my ($classname, $path) = @_;

	$path =~ s/^\///;
	$path =~ s/\/$//;

	my @parts = split(/\//, $path);

	my $folder_path = '';

	foreach my $part (@parts)
	{
		$folder_path .= '/'.$part;

		if(!-e $folder_path)
		{
			mkdir($folder_path);
		}
	}
}

sub remove_non_standard_characters
{
	my ($classname, $value) = @_;

	my $ret = $value;

	#$ret =~ s/[^\w\s\.\!\"\£\$\%\^\&\*\(\)\-\_\+\=\[\]\{\}\:\;\@\'\~\#\<\,\>\?\/\\\`]//g;
	
	my %good = map {$_=>1} (9,10,13,32..127);
	
	$ret =~ s/(.)/$good{ord($1)} ? $1 : ''/eg;

	return $ret;
}

sub get_date_formatted
{
	my ($classname, $date_obj) = @_;
	
	my $ret = &Webkit::Date::get_string($date_obj);
	
	$ret =~ s/^(\d+)\/(\d+)\/(\d+)$/$3\/$2\/$1/;
	
	return $ret;
}

sub parse_csv_value
{
	my ($self, $value) = @_;
	
	$value =~ s/\"/\"\"/g;
	
	return "\"$value\"";
}

1;
