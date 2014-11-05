/// The width, title and field arrays describe properties of the spreadsheet
/// Override these in a different application for a different field structure.

var editTableRow_widths = new Array(0, 35, 35, 35, 35, 35, 65, 65, 65, 35, 65, 30, 30, 35);
var editTableRow_titles = new Array("Field", "For", "Item", "Rate", "OTH", "OTR", "Org", "Ext", "Total", "MUp", "T+MUp", "NI", "WD", "WD T");
var editTableRow_codes = new Array("title", "for", "itemLabel", "rate", "ot_hrs", "ot_rate", "orig", "extra", "total", "markup", "markup_total", "nic", "wdays", "wdays_total");

var editTableRow_code_titles = new Object();

/// Overall props - totalWidth applies to table to ensure widths
/// initialBudgetRows defines how many rows will be created by default

var totalWidth = 0;
var initialBudgetRows = 25;
var budgetRow_selected_bg_color = '#f5f0cc';
var budgetRow_currency_bg_color = '#e5f5cc';

/// Holding variables

var wasEscPressed = false;
var nextTabbedTd = null;
var toolbarBlurOveride = false;
var inputOriginalValue = '';
var budgetTableInputClick = false;
var budgetToolbarValueChanged = false;



for(var i=0; i<editTableRow_widths.length; i++)
{
	var code = editTableRow_codes[i];
	var title = editTableRow_titles[i];

	totalWidth += editTableRow_widths[i];

	editTableRow_code_titles[code] = title;
}

