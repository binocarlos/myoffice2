// ©Xara Ltd 2002

// variables used to store info on each menu that is visible

var ma = new Array();

var mx = new Array();

var my = new Array();

var mc = new Array();

var mal = 0;

var main = 0;

var mainMode = false;

var clickMode = false;

var shouldResetClickMode = false;

var menuw = 200;

var psrc = 0;

var pname = "";

var al="";





var gd = 0;

var gx,gy;



// browser sniffer function

var d = document;

var NS7 = (!d.all && d.getElementById);

var NS4 = (!d.getElementById);

var IE5 = (!NS4 && !NS7 && navigator.userAgent.indexOf('MSIE 5.0')!=-1);

// Opera misbehaves so treat it like NS4

if (navigator.userAgent.indexOf('Opera')!=-1) NS4=1;

// is it a netscape6 or a mozilla-mozlike ns7?

var ifr = (!NS7 && !NS4); // use iframes to put menus over the <form> objects in IE?

var NS6 = (NS7 && navigator.userAgent.indexOf('Netscape6')!=-1);



// must be called to start a navbar menu

// file = the top/left navbar end

// dir = direction of the navbar 1 for vertical, 2 for horizontal, 3 for nontable vertical and 4 for nontable horizontal

// space = the spacing between buttons

// align = 1 right justify the graphics in the table, 2 = center the graphics, anything else and left justify them

function startMainMenu(file, h, w, dir, space, align)
{
	mainMode = true;

	if (w>0) menuw = w;

	main = dir;

	if (main == 1 || main == 2) d.write("<table border=\"0\" cellspacing=\"" + space + "\" cellpadding=\"0\">");

if (file != "")

	{

	al="";

	if (align==1) al=" align=\"right\"";

	if (align==2) al=" align=\"center\"";

	if (main == 1 || main == 2) d.write("<tr><td" + al + ">");

	d.write("<img src=\"" + loc + file + "\" border=\"0\"");

	if (h>0) d.write(" height=\"" + h + "\"");

	if (w>0) d.write(" width=\"" + w + "\"");

	d.write(" />");

	if (main == 1 || main == 2) d.write("</td>");

	if (main == 1) d.write("</tr>");

	if (main == 3) d.write("<br />");

	}

}



// must be called to end a navbar menu

// file = the graphic of the bottom/right end bar

// h = height of the end bar graphic if applicable, zero to ignore

// w = width of the end bar graphic if applicable, zero to ignore

function endMainMenu(file, h, w)

{

	mainMode = false;

if (file != "")

	{

	if (main == 1) d.write("<tr>");

	if (main == 1 || main == 2) d.write("<td" + al + ">");

	d.write("<img src=\"" + loc + file + "\" border=\"0\"");

	if (h>0) d.write(" height=\"" + h + "\"");

	if (w>0) d.write(" width=\"" + w + "\"");

	d.write(" />");

	if (main == 1 || main == 2) d.write("</td></tr>");

	}

if (main == 1 || main == 2) d.write("</table>");

main = 0;

}


// called for each graphic element and source of a menu in the navbar menu
// name = the unique name of the submenu to create. Also the name of graphic if the ext is ".gif" etc.
//	if so graphics are required for name.ext and possibly name_over.ext
// ext = the graphic file extention eg ".gif", if it doesnt start with a . is assumed to be a text element in the menu
// url = the url this item links to
// tar = the target
// dir = the direction of the submenu 1 to the right, 2 down, 3 to the left
// state = number of button states 1 for static graphics, 2 for showing over states
// s = the css class which controls what this entry looks like in terms of font, colour, rollover, triangle graphics etc

