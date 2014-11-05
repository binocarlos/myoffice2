// sub_question_editor.js
//
// This file is responsible for creating and managing the in-memory
// javascript representation of the mainTableRow, contentCell, questionInput and questionComponent objects
//
// Object files used by this are:
//
// mainTableRow.js
// contentCell.js
// questionInput.js
// questionComponent.js


// selectedContentCell is the currently selected contentCell object

var selectedContentCell = null;

//////////////////////////////////////////
// This is called once the page is loaded to create the initial gui
//////////////////////////////////////////

function initialiseGUI(subQuestionId)
{
	for(var i=0; i<mainTableRowArray.length; i++)
	{
		var tableRow = mainTableRowArray[i];

		tableRow.checkMP3Count();
		tableRow.checkHeight();
		tableRow.checkMarks();

		document.getElementById('mainEditArea').appendChild(tableRow.tableElem);
	}

	// tells top that there is a subQuestion loaded
	// This also resets the subQuestionSaved
	top.setCurrentSubQuestionId(subQuestionId);

	// ensures that when the body is clicked - the selected cell is de-selected
	document.body.onclick = deselectContentCell;

	// resets top.currentSubQuestionId (which means that the toolbar buttons won't work)
	document.body.onunload = bodyUnloaded;

	// shows the ruler
	parent.showRuler();

	parent.loadEditorToolbar();
}

//////////////////////////////////////////
// Resets top.currentSubQuestionId - renders the sub-question toolbar useless
//////////////////////////////////////////

function bodyUnloaded()
{
	top.currentSubQuestionId = null;
	parent.hideRuler();
}

//////////////////////////////////////////
// Returns the next avaliable layoutId within this subQuestion
//////////////////////////////////////////

function getNextLayoutId()
{
	nextLayoutId++;

	return nextLayoutId;
}

//////////////////////////////////////////
// Delselects the currently selected Cell (only if one is selected)
//////////////////////////////////////////

function deselectContentCell()
{
	if(selectedContentCell!=null)
	{
		selectedContentCell.tdElem.className = 'editor_td';
		selectedContentCell.selected = false;
		selectedContentCell = null;

		var toolbar = top.content.page.title;

		toolbar.setTdAlign('left');
		toolbar.setTdVAlign('middle');
		toolbar.setTdWidth(null);
		toolbar.setTdHeight(null);
	}
}


//////////////////////////////////////////
// Selects the given contentCell object - if the contentCell given is currently selected
// - it will deselect instead
//////////////////////////////////////////

function selectContentCell(contentCell)
{
	var sameCell = false;

	// sameCell indicates whether the existing selection is the same as the new one
	// and therefore simply deselect

	if((selectedContentCell!=null)&&(selectedContentCell.id==contentCell.id)) { return; }

	deselectContentCell();

	selectedContentCell = contentCell;
	selectedContentCell.selected = true;
	selectedContentCell.tdElem.className = 'editor_td_on';

	var tableRow = selectedContentCell.getTableRow();

	var toolbar = top.content.page.title;

	toolbar.setTdAlign(selectedContentCell.align);
	toolbar.setTdVAlign(selectedContentCell.valign);
	toolbar.setTdWidth(selectedContentCell.width);
	toolbar.setTdHeight(tableRow.height);
}

//////////////////////////////////////////
// Deletes the selected contentCell
//////////////////////////////////////////

function deleteContentCell()
{
	if(!selectedContentCell) { return; }

	top.setSubQuestionSaved(false);

	var cellToDelete = selectedContentCell;

	var tableRow = mainTableRows[cellToDelete.rowId];

	if(tableRow.contentCellArray.length<=1) { return; }

	deselectContentCell();

	tableRow.removeContentCell(cellToDelete);
}

//////////////////////////////////////////
// Inserts a contentCell into the currently selected Row at the given position
//////////////////////////////////////////

function insertContentCell(positionGap)
{
	if(!selectedContentCell) { return; }

	top.setSubQuestionSaved(false);

	var currentPosition = selectedContentCell.position;

	if(positionGap>0) { currentPosition++; }

	var tableRow = mainTableRows[selectedContentCell.rowId];

	var newId = getNextLayoutId();

	var newContentCell = new contentCell(newId, tableRow.id);

	tableRow.addContentCell(newContentCell, currentPosition);
}

//////////////////////////////////////////
// Deletes the currently selected mainTableRow
//////////////////////////////////////////

function deleteTableRow()
{
	if(!selectedContentCell) { return; }

	top.setSubQuestionSaved(false);

	var tableRow = mainTableRows[selectedContentCell.rowId];

	if(mainTableRowArray.length<=1) { return; }

	deselectContentCell();

	var newArray = new Array();

	for(var i=0; i<mainTableRowArray.length; i++)
	{
		var nextRow = mainTableRowArray[i];

		if(nextRow.id!=tableRow.id)
		{
			newArray.push(nextRow);
			nextRow.position = newArray.length;
		}
	}

	mainTableRowArray = newArray;

	document.getElementById('mainEditArea').removeChild(tableRow.tableElem);
}


//////////////////////////////////////////
// Inserts a mainTableRow into the given position
//////////////////////////////////////////

