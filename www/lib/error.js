document._error_messages = new Array();
var w;

function doError(msg,url,ln) {
	var _error_obj = {msg : msg, url : url, ln : ln};

	document._error_messages[document._error_messages.length] = _error_obj;

	str = ""
	str += "<title>Error</title>"
	str += "<script>window.onload=new Function('showError()');"
	str += 'var nr=0;'
	str += 'function next() {'
	str += '   nr=Math.min(window.opener.document._error_messages.length-1,nr+1);'
	str += '   showError();'
	str += '}'
	str += 'function previous() {'
	str += '   nr=Math.max(0,nr-1);'
	str += '   showError();'
	str += '}'
	str += 'function showError() {'
	str += '   errorArray = window.opener.document._error_messages;'
	str += '   if (errorArray.length != 0 && nr >= 0 && nr < errorArray.length) {'
	str += '      url.innerText = errorArray[nr].url;'
	str += '      msg.innerText = errorArray[nr].msg;'
	str += '      ln.innerText = errorArray[nr].ln;'
	str += '   }'
	str += '}</script>'
	str += "<style>"
	str += "body, td {background:#d4d0c8; color: black; border:0px; font-family: tahoma, arial, helvitica; font-size: 11px; margin:20px;}"
	str += "button {color: black; font-family:tahoma, arial; font-size:11px; height:23px;  width:75px;}"
	str += "</style>"
	str += '<body scroll="no">'
	str += '<TABLE WIDTH="100%" BORDER="0" CELLPADDING="0" CELLSPACING="0"><TR><TD VALIGN="TOP" WIDTH="58"><img src="/images/error.gif" width="38" height="34"><br><br><br></TD>'
	str += '<TD ALIGN="LEFT" VALIGN="TOP"><b>An error ocurred in the application</b><br>This may prevent the application from functioning</TD></TR></TABLE>'
	str += '<table style="width: 100%;" cellspacing=0 cellpadding=0 border=0><tr><td>'
	str += '<button name="showerror" onclick=\'if (infoArea.style.display!="block") {infoArea.style.display = "block";window.resizeTo(380,275);this.innerText="Hide Error";}else {infoArea.style.display="none";window.resizeTo(380,145);this.innerText="Show Error";}\'>Show Error</button>'
	str += '</td><td align="RIGHT"><button onclick="window.close()">Ok</button>'
	str += '</td></tr></table>'
	str += '<div id="infoArea" style="display: none;">'
	str += '<div id="info"><br>'
	str += '<table style="width: 100%; border:1px black solid;" cellspacing=5 cellpadding=0 border=0>'
	str += '<tr><td><p>URL:</p></td><td><p id="url"></p></td></tr>'
	str += '<tr><td><p>Message:</p></td><td><p id="msg"></p></td></tr>'
	str += '<tr><td><p>Line:</p></td><td><p id="ln"></p></td></tr>'
	str += '</table><br>'
	str += '</div>'
	str += '<table style="width: 100%;" cellspacing=0 cellpadding=0 border=0><tr><td>'
	str += '<button onclick="previous()">Previous</button>'
	str += '</td><td align=right><button onclick="next()">Next</button>'
	str += '</td></tr></table>'
	str += '</div>'
	str += '</body>'

	if (!w || w.closed) {
		w = window.open("","error_win","width=370,height=120");
		var d = w.document;
		d.open();
		d.write(str);
		d.close();
		w.focus();
	}
	return true;

}



window.onerror = doError