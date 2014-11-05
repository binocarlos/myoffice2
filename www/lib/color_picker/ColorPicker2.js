ColorPicker_targetInput = null;
function ColorPicker_writeDiv() {
	document.writeln("<DIV ID=\"colorPickerDiv\" STYLE=\"position:absolute;visibility:hidden;\"> </DIV>");
	}

function ColorPicker_show(anchorname) {
	this.showPopup(anchorname);
	}

function ColorPicker_pickColor(color,obj) {
	obj.hidePopup();
	pickColor(color);
	}

// A Default "pickColor" function to accept the color passed back from popup.
// User can over-ride this with their own function.
function pickColor(color) {
	if (ColorPicker_targetInput==null) {
		alert("Target Input is null, which means you either didn't use the 'select' function or you have no defined your own 'pickColor' function to handle the picked color!");
		return;
		}
	ColorPicker_targetInput.value = color;

	color_changed(ColorPicker_targetInput.value);
	}

// This function is the easiest way to popup the window, select a color, and
// have the value populate a form field, which is what most people want to do.
function ColorPicker_select(inputobj,linkname) {
	if (inputobj.type!="text" && inputobj.type!="hidden" && inputobj.type!="textarea") { 
		alert("colorpicker.select: Input object passed is not a valid form input object"); 
		window.ColorPicker_targetInput=null;
		return;
		}
	window.ColorPicker_targetInput = inputobj;
	this.show(linkname);
	}
	
// This function runs when you move your mouse over a color block, if you have a newer browser
function ColorPicker_highlightColor(c) {
	var thedoc = (arguments.length>1)?arguments[1]:window.document;
	var d = thedoc.getElementById("colorPickerSelectedColor");
	d.style.backgroundColor = c;
	d = thedoc.getElementById("colorPickerSelectedColorValue");
	d.innerHTML = c;
	}

function ColorPicker() {
	var windowMode = false;
	// Create a new PopupWindow object
	if (arguments.length==0) {
		var divname = "colorPickerDiv";
		}
	else if (arguments[0] == "window") {
		var divname = '';
		windowMode = true;
		}
	else {
		var divname = arguments[0];
		}
	
	if (divname != "") {
		var cp = new PopupWindow(divname);
		}
	else {
		var cp = new PopupWindow();
		cp.setSize(200,150);
		}

	// Object variables
	cp.currentValue = "#FFFFFF";
	
	// Method Mappings
	cp.writeDiv = ColorPicker_writeDiv;
	cp.highlightColor = ColorPicker_highlightColor;
	cp.show = ColorPicker_show;
	cp.select = ColorPicker_select;

	// Code to populate color picker window
	 var colors = new Array("#FF0000","#FFFF00","#00FF00","#00FFFF","#0000FF","#FF00FF","#FFFFFF","#DEDBDE","#C6C3C6","#ADAAAD","#8C8E8C","#737573","#5A595A","#393C39","#212021","#000000",
													"#FF9673","#FFB27B","#FFCF84","#F7FF94","#C6EB94","#A5DF94","#84D394","#8CD7BD","#94D7E7","#9CAED6","#9C92C6","#9C7DBD","#B582BD","#CE8AC6","#FF9ACE","#FF96A5",
													"#FF6139","#FF8E42","#FFB64A","#F7FF63","#A5DF63","#73CF6B","#42BA6B","#4ABEA5","#5AC7DE","#6B8AC6","#6B69B5","#6B45A5","#944DA5","#BD55AD","#FF61B5","#FF617B",
													"#FF2808","#FF5D10","#FF9618","#F7FF29","#7BCF31","#29B239","#009A4A","#00A294","#18AECE","#3961AD","#39349C","#39008C","#6B088C","#9C148C","#FF2894","#FF2852",
													"#AD1800","#AD3800","#AD6110","#A5AA10","#528A18","#187521","#006129","#006D5A","#08718C","#213C73","#212063","#21005A","#42045A","#63085A","#A5145A","#A51831",
													"#7B0C00","#7B2400","#7B4500","#737908","#396110","#105518","#004518","#004942","#085163","#10284A","#10144A","#100042","#290042","#420442","#730C42","#7B0821");
	var total = colors.length;
	var width = 16;
	var cp_contents = "";
	var windowRef = (windowMode)?"window.opener.":"";
	if (windowMode) {
		cp_contents += "<HTML><HEAD><TITLE>Select Color</TITLE></HEAD>";
		cp_contents += "<BODY MARGINWIDTH=0 MARGINHEIGHT=0 LEFMARGIN=0 TOPMARGIN=0><CENTER>";
		}
	cp_contents += "<div class=panelouter><div class=panelinner style=padding:5px;>&nbsp;Choose&nbsp;a&nbsp;colour:<TABLE BORDER=0 CELLSPACING=3 CELLPADDING=0>";
	var use_highlight = (document.getElementById || document.all)?true:false;
	for (var i=0; i<total; i++) {
		if ((i % width) == 0) { cp_contents += "<TR>"; }
		if (use_highlight) { var mo = 'onMouseOver="'+windowRef+'ColorPicker_highlightColor(\''+colors[i]+'\',window.document)"'; }
		else { mo = ""; }
		cp_contents += '<TD BGCOLOR="'+colors[i]+'" onClick="'+windowRef+'ColorPicker_pickColor(\''+colors[i]+'\','+windowRef+'window.popupWindowObjects['+cp.index+']);return false;" '+mo+' STYLE="width:12px; height:12px; border:1px inset; cursor:hand; font-size:1px;"><img src="/images/clear.gif" width="12" height="12"></TD>';
		if ( ((i+1)>=total) || (((i+1) % width) == 0)) { 
			cp_contents += "</TR>";
			}
		}
	// If the browser supports dynamically changing TD cells, add the fancy stuff
	if (document.getElementById) {
		var width1 = width;
		cp_contents += "<TR><TD COLSPAN='"+width+"'><div ID='colorPickerSelectedColor' style='border:1px inset; height:14px;'></div><div ID='colorPickerSelectedColorValue' style='display:none;'>#FFFFFF</div></td></TR>";
		}
	cp_contents += "</TABLE></div>";
	if (windowMode) {
		cp_contents += "</CENTER></BODY></HTML>";
		}
	// end populate code

	// Write the contents to the popup object
	cp.populate(cp_contents+"\n");
	// Move the table down a bit so you can see it
	cp.offsetY = -30;
	cp.offsetX = -50;
	cp.autoHide();
	return cp;
	}