function insertTableRow(positionGap)
{
	if(!selectedContentCell) { return; }

	top.setSubQuestionSaved(false);

	var tableRow = mainTableRows[selectedContentCell.rowId];

	var currentPosition = tableRow.position;

	if(positionGap>0) { currentPosition++; }

	var rowId = getNextLayoutId();

	var newRow = new mainTableRow(rowId, null, true);

	var cellId = getNextLayoutId();

	var newCell = new contentCell(cellId, newRow.id);

	newRow.addContentCell(newCell);

	if(currentPosition==mainTableRowArray.length+1)
	{
		newRow.position = currentPosition;

		mainTableRowArray.push(newRow);

		document.getElementById('mainEditArea').appendChild(newRow.tableElem);
	}
	else
	{
		var existingRow = mainTableRowArray[currentPosition-1];

		var newArray = new Array();

		for(var i=0; i<mainTableRowArray.length; i++)
		{
			var nextRow = mainTableRowArray[i];

			if(nextRow.id==existingRow.id)
			{
				newArray.push(newRow);
				newRow.position = newArray.length;
			}

			newArray.push(nextRow);
			nextRow.position = newArray.length;
		}

		existingRow.tableElem.insertAdjacentElement("beforeBegin",newRow.tableElem);

		mainTableRowArray = newArray;
	}
}

//////////////////////////////////////////
// Generates the XML packet for this subQuestion
//////////////////////////////////////////

function getSubQuestionXML()
{
	var packet = "<subQuestion>\n";

	for(var i=0; i<mainTableRowArray.length; i++)
	{
		var tableRow = mainTableRowArray[i];

		packet += tableRow.getXMLPacket();
	}

	packet += "</subQuestion>";
	
	return packet;
}

//////////////////////////////////////////
// sets the form value to the XML before submitting
//////////////////////////////////////////

function saveSubQuestion()
{
	top.setSubQuestionSaved(true);
	
	var packet = getSubQuestionXML();

	document.sub_question_form.layout_packet.value = packet;
	document.sub_question_form.submit();
}

//////////////////////////////////////////
// Adds a comment to the current contentCell
//////////////////////////////////////////

function previewSubQuestion()
{
	var packet = getSubQuestionXML();	

	var query = '&method=tests_sub_question_preview_redirect&title=Preview Part';

	var ret = get_modal_window_return(query, 720, 470, packet);
}

//////////////////////////////////////////
// Changes the width for the contentCell
//////////////////////////////////////////

function tdWidthChange(newValue)
{
	if(!selectedContentCell) { return; }

	top.setSubQuestionSaved(false);

	selectedContentCell.setWidth(newValue);
}

//////////////////////////////////////////
// Changes the height for the mainTableRow (belonging to the selected Cell)
//////////////////////////////////////////

function tdHeightChange(newValue)
{
	if(!selectedContentCell) { return; }

	top.setSubQuestionSaved(false);

	var tableRow = selectedContentCell.getTableRow();

	tableRow.setHeight(newValue);
}

//////////////////////////////////////////
// Changes the alignment for the contentCell
//////////////////////////////////////////

function tdAlignChange(newValue)
{
	if(!selectedContentCell) { return; }

	top.setSubQuestionSaved(false);

	selectedContentCell.setAlign(newValue);
}

//////////////////////////////////////////
// Changes the Vertical alignment for the contentCell
//////////////////////////////////////////

function tdVAlignChange(newValue)
{
	if(!selectedContentCell) { return; }

	top.setSubQuestionSaved(false);

	selectedContentCell.setVAlign(newValue);
}

//////////////////////////////////////////
// Adds a comment to the current contentCell
//////////////////////////////////////////

function editCellContents()
{
	if(!selectedContentCell) { return; }

	var query;

	if(selectedContentCell.component)
	{
		query = '&method=tests_question_component_form&question_component_id=' + selectedContentCell.componentId;
	}
	else if(selectedContentCell.input)
	{
		query = '&method=tests_question_input_form&question_input_id=' + selectedContentCell.inputId;
	}
	else
	{
		query = '&method=tests_question_choose_component_type';
	}

	query += '&title=Edit Cell Contents';

	var returnData = get_modal_window_return(query, 550, 400);

	if(returnData)
	{
		top.setSubQuestionSaved(false);

		var newObj;

		if(returnData.type=='component')
		{
			newObj = new questionComponent(returnData.id, 'component', returnData.hasMP3, returnData.htmlText);
		}

		if(returnData.type=='input')
		{
			newObj = new questionInput(returnData.id, 'input', returnData.marks, returnData.htmlText);
		}

		if(newObj)
		{
			selectedContentCell.reapplyComponent(newObj);
		}
	}
}

//////////////////////////////////////////
// Modal Window Methods
//////////////////////////////////////////

function show_modal_window(loc, width, height, args)
{
	width += 20;
	height += 20;

	var props = 'center:yes;status:no;resizable:no;dialogWidth:' + width + 'px;dialogHeight:' + height + 'px;help:no;scroll:no;status:no;';
	
	if(args==null) { args = 'nctest'; }

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
