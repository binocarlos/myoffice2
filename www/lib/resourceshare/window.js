var IsSP2 = false;
IsSP2 = (window.navigator.userAgent.indexOf("SV1") != -1);

var current_folder_id = null;
var current_folder_editable = false;
var current_folder_parent_id = null;
var current_folder_contributed_id = null;
var current_folder_auto_value = null;

var resources_active = true;

var select_resource_id = '';

var max_history_count = 10;

var timeline_window_width = 800;
var timeline_window_height = 600;
var folder_window_width = 800;
var folder_window_height = 650;
var resource_window_width = 800;
var resource_window_height = 650;
var options_window_width = 500;
var options_window_height = 650;
var security_window_width = 680;
var security_window_height = 520;
var versions_window_width = 500;
var versions_window_height = 300;
var search_window_width = 650;
var search_window_height = 350;
var download_window_width = screen.availWidth - 50;
var download_window_height = screen.availHeight - 50;

var selected_item_id = null;
var selected_item_mode = null;
var selected_item_url = null;

var clipboard_item_id = null;
var clipboard_mode = null;
var clipboard_item_mode = null;

var history_array = new Array();

var buttonStates = new Object();

////////////////////////////////
//////// CURRENT FOLDER METHODS
////////////////////////////////

function get_current_folder_id()
{
	return current_folder_id;
}

// This is called from the folder contents page to assign the current folder details

function entered_recycle_bin()
{
	var new_entry = new Object();

	new_entry.id = 'recycle_bin';
	new_entry.address = 'Recycle Bin';

	apply_history_options(new_entry);

	current_folder_id = 'recycle_bin';
	current_folder_parent_id = 'rootfolder';
	current_folder_editable = false;

	activate_button('up');

}

function assign_current_folder_details(address, folder_id,  parent_id, contributed_id, auto_value, editable)
{
	var new_entry = new Object();

	new_entry.id = folder_id;
	new_entry.address = address;
	new_entry.auto_value = auto_value;
	new_entry.contributed_id = contributed_id;
	
	apply_history_options(new_entry);

	current_folder_id = folder_id;
	current_folder_parent_id = parent_id;
	current_folder_editable = editable;
	current_folder_contributed_id = contributed_id;
	current_folder_auto_value = auto_value;
	
	if(parent_id)
	{
		activate_button('up');
	}
	else
	{
		deactivate_button('up');
	}

	if(history_array.length>1)
	{
		activate_button('back');
	}
	else
	{
		deactivate_button('back');
	}
	
	
	activate_paste_option();
	
	if(folder_id!='rootfolder')
	{
		if(document.content.sidebar.content.loaded)
		{
			document.content.sidebar.content.expand_folder(folder_id);	
		}
	}
}

// returns the currently selected (not currently viewing) folder

function get_selected_item_id()
{
	return selected_item_id;
}

function get_selected_item_mode()
{
	return selected_item_mode;
}

function get_selected_folder_id()
{
	if(selected_item_mode=='folder')
	{
		return get_selected_item_id();
	}
	else
	{
		return null;
	}
}

function get_selected_resource_id()
{
	if(selected_item_mode=='resource')
	{
		return get_selected_item_id();
	}
	else
	{
		return null;
	}
}

function set_selected_resource(resource)
{
	selected_item_id = resource.id;
	selected_item_mode = 'resource';
	activate_selected_options(resource.editable);
	selected_item_url = resource.url;
}

function set_selected_folder(folder)
{
	selected_item_id = folder.id;
	selected_item_mode = 'folder';
	activate_selected_options(folder.editable, folder.website_id, folder.website_root);
}

function reset_selected_item()
{
	selected_item_id = null;
	selected_item_mode = null;
	selected_item_url = null;
	deactivate_selected_options();
}

function activate_selected_options(editable, website_id, website_root)
{
	if(editable)
	{
		if(website_root!='y')
		{
			activate_button('delete');
			activate_button('cut');
			activate_button('edit');
			//activate_button('security');
		}
	}
	
	if(selected_item_mode=='resource')
	{
		activate_button('versions');
		activate_button('download');
	}

	if(website_root!='y')
	{
		activate_button('copy');
	}
}

