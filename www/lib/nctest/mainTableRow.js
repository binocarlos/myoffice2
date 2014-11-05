// mainTableRow.js
//
// This represents on main row within a sub-question and will contain
// contentCell objects

var editorRowHeight = 60;

var mainTableRows = new Object();
var mainTableRowArray = new Array();

function mainTableRow(id, height, noarray)
{
	this.id = id;
	this.height = height;

	this.contentCellArray = new Array();
	this.position = mainTableRowArray.length + 1;

	mainTableRows[this.id] = this;

	if(!noarray)
	{
		mainTableRowArray.push(this);
	}

	this.generateGUI = mainTableRow_generateGUI;
	this.addContentCell = mainTableRow_addContentCell;
	this.removeContentCell = mainTableRow_removeContentCell;
	this.getXMLPacket = mainTableRow_getXMLPacket;
	this.checkMP3Count = mainTableRow_checkMP3Count;
	this.checkMarks = mainTableRow_checkMarks;
	this.checkHeight = mainTableRow_checkHeight;
	this.setHeight = mainTableRow_setHeight;

	this.generateGUI();
}

//////////////////////////////////////////
// removes the given contentCell from this row
//////////////////////////////////////////

function mainTableRow_removeContentCell(contentCell)
{
	if(this.contentCellArray.length<=1) { return; }

	var newArray = new Array();

	for(var i=0; i<this.contentCellArray.length; i++)
	{
		var nextCell = this.contentCellArray[i];

		if(nextCell.id!=contentCell.id)
		{
			newArray.push(nextCell);

			nextCell.position = newArray.length;
		}
	}

	this.contentCellArray = newArray;

	this.trElem.removeChild(contentCell.tdElem);
}

//////////////////////////////////////////
// Adds a contentCell to this row
// If position is given - then the current Array is spliced and re-created
// Otherwise it is a simple addition onto the end of the row and array
//////////////////////////////////////////

function mainTableRow_addContentCell(contentCell, position)
{
	if((!position)||(position==this.contentCellArray.length+1))
	{
		contentCell.position = this.contentCellArray.length + 1;

		this.contentCellArray.push(contentCell);

		this.trElem.appendChild(contentCell.tdElem);
	}
	else
	{
		var existingCell = this.contentCellArray[position-1];

		var newArray = new Array();

		for(var i=0; i<this.contentCellArray.length; i++)
		{
			var nextCell = this.contentCellArray[i];

			if(nextCell.id==existingCell.id)
			{
				newArray.push(contentCell);
				contentCell.position = newArray.length;	
			}

			newArray.push(nextCell);
			nextCell.position = newArray.length;
		}

		existingCell.tdElem.insertAdjacentElement("beforeBegin",contentCell.tdElem);

		this.contentCellArray = newArray;
	}
}

//////////////////////////////////////////
// Generates the Table and TR elements for this mainTableRow
//////////////////////////////////////////
//
//
//<!-- Row Start -->
//<table cellpadding="0" cellspacing="0" border="0" width="100%">
//<tr>
//	<td class="leftcol"><div class="sound"><img src="sound_off.gif" title="Play" border="0"></div></td>
//	<td valign="top" align="left">
//
//	<table cellpadding="0" cellspacing="0" border="0" width="100%">
//	<tr>
//		<td width="100%"><div class="comment">Some children are making ice lollies.<br><br>The children cool the liquid. It changes into ice.</div></td>
//	</tr>
//	</table>
//
//	</td>
//  <td class="rightcol"><div class="marks">2 marks</div></td>
//</tr>
//</table>
//<!-- Row End -->
//
//
//////////////////////////////////////////

function mainTableRow_generateGUI()
{
	// The main table containing everything in this row
	var mainTable = document.createElement("TABLE");
	mainTable.cellPadding = 0;
	mainTable.cellSpacing = 0;
	mainTable.border = 0;
	mainTable.width = "100%";

	// The table body
	var mainTableBody = document.createElement("TBODY");
	mainTable.appendChild(mainTableBody);

	// The main table row, split into 3 cols -> sound, cells, marks
	var mainTableTr = document.createElement("TR");
	mainTableBody.appendChild(mainTableTr);

		// The sound td -> contains a div -> img
		var soundTd = document.createElement("TD");
		soundTd.className = "editor_leftcol";
		mainTableTr.appendChild(soundTd);

			var soundDiv = document.createElement("DIV");
			soundDiv.className = "editor_sound";
			soundTd.appendChild(soundDiv);

				var soundImg = document.createElement("IMG");
				soundImg.border = 0;
				soundImg.src = soundImgSrc;
				soundImg.style.display = 'none';
				soundDiv.appendChild(soundImg);

		// The editor Td -> contains the editor table
		var editorTd = document.createElement("TD");
		editorTd.align = "left";
		editorTd.vAlign = "top";
		mainTableTr.appendChild(editorTd);

			// the editorTable -> split into X cells
			var editorTable = document.createElement("TABLE");
			editorTable.cellPadding = 0;
			editorTable.cellSpacing = 0;
			editorTable.border = 0;
			editorTable.width = "100%";
			editorTd.appendChild(editorTable);

			var editorTableBody = document.createElement("TBODY");
			editorTable.appendChild(editorTableBody);

			var rowHeight = editorRowHeight;

			if(this.height!=null) { rowHeight = this.height; }

			// This is the tr that contentCells will attach to
			var editorTableTr = document.createElement("TR");
			editorTableTr.height = rowHeight;
			editorTableBody.appendChild(editorTableTr);

		// The marks TD -> contains the marks comment
		var marksTd = document.createElement("TD");
		marksTd.className = "editor_rightcol";
		mainTableTr.appendChild(marksTd);

			var marksDiv = document.createElement("DIV");
			marksDiv.className = "editor_marks";
			marksTd.appendChild(marksDiv);


	this.tableElem = mainTable;
	this.trElem = editorTableTr;
	this.soundImg = soundImg;
	this.soundTd = soundTd;
	this.marksDiv = marksDiv;
}

