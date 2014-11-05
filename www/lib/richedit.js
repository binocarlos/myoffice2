
function initRichEdit(el) {
	if (el.id) {	// needs an id to be accessible in the frames collection
		el.frameWindow = document.frames[el.id];
		if (el.value == null)
			el.value = el.innerHTML;
		
		if ( el.value.replace(/\s/g, "") == "" )
			el.value = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n" +
				"\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n" +
				"<html>\n" +
				"<head>\n<title></title>\n</head>\n<body>\n</body>\n</html>";
					
//		el.src = "/templates/blank.htm";
		var d = el.frameWindow.document;
		d.designMode = "On";
		d.open();
		d.write(el.value);
		d.close();
		
		el.supportsXHTML = el.frameWindow.document.documentElement && el.frameWindow.document.childNodes != null;
		
		// set up the expandomethods
		
		// first some basic
		
		el.setHTML = function (sHTML) {
			el.value = sHTML;
			initRichEdit(el);
		}
		
		el.getHTML = function () {
			// notice that IE4 cannot get the document.documentElement so we'll use the body
			return el.frameWindow.document.body.innerHTML;
			// for IE5 the following is much better. If you don't want IE4 compatibilty modify this
			//return el.frameWindow.document.documentElement.outerHTML;
		}

		el.getXHTML = function () {
			if (!el.supportsXHTML) {
				alert("Document root node cannot be accessed in IE4.x");
				return;
			}
			else if (typeof window.StringBuilder != "function") {
				alert("StringBuilder is not defined. Make sure to include stringbuilder.js");
				return;
			}
			
			
			var sb = new StringBuilder;
			// IE5 and IE55 has trouble with the document node
			var cs = el.frameWindow.document.childNodes;
			var l = cs.length;
			for (var i = 0; i < l; i++)
				_appendNodeXHTML(cs[i], sb);
		
			return sb.toString();
		};
		el.setText = function (sText) {
			el.value = sText.replace(/\&/g, "&amp;").replace(/\</g, "&lt;").replace(/\>/g, "&gt;").replace(/\n/g, "<br>");
			initRichEdit(el);
		}
		
		el.getText = function () {
			// notice that IE4 cannot get the document.documentElement so we'll use the body
			// not hat it matters when it comes to innerText :-)
			return el.frameWindow.document.body.innerText;
		}

		// and now some text manipulations
		
		el.execCommand = function (execProp, execVal, bUI) {
			return execCommand(this, execProp, execVal, bUI);
		}	
		el.setBold = function () {
			return this.execCommand("bold");
		}
		el.setItalic = function () {
			return this.execCommand("italic");
		}
		el.setUnderline = function () {
			return this.execCommand("underline");
		}
		el.setBackgroundColor = function(sColor) {
			return this.execCommand("backcolor", sColor);
		}
		el.setColor = function(sColor) {
			return this.execCommand("forecolor", sColor);
		}
		el.surroundSelection = function(sBefore, sAfter) {
			var r = this.getRange();
			if (r != null)
				r.pasteHTML(sBefore + r.htmlText + sAfter);
		};
		el.getRange = function () {
			var doc = this.frameWindow.document;
			var r = doc.selection.createRange();
			if (doc.body.contains(r.parentElement()))
				return r;
			// can happen in IE55+
			return null;
		};

		/* modifies the enter keyup event to generate BRs. */

		/* Enabled by default */
		

		
			el.frameWindow.document.onkeydown = function () { 
				if (el.frameWindow.event.keyCode == 13) {	// ENTER
					var sel = el.frameWindow.document.selection;
					if (sel.type == "Control")
						return;
					
					var r = sel.createRange();	
					r.pasteHTML("<BR>");
					el.frameWindow.event.cancelBubble = true; 
					el.frameWindow.event.returnValue = false; 

					r.select();
					r.moveEnd("character", 1);
					r.moveStart("character", 1);
					r.collapse(false);
					
					return false;
				}
			};
			el.frameWindow.document.onkeypress = 
			el.frameWindow.document.onkeyup = function () { 
				if (el.frameWindow.event.keyCode == 13) {	// ENTER
					el.frameWindow.event.cancelBubble = true;
					el.frameWindow.event.returnValue = false;
					return false;
				}
			};			
		
		// Add your own or use the execCommand method.
		// See msdn.microsoft.com for commands

		// call oneditinit if defined
		if (typeof el.oneditinit == "string")
			el.oneditinit = new Function(el.oneditinit);
		if (typeof el.oneditinit == "function")
			el.oneditinit();
	}
	
	function execCommand(el, execProp, execVal, bUI) {
		var doc = el.frameWindow.document;
		var type = doc.selection.type;
		var oTarget = type == "None" ? doc : doc.selection.createRange();
		var r = oTarget.execCommand(execProp, bUI, execVal);
		if (type == "Text")
			oTarget.select();
		return r;
	}
}

function richEditInsertLink(id)
{
	var props = 'status:no;resizable:yes;dialogWidth:250px;dialogHeight:150px;help:no;scroll:no;status:no;';

	var newloc = top.href + '&method=siteeditor_link_input&appname=sitemanager';

	var ret = window.showModalDialog(newloc, null, props);

	if(ret)
	{
		el = document.getElementById('component' + id);

		var r = el.getRange();

		var target = "";

		if(ret.win=='new')
		{
			target = ' target="_blank"';
		}

		if((!ret.url.match(/^http/i))&&(!ret.url.match(/^\//)))
		{
			ret.url = 'http://' + ret.url;	
		}

		if (r != null)
		{
			var text = r.htmlText;

			if(text=='')
			{
				text = ret.url;
			}

			r.pasteHTML('<a href="' + ret.url + '"' + target + '>' + text + '</a>');
		}
	}
}