function activate_paste_option()
{
	if(is_folder_pastable())
	{
		activate_button('paste');
	}
	else
	{
		deactivate_button('paste');
	}
}

function deactivate_selected_options()
{
	deactivate_button('delete');
	deactivate_button('cut');
	deactivate_button('copy');
	deactivate_button('edit');
	//deactivate_button('security');
	deactivate_button('versions');
	deactivate_button('download');	

	if(!is_folder_pastable())
	{
		deactivate_button('paste');
	}
}

////////////////////////////////
//////// CLIPBOARD METHODS
////////////////////////////////

function reset_clipboard_item()
{
	clipboard_mode = null;
	clipboard_item_mode = null;
	clipboard_item_id = null;
	
	deactivate_button('paste');
}

function set_clipboard_item(mode)
{
	if(!selected_item_id>0)
	{
		return;
	}
	
	clipboard_mode = mode;
	clipboard_item_mode = selected_item_mode;
	clipboard_item_id = selected_item_id;
	
	document.content.page.content.select_item_td(clipboard_item_id, clipboard_item_mode, clipboard_mode);
	
	activate_paste_option();
}

function cut()
{
	set_clipboard_item('cut');
}

function copy()
{
	set_clipboard_item('copy');
}

function paste()
{
	if(!is_folder_pastable())
	{
		return;
	}

	var new_loc = href + '&method=resources_paste_item&security_type=' + clipboard_item_mode;
	new_loc += '&item_id=' + clipboard_item_id + '&clipboard_mode=' + clipboard_mode + '&paste_folder_id=' + current_folder_id;

	document.content.page.content.location = new_loc;
}

function is_folder_pastable()
{
	if(!current_folder_editable)
	{
		return false;
	}
	else
	{
		if(clipboard_item_id>0)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
}

////////////////////////////////
//////// HISTORY METHODS
////////////////////////////////

// The event handler for the history changing

function history_changed(selectObj)
{
	if(selectObj.value)
	{
		set_current_folder(selectObj.id, selectObj.contributed_id, selectObj.auto_value);
	}
}

function go_back()
{
	var backObj = history_array[1];
	
	if(!backObj) { return; }
	
	set_current_folder(backObj.id, backObj.contributed_id, backObj.auto_value);
}

// This will add the current folder to the history select object

function apply_history_options(newObj)
{
	var selectObj = document.getElementById('history_select');
	
	var new_history_array = new Array();
	
	new_history_array[0] = newObj;
	
	var history_count = history_array.length;
	
	if(history_count>max_history_count)
	{
		history_count = max_history_count;
	}
	
	for(var i=0; i<history_count; i++)
	{
		new_history_array[new_history_array.length] = history_array[i];
	}
	
	history_array = new_history_array;	

	var option_count = 0;

	for(var i=0; i<history_array.length; i++)
	{
		var obj = history_array[i];
		
		if(obj)
		{			
			var newOption = document.createElement("OPTION");
			newOption.text = obj.address;
			newOption.value = obj.id;
			
			selectObj.options[option_count] = newOption;
			
			option_count++;
		}
	}
}

////////////////////////////////
//////// BUTTON METHODS
////////////////////////////////

// This method will display the resources home page (when clicked from the menu)

function resources_frameset()
{
	var new_loc = '/wkhtml/vertical_frameset/?session_id=' + session_id + '&details_key=resourceshare_main';

	document.content.location = new_loc;
}

function view_linked_folder(folder_id, resource_id)
{
		select_resource_id = resource_id;
		
		set_current_folder(folder_id);
}

// This is called to navigate to a different folder
// fromtree indicates that this was called from the tree itself
// and therefore shouldn't try and mess with the tree

function set_current_folder_from_tree(new_id, org_id, auto_value, page)
{
	var loc = href + '&method=resources_view_folder&folder_id=' + new_id;
	loc += '&select_resource_id=' + select_resource_id;
	
	if(org_id>0)
	{
		loc += '&contributed_id=' + org_id;
	}

	if(auto_value)
	{
		loc += '&auto_folder_value=' + auto_value;
	}

	if(page>0)
	{
		loc += '&page=' + page;
	}
	
	document.content.page.content.location = loc;
	
	select_resource_id = '';
}

function set_current_folder(new_id, org_id, auto_value, page)
{
	if((!auto_value)&&(!page))
	{
		document.content.sidebar.content.click_folder(new_id, org_id, auto_value, page);
	}
	else
	{
		set_current_folder_from_tree(new_id, org_id, auto_value, page);
	}
}

// This function will navigate to the parent of the current folder if defined

function go_up()
{
	if(!resources_active)
	{
		return;
	}
	
	if(current_folder_parent_id)
	{
		var auto_value = '';

		if((current_folder_auto_value!='')&&(current_folder_contributed_id>0))
		{
			auto_value = current_folder_auto_value;
		}

		set_current_folder(current_folder_parent_id, 0, auto_value);
	}
}

function delete_item()
{
	if(!resources_active)
	{
		return;
	}
	
	if(!selected_item_id>0)
	{
		return;
	}

	var item_title = 'Resource';

	if(selected_item_mode=='folder')
	{
		item_title = 'Folder and its contents';
	}

	var confirm = window.confirm('Are you sure you want to send this ' + item_title + ' to the Recycle Bin?');

	if(confirm)
	{
		var new_loc = href + '&method=resources_delete_item&security_type=' + selected_item_mode + '&item_id=' + selected_item_id;

		document.content.page.content.location = new_loc;
	}
}

function edit_item()
{
	if(!resources_active)
	{
		return;
	}
	
	if(!selected_item_id>0)
	{
		return;
	}
	
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare";
	var item_id = get_selected_item_id();
	var width = 0;
	var height =  0;
	var folder_reload = false;
	
	if(selected_item_mode=='folder')
	{
		width = folder_window_width;
		height = folder_window_height;
		modal_loc += "&method=resources_folder_form&title=Edit Folder&folder_id=" + item_id;
		folder_reload = true;
	}
	else if(selected_item_mode=='resource')
	{
		width = resource_window_width;
		height = resource_window_height;
		modal_loc += "&method=resources_resource_form&title=Edit Resource&resource_id=" + item_id;
	}

	var item_id = show_modal_window(modal_loc, width, height);
	//window.open(modal_loc, 1000, 600);
	
//	return;
	if(item_id>0)
	{
		if(folder_reload)
		{
			document.content.sidebar.content.document.location.reload();
		}
		
		document.content.page.content.document.location.reload();
	}	
}

function search_resources()
{
	if(!resources_active)
	{
		return;
	}
	
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare&method=resources_search&title=Search Resources";

	var status = show_modal_window(modal_loc, search_window_width, search_window_height);

	if(status)
	{
		select_resource_id = status.resource_id;
		
		set_current_folder(status.folder_id);
	}	
}

function view_timeline(id)
{
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare&method=resources_view_jobfile_timeline&jobfile_id=" + id;

	var status = show_modal_window(modal_loc, timeline_window_width, timeline_window_height);	
}

function view_options()
{
	//get_menu_query('&method=resources_options&appname=resourceshare&title=Options');	
	
	var loc = '/htmlhub/frames_double?session_id=' + session_id + '&frameset_key=resourceshare_options_frame';
				
	document.content.location = loc;	
	
	return;
	
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare&method=resources_options";
	modal_loc += '&title=Options';

	var status = show_modal_window(modal_loc, options_window_width, options_window_height);
}

function versions()
{
	if(!resources_active)
	{
		return;
	}
	
	if((!selected_item_id>0)||(selected_item_mode!='resource'))
	{
		return;
	}
	
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare&method=resources_view_versions";
	modal_loc += "&resource_id=" + selected_item_id + '&title=Resource Versions';

	var status = show_modal_window(modal_loc, versions_window_width, versions_window_height);
}

function edit_security()
{
	if(!resources_active)
	{
		return;
	}
	
	if(!selected_item_id>0)
	{
		return;
	}
	
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare&method=resources_privilages_form";
	modal_loc += "&security_type=" + selected_item_mode + "&item_id=" + selected_item_id + '&title=Security Settings';

	//var status = show_modal_window(modal_loc, security_window_width, security_window_height);	
	openWindow(modal_loc, 1000, 800);
}

function create_virtual_folder()
{
	if(!resources_active)
	{
		return;
	}
	
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare";
	modal_loc += "&method=resources_virtual_folder_form&title=Create Folder";

	var folder_id = show_modal_window(modal_loc, folder_window_width, folder_window_height);

	if(folder_id>0)
	{
		document.content.sidebar.content.document.location = href + '&method=resources_view_folder&folder_id=' + folder_id;
		document.content.page.content.document.location.reload();
	}
}

function create_discussion()
{
	create_folder('&is_forum=y');	
}

function create_client()
{
	create_folder('&is_client=y');		
}

// This will open the modal dialog to create a folder within the current one.
function create_folder(append)
{
	if(!resources_active)
	{
		return;
	}
	
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare";
	modal_loc += "&method=resources_folder_form&title=Create Folder";
	
	if(append!=null) { modal_loc += append; }

	var folder_id = show_modal_window(modal_loc, folder_window_width, folder_window_height);

	if(folder_id>0)
	{
		document.content.page.content.document.location = href + '&method=resources_view_folder&folder_id=' + folder_id;
		
		document.content.sidebar.content.location.reload();
	}
}

function download()
{
	if(!resources_active)
	{
		return;
	}
	
	document.content.page.content.download_current_resource();
}

// This will open the modal dialog to create a file within the current folder.

function create_link()
{
	create_resource('link');
}

function create_text()
{
	create_resource('text');
}

function create_file()
{
	create_resource('file');
}



function create_resource(type)
{
	if(!resources_active)
	{
		return;
	}
	
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare";
	modal_loc += "&method=resources_resource_form&title=Create Resource&type=" + type;

	var folder_id = show_modal_window(modal_loc, resource_window_width, resource_window_height);
//	openWindow(modal_loc, 1000, 800);
//	return;

	if(folder_id>0)
	{
//		document.content.sidebar.content.document.location.reload();
		document.content.page.content.document.location = href + '&method=resources_view_folder&folder_id=' + folder_id;
	}
}

function download_resource(id)
{
	if(!resources_active)
	{
		return;
	}
	
	if(selected_item_url)
	{
		var url_win = window.open(selected_item_url);
	}
	else
	{
		var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=resourceshare";
		modal_loc += "&method=resources_modal_download&title=Download Resource&resource_id=" + id;

		var download_mode = openWindow(modal_loc, download_window_width, download_window_height);
	}
}

////////////////////////////////
//////// UTILITY METHODS
////////////////////////////////

function show_modal_window(loc, width, height, args)
{
	if(IsSP2)
	{
		height += 35;
	}
	
	var props = 'center:yes;status:no;resizable:no;dialogWidth:' + width + 'px;dialogHeight:' + height + 'px;help:no;scroll:no;status:no;';

	var ret = window.showModalDialog(loc, args, props);

	return ret;
}

function activate_button(key)
{
	buttonStates[key] = true;
	document.getElementById(key).style.display = 'inline';
	document.getElementById(key + '_g').style.display = 'none';	
}

function deactivate_button(key)
{
	buttonStates[key] = false;
	document.getElementById(key).style.display = 'none';
	document.getElementById(key + '_g').style.display = 'inline';
}

function register_resource_tree()
{
	document.content.document.body.onunload = resources_unloaded;
	resources_active = true;
	
	activate_button('search');	
	deactivate_button('resources');
	
	document.getElementById('history_select').disabled = false;	
}

function resources_unloaded()
{
	resources_active = false;

	deactivate_button('delete');
	deactivate_button('cut');
	deactivate_button('copy');
	deactivate_button('edit');
	//deactivate_button('security');
	deactivate_button('versions');
	deactivate_button('download');	
	deactivate_button('paste');
	deactivate_button('up');	
	deactivate_button('search');
		
	activate_button('resources');
	
	document.getElementById('history_select').disabled = true;
}

function view_moderation()
{
	var new_loc ='/htmlhub/frames_double_content?method=moderation_home&title=_moderation_toolbar&title_height=140&appname=resourceshare&frame_name=moderationcontent&session_id=' + session_id;

	document.content.location = new_loc;
}