//////////////////////////////////////////
// sets the height of this tableRow
//////////////////////////////////////////

function mainTableRow_setHeight(value)
{
	if(value!='')
	{
		var parsedValue = parseInt(value);

		if(isNaN(parsedValue))
		{
			alert('The height must be an integer');
			return;
		}

		this.height = value;
		this.trElem.height = value;
	}
	else
	{
		this.height = null;
		this.checkHeight();
	}
}

//////////////////////////////////////////
// Checks what height the editor should apply to this row
// If the row contains a contentCell with contents - then the height is not set
// If the row contains no contentCell's with contents - the height is set to editorRowHeight
// If the row.height property is set - it leaves the height alone
//////////////////////////////////////////

function mainTableRow_checkHeight()
{
	// Is there a height set? if so then we don't need to do nothing
	if(this.height!=null) { return; }

	var contentCount = 0;

	for(var i=0; i<this.contentCellArray.length; i++)
	{
		var contentCell = this.contentCellArray[i];

		if(contentCell.component)
		{
			contentCount++;
		}

		if(contentCell.input)
		{
			contentCount++;
		}
	}

	if(contentCount>0)
	{
		this.trElem.height = '';
	}
	else
	{
		this.trElem.height = editorRowHeight;
	}
}

//////////////////////////////////////////
// adds up all the marks that are present within inputs on this row
// if the marks add up to more than 0 - it will add the comment to the
// row - otherwise it will clear the comment
//////////////////////////////////////////

function mainTableRow_checkMarks()
{
	var totalMarks = 0;
	for(var i=0; i<this.contentCellArray.length; i++)
	{
		var contentCell = this.contentCellArray[i];

		if(contentCell.input)
		{
			totalMarks += contentCell.input.marks;
		}
	}

	if(totalMarks>0)
	{
		this.marksDiv.innerHTML = '(' + totalMarks + ' marks)';
	}
	else
	{
		this.marksDiv.innerHTML = '';
	}
}

//////////////////////////////////////////
// checks whether there are any MP3's within components on this row - if there are, show the MP3 image
// if there arn't - hide the MP3 image
//
// If there is more than one MP3 on the row - show a warning and set the TD to red
//
// afterEdited indicates whether this has been called after a component has been edited
// and therefore the alert shouldn't be shown
//////////////////////////////////////////

function mainTableRow_checkMP3Count(afterEdited)
{
	var MP3Count = 0;

	for(var i=0; i<this.contentCellArray.length; i++)
	{
		var contentCell = this.contentCellArray[i];

		if(contentCell.component)
		{
			if(contentCell.component.hasMP3)
			{
				MP3Count++;
			}
		}
	}

	if(MP3Count==0)
	{
		this.soundTd.style.backgroundColor = '';
		this.soundImg.style.display = 'none';
	}
	else if(MP3Count==1)
	{
		this.soundTd.style.backgroundColor = '#ffffff';
		this.soundImg.style.display = 'inline';
	}
	else
	{
		this.soundTd.style.backgroundColor = '#ff8888';
		this.soundImg.style.display = 'inline';

		if(afterEdited)
		{
			alert('This row has more than 1 MP3 file associated with it - please delete one');
		}
	}
}

//////////////////////////////////////////
// gets the XML representing this mainTableRow - calls getXMLPacket for each contentCell also
//////////////////////////////////////////

function mainTableRow_getXMLPacket()
{
	var packet = "	<mainTableRow";

	if(this.height!=null)
	{
		packet += ' height="' + this.height + '"';
	}
	
	packet += ">\n";

	for(var i=0; i<this.contentCellArray.length; i++)
	{
		var contentCell = this.contentCellArray[i];

		packet += contentCell.getXMLPacket();
	}

	packet += "	</mainTableRow>\n";

	return packet;
}