function mainMenuItem(name, ext, h, w, url, tar, alt, dir, state, s)
{
	if (NS4 && main==0) return;

	var isgraphic = false;

	if (main == 1) d.write("<tr>");

	if (main == 1 || main == 2) d.write("<td" + al + ">");

	d.write("<a style=\"cursor:default;\" id=\"mainMenu_" + name + "\"");

	if (url != "" || !isgraphic) d.write("href=\"" + url + "\" ");

	if (tar != "") d.write("target=\"" + tar + "\" ");

	d.write ("onmouseout=\"");

	if (dir > 0) d.write("tidyMenu(event);");



	var forceRoll = 'false';



	if(!mainMode)

	{

		forceRoll = 'true';

	}

	else

	{

		d.write("\" onclick=\"");

		if (dir > 0) d.write("openMenu(event, '" + name + "'," + dir + "," + bc + "," + fc + ", true, false);");

		d.write("return false;\"");

	}



	d.write("\" onmouseover=\"");

	if (dir > 0) d.write("openMenu(event, '" + name + "'," + dir + "," + bc + "," + fc + ", false, " + forceRoll + ");");

	d.write("return false;\"");







	if (!isgraphic) d.write(" class=\""+s+"\" style=\"width:100%\"");



	d.write(">");



	d.write("&nbsp;" + ext + "&nbsp;");



	d.write("</a>");



	if (main == 1 || main == 2) d.write("</td>");

	if (main == 1) d.write("</tr>");

	if (main == 3) d.write("<br />");

}



// called first when defining a submenu

// name = unique name of the submenu

function startSubmenu(name, style, sw)

{

	if (NS4) return;

	if (sw>0) menuw = sw;

	d.write("<div id=\"" + name + "\" class=\""+ style + "\"  style=\"width:" + (menuw+(NS7?bd*2:0)) + "px\">");

}



// called to mark the end of a submenu definition

// name = unique name of the submenu

function endSubmenu(name)

{

	if (NS4) return;

	d.write("</div>");

	// register the mouseout from this div

	if (!NS7) d.getElementById(name).onmouseout = tidyMenu;

}



// called to define each element on the submenu

// text = the menu items text

// url = its url

// tar = its target

// s = css class name

function submenuItem(text, url, tar, s)
{

	if (NS4) return;

	if (text == '---')
	{
		d.write("<img src=\"/images/menus/---.gif\" height=\"1\" width=\""+(menuw-35)+"\" align=\"right\"/>");
	}
	else

	{

		d.write("<a ");

		if (url != "") d.write("href=\"" + url + "\" ");

		if (tar != "") d.write("target=\"" + tar + "\" ");

		d.write("class=\""+s+"\" style=\"width:" + menuw + "px\">&nbsp;" + text + "&nbsp;</a>");

	}

}



// change the image that spawned the event to show the graphic 'file'

function setGraphic(event, name)

{

	if (NS4) return;

	psrc = (NS7) ? event.target : event.srcElement;

	pname = psrc.src;



	if (NS7)

		event.target.src = name;

	else

		event.srcElement.src = name;



}



// open the submenu

// id = the name of the submenu

// pos = the relative position of the submenu 1 to right, 2 down, 3 to left

function openMenu(event, id, pos, bc, fc, wasclicked, force)

