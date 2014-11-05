// fix for deprecated method in Chrome 37
  if (!window.showModalDialog) {
     window.showModalDialog = function (arg1, arg2, arg3) {

        var w;
        var h;
        var resizable = "no";
        var scroll = "no";
        var status = "no";

        // get the modal specs
        var mdattrs = arg3.split(";");
        for (i = 0; i < mdattrs.length; i++) {
           var mdattr = mdattrs[i].split(":");

           var n = mdattr[0];
           var v = mdattr[1];
           if (n) { n = n.trim().toLowerCase(); }
           if (v) { v = v.trim().toLowerCase(); }

           if (n == "dialogheight") {
              h = v.replace("px", "");
           } else if (n == "dialogwidth") {
              w = v.replace("px", "");
           } else if (n == "resizable") {
              resizable = v;
           } else if (n == "scroll") {
              scroll = v;
           } else if (n == "status") {
              status = v;
           }
        }

        var left = window.screenX + (window.outerWidth / 2) - (w / 2);
        var top = window.screenY + (window.outerHeight / 2) - (h / 2);
        var targetWin = window.open(arg1, arg1, 'toolbar=no, location=no, directories=no, status=' + status + ', menubar=no, scrollbars=' + scroll + ', resizable=' + resizable + ', copyhistory=no, width=' + w + ', height=' + h + ', top=' + top + ', left=' + left);
        targetWin.focus();
     };
  }

function get_double_frameset(key)
{
	var loc = '/htmlhub/frames_double?session_id=' + session_id + '&frameset_key=' + key;
				
	document.getElementById('appContent').src = loc;
}

function printPage()
{
	document.getElementById('appContent').print();
}

function go_home()
{
	var loc = '/htmlhub/frames_double?session_id=' + session_id + '&frameset_key=myoffice2_homepage';
				
	document.getElementById('appContent').src = loc;
}

function load_new_tour(tour_id)
{
	var loc = '/htmlhub/frames_double?session_id=' + session_id + '&frameset_key=myoffice2_homepage&switch_tour_id=' + tour_id;
				
	document.getElementById('appContent').src = loc;	
}

function get_menu_query(query)
{
	var new_loc = href + query;

	document.getElementById('appContent').src = new_loc;
}
			
function get_manage_visitors()
{
	var loc = '/htmlhub/frames_double?session_id=' + session_id + '&frameset_key=skills_audit_manage_visitors';
				
	document.getElementById('appContent').src = loc;
}

function get_menu_iframe_query(method, title)
{
	var new_loc = '/wkhtml/iframe_title_frame/?session_id=' + session_id + '&appname=' + appname;
	new_loc += '&frame_method=' + method + '&title=' + title;

	document.getElementById('appContent').src = new_loc;
}

function show_modal_window(loc, width, height, args)
{
	width += 20;
	height += 20;

	var props = 'center:yes;status:no;resizable:no;dialogWidth:' + width + 'px;dialogHeight:' + height + 'px;help:no;scroll:no;status:no;';

	var ret = window.showModalDialog(loc, 'myoffice2', props);

	return ret;
}

function get_modal_window_return(query, width, height)
{
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=" + appname;
	modal_loc += query;

	var ret = show_modal_window(modal_loc, width, height);

	return ret;
}

function openWindow(url,width,height,status)
{
	width -= 12;
	height -= 31;
    PopURL=url;
    if(!PopWin || PopWin.closed){
        PopWin=PopWinOpen(width,height,status);
    }
    else {
        PopWin.close();
        PopWin=null;
        PopWin=PopWinOpen(width,height,status);
    }
}
var PopURL="";
var PopWin=null;
var openpopwin=null;
var calendar_span;
function PopWinOpen(width,height,status){
    var x =(screen.availWidth-width)/2;
    var y =(screen.availHeight-height)/2;
	var status_st = '';
	if(status)
	{
		status_st = ',status';
	}

	var date_obj = new Date();
	var date_st = '' + date_obj.getTime();

  var winfeatures="width="+width+",height="+height+",top="+y+",left="+x+",resizable=yes,scrollbars=0" + status_st;
	openpopwin=null;
	openpopwin=window.open(PopURL,"wkapp" + date_st,winfeatures);
	return openpopwin;
}

function application_logout()
{
	get_menu_iframe_query('log_out', 'Log Out');
}

function addBooking()
{
	var venue_id = get_modal_window_return('&method=booking_add_booking', 680, 500);

	if(venue_id)
	{
		get_double_frameset('myoffice2_booking_progress&venue_id=' + venue_id + '&filter=all');		
	}
}

function viewTimeline()
{
//	var ret = get_modal_window_return('&method=editors_daterange', 500, 400);
//
//	if(ret)
//	{
		get_double_frameset('myoffice2_timeline');
//	}
}

function viewDealSheet(showing_id, tour_id)
{
	if(!showing_id>0)
	{
		var ret = get_modal_window_return('&method=modal_find_showing_frame', 680, 500);		
		
		if(!ret) { return; }
		
		showing_id = ret.showing_id;
		tour_id = ret.tour_id;
	}

	document.getElementById('appContent').src = href + '&method=booking_view_dealsheet_redirect&showing_id=' + showing_id;
	document.getElementById('tour_id').value = tour_id;
}

function searchVenueHistory()
{
	var ret = get_modal_window_return('&method=modal_venue_status_search', 900, 640);
	
	if(ret)
	{		
		get_double_frameset('myoffice2_venue_status&from_search=1&venue_id=' + ret.venue_id + '&showing_id=' + ret.showing_id);
	}
}

function venueStatusSearchResults()
{
	var ret = get_modal_window_return('&method=modal_venue_status_search_results&from_session=1', 900, 640);
	
	if(ret)
	{		
		get_double_frameset('myoffice2_venue_status&from_search=1&venue_id=' + ret.venue_id + '&showing_id=' + ret.showing_id);
	}	
}

function viewVenueStatus()
{
	var ref = get_modal_window_return('&method=modal_search_venues_frame&modal=1', 680, 500);
	
	if(ref)
	{		
		get_double_frameset('myoffice2_venue_status&venue_id=' + ref);
	}
}