top.editTableRow_code_titles = editTableRow_code_titles;

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
/// Budget Table - this class represents the spreadsheet interface as a whole.
/// It will create the actual interface of cells and control the one input element.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table()
{
	// Initialise the table rows;
	this.rows = new Array();
	this.rowCount = initialBudgetRows;

	this.selectedRow = null;
	this.selectedCode = null;

// Create the actual table element & properties

	var table = document.createElement('table');
	var tbody = document.createElement('tbody');

// give the tbody an id so we can get to it after cloning the table
	
	table.appendChild(tbody);

	table.border = 1;
	table.cellSpacing = 0;
	table.cellPadding = 0;
	table.borderColor = '#808080';
	table.className = 'g';

// clone the table ready for the title tr to be appended

//	the document.onclick is the replacement for the input's blur

	document.onclick = budget_table_input_blur;
	document.body.style.backgroundColor = '#ffffff';

//	table.width = totalWidth + 15;

	// Now creating the title TR

	var titletr = document.createElement('tr');

	var blanktd = document.createElement('td');

	blanktd.className = 'tdp';
	blanktd.bgColor = '#D4D0C8';
	blanktd.style.width = 15;
	blanktd.width = 15;

	titletr.appendChild(blanktd);

	var editTable_total_width = 0;

	// Title Loop

	for(var i=0; i<editTableRow_widths.length; i++)
	{
		var titletd = document.createElement('td');
		titletd.className = 'tdp';

		var width = editTableRow_widths[i];

		if(width>0)
		{
			titletd.style.width = editTableRow_widths[i] + 'px';
			titletd.width = editTableRow_widths[i];
		}

		var title = editTableRow_titles[i];

		if(title=='')
		{
			title = '&nbsp;';
		}

		var titletable = '' 
		+ '<TABLE WIDTH="100%" BORDER="0" CELLPADDING="0" CELLSPACING="0">'
		+ '<TR>'
		+ '<TD CLASS="gh" NOWRAP="NOWRAP">'
		+ title
		+ '</TD>'
		+ '</TR>'
		+ '</TABLE>';

		titletd.innerHTML = titletable;

		titletr.appendChild(titletd);
	}

	tbody.appendChild(titletr);

// Making the Main TR (to be copied);

	var mainTr = document.createElement('tr');

// NumberTD & Title TD are the first two grey tds in each budget row

	var numbertd = document.createElement('td');
	numbertd.className = 'tdp';

	var titletd = numbertd.cloneNode(true);

	var numbertable = '' 
	+ '<TABLE WIDTH="100%" BORDER="0" CELLPADDING="0" CELLSPACING="0">'
	+ '<TR>'
	+ '<TD align="right" CLASS="gh" id="numbertd" NOWRAP="NOWRAP">'
	+ '&nbsp;'
	+ '</TD>'
	+ '</TR>'
	+ '</TABLE>';

	var titletable = '' 
	+ '<TABLE WIDTH="100%" BORDER="0" CELLPADDING="0" CELLSPACING="0" id="titletable">'
	+ '<TR>'
	+ '<TD CLASS="gh" id="titletd" NOWRAP="NOWRAP" style="cursor:hand;">'
	+ '&nbsp;'
	+ '</TD>'
	+ '</TR>'
	+ '</TABLE>';

	numbertd.innerHTML = numbertable;
	titletd.innerHTML = titletable;
	titletd.id = 'title';
	numbertd.id = 'number';

	mainTr.appendChild(numbertd);
	mainTr.appendChild(titletd);

	// Now the Title & Number TDS are on the MainTR 
	// (the template for all spreadsheet rows)

	// Create the checkbox img span ready for each of the cells that need it

	var checkboxImgCross = document.createElement('IMG');

	checkboxImgCross.width = 14;
	checkboxImgCross.height = 14;
	checkboxImgCross.border = 0;
	checkboxImgCross.style.display = 'none';
	checkboxImgCross.id = 'cross';

	checkboxImgCross.src = '/images/holiday/cross.gif';

	var checkboxImgTick = document.createElement('IMG');

	checkboxImgTick.width = 14;
	checkboxImgTick.height = 14;
	checkboxImgTick.border = 0;
	checkboxImgTick.style.display = 'none';
	checkboxImgTick.id = 'tick';

	checkboxImgTick.src = '/images/holiday/tick.gif';

	var checkboxImgSpan = document.createElement('SPAN');

	checkboxImgSpan.appendChild(checkboxImgCross);
	checkboxImgSpan.appendChild(checkboxImgTick);

	// Now we loop through each colomn, adding the td to the MainTR

	for(var i=1; i<editTableRow_widths.length; i++)
	{
		var id = editTableRow_codes[i];

		// Create the TD

		var blanktd = document.createElement('td');
		blanktd.id = id;
		blanktd.align = 'right';

		// Create the ContentDiv (The element to contain the actual content)

		var contentdiv = document.createElement('SPAN');
		contentdiv.style.overflowX = 'hidden';

		var width = editTableRow_widths[i];

		if(width>0)
		{
			width -= 10;

			contentdiv.style.width = width + 'px';
			contentdiv.width = width;
		}

		contentdiv.id = 'contentdiv';

		// check to see if a copy of the 

		if((id=='nic')||(id=='wdays'))
		{
			var newCheckboxSpan = checkboxImgSpan.cloneNode(true);

			contentdiv.appendChild(newCheckboxSpan);
		}

		blanktd.appendChild(contentdiv);

		mainTr.appendChild(blanktd);
	}

	var input = document.createElement("INPUT");

	input.type = 'text';
	input.className = 'budgetHubInput';
	input.style.top = '-200px';
	input.bgColor = '#ffffff';


//	input.onblur = budget_table_input_blur;
	input.onchange = budget_table_input_change;
	input.onkeydown = budget_table_input_keydown;
	input.onkeyup = budget_table_input_keyup;

	document.body.appendChild(input);

	this.table = table;
	this.tbody = tbody;
	this.tr = mainTr;
	this.input = input;
	this.checkboxImgSpan = checkboxImgSpan;

	this.currentDepartment = null;

	this.generateRows = budget_table_generate_rows;
	this.generateRow = budget_table_generate_row;
	this.getElem = budget_table_get_elem;

	this.setDepartment = budget_table_set_department;
	this.resetDepartment = budget_table_reset_department;

	this.selectRow = budget_table_select_row;
	this.insertRow = budget_table_insert_row;
	this.deleteRow = budget_table_delete_row;
	this.moveRowPosition = budget_table_move_row;
	this.changeCurrency = budget_table_change_currency;
	this.changeComment = budget_table_change_comment;
	this.currencyHighlightRow = budget_table_currency_highlight_row;
	
	this.highlightRow = budget_table_highlight_row;
	this.unHighlightRow = budget_table_unhighlight_row;
	this.checkboxClick = budget_table_checkbox_click;
	this.calcFieldObject = budget_table_calc_field_object;

	this.generateRows();

	return this;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Generate Rows - this will append the budget_row.getElem (which is a tr)
// to the actual table - the row itself is got from generateRow
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_generate_rows()
{
	for(var i=1; i<=this.rowCount; i++)
	{
		var row = this.generateRow(i);

		this.rows[i] = row;

		this.tbody.appendChild(row.getElem());
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// GEnerateRow - this will create a new budget_row to be added to
// the table (spreadsheet)
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_generate_row(rowcount)
{
	var budget_row_obj = new budget_row(this, rowcount);

	return budget_row_obj;
}


//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// getElem - this is used as an accessor for the template gui parts
//	this.table = table;
//	this.tbody = tbody;
//	this.tr = mainTr;
//	this.input = input;
//	this.checkboxImgSpan = checkboxImgSpan;
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_get_elem(part)
{
	if(!part)
	{
		return this.table;
	}
	else
	{
		return this[part];
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// this is the method called to apply a department (and its fields)
// to the spreadsheet.

// It is also responsible for assigning the total / nic fields.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_set_department(department_obj)
{
// reset the currently assigned department
// (sometimes this is the current one when re-ordering fields etc)
	if(this.currentDepartment)
	{
		this.resetDepartment();
	}

	this.currentDepartment = department_obj;

// this is now the main loop of fields
// it will apply each field to a budget_row
// it will assign each cost to a total_field and nic_field
// it loops backwards to catch the order

	var currentSubTotal;
	var currentNicTotal;
	var prevField = null;

	var department_total = department_obj.totalField;

	var recalculate_array = new Array(department_total);

	var cycle_array = department_obj.field_array;

	var deptTotalIndex = cycle_array.length;
	var deptTotalRowIndex = deptTotalIndex + 2;
	var deptTotalRow = this.rows[deptTotalRowIndex];
	
	deptTotalRow.setField(department_total);

	department_total.budgetRow = deptTotalRow;

	for(var i=cycle_array.length-1; i>=0; i--)
	{
		var field_obj = cycle_array[i];

		field_obj.deptIndex = i;

		if((field_obj.type=='sub_total')||(field_obj.type=='nic'))
		{
			recalculate_array[recalculate_array.length] = field_obj;
		}

		var rowIndex = i+1;

		if((field_obj.type=='simple_cost')||(field_obj.type=='time_cost'))
		{
			department_total.addField(field_obj);

			if(currentSubTotal)
			{
				currentSubTotal.addField(field_obj);
			}

			if(field_obj.type=='time_cost')
			{
				if(currentNicTotal)
				{
					currentNicTotal.addField(field_obj);
				}
			}
		}
		else if(field_obj.type=='sub_total')
		{
			currentSubTotal = field_obj;			
		}
		else if(field_obj.type=='nic')
		{
			currentNicTotal = field_obj;

			department_total.addField(field_obj);

			if(currentSubTotal)
			{
				currentSubTotal.addField(field_obj);
			}
		}

		var budget_row = this.rows[rowIndex];

		budget_row.setField(field_obj);
	}

	for(var i=recalculate_array.length-1; i>=0; i--)
	{
		var field_obj = recalculate_array[i];

		field_obj.calculateAll();

		field_obj.update();		
	}

	department_obj.applyTotalField();
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will remove the currentDepartment from the spreadsheet
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_reset_department()
{
	if(!this.currentDepartment)
	{
		return;
	}

	var department_obj = this.currentDepartment;

	var cycle_array = this.currentDepartment.field_array;

	for(var i=0; i<cycle_array.length; i++)
	{
		var field_obj = cycle_array[i];
		var brow = field_obj.guiRow;

		if((field_obj.type=='sub_total')||(field_obj.type=='nic'))
		{
// REmove all of the dependent fields from totals

			field_obj.resetFields();
		}

// Disassciate the field from the budget_row

		brow.resetField();

		field_obj.guiRow = null;
	}

// Remove the total field

	var department_total = department_obj.totalField;

	var totalbrow = department_total.budgetRow;

	department_total.resetFields();

	totalbrow.resetField();

	department_total.guiRow = null;
	department_total.budgetRow = null;

// Remove the currentDepartment

	this.currentDepartment = null;
	this.selectedRow = null;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is called to swap two rows (i.e. move one rows position)
// It will swap them in the linked list, call re-build field array
// and then reapply the department
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_move_row(focusrow, destIndex)
{
	var destinationrow = this.rows[destIndex];

// check that where you are swapping to is a valid place

	if((!destinationrow)||(!destinationrow.field_obj)||(destinationrow.field_obj.isDepartmentTotal))
	{
		alert('please choose a valid row to move this field to.');

		return;
	}

	var focusfield = focusrow.field_obj;

// and from which department

	var selectedDept = this.currentDepartment;

// lets remove the focus from the interface

	budget_table_input_blur();

// and then remove the department from the spreadsheet

	this.resetDepartment();

// actually swap the twos fields within the department

	selectedDept.moveField(focusfield, destIndex);

// and then reapply the department to the spreadsheet

	this.setDepartment(selectedDept);

// finally make sure that this deletion can be saved.

	top.budgetHub_budget_changed();
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is called to delete a row, the row and field will be removed
// It is called by passing the selected row from the toolbar.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_delete_row(row)
{

// what is the field_obj to be deleted?

	var field_obj = row.field_obj;

// and from which department

	var selectedDept = this.currentDepartment;

// lets remove the focus from the interface

	budget_table_input_blur();

// and then remove the department from the spreadsheet

	this.resetDepartment();

// actually remove the field from the department

	selectedDept.deleteField(field_obj);

// and then reapply the department to the spreadsheet

	this.setDepartment(selectedDept);

// finally make sure that this deletion can be saved.

	top.budgetHub_budget_changed();
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is called with a obj of params to
// create a new field object, assign it to the department
// and then re-apply the department to the spreadsheet.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_insert_row(obj)
{
	if(obj.position>this.rows.length)
	{
		alert('The Position Is Longer Than the Spreadsheet, please try again');

		return;
	}

// which department to add the field to

	var selectedDept = this.currentDepartment;

// remove the focus from the interface

	budget_table_input_blur();

// remove the department from the spreadsheet

	this.resetDepartment();

// actually insert the field

	selectedDept.insertNewField(obj);

// reapply the department to the spreadsheet

	this.setDepartment(selectedDept);

// ensure this addition can be saved

	top.budgetHub_budget_changed();
}



function budget_table_change_comment(text)
{
	var selectedField = mainBudgetTable.selectedRow.field_obj;

	selectedField.setValue('comment', text);

	mainBudgetTable.selectedRow.applyComment();

	top.budgetHub_budget_changed();
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_change_currency(obj)
{
	if(obj.action=='error')
	{
		alert(obj.text);

		return;
	}

	var selectedField = mainBudgetTable.selectedRow.field_obj;

	if(obj.action=='norate')
	{
		selectedField.resetCurrency();
	}
	else if(obj.action=='ratechange')
	{
		selectedField.setCurrency(obj.country_code, obj.rate);
	}

	mainBudgetTable.calcFieldObject(selectedField, true);

	mainBudgetTable.currencyHighlightRow(mainBudgetTable.selectedRow);

	top.editBudget.addCurrency(obj.country_code, obj.rate);
	top.budgetHub_budget_changed();

	budget_table_input_blur();
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This acts as the input.onblur i.e. when the document is clicked
// it checks whether the value of the toolbar input has changed
// and class input.onchange (because setting the input value with script
// does not seem to fire this event).
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


function budget_table_input_blur()
{
	if(budgetToolbarValueChanged)
	{
		budget_table_input_change();
	}

	if(!budgetTableInputClick)
	{
		var input = mainBudgetTable.input;

		input.style.top = '-100px';

		wasEscPressed = false;

		// the unhighlight row will also hide the toolbar

		mainBudgetTable.unHighlightRow();

		if(nextTabbedTd)
		{
			nextTabbedTd.click();

			nextTabbedTd = null;
		}
	}
	else
	{
		budgetTableInputClick = false;
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will update the input as a result of the toolbar input changing
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_update_input_value(val)
{
	mainBudgetTable.input.value = val;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This reacts to the user having pressed a key within the main input
// Its role is to update the value of the input in the toolbar.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_input_keyup()
{
// get the code

	var code = event.keyCode;

	var input = mainBudgetTable.input;

// Make sure they didn't press Enter, Esc or Tab

	if((code!=13)&&(code!=27)&&(code!=9))
	{
		top.budget_toolbar.update_row_field(input.value);
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This reacts to the user having relesed a key within the main input
// Its role is to check for the Esc, Enter and Tab keys
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_input_keydown()
{
	var code = event.keyCode;

	var input = mainBudgetTable.input;
////////////////////
////////////////////
// is it the enter key?
////////////////////
////////////////////
	if(code==13)
	{
		budget_table_input_change();
		budget_table_input_blur();

		return false;
	}
////////////////////
////////////////////
// is it the escape key?
////////////////////
////////////////////
	else if(code==27)
	{
		wasEscPressed = true;

		budget_table_input_blur();

		return false;
	}
////////////////////
////////////////////
// is it the down key
////////////////////
////////////////////
	else if(code==40)
	{
		var currentRow = mainBudgetTable.selectedRow;

// and what column is current selected

		var currentIndex = currentRow.index;
		var nextSelectedIndex = null;
		var mode = false;

// Loop through the fields until we find a simple_cost or time_cost

		while(!mode)
		{
			currentIndex++;

			var nextRow = mainBudgetTable.rows[currentIndex];

			if((nextRow)&&(nextRow.field_obj))
			{
				if(nextRow.hasGui(mainBudgetTable.selectedCode))
				{
					nextSelectedIndex = currentIndex;

					mode = true;
				}
			}

			if(currentIndex>=mainBudgetTable.rows.length)
			{
				currentIndex = 0;
			}
		}

// if nextSelectedIndex then we have the next row to tab to, otherwise, lets not worry.

		if(nextSelectedIndex)
		{
// we now know the row, so lets get the first td within in using getFirstGui

			var nextRow = mainBudgetTable.rows[nextSelectedIndex];

			var nextTd = nextRow.row.all(mainBudgetTable.selectedCode);

			nextTabbedTd = nextTd;
		}


// we call budget_table_input_change because when they tab, they have also confirmed.

		budget_table_input_change();

// we then call blur to remove the focus from here

		budget_table_input_blur();

		return false;

	}
////////////////////
////////////////////
// is it the up key
////////////////////
////////////////////
	else if(code==38)
	{
		var currentRow = mainBudgetTable.selectedRow;

// and what column is current selected

		var currentIndex = currentRow.index;
		var prevSelectedIndex = null;
		var mode = false;

// Loop through the fields until we find a simple_cost or time_cost

		while(!mode)
		{
			currentIndex--;

			var prevRow = mainBudgetTable.rows[currentIndex];

			if((prevRow)&&(prevRow.field_obj))
			{
				var prevType = prevRow.field_obj.type;

				if(prevRow.hasGui(mainBudgetTable.selectedCode))
				{
					prevSelectedIndex = currentIndex;

					mode = true;
				}
			}

			if(currentIndex<0)
			{
				currentIndex = mainBudgetTable.rows.length-1;
			}
		}

// if nextSelectedIndex then we have the next row to tab to, otherwise, lets not worry.

		if(prevSelectedIndex)
		{
// we now know the row, so lets get the first td within in using getFirstGui

			var prevRow = mainBudgetTable.rows[prevSelectedIndex];

			var prevTd = prevRow.row.all(mainBudgetTable.selectedCode);

			nextTabbedTd = prevTd;
		}


// we call budget_table_input_change because when they tab, they have also confirmed.

		budget_table_input_change();

// we then call blur to remove the focus from here

		budget_table_input_blur();

		return false;

	}
////////////////////
////////////////////
// is it the left key
////////////////////
////////////////////
	else if(code==37)
	{
		var currentRow = mainBudgetTable.selectedRow;

// and what column is current selected

		var currentTd = currentRow.row.all(mainBudgetTable.selectedCode);

// call the getNextGui command to see if the next tab is on this row

		var prevTdCode = currentRow.getPreviousGui(currentTd);

// is this was good, we have the nextTd from the current row via nextTdCode

		if(prevTdCode)
		{
			var prevTd = currentRow.row.all(prevTdCode);

			nextTabbedTd = prevTd;
		}
		else
		{
// Otherwise we need to get the next row for the nextTd

			var currentIndex = currentRow.index;
			var prevSelectedIndex = null;
			var mode = false;

// Loop through the fields until we find a simple_cost or time_cost

			while(!mode)
			{
				currentIndex--;

				var prevRow = mainBudgetTable.rows[currentIndex];

				if((prevRow)&&(prevRow.field_obj))
				{
					var prevType = prevRow.field_obj.type;

					if((prevType=='time_cost')||(prevType=='simple_cost'))
					{
						prevSelectedIndex = currentIndex;

						mode = true;
					}
				}

				if(currentIndex<0)
				{
					currentIndex = mainBudgetTable.rows.length-1;
				}
			}

// if nextSelectedIndex then we have the next row to tab to, otherwise, lets not worry.

			if(prevSelectedIndex)
			{
// we now know the row, so lets get the first td within in using getFirstGui

				var prevRow = mainBudgetTable.rows[prevSelectedIndex];

				var prevTdCode = prevRow.getLastGui();

				var prevTd = prevRow.row.all(prevTdCode);

				nextTabbedTd = prevTd;
			}
		}

// we call budget_table_input_change because when they tab, they have also confirmed.

		budget_table_input_change();

// we then call blur to remove the focus from here

		budget_table_input_blur();

		return false;

	}
////////////////////
////////////////////
// is it the tab key (or the right arrow key)
////////////////////
////////////////////
	else if((code==9)||(code==39))
	{

// what is the current row

		var currentRow = mainBudgetTable.selectedRow;

// and what column is current selected

		var currentTd = currentRow.row.all(mainBudgetTable.selectedCode);

// call the getNextGui command to see if the next tab is on this row

		var nextTdCode = currentRow.getNextGui(currentTd);

// is this was good, we have the nextTd from the current row via nextTdCode

		if(nextTdCode)
		{
			var nextTd = currentRow.row.all(nextTdCode);

			nextTabbedTd = nextTd;
		}
		else
		{
// Otherwise we need to get the next row for the nextTd

			var currentIndex = currentRow.index;
			var nextSelectedIndex = null;
			var mode = false;

// Loop through the fields until we find a simple_cost or time_cost

			while(!mode)
			{
				currentIndex++;

				var nextRow = mainBudgetTable.rows[currentIndex];

				if((nextRow)&&(nextRow.field_obj))
				{
					var nextType = nextRow.field_obj.type;

					if((nextType=='time_cost')||(nextType=='simple_cost'))
					{
						nextSelectedIndex = currentIndex;

						mode = true;
					}
				}

				if(currentIndex>=mainBudgetTable.rows.length)
				{
					currentIndex = 0;
				}
			}

// if nextSelectedIndex then we have the next row to tab to, otherwise, lets not worry.

			if(nextSelectedIndex)
			{
// we now know the row, so lets get the first td within in using getFirstGui

				var nextRow = mainBudgetTable.rows[nextSelectedIndex];

				var nextTdCode = nextRow.getFirstGui();

				var nextTd = nextRow.row.all(nextTdCode);

				nextTabbedTd = nextTd;
			}
		}

// we call budget_table_input_change because when they tab, they have also confirmed.

		budget_table_input_change();

// we then call blur to remove the focus from here

		budget_table_input_blur();

		return false;
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is the function that will respond to clicking
// a checkbox
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_checkbox_click(row, td, event)
{
// get the field obj from the budget_row

	var field_obj = row.field_obj;

// reverse the value

	var value = field_obj.getValue(td.id);

	value = !value;

	field_obj.setValue(td.id, value);

	budget_apply_checkbox_src(td, value);

	if(field_obj.getValue('orig')==0)
	{
		return;
	}

	if((td.id=='nic')&&(field_obj.nicField))
	{
		field_obj.nicField.calculate(field_obj, true);

		field_obj.nicField.update();

		if(field_obj.nicField.totalField)
		{
			field_obj.nicField.totalField.calculate(field_obj.nicField);
			field_obj.nicField.totalField.update();
		}

		field_obj.mainTotalField.calculate(field_obj.nicField);

		field_obj.mainTotalField.update();

		field_obj.department.applyTotalField();
	}
	else if(td.id=='wdays')
	{
		mainBudgetTable.calcFieldObject(field_obj);

		top.budgetHub_budget_changed();
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This function is called via the default events and also from other functions.
// It signifies that the user input has changed and that it should apply the
// value to formulas and totals.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_input_change()
{

// Lets make sure, that we have a selectedRow and that we know the column in that row
// Also that Esc wasn't pressed in which case we dont want this method

	if((mainBudgetTable.selectedRow)&&(mainBudgetTable.selectedCode)&&(!wasEscPressed))
	{
// So the value has changed and we need to apply it

		var stringvalue = mainBudgetTable.input.value;

// Lets check it really has changed.

		if(stringvalue==inputOriginalValue)
		{
			return;
		}

		var value = parseFloat(stringvalue);

// if the input is bad, an alert and blur follows.

		if(isNaN(value))
		{
			alert(stringvalue + ' is not a number, please re-enter');

			budget_table_input_blur();

			return;
		}

// This setValue is automatically apply setOldValue;

		var currentRow = mainBudgetTable.selectedRow;

// we now apply the value to the field object.

		var fieldObj = currentRow.field_obj;

		var key = mainBudgetTable.selectedCode;

		fieldObj.setInputValue(key, value);

// set the value from the input into the budget_row

		currentRow.setValue(key, fieldObj.getValue(key));

// We now want to calculate the field

		mainBudgetTable.calcFieldObject(fieldObj);

		top.budgetHub_budget_changed();

	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is responsible for ensuring the right order of
// calculate is completed.
// The field object must arrive having had the changed
// value already set.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_calc_field_object(field_obj, fullAssign)
{
	if((field_obj.type=='sub_total')||(field_obj.type=='nic'))
	{
		return;
	}

	field_obj.calculate();

	field_obj.update(fullAssign);

	if(!field_obj.hasChanged())
	{
		return;
	}

	if(field_obj.totalField)
	{
		field_obj.totalField.calculate(field_obj);

		field_obj.totalField.update();
	}

	if(field_obj.nicField)
	{
		field_obj.nicField.calculate(field_obj);

		field_obj.nicField.update();

		if(field_obj.nicField.totalField)
		{
			field_obj.nicField.totalField.calculate(field_obj.nicField);
			field_obj.nicField.totalField.update();
		}

		field_obj.mainTotalField.calculate(field_obj.nicField);
	}


	field_obj.mainTotalField.calculate(field_obj);

	field_obj.mainTotalField.update();

	field_obj.department.applyTotalField();
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This applies the focus to a selected row
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
function budget_table_currency_highlight_row(row)
{
	if(row.field_obj.currency_code)
	{
		row.row.bgColor = budgetRow_currency_bg_color;
		row.origBgColor = budgetRow_currency_bg_color;
	}
	else
	{
		row.row.bgColor = '';
		row.origBgColor = '';
	}
}

function budget_table_highlight_row(row)
{
	if(this.selectedRow)
	{
		this.selectedRow.row.bgColor = this.selectedRow.origBgColor;
	}

	this.selectedRow = row;	

	row.origBgColor = row.row.bgColor;

	row.row.bgColor = budgetRow_selected_bg_color;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This removes the focus from a selected row
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function budget_table_unhighlight_row()
{
	if(this.selectedRow)
	{
// remove the toolbar

		top.budget_toolbar.hide_toolbar();

// reset the rows bgColor

		this.selectedRow.row.bgColor = this.selectedRow.origBgColor;

		this.selectedRow = null;
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is the budget table function that
// will respond the clicking an input TD.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


function budget_table_select_row(row, td, event)
{	
	var input = this.input;

// get the field_obj associated with the budget_row

	var field_obj = row.field_obj;

// assign the input values

	input.value = field_obj.getInputValue(td.id);

	inputOriginalValue = input.value;

// the following code makes the input hover over the TD
// that was clicked.

// This involves calculating the offSet (x and y) between the
// event and the top left of the TD.
// Also, using clientWidth/Height, it adjusts the size of the
// input to fit.

	input.style.width = td.clientWidth;
	input.style.height = td.clientHeight;

	var srcElem = event.srcElement;

	var extraX = 0;
	var extraY = 0;

	if(srcElem.tagName=='SPAN')
	{
		extraX = srcElem.offsetLeft;
		extraY = srcElem.offsetTop;
	}

	var tdX = event.clientX - event.offsetX - extraX + document.body.scrollLeft;
	var tdY = event.clientY - event.offsetY - extraY + document.body.scrollTop;

	input.style.left = tdX;
	input.style.top = tdY;

	input.focus();
	input.select();

// call highlightRow to select the row

	this.highlightRow(row);

	this.selectedRow = row;	
	this.selectedCode = td.id;
}

