// budget_row.js - this represents one row within the budget table
// it does not represent a field (field.js) but the interface used
// by a field within a spreadsheet.

// It will clone the mainBudgetTable template row as its DOM node

var mouseOverBg = '#D4D0C8';
var mouseOverGuiBg = '#e5d5f8';
var formulaLinkedBg = '#f0ccf5';

var budget_rows = new Object();

function budget_row(budget_table, index)
{
// clone the TR calling budget_table.getElem (its interface to template guis)

	this.row = budget_table.getElem('tr').cloneNode(true);

// the index

	this.index = index;

	this.row.id = index;

	this.current_field = null;

	this.row.all('numbertd').innerText = this.index;

	this.guiFields = new Object();
	this.checkboxFields = new Object();
	this.valueFields = new Object();

	this.getElem = budget_row_get_elem;
	this.setField = budget_row_set_field;
	this.resetField = budget_row_reset_field;
	this.setTitle = budget_row_set_title;
	this.getTitle = budget_row_get_title;
	this.resetTitle = budget_row_reset_title;
	this.applyNewTitle = budget_row_apply_new_title;
	this.setValue = budget_row_set_value;
	this.addValue = budget_row_add_value;
	this.setContent = budget_row_set_content;
	this.removeValue = budget_row_remove_value;
	this.addGui = budget_row_add_gui;
	this.hasGui = budget_row_has_gui;
	this.addCheckbox = budget_row_add_checkbox;
	this.removeGui = budget_row_remove_gui;
	this.removeCheckbox = budget_row_remove_checkbox;
	this.getNextGui = budget_row_get_next_gui;
	this.getPreviousGui = budget_row_get_previous_gui;
	this.getFirstGui = budget_row_get_first_gui;
	this.getLastGui = budget_row_get_last_gui;
	this.updateIndex = budget_row_update_index;
	this.applyComment = budget_row_apply_comment;
	this.resetComment = budget_row_reset_comment;

	this.getTd = budget_row_get_td;
	this.getDependentTds = budget_row_get_dependent_tds;

	budget_rows[this.index] = this;

	return this;
}

function budget_row_update_index(newIndex)
{
	this.index = newIndex;

	this.row.all('numbertd').innerText = this.index;
}
	

function budget_row_get_td(code)
{
	var td = this.row.all(code);

	return td;
}

function budget_row_get_elem()
{
	return this.row;
}

function budget_row_reset_field()
{
	if(!this.field_obj)
	{
		return;
	}

	this.resetTitle();

	for(var gui_field in this.guiFields)
	{
		this.removeGui(gui_field);
	}

	for(var checkbox_field in this.checkboxFields)
	{
		this.removeCheckbox(checkbox_field);
	}

	for(var value_field in this.valueFields)
	{
		this.removeValue(value_field);
	}

	this.origBgColor = '';
	this.row.bgColor = '';

	this.field_obj = null;

	this.guiFields = new Object();
	this.valueFields = new Object();

	this.resetComment();

}

function budget_row_reset_comment()
{
	var td = this.row.all('titletd');

	td.style.backgroundImage = '';

	this.row.title = '';
}

function budget_row_apply_comment()
{
	var comment = this.field_obj.getCommentValue();

	if(comment!='')
	{
		var td = this.row.all('titletd');

		td.style.backgroundImage = 'url(/images/budgethub/comment_tab.gif)';

		this.row.title = comment;
	}
	else
	{
		this.resetComment();
	}
}

function budget_row_set_field(field_obj)
{
	if(!field_obj)
	{
		return;
	}

	if(this.field_obj)
	{
		this.resetField();

		return;
	}

	this.field_obj = field_obj;

	this.setTitle(field_obj.title);

	field_obj.guiRow = this;

	field_obj.rowAssign(this);

	if(field_obj.currency_code)
	{
		mainBudgetTable.currencyHighlightRow(this);
	}

	this.applyComment();

}

function budget_row_apply_new_title(title)
{
	this.field_obj.title = title;

	this.setTitle(title);
}

function budget_row_get_title()
{
	return this.field_obj.title;
}

function budget_row_set_title(title)
{
	var td = this.row.all('titletd');
	var table = this.row.all('titletable');

	td.innerHTML = title;

	table.onclick = budget_row_title_click;
}

function budget_row_reset_title()
{
	var table = this.row.all('titletable');
	var td = this.row.all('titletd');

	td.innerHTML = '&nbsp;';

	table.onclick = '';
}

function budget_apply_checkbox_src(td, value)
{
	if(value=='remove')
	{
		td.all.cross.style.display = 'none';
		td.all.tick.style.display = 'none';		
	}
	else if(value)
	{
		td.all.cross.style.display = 'none';
		td.all.tick.style.display = 'inline';
	}
	else
	{
		td.all.tick.style.display = 'none';
		td.all.cross.style.display = 'inline';
	}
}

function budget_row_add_checkbox(code, value)
{
	var td = this.row.all(code);

	budget_apply_checkbox_src(td, value);

	td.onclick = budget_row_td_checkbox_click;

	td.style.cursor = 'hand';

	this.checkboxFields[code] = true;
}

function budget_row_get_first_gui()
{
	var nextcode = null;
	var mode = false;

	for(var i=0; i<editTableRow_codes.length; i++)
	{
		var code = editTableRow_codes[i];

		if((this.guiFields[code])&&(!mode))
		{
			nextcode = code;
			mode = true;
		}
	}

	return nextcode;
}

function budget_row_get_last_gui()
{
	var lastcode = null;
	var mode = false;

	for(var i=editTableRow_codes.length-1; i>=0; i--)
	{
		var code = editTableRow_codes[i];

		if((this.guiFields[code])&&(!mode))
		{
			lastcode = code;
			mode = true;
		}
	}

	return lastcode;
}

function budget_row_has_gui(code)
{
	if(this.guiFields[code])
	{
		return true;
	}
	else
	{
		return false;
	}
}

function budget_row_get_next_gui(td)
{
	var currentcode = td.id;
	var nextcode = null;
	var mode = false;

	for(var i=0; i<editTableRow_codes.length; i++)
	{
		var code = editTableRow_codes[i];

		if((mode)&&(this.guiFields[code]))
		{
			nextcode = code;
			mode = false;
		}
		else if(code==currentcode)
		{
			mode = true;
		}
	}

	return nextcode;
}

function budget_row_get_previous_gui(td)
{
	var currentcode = td.id;
	var prevcode = null;
	var mode = false;

	for(var i=editTableRow_codes.length-1; i>=0; i--)
	{
		var code = editTableRow_codes[i];

		if((mode)&&(this.guiFields[code]))
		{
			prevcode = code;
			mode = false;
		}
		else if(code==currentcode)
		{
			mode = true;
		}
	}

	return prevcode;
}

function budget_row_add_gui(code, value)
{
	this.addValue(code, value);

	var td = this.row.all(code);

	td.onclick = budget_row_td_click;
	td.all.contentdiv.style.cursor = 'text';
	td.style.cursor = 'text';

	this.guiFields[code] = true;
}

function budget_row_remove_checkbox(code)
{
	var td = this.row.all(code);

	budget_apply_checkbox_src(td, 'remove');

	td.bgColor = '';

	td.onmouseover = '';
	td.onmouseout = '';
	td.onclick = '';
}

function budget_row_remove_gui(code)
{
	var td = this.row.all(code);

	td.all.contentdiv.style.cursor = 'default';
	td.style.cursor = 'default';

	td.onclick = '';
}

function budget_row_set_content(code, value)
{
	var td = this.row.all(code);

	td.all.contentdiv.innerText = value;

	this.valueFields[code] = true;	
}

function budget_row_add_value(code, value)
{
	this.setValue(code, value);

	var td = this.row.all(code);

	td.onmouseover = budget_row_td_mouseover;
	td.onmouseout = budget_row_td_mouseout;
}

function budget_row_set_value(code, value)
{
	var td = this.row.all(code);

	td.all.contentdiv.innerText = reformat_float(value);

	this.valueFields[code] = true;	
}

function budget_row_remove_value(code)
{
	var td = this.row.all(code);

	td.all.contentdiv.innerText = '';

	td.onmouseover = '';
	td.onmouseout = '';
}

function budget_row_td_mouseover()
{
	var td = event.srcElement;

	while(td.tagName!='TD')
	{
		td = td.parentElement;
	}

	var tr = td.parentElement;

	var budget_row = budget_rows[tr.id];

	var dependentTds = budget_row.getDependentTds(td.id);

	budget_row.dependentTds = dependentTds;

	for(var i=0; i<dependentTds.length; i++)
	{
		var deptd = dependentTds[i];

		deptd.bgColor = formulaLinkedBg;
	}

	var newBg = mouseOverBg;

	if(budget_row.guiFields[td.id])
	{
		newBg = mouseOverGuiBg;
	}

	td.bgColor = newBg;

	var field_obj = budget_row.field_obj;

	var status = field_obj.getComment(td.id);

	top.budget_toolbar.show_toolbar_status(status);
}

function budget_row_get_dependent_tds(tdid)
{
	var field_obj = this.field_obj;

	var tdArray = new Array();

	if(field_obj.type=='sub_total')
	{
		for(var field_id in field_obj.calcFields)
		{
			var child_field = field_obj.calcFields[field_id];

			var td = child_field.guiRow.row.all(tdid);

			tdArray[tdArray.length] = td;
		}
	}
	else if(field_obj.type=='nic')
	{
		if(tdid=='rate')
		{
			for(var field_id in field_obj.calcFields)
			{
				var child_field = field_obj.calcFields[field_id];

				var td = child_field.guiRow.row.all('orig');

				tdArray[tdArray.length] = td;
			}
		}
		else
		{
			var td = this.row.all('rate');

			tdArray[tdArray.length] = td;
		}
	}
	else
	{
		var fieldArray = field_obj.getLinkedFormulaFields(tdid);

		for(var i=0; i<fieldArray.length; i++)
		{
			var field = fieldArray[i];

			var td = this.row.all(field);

			tdArray[tdArray.length] = td;
		}
	}

	return tdArray;
}


function budget_row_td_mouseout()
{
	var td = event.srcElement;

	while(td.tagName!='TD')
	{
		td = td.parentElement;
	}

	var tr = td.parentElement;

	var budget_row = budget_rows[tr.id];

	var dependentTds = budget_row.dependentTds;

	for(var i=0; i<dependentTds.length; i++)
	{
		var deptd = dependentTds[i];

		deptd.bgColor = '';
	}

	budget_row.dependentTds = null;

	td.bgColor = '';

	top.budget_toolbar.hide_toolbar_status();
}

function budget_row_td_checkbox_click()
{
	var td = event.srcElement;

	while(td.tagName!='TD')
	{
		td = td.parentElement;
	}

	var tr = td.parentElement;

	var budget_row = budget_rows[tr.id];

	mainBudgetTable.checkboxClick(budget_row, td, event);
}


function budget_row_td_click()
{
	var td = event.srcElement;

	while(td.tagName!='TD')
	{
		td = td.parentElement;
	}

	var tr = td.parentElement;

	var budget_row = budget_rows[tr.id];

	top.budget_toolbar.select_field(budget_row, td.id);

	mainBudgetTable.selectRow(budget_row, td, event);

	budgetTableInputClick = true;

	return false;
}

function budget_row_title_click()
{
	var elem = event.srcElement;

	while(elem.id!='title')
	{
		elem = elem.parentElement;
	}

	var tr = elem.parentElement;

	var budget_row = budget_rows[tr.id];

	top.budget_toolbar.select_row_title(budget_row);

	mainBudgetTable.highlightRow(budget_row);

	budgetTableInputClick = true;

	return false;
}
