// app.js - this is the file that will accompany the window - 
// ie, it will perform the top level application functions.

// another test //

var budgetHub_default_status_text = '';

var budgetHub_new_object_id = 1;

var budgetHub_changed_objects = new Object();
var budgetHub_saved = true;
var budgetHub_changed_count = 0;
var budgetHub_next_query = null;
var budgetHub_next_sidebar = null;
var budgetHub_next_eval = null;
var budgetHub_mainFrame = false;

var budgetHub_current_budget_id = null;
var budgetHub_selected_row = null;

var budgetHub_is_top = true;

var budgetHub_is_Mac = false;

var budgetHub_platform = navigator.platform;

if(budgetHub_platform.indexOf('Mac')>=0)
{
	budgetHub_is_Mac = true;
}

var sidebar_mode = false;
var sidebar_button_mode = false;

var currentFieldGui;

////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////
//// MAIN MENU
////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////

function get_menu_query(query)
{
	budgetHub_get_main_query(query);
}

function budgetHub_get_sidebar_query(query)
{
	budgetHub_get_query(query, true);
}

function budgetHub_get_main_query(query)
{
	budgetHub_get_query(query, false, true);
}

function get_budget_open_query(method)
{
	if(!budgetHub_current_budget_id)
	{
		budgetHub_open_budget(method);
		return;
	}
	else
	{
		get_menu_query('&method=' + method + '&budget_id=' + budgetHub_current_budget_id);
	}
}


function budgetHub_get_query(query, sidebar, mainFrame)
{
	if(budgetHub_saved)
	{
		var new_loc = href + query;

		if(sidebar)
		{
			document.content.sidebar.location = new_loc;
		}
		else if(mainFrame)
		{
			document.content.location = new_loc;
		}
		else
		{
			document.content.page.location = new_loc;
		}

		budgetHub_reset_current_budget();
	}
	else
	{
		budgetHub_ask_save(query, sidebar, null, mainFrame);
	}
}

function budgetHub_set_status_timeout()
{
	setTimeout("document.all('statustext').innerText='';", 5000);
}

function budgetHub_set_status(text, noreset)
{
	document.all('statustext').innerText = text;

	if(!noreset)
	{
		budgetHub_set_status_timeout();
	}
}

function budgetHub_reset_current_budget()
{
	budgetHub_current_budget_id = null;
	budgetHub_saved = true;
	budgetHub_next_query = null;
	budgetHub_next_sidebar = null;
	budgetHub_next_eval = null;

	budgetHub_set_sidebar_button(false);
}

function budgetHub_setCurrent_budget(budget_id)
{
	budgetHub_current_budget_id = budget_id;
	budgetHub_saved = true;

	budgetHub_set_sidebar_button(true);
}


function budgetHub_budget_changed()
{
	budgetHub_saved = false;
}

function budgetHub_get_save_packet()
{
	alert(document.content.sidebar.budgetHub_get_budget_xml());
}

function budgetHub_save_completed()
{
	budgetHub_set_status('Budget Saved ....');
	budgetHub_set_status_timeout();

	budgetHub_saved = true;

	if(budgetHub_next_query)
	{
		budgetHub_get_query(budgetHub_next_query, budgetHub_next_sidebar, budgetHub_mainFrame);

		budgetHub_reset_current_budget();
	}

	if(budgetHub_next_eval)
	{
		eval(budgetHub_next_eval);

		budgetHub_next_eval = null;
	}
}

function budgetHub_open_budget(file_type)
{
	if(budgetHub_saved)
	{
		var loc = href + '&method=open_budget_file&file_type=' + file_type;

		var arr = budgetHub_show_modal_window(loc, 450, 350);

		if(arr)
		{
			var id = arr[0];
			var mode = arr[1];

			if(!mode)
			{
				mode = 'all';
			}

			if(mode=='all')
			{
				var query = '&method=edit_budget_entries&budget_id=' + id;

				budgetHub_get_main_query(query);
			}
			else
			{
				var query = '&method=' + mode + '&budget_id=' + id;

				budgetHub_get_main_query(query);
			}
		}
	}
	else
	{
		budgetHub_ask_save(null, null, "budgetHub_open_budget();");
	}
}

function budgetHub_delete_budget()
{
	if(budgetHub_saved)
	{
		var loc = href + '&method=delete_budget_file';

		var id = budgetHub_show_modal_window(loc, 400, 340);

		if(id)
		{
			var query = '&method=budget_delete_budget&budget_id=' + id;

			budgetHub_get_main_query(query);
		}
	}
	else
	{
		budgetHub_ask_save(null, null, "budgetHub_delete_budget();");
	}

}

function budgetHub_ask_save(query, sidebar, evaltext, mainFrame)
{
	var loc = href + '&method=show_save_confirm';

	var ret = budgetHub_show_modal_window(loc, 450, 350);

	if(ret=='dontsave')
	{
		budgetHub_saved = true;

		if(evaltext)
		{
			eval(evaltext);
		}
		else
		{
			budgetHub_get_query(query, sidebar, mainFrame);
		}
	}

	if(ret=='save')
	{
		if(evaltext)
		{
			budgetHub_next_eval = evaltext;
		}
		else
		{
			budgetHub_next_query = query;
			budgetHub_next_sidebar = sidebar;
			budgetHub_mainFrame = mainFrame;
		}

		budgetHub_save_budget();
	}
}