{

	if(!force)

	{

		if(wasclicked)

		{

			var button = d.getElementById('mainMenu_' + id);



			if((button.className=='menu_root_click')||(button.className=='menu_root'))

			{

				button.blur();

			}



			if(clickMode)

			{

				return;

			}



			clickMode = true;

		}



		if(!clickMode)

		{

			return;

		}



		shouldResetClickMode = false;

	}



	if (NS4) return;

	var el, x, y, dx, dy;



	// if the global position (gx,gy) isnt sorted, sort it now

	// ie are we in any layers, divs etc?

	if (gd==0)

	{

		var p = d.getElementById(id);

		gx=0;

		gy=0;



		while (p && p.parentNode.nodeName != "BODY")

		{

			p = p.parentNode;

			if (p.nodeName == "DIV" || p.nodeName == "LAYER" || p.nodeName == "SPAN" )

				if (p.style.position == "absolute")

				{

					gx += p.offsetLeft;

					gy += p.offsetTop;

				}

		}



		if (p) gd = 1;

	}



	x = event.clientX - event.offsetX + d.body.scrollLeft - d.body.clientLeft;

	y = event.clientY - event.offsetY + d.body.scrollTop - d.body.clientTop;

	dx = event.srcElement.offsetWidth;

	dy = event.srcElement.offsetHeight;



	if (mal>0)

	{

		y -= bd;

		if (pos!=3) x-=2*bd;

	}



	x -= gx;

	y -= gy;

	x -= 0;

	y -= 1;



	el = d.getElementById(id);



	var button = d.getElementById('mainMenu_' + id);



	if(button.className=='menu_root')

	{

		button.className = 'menu_root_click';

		el.mainMenuElement = button;

	}





	if (el && el.style.visibility != "visible")

	{

		if (pos == 1)

		{

			x += dx;

			el.style.left = x-el.offsetWidth+"px";

			el.style.top  = y+"px";

			nspeed = el.offsetWidth / frames;

		}

		else if (pos == 2)

		{

			y += dy;

			el.style.left = x+"px";

			el.style.top  = y-el.offsetHeight+"px";

			nspeed = el.offsetHeight / frames;

		}

		else if (pos == 3)

		{

			x -= el.offsetWidth;

			el.style.left = x+el.offsetWidth+"px";

			el.style.top  = y+"px";

			nspeed = el.offsetWidth / frames;

		}



		mx[mal] = x;

		my[mal] = y;



		if (NS7 || IE5 || frames==0)

		{

			el.style.left = x+"px";

			el.style.top = y+"px";

		}



		el.style.visibility = "visible";

		el.style.zIndex=999;

		ma[mal] = id;



		mc[mal] = event.srcElement.style;

		if (mal>0) // remove this line for highlighting top level menus

		{

			mc[mal].backgroundColor = bc;

			mc[mal].color = fc;

		}



		mal++;

	}





}



// return the name of the menu which contains x,y

function overMenu(x,y)

{

	x -= gx;

	y -= gy;

	for (i=0; i < mal; i++)

	{

		var el = d.getElementById(ma[i]);

		if (el.offsetLeft + el.offsetWidth > x && el.offsetLeft <= x

		&& el.offsetTop + el.offsetHeight > y && el.offsetTop <= y)

		{

			return ma[i];

		}

	}

	return "";

}



// the cursor has left a menu or a button

// tidy away menus that the cursor isnt over or arnt parents of a menu the cursor is over

// the parents are identified by having a name that starts the same as the child

// eg if the child is called menu2_3_1 the parent would be called menu2_3

function tidyMenu(e)

{

	if (NS4) return;



	t = overMenu(event.clientX + d.body.scrollLeft-d.body.clientLeft, event.clientY + d.body.scrollTop-d.body.clientTop);



	om = 0;

	for (i=0; i < mal; i++)

	{

		var mail = ma[i].length;

		if (mail > t.length || t.substring(0, mail) != ma[i])

		{

			var el = d.getElementById(ma[i]);



			if(el.mainMenuElement)

			{

				shouldResetClickMode = true;



				setTimeout("reset_clickMode();", 500);



				el.mainMenuElement.className = 'menu_root';

			}



			el.style.visibility = "hidden";

			mc[i].backgroundColor = "";

			mc[i].color = "";



			if (ifr)

			{

				var p = d.getElementById(ma[i] + "i");



				if (p)

				{

					p.style.display="none";

				}

			}

		}

		else

		{

			ma[om] = ma[i];

			mx[om] = mx[i];

			my[om] = my[i];

			om++;

		}

	}

	mal = om;



	// replace the button graphic

	if (mal == 0 && psrc) psrc.src = pname;

}



function reset_clickMode()

{

	if(shouldResetClickMode)

	{

		clickMode = false;

	}

}





