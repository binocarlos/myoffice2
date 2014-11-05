var current_list_id = null;

function easemail_home()
{
	var new_loc = href + '&method=easemail_app_home';
				
	set_new_content_location(new_loc);
}

function emails_home()
{
	var new_loc = href + '&method=easemail_home';
	
	set_new_content_location(new_loc);
}

function unsubscribe()
{
	var new_loc = href + '&method=easemail_unsubscribe_member';
	
	set_new_content_location(new_loc);
}

function set_current_list(id)
{
	current_list_id = id;
	
	var new_loc = href + '&method=easemail_list_home&list_id=' + current_list_id;
	
	set_new_content_location(new_loc);
}

function set_new_content_location(new_loc)
{
	document.content.page.content.location = new_loc;
}

function is_valid_list_selected()
{
	if((current_list_id)&&(current_list_id!='rootfolder'))
	{
		return true;
	}
	else
	{
		return false;
	}
}

function reset_current_list()
{
	current_list_id = null;
}

function delete_current_list()
{
	if(is_valid_list_selected())
	{
		var conf = window.confirm('Are you sure you want to delete this list and all of its members!!!');
		
		if(conf)
		{		
			var new_loc = href + '&method=easemail_delete_list&list_id=' + current_list_id;
		
			set_new_content_location(new_loc);
		}
	}
	else
	{
		alert('please select a list');
	}	
}

function edit_current_list()
{
	if(is_valid_list_selected())
	{
		var new_loc = href + '&method=easemail_list_form&list_id=' + current_list_id;
		
		set_new_content_location(new_loc);
	}
	else
	{
		alert('please select a list');
	}	
}

function add_child_list()
{
	if(current_list_id)
	{
		var new_loc = href + '&method=easemail_list_form';
		
		set_new_content_location(new_loc);	
	}
	else
	{
		alert('please select a list');
	}	
}

function search_members()
{
	var append = '';

	var new_loc = href + '&method=easemail_search_members&list_id=' + current_list_id + '&all=1';
		
	set_new_content_location(new_loc);
}

function transfer_members()
{
	if(is_valid_list_selected())
	{
		var new_loc = href + '&method=easemail_transfer_members&list_id=' + current_list_id;
		
		set_new_content_location(new_loc);
	}
	else
	{
		alert('please select a list');
	}
}

function download_members()
{
	var new_loc = href + '&method=easemail_download_members&list_id=' + current_list_id;
		
	set_new_content_location(new_loc);
}

function remove_bounces()
{
	var new_loc = href + '&method=easemail_remove_bounces';
		
	set_new_content_location(new_loc);
}

function send_email()
{
	var new_loc = href + '&method=easemail_send_email_select_lists';
		
	set_new_content_location(new_loc);
}

function upload_members()
{
	if(is_valid_list_selected())
	{
		var new_loc = href + '&method=easemail_upload_members&list_id=' + current_list_id;
		
		set_new_content_location(new_loc);
	}
	else
	{
		alert('please select a list');
	}
}

function add_member()
{
	if(is_valid_list_selected())
	{
		var new_loc = href + '&method=easemail_member_form&list_id=' + current_list_id;
		
		set_new_content_location(new_loc);
	}
	else
	{
		alert('please select a list');
	}	
}

function get_list_id_array()
{
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=easemail&method=easemail_select_multiple_lists&title=Choose Lists";
	var arr = this.show_modal_window(modal_loc, 600, 450);
	
	return arr;
}

function show_modal_window(loc, width, height, args)
{
	var props = 'center:yes;status:no;resizable:no;dialogWidth:' + width + 'px;dialogHeight:' + height + 'px;help:no;scroll:no;status:no;';

	var ret = window.showModalDialog(loc, args, props);

	return ret;
}
