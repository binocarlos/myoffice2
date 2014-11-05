var holiday_default_status_text = '';

var holiday_new_object_id = 1;

var holiday_changed_objects = new Object();
var holiday_saved = true;
var holiday_changed_count = 0;

var sidebar_mode = true;

var holiday_is_top = true;

var holiday_is_Mac = false;

var holiday_platform = navigator.platform;

if(holiday_platform.indexOf('Mac')>=0)
{
	holiday_is_Mac = true;
}

////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////
//// MAIN MENU
////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////

function get_xTree_query(query)
{
	holiday_get_query(query);
}

function get_main_query(query)
{
	var new_loc = href + query;

	document.content.location = new_loc;
}

function get_menu_query(query)
{
	var new_loc = href + query;

	document.content.page.location = new_loc;
}

function get_menu_query(query)
{
	var new_loc = href + query;

	document.content.page.location = new_loc;
}

function holiday_get_sidebar_query(query)
{
	var new_loc = href + query;

	document.content.sidebar.sidebarmain.location = new_loc;
}	

function holiday_get_query(query)
{
	if(holiday_is_saved())
	{
		var new_loc = href + query;

		document.content.page.pagemain.location = new_loc;
	}
	else
	{
		alert('You have not saved');
	}
}

////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////
//// GUI
////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////

function holiday_sidemenu_rollover(mode)
{

}

function holiday_toggle_sidemenu()
{
	sidebar_mode = !sidebar_mode;
		
	var cols = '160,*';
	var text = 'Hide';
		
	if(!sidebar_mode)
	{
		cols = '0,*';
		text = 'Show';
	}

	document.all('showhidetitle').innerText = text;
		
	document.content.document.all.sidebar_frameset.cols=cols;
}


function holiday_focus_cell(cell)
{
	cell.style.borderColor = '#0099cc';
}

function holiday_blur_cell(cell)
{
	cell.style.borderColor = '#dddddd';
}

function holiday_image_roll(img, mode)
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

function holiday_set_main_status(text)
{
	var status_span = document.all('main_status');

	var new_html = '<b class="red" style="background-color:#ffffff; padding: 2px;">' + text + '</b>';

	document.all('main_status').innerHTML = new_html;
//	document.all('status_td').bgColor = #ffffff;

	setTimeout("holiday_apply_default_status()", 5000);	
}

function holiday_init_default_status()
{
	diaryApp_default_status_text = document.all('main_status').innerHTML;
}

function holiday_apply_default_status()
{
	document.all('main_status').innerHTML = holiday_default_status_text;
//	document.all('status_td').bgColor = #cccccc;
}


////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////
//// WDDX METHODS
////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////


function holiday_do_save()
{
	if(holiday_changed_count>0)
	{
		var object_packet = holiday_get_changed_objects_packet();

		document.toolbar.document.object_form.object_packet.value = object_packet;

		document.toolbar.document.object_form.submit();
	}
	else
	{
		holiday_set_main_status('No Changes to Save');
	}
}

function holiday_is_saved()
{
	return holiday_saved;
}

function holiday_reset_changed_objects()
{
	holiday_changed_count = 0;
	holiday_changed_objects = new Object();
	holiday_saved = true;
}

function holiday_replace_object_id(table, old_id, new_id)
{
	var object = table[old_id];

	object.id = new_id;

	delete(table[old_id]);

	table[object.id] = object;
}

function holiday_add_changed_object(obj)
{
	var changed_id = '' + obj.table + '_' + obj.id;

	holiday_changed_objects[changed_id] = obj;

	holiday_changed_count++;

	holiday_saved = false;
}

function holiday_get_changed_objects()
{
	return holiday_changed_objects;
}


function holiday_get_changed_objects_packet()
{
	var main_packet = "<objects>\n";

	for (var obj_id in holiday_changed_objects)
	{
		var obj = holiday_changed_objects[obj_id];

		main_packet += holiday_get_object_packet(obj);
	}

	main_packet += "</objects>";

	return main_packet;
}

function holiday_get_object_packet(object)
{
	var packet = "<object>\n";

	for (var prop in object)
	{
		var value = object[prop];

		var value_st = '' + value;

		value_st = value_st.replace(/&/, '&amp;');
		value_st = value_st.replace(/</, '&lt;');
		value_st = value_st.replace(/>/, '&gt;');

		packet += '<' + prop + '>' + value_st + '</' + prop + ">\n";
	}

	packet += "</object>\n";

	return packet;
}

function swap(image,imagefile)
{
  document.images[image].src = imagefile
}