function budgetHub_save_budget()
{
	if(budgetHub_saved)
	{
		budgetHub_set_status("This budget is already saved.");
		return;
	}

	if(!budgetHub_current_budget_id)
	{
		budgetHub_set_status("You must open a Budget to save it.");
		return;
	}

	budgetHub_set_status('Saving Budget, Please Wait ...', true);

	setTimeout("budgetHub_submit_save_form();", 10);
}


function budgetHub_save_budget_as()
{
	if(!budgetHub_current_budget_id)
	{
		budgetHub_set_status("You must open a Budget to save it.");
		return;
	}

	var loc = href + '&method=save_budget_file_as';

	var arr = budgetHub_show_modal_window(loc, 450, 350);

	if(arr)
	{
		var id = arr[0];
		var name = arr[1];
		var mode = arr[2];

		budgetHub_set_status('Saving Budget, Please Wait ...', true);

		setTimeout('budgetHub_submit_save_form_values(\'' + id + '\', \'' + name + '\', \'' + mode + '\');', 10);
	}
}

function budgetHub_export_excel()
{
	if(!budgetHub_current_budget_id)
	{
		budgetHub_set_status("You must open a Budget to export it.");
		return;
	}

	if(budgetHub_saved)
	{		
		var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=budgethub";
		modal_loc += "&method=budget_export_excel&title=Export To Excel&budget_id=" + budgetHub_current_budget_id;
		
		var ret = budgetHub_show_modal_window(modal_loc, 450, 200);
	}
	else
	{
		budgetHub_ask_save(null, null, "budgetHub_export_excel();");
	}
}

function budgetHub_show_modal_window(loc, width, height, args)
{
	var props = 'status:no;resizable:yes;dialogWidth:' + width + 'px;dialogHeight:' + height + 'px;help:no;scroll:no;status:no;';

	var ret = window.showModalDialog(loc, args, props);

	return ret;
}

function budgetHub_submit_save_form_values(id, name, mode)
{
	document.save.document.save_form.original_budget_id.value = budgetHub_current_budget_id;

	if(id)
	{
		document.save.document.save_form.budget_id.value = id;
	}

	if(name)
	{
		document.save.document.save_form.budget_name.value = name;
	}

	document.save.document.save_form.packet.value = document.content.sidebar.budgetHub_get_budget_xml(mode);

	document.save.document.save_form.submit();
}

function budgetHub_submit_save_form()
{
	document.save.document.save_form.budget_id.value = budgetHub_current_budget_id;

	document.save.document.save_form.packet.value = document.content.sidebar.budgetHub_get_budget_xml('all');

	document.save.document.save_form.submit();
}

////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////
//// GUI
////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////

function budgetHub_set_sidebar_button(mode)
{
	var dis = 'none';

	if(mode)
	{
		dis = 'inline';
	}

	sidebar_mode = mode;

	document.getElementById('hidetotals').style.display = dis;
}

function budgetHub_toggle_sidemenu()
{
	sidebar_mode = !sidebar_mode;

	var cols = '260,*';
	var text = 'Hide';

	if(!sidebar_mode)
	{
		cols = '0,*';
		text = 'Show';
	}

	document.getElementById('hidetotals_title').innerText = text;

	document.content.document.all.sidebar_frameset.cols=cols;
}



function budgetHub_focus_cell(cell)
{
	cell.style.borderColor = '#0099cc';
}

function budgetHub_blur_cell(cell)
{
	cell.style.borderColor = '#dddddd';
}

function budgetHub_image_roll(img, mode)
{
	if(mode)
	{
		img.className = 'roll_img_button';
	}
	else
	{
		img.className = 'normal_img_button';
	}
}

////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////
//// STATUS
////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////

function budgetHub_set_main_status(text)
{
	var status_span = document.all('main_status');

	var new_html = '<b class="red" style="background-color:#ffffff; padding: 2px;">' + text + '</b>';

	document.all('main_status').innerHTML = new_html;
//	document.all('status_td').bgColor = #ffffff;

	setTimeout("budgetHub_apply_default_status()", 5000);
}

function budgetHub_init_default_status()
{
	diaryApp_default_status_text = document.all('main_status').innerHTML;
}

function budgetHub_apply_default_status()
{
	document.all('main_status').innerHTML = diaryApp_default_status_text;
//	document.all('status_td').bgColor = #cccccc;
}


////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////
//// WDDX METHODS
////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////

function swap(image,imagefile)
{
	if(document.images[image])
	{
	  document.images[image].src = imagefile;
	}
}


function budgetHub_set_selected_row(row)
{
	budgetHub_selected_row = row;
}

function budgetHub_insert_row()
{
	if(budgetHub_current_budget_id)
	{
		document.budget_toolbar.add_budget_row();
	}
}

function budgetHub_delete_row()
{
	if(budgetHub_selected_row)
	{
		document.budget_toolbar.delete_budget_row();
	}
}

function budgetHub_move_row()
{
	if(budgetHub_selected_row)
	{
		document.budget_toolbar.edit_budget_row_position();
	}
}

function budgetHub_change_row_currency()
{
	if(budgetHub_selected_row)
	{
		document.budget_toolbar.change_row_currency();
	}
}

function budgetHub_edit_comment()
{
	if(budgetHub_selected_row)
	{
		document.budget_toolbar.edit_row_comment();
	}
}
