///////////////////////////////////////////////////////////////////////
//     This slidebar script was designed by Erik Arvidsson for WebFX //
//                                                                   //
//     For more info and examples see: http://webfx.eae.net          //
//     or contact Erik at http://webfx.eae.net/contact.html#erik     //
//                                                                   //
//     Feel free to use this code as lomg as this disclaimer is      //
//     intact.                                                       //
///////////////////////////////////////////////////////////////////////

var dragobject = null;
var type;
var onchange = "";
var tx;
var ty;


function getReal(el, type, value) {
	temp = el;
	while ((temp != null) && (temp.tagName != "BODY")) {
		if (eval("temp." + type) == value) {
			el = temp;
			return el;
		}
		temp = temp.parentElement;
	}
	return el;
}

function moveme_onmousedown() {
	var tmp = getReal(window.event.srcElement, "className", "sliderHandle");	//Traverse the element tree
	if(tmp.className == "sliderHandle") {
		dragobject = tmp;			//This is a global reference to the current dragging object

		onchange = dragobject.getAttribute("onchange");	//Set the onchange function
		if (onchange == null) onchange = "";
		type = dragobject.getAttribute("type");			//Find the type

		if (type=="y")		//Vertical
			ty = (window.event.clientY - dragobject.style.pixelTop);
		else				//Horizontal
			tx = (window.event.clientX - dragobject.style.pixelLeft);

		window.event.returnValue = false;
		window.event.cancelBubble = true;
	}
	else {
		dragobject = null;	//Not draggable
	}	
}

function moveme_onmouseup() {
	if(dragobject) {
		dragobject = null;
	}
}

function moveme_onmousemove() {
	if(dragobject) {
		if (type=="y") {
			if(event.clientY >= 0) {
				if ((event.clientY - ty >= 0) && (event.clientY - ty <= dragobject.parentElement.offsetHeight - dragobject.offsetHeight)) {
					dragobject.style.top = event.clientY - ty;
				}
				if (event.clientY - ty < 0) {
					dragobject.style.top = "0";
				}
				if (event.clientY - ty > dragobject.parentElement.offsetHeight - dragobject.offsetHeight - 0) {
					dragobject.style.top = dragobject.parentElement.offsetHeight - dragobject.offsetHeight;
				}

				dragobject.value = dragobject.style.pixelTop / (dragobject.parentElement.offsetHeight - dragobject.offsetHeight);
				eval(onchange.replace(/this/g, "dragobject"));
			}
		}
		else {
			if(event.clientX  >= 0) {
				if ((event.clientX  - tx >= 0) && (event.clientX - tx <= dragobject.parentElement.offsetWidth - dragobject.offsetWidth)) {
					dragobject.style.left = event.clientX - tx;
				}
				if (event.clientX - tx < 0) {
					dragobject.style.left = "0";
				}
				if (event.clientX - tx > dragobject.parentElement.clientWidth - dragobject.offsetWidth - 0) {
					dragobject.style.left = dragobject.parentElement.clientWidth - dragobject.offsetWidth;
				}

				dragobject.value = dragobject.style.pixelLeft / (dragobject.parentElement.clientWidth - dragobject.offsetWidth);
				eval(onchange.replace(/this/g, "dragobject"));
			}
		}
		
		
		window.event.returnValue = false;
		window.event.cancelBubble = true;
	} 
}

function setValue(el, val) {
	el.value = val;
	if (el.getAttribute("TYPE") == "x")
		el.style.left =  val * (el.parentElement.clientWidth - el.offsetWidth);
	else
		el.style.top =  val * (el.parentElement.clientHeight - el.offsetHeight);

	eval(el.onchange.replace(/this/g, "el"))
}

document.onmousedown = moveme_onmousedown;
document.onmouseup = moveme_onmouseup;
document.onmousemove = moveme_onmousemove;

document.write('<style type="text/css">\
				.sliderHandle	{position: relative; cursor: default;}\
				</style>');