function hidestatus()
{
window.status=' ';
return true
}
//if (document.layers)
//document.captureEvents(Event.MOUSEOVER | Event.MOUSEOUT)
//document.onmouseover=hidestatus;
//document.onmouseout=hidestatus;
//document.onmousedown=hidestatus;
//document.onmouseup=hidestatus;
//document.onclick=hidestatus;
//document.ondblclick=hidestatus;

function set_status(text,timeoutClear)
{
	clearTimeout();
	top.window.status = text;
	if(timeoutClear)
	{
		setTimeout("set_status(' ');", 5000);
	}
}

/*
var message="";

function clickIE() {if (document.all) {(message);return false;}}
function clickNS(e) {if
(document.layers||(document.getElementById&&!document.all)) {
if (e.which==2||e.which==3) {(message);return false;}}}
if (document.layers)
{document.captureEvents(Event.MOUSEDOWN);document.onmousedown=clickNS;}
else{document.onmouseup=clickNS;document.oncontextmenu=clickIE;}

document.oncontextmenu=new Function("return false")

function disableselect(e){
return false
}
function reEnable(){
return true
}
document.onselectstart=new Function ("return false")

if (window.sidebar){
document.onmousedown=disableselect
document.onclick=reEnable
}
*/