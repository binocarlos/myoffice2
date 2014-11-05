var helpspan = null;
var text_object = null;
var original_text = '';

function init_help(textobj)
{
	helpspan = document.getElementById('helpspan');
	
	if(!helpspan)
	{
		return;
	}
	
	text_object = textobj;
	original_text = helpspan.innerText;
}

function show_help(key)
{
	var helptext = text_object[key];

	if(helpspan)
	{
		helpspan.innerText = helptext;
	}
	else
	{
		top.set_status(helptext, false);
	}
}

function hide_help()
{
	if(helpspan)
	{
		helpspan.innerText = original_text;
	}
	else
	{
		top.set_status(original_text, false);
	}
}
