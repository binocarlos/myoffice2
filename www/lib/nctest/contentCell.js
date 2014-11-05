// contentCell.js
//
// This represents one cell within the sub-question editor and will
// contain questionInput or questionComponent objects

var contentCells = new Object();

function contentCell(id, rowId, componentId, inputId, align, valign, width)
{
	this.id = id;
	this.rowId = rowId;
	this.componentId = componentId;
	this.inputId = inputId;
	this.align = align;
	this.valign = valign;
	this.width = width;

	if(this.componentId>0)
	{
		this.component = questionComponents[this.componentId];
	}

	if(this.inputId>0)
	{
		this.input = questionInputs[this.inputId];
	}

	if(!this.align) { this.align = 'left'; }
	if(!this.valign) { this.valign = 'middle'; }

	contentCells[this.id] = this;

	this.generateGUI = contentCell_generateGUI;
	this.mouseClicked = contentCell_mouseClicked;
	this.mouseDblClicked = contentCell_mouseDblClicked;
	this.addToTableRow = contentCell_addToTableRow;
	this.getXMLPacket = contentCell_getXMLPacket;
	this.setAlign = contentCell_setAlign;
	this.setVAlign = contentCell_setVAlign;
	this.reapplyComponent = contentCell_reapplyComponent;
	this.getTableRow = contentCell_getTableRow;
	this.setWidth = contentCell_setWidth;

	this.generateGUI();
}

//////////////////////////////////////////
// get the MainTableRow object associated with this contentCell
//////////////////////////////////////////

function contentCell_getTableRow()
{
	var tableRow = mainTableRows[this.rowId];

	return tableRow;
}

//////////////////////////////////////////
// Adds the contentCell to the associated mainTableRow
//////////////////////////////////////////

function contentCell_addToTableRow()
{
	var tableRow = this.getTableRow();

	tableRow.addContentCell(this);
}

//////////////////////////////////////////
// Generates the TD element associated with this contentCell
//////////////////////////////////////////

function contentCell_generateGUI()
{
	this.tdElem = document.createElement("TD");

	this.tdElem.className = 'editor_td';
	this.tdElem.align = this.align;
	this.tdElem.vAlign = this.valign;

	if(this.width)
	{
		this.tdElem.width = this.width;
	}

	this.tdElem.contentCellId = this.id;

	this.tdElem.onclick = this.mouseClicked;
	this.tdElem.ondblclick = this.mouseDblClicked;

	if(this.component)
	{
		this.tdElem.innerHTML = this.component.htmlText;
	}
	else if(this.input)
	{
		this.tdElem.innerHTML = this.input.htmlText;
	}
	else
	{
		this.tdElem.innerHTML = '&nbsp';
	}
}

//////////////////////////////////////////
// Reapplies the given questionComponent / questionInput object to this contentCell
//////////////////////////////////////////

function contentCell_reapplyComponent(component)
{
	if(this.component)
	{
		this.tdElem.innerHTML = '';
		this.component = null;
		this.componentId = null;
	}

	if(this.input)
	{
		this.tdElem.innerHTML = '';
		this.input = null;
		this.inputId = null;
	}

	var tableRow = this.getTableRow();

	if(component.type=='component')
	{
		this.component = component;
		this.componentId = component.id;

		this.tdElem.innerHTML = this.component.htmlText;

		tableRow.checkMP3Count(true);
	}

	if(component.type=='input')
	{
		this.input = component;
		this.inputId = component.id;

		this.tdElem.innerHTML = this.input.htmlText;

		tableRow.checkMarks();
	}

	tableRow.checkHeight();
}

//////////////////////////////////////////
// TD mouseDblClicked - calls editCellContents() for the selectedContentCell
//////////////////////////////////////////

function contentCell_mouseDblClicked()
{
	event.cancelBubble = true;

	if(!selectedContentCell) { return; }

	editCellContents();
}

//////////////////////////////////////////
// TD mouseClicked - calls selectContentCell for this contentCell
//////////////////////////////////////////

function contentCell_mouseClicked()
{
	event.cancelBubble = true;

	var td = event.srcElement;

	while((!td.contentCellId)&&(td.tagName!='BODY'))
	{
		td = td.parentElement;
	}

	if(!td.contentCellId) { return; }

	var contentCell = contentCells[td.contentCellId];

	selectContentCell(contentCell);
}

//////////////////////////////////////////
// gets the XML representing this contentCell
//////////////////////////////////////////

function contentCell_getXMLPacket()
{
	var packet = '		<contentCell align="' + this.align + '" valign="' + this.valign + '"';

	if(this.width)
	{
		packet += ' width="' + this.width + '"';
	}

	if(this.componentId>0)
	{
		packet += ' component_id="' + this.componentId + '"';
	}

	if(this.inputId>0)
	{
		packet += ' input_id="' + this.inputId + '"';
	}

	packet += '>' + "\n";

	packet += "		</contentCell>\n";

	return packet;
}

//////////////////////////////////////////
// sets the contentCell alignment
//////////////////////////////////////////

function contentCell_setAlign(value)
{
	this.align = value;
	this.tdElem.align = value;
}

//////////////////////////////////////////
// sets the contentCell Valignment
//////////////////////////////////////////

function contentCell_setVAlign(value)
{
	this.valign = value;
	this.tdElem.vAlign = value;
}

//////////////////////////////////////////
// sets the contentCell width
//////////////////////////////////////////

function contentCell_setWidth(value)
{
	if(value!='')
	{
		var parsedValue = parseInt(value);

		if(isNaN(parsedValue))
		{
			alert('The width must be an integer');
			return;
		}

		this.width = value;
		this.tdElem.width = value;
	}
	else
	{
		this.width = null;
		this.tdElem.width = '';
	}
}

