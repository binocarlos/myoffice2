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

 //comment

// cvs is great !!!

function show_modal_window(loc, width, height, args)
{
	width += 20;
	height += 20;

	var props = 'center:yes;status:no;resizable:no;dialogWidth:' + width + 'px;dialogHeight:' + height + 'px;help:no;scroll:no;status:no;';

	var ret = window.showModalDialog(loc, args, props);

	return ret;
}

function get_modal_window_return(query, width, height, args)
{
	var modal_loc = "/wkhtml/modal_frameset/?session_id=" + session_id + "&appname=" + appname;
	modal_loc += query;

	var ret = show_modal_window(modal_loc, width, height, args);

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

function reformat_float(value)
{
	if(!value)
	{
		value = 0;
	}

	var result= Math.round(value*100)/100;

	return result;
}

function generate_calendar_window(elem_id, value)
{
	var frameleft = event.clientX;
	var frametop = event.clientY;

	var loc = '/templates/calendar.htm';

	var caldiv = '<iframe id="calendarframe" scrolling=no style="width:100%;height:100%;" width=100% height=100% src="/templates/calendar.htm"></iframe>';

	var container = document.createElement('SPAN');
	container.id = 'calendarspan';
	container.style.position = 'absolute';
	container.style.display = 'inline';
	container.style.border = '1px solid #000000';
	container.style.width = '280px';
	container.style.height = '320px';
	container.style.left = frameleft;
	container.style.top = frametop;

	container.innerHTML = caldiv;

	var frame = container.all('calendarframe');

	alert(frame);

	frame.setDateValue(value);

	document.body.appendChild(container);


}

function apply_winbuts(arr)
{
	for(var i=0; i<arr.length; i++)
	{
		var id = arr[i];

		var elem = document.getElementById(id);

		elem.onmouseover = winbut_rollover;
		elem.onmouseout = winbut_rolloff;
	}
}

function winbut_rolloff()
{
	var elem = event.srcElement;

	var insane = 0;

	while((elem.tagName!='A')&&(elem.tagName!='BODY')&&(insane<10000))
	{
		elem = elem.parentElement;

		insane++;
	}

	elem.className = 'buttonoff';
}

function winbut_rollover()
{
	var elem = event.srcElement;

	var insane = 0;

	while((elem.tagName!='A')&&(elem.tagName!='BODY')&&(insane<10000))
	{
		elem = elem.parentElement;

		insane++;
	}

	elem.className = 'buttonouter';
}

function swap(imagename,changeimageto)
{
    document.images[imagename].src = changeimageto;
}

function set_status(text)
{
	clearTimeout();
	top.window.status = text;
}