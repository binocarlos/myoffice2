var isNS, isIE;
var range = "";
var styleObj = "";

if (parseInt(navigator.appVersion) >=4 )
{
	if (navigator.appName.indexOf("Microsoft") < 0)
	{	
		isNS = true;
	}
	else
	{
		isIE = true;
		range = "all.";
		styleObj = ".style";
	}
}

var dns_host = '';
var error = false;
var border_error_flag = false;
var href = '';
var new_url = '';
var save_options_win = null;
var save_options_win_state = false;
var submit_form = null;
var savewin_state = false;
var savewin;
var save_submit_method = '';
var status_span = '';
var changed_count = 0;

var Date_months = new Array("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
var venue_address_summary_folder_open = new Image();
var venue_address_summary_folder_closed = new Image();

venue_address_summary_folder_open.src = '/images/nav/folderopen.gif';
venue_address_summary_folder_closed.src = '/images/nav/folderclosed.gif';


var venue_contacts_summary_folder_open = new Image();
var venue_contacts_summary_folder_closed = new Image();

venue_contacts_summary_folder_open.src = '/images/nav/folderopen.gif';
venue_contacts_summary_folder_closed.src = '/images/nav/folderclosed.gif';

var venue_contacts_summary_present = new Array();

var Date_winstate = false;
var Date_win;
var Date_is_small;
var Date_object_id;
var Date_span_id;
var Date_td_id;
var Date_field;
var Date_table;

var TextBox_winstate = false;
var TextBox_win;
var TextBox_object_id;
var TextBox_span_id;
var TextBox_table;
var TextBox_field;

function add_changed_object(obj)
{
	parent.add_changed_object(obj);
}

function get_url(query)
{
	new_url = '';

	parent.iframe_get_url(query);
}

function get_option_object(id, text)
{
	var newOption = document.createElement("OPTION");
	newOption.text = text;
	newOption.value = id;

	return newOption;
}

function position_warning_div()
{
//	var scheight = screen.availHeight;
//	var scwidth = screen.availWidth;
	
//	var div_width = 300;
//	var div_height = 150;

//	var newwinx = (scwidth/2) - (div_width/2);
//	var newwiny = (scheight/2) - (div_height/2);
	
	document.body.scrollLeft = 0;
	document.body.scrollTop = 0;

}

function set_parent_status(text)
{
	parent.set_status(text);
}

function super_main_document_click(e)
{
	if(savewin_state)
	{
		if(!savewin.closed)
		{
			savewin.focus();
		}
	}

	if(save_options_win_state)
	{
		if(!save_options_win_state)
		{
			save_options_win.focus();
		}
	}
}

function get_object_summary(obj, fields, istitle)
{
	var ret = '';

	for(var i=0; i<fields.length; i++)
	{
		var field_value = obj[fields[i]];
	
		var value = '<span class="smallred">' + field_value + '</span>';

		if(field_value==null) { value = '---'; }

		if(istitle)
		{
			value = '<span class="small">' + fields[i] + ': </span>' + value;
		}		

		ret += value;

		if(i<fields.length-1) { ret += '<br>'; }
	}

	return ret;
}

function getObject(obj)
{
	var theObj;
	if (typeof obj == "string")
	{
		theObj = eval("document." + range + obj + styleObj);
	}
	else
	{
		theObj = obj;
	}

	return theObj;
}

function change_src(ref, src)
{
	var imageObj = eval("document." + ref);
	imageObj.src = src;
}		

function get_date_ext(sday)
{
	var ext = 'th';

	if((sday==1)||(sday==21)||(sday==31)) { ext = 'st'; }

	if((sday==2)||(sday==22)) { ext = 'nd'; }

	if((sday==3)||(sday==23)) { ext = 'rd'; }

	return ext;
}

function get_short_date_summary(sdate)
{
	if(!sdate)
	{
		return '';
	}

	var date = sdate.getDate();
	var month = sdate.getMonth() + 1;
	var year = sdate.getFullYear();
	
	if(date<10)
	{
		date = '0' + date;
	}
	
	if(month<10)
	{
		month = '0' + month;
	}

	if(year<2000)
	{
		year += 1900;
	}
	
	year = year - 2000;
	
	if(year<10)
	{
		year = '0' + year;
	}
	
	return date + '/' + month + '/' + year;
}	

function get_date_summary(sdate)
{
	if(!sdate)
	{
		return '';
	}

	var mn = Date_months[sdate.getMonth()];
	var ext = get_date_ext(sdate.getDate());

	var year = sdate.getFullYear();

	if(year<1000)
	{
		year += 1900;
	}

	var summary = '' + sdate.getDate() + ext + ' ' + mn + ' ' + year;

	return summary;
}

function cell_focus(cell)
{

		cell.style.borderColor = '#3399CC';

}

function cell_blur(cell)
{
	cell.style.borderColor = '#dddddd';
}

function reformat_float(value)
{
	if(!value)
	{
		value = 0;
	}

	var result= Math.round(value*100)/100; 

	return result;
}

function reformat_float_st(value)
{
	var value_st = '' + value;
	
	if(value_st.indexOf(".")>=0)
	{
		var value_array = value_st.split(".");

		var right = value_array[1];	

		if(right.length==1)
		{
			value_st += '0';
		}
	}
	else
	{
		value_st += '.00';
	}

	return value_st;
}

function reformat_price(value, nopound, nocomma, isint)
{
	if(!value)
	{
		value = 0;
	}

	value = reformat_float(value);

	var value_st = "" + value;
	var ret_st = "";
	
	var left;
	var right;
	var appended_right;
	
	if(value_st.indexOf(".")>=0)
	{
		var value_array = value_st.split(".");
		right = value_array[1];	
		left = value_array[0];
	}
	else
	{
		left = value_st;

		if(!isint)
		{
			appended_right = '.00';
		}
	}
	
	var comma_count = 0;

	if(!nocomma)
	{
		var final_left = "";
	
		for(i=left.length-1; i>=0; i--)
		{
			comma_count++;
		
			var num = left.charAt(i);
		
			if((comma_count==4)||(comma_count==7)||(comma_count==10)||(comma_count==13)||(comma_count==16))
			{
				if(num!='-')
				{
					final_left = "," + final_left;
				}
			}
		
			final_left = num + final_left;
		}
	
		ret_st = final_left;
	}
	else
	{
		ret_st = left;
	}
	
	if(right)
	{
		var right_reduced = right.substring(0, 2);
		if(right_reduced.length==1) { right_reduced += "0"; }
		ret_st += "." + right_reduced;
	}

	if(appended_right)
	{
		ret_st += appended_right;
	}
	
	return ret_st;
}

function get_total_table_width()
{
	var width = 0;

	for(var i=0; i<table_widths.length; i++)
	{
		width += table_widths[i];
	}

	return width;
}

function open_tr()
{
	return '<tr valign=top>';
}

function close_tr()
{
	return '</tr>';
}

function get_td(col, content, tdclass, align, colspan, otherwidth, style, id, background)
{
	if(tdclass==null) { tdclass = 'white_td'; }
	if(align==null) { align = 'left'; }
	if(colspan==null) { colspan = 1; }

	var bg_txt = '';

	if(background!=null)
	{
		bg_txt = ' background="' + background + '"';
	}

	var width = '';

	if(col)
	{
		width = table_widths[col];
	}

	if(otherwidth) { width = otherwidth; }

	if(style==null) { style = ''; };

	var id_txt = '';

	if(id!=null)
	{
		id_txt = ' id="' + id + '"';
	}

	var txt = '<td valign=top colspan=' + colspan + ' width=' + width + ' class="' + tdclass + '" align=' + align + ' style="' + style + '"' + id_txt + bg_txt + '>' + content + '</td>';

	return txt;
}

function get_table_header_row()
{
	var row_txt = '<tr valign=top>';

	for(var i=0; i<table_titles.length; i++)
	{
		var t = table_titles[i];

		row_txt += get_td(i, t, 'edit_table_header_cell', 'left');
	}

	row_txt += '</tr>';

	table_row++;

	return row_txt;
}

function get_table_close_code()
{
	return '</table>';
}

function get_table_open_code()
{
	var total_width = get_total_table_width();

	var txt = '<table bgcolor="#666666" border=0 cellpadding=3 cellspacing=1 width=' + total_width + '>';

	txt += get_table_header_row();

	return txt;
}


function simple_window(src)
{
	var w = window.open(src);
	
	return w;
}

function open_params_js_window(src, params)
{
	var scheight = screen.availHeight;
	var scwidth = screen.availWidth;

	var newwinx = (scwidth/2) - (width/2);
	var newwiny = (scheight/2) - (height/2);

	var w = window.open(src, "", params);

	w.moveTo(newwinx, newwiny);
	
	return w;
}

function open_js_window(src, width, height)
{
	var params = "dependent=yes,status=yes,scrollbars=yes,width=" + width + ",height=" + height;

	var scheight = screen.availHeight;
	var scwidth = screen.availWidth;

	var newwinx = (scwidth/2) - (width/2);
	var newwiny = (scheight/2) - (height/2);

	var w = window.open(src, "", params);

	w.moveTo(newwinx, newwiny);
	
	return w;
}

function click_void()
{

}

function tools_get_object_packet(object)
{
	var packet = "<object>\n";

	for (var prop in object)
	{
		var value = object[prop];

		packet += '<' + prop + '>' + value + '</' + prop + ">\n";
	}

	packet += "</object>\n";

	return packet;
}

function MM_checkBrowser(NSvers,NSpass,NSnoPass,IEvers,IEpass,IEnoPass,OBpass,URL,altURL) { //v4.0
  var newURL='', verStr=navigator.appVersion, app=navigator.appName, version = parseFloat(verStr);
  if (app.indexOf('Netscape') != -1) {
    if (version >= NSvers) {if (NSpass>0) newURL=(NSpass==1)?URL:altURL;}
    else {if (NSnoPass>0) newURL=(NSnoPass==1)?URL:altURL;}
  } else if (app.indexOf('Microsoft') != -1) {
    if (version >= IEvers || verStr.indexOf(IEvers) != -1)
     {if (IEpass>0) newURL=(IEpass==1)?URL:altURL;}
    else {if (IEnoPass>0) newURL=(IEnoPass==1)?URL:altURL;}
  } else if (OBpass>0) newURL=(OBpass==1)?URL:altURL;
  if (newURL) { window.location=unescape(newURL); document.MM_returnValue=false; }
}
