var current_page_id = null;
var changed_components = new Object();
var changed_count = 0;

function assign_page_id(id)
{
	current_page_id = id;
	document.getElementById('control_table').style.display = 'inline';
}

function reset_page()
{
	changed_components = new Object();
	changed_count = 0;
	current_page_id = null;
	set_saved_status('');
	document.getElementById('control_table').style.display = 'none';
}

function add_changed_component(id, type, content)
{
	changed_count++;

	var changed;

	if(changed_components[id])
	{
		changed = changed_components[id];
	}
	else
	{	
		changed = new Object();
		changed.id = id;
	}

	changed.content = content;
	changed.type = type;

	set_saved_status('(*)');
	
	changed_components[id] = changed;
}

function preview_page()
{
	if(!current_page_id)
	{
		return;
	}

	document.save.submit_preview_form(current_page_id, changed_components);	

	set_saving_status('Generating Preview, please wait...', false);
	top.set_status('Generating Preview, please wait...', false);
}

function finished_preview_saving()
{
	set_saving_status('Opening Preview Window', true);
	top.set_status('Opening Preview Window', true);

	var props = 'center:yes;resizable:yes;dialogWidth:800px;dialogHeight:580px;help:no;scroll:no;status:no;';

	var loc = href + '&method=siteeditor_preview_frameset&page_id=' + current_page_id;

	var ret = window.showModalDialog(loc, null, props);
}

function save_page()
{
	if(!has_changed())
	{
		alert('There are no changes to save');
		return;
	}

	document.save.submit_form(current_page_id, changed_components);

	set_saving_status('Saving, please wait...', false);
	top.set_status('Saving, please wait...', false);
}

function set_saving_status(text, timeoutClear)
{
	clearTimeout();

	document.getElementById('saving_status').innerText = text;

	if(timeoutClear)
	{
		setTimeout("set_saving_status('');", 5000);
	}
}	

function finished_saving()
{
	changed_components = new Object();
	changed_count = 0;
	set_saved_status('');
	set_saving_status('Saved', true);
	top.set_status('Saved', true);
}

function set_saved_status(text)
{
	document.getElementById('save_span').innerText = text;
}

function has_changed()
{
	if(changed_count>0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

function page_unload_confirm()
{
	if(has_changed())
	{
		var ret = window.confirm('This will lose your changes, continue?');
		
		return ret;
	}
	else
	{
		return true;
	}
}


function close_page()
{
	if(!current_page_id)
	{
		return;
	}
	
	if(!page_unload_confirm())
	{
		return;
	}

	var new_location = href + '&method=siteeditor_site_index';
	
	parent.content.location = new_location;
}

function reset_current_page()
{
	if(!page_unload_confirm())
	{
		return;
	}
	
	var new_loc = href + '&method=siteeditor_edit_page&page_id=' + current_page_id;
	
	parent.content.location = new_loc;
}
