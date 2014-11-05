var toolbar_selected_row = null;
var toolbar_selected_field = null;
var tinput = null;
var input_mode = '';
var input_orig_value = '';
var non_edit_fields = new Array('field_title_input', 'tick_button', 'cross_button', 'currency_button', 'comment_button');

function show_toolbar_status(text)
{
	if(toolbar_selected_row)
	{
		return;
	}

	document.getElementById('budget_toolbar_status_span').innerHTML = text;
	document.getElementById('budget_toolbar_status').style.display = 'inline';
}

function hide_toolbar_status()
{
	document.getElementById('budget_toolbar_status').style.display = 'none';
}

function show_toolbar(field_obj)
{
	var edit_mode = 'inline';

	if((field_obj.type=='sub_total')||(field_obj.type=='nic'))
	{
		edit_mode = 'none';
	}

	hide_toolbar_status();
	document.getElementById('budget_toolbar_table').style.display = 'inline';

	for(var i=0; i<non_edit_fields.length; i++)
	{
		var hidefield = non_edit_fields[i];

		document.getElementById(hidefield).style.display = edit_mode;
	}

	top.content.page.budgetToolbarValueChanged = false;
}

function hide_toolbar()
{
	input_mode = '';
	tinput.value = '';
	toolbar_selected_row = null;
	toolbar_selected_field = null;
	top.content.page.budgetToolbarValueChanged = false;

	top.budgetHub_set_selected_row(null);

	document.getElementById('budget_toolbar_currency_span').innerHTML = '';

	document.getElementById('budget_toolbar_table').style.display = 'none';
}

function toolbar_init()
{
	tinput = document.getElementById('toolbar_input');
}	

function select_field(budget_row, key)
{
	toolbar_selected_row = budget_row;
	toolbar_selected_field = key;

	var value = budget_row.field_obj.getInputValue(key);

	tinput.value = value;
	input_orig_value = value;

	var comment = budget_row.field_obj.getComment(key);

	document.getElementById('budget_toolbar_currency_span').innerHTML = comment;

	show_toolbar(budget_row.field_obj);

	input_mode = 'field';

	top.budgetHub_set_selected_row(budget_row);
}

function select_row_title(budget_row)
{
	toolbar_selected_row = budget_row;

	var title = budget_row.getTitle();

	tinput.value = title;
	input_orig_value = title;

	show_toolbar(budget_row.field_obj);

	input_mode = 'title';

	top.budgetHub_set_selected_row(budget_row);
}

function accept_field_input()
{
	if(toolbar_selected_row)
	{
		top.content.page.budget_table_input_change();
		top.content.page.budget_table_input_blur();
	}
}

function accept_title_input()
{
	if(toolbar_selected_row)
	{
		var new_title = tinput.value;

		input_orig_value = new_title;

		toolbar_selected_row.applyNewTitle(new_title);
		top.content.page.budget_table_input_blur();
	}
}

function accept_input()
{
	if(input_mode=='title')
	{
		accept_title_input();
	}

	if(input_mode=='field')
	{
		accept_field_input();
	}
}

function update_row_field(value)
{
	tinput.value = value;
}

function toolbar_input_keyup()
{
	var code = event.keyCode;

	if(code==13) 	// is it the enter key?
	{
		accept_input();

		return false;
	}
	else if(code==27)	// is it the escape key?
	{
		tinput.value = input_orig_value;

		top.content.page.budget_table_update_input_value(tinput.value);

		return false;
	}
	else if(code==9)	// is it the tab key?
	{
		return false;
	}
	else if(input_mode=='field')
	{
		top.content.page.budget_table_update_input_value(tinput.value);
		top.content.page.budgetToolbarValueChanged = true;
	}
}

function cancel_input()
{
	tinput.value = input_orig_value;

	toolbar_input_keyup();
}

function toolbar_ensure_budget_table_focus()
{
	top.content.page.budget_table_toolbar_focus();
}

function delete_budget_row()
{
	var loc = href + '&method=show_delete_confirm';

	var status = top.budgetHub_show_modal_window(loc, 450, 250);

	if(status=='delete')
	{
		top.content.page.mainBudgetTable.deleteRow(toolbar_selected_row);
	}
}

function edit_budget_row_position()
{
	var loc = href + '&method=field_position_modal'

	loc += '&position=' + toolbar_selected_row.index;
	loc += '&type=' + toolbar_selected_row.field_obj.type;
	loc += '&title=' + toolbar_selected_row.field_obj.title;

	var obj = top.budgetHub_show_modal_window(loc, 450, 250);

	if(obj)
	{
		top.content.page.mainBudgetTable.moveRowPosition(toolbar_selected_row, obj.position);
	}
}

function edit_row_comment()
{
	var loc = href + '&method=field_comment_modal';

	var args = null;

	if(toolbar_selected_row)
	{
		loc += '&title=' + toolbar_selected_row.field_obj.title;

		args = toolbar_selected_row.field_obj.getCommentValue();
	}

	var obj = top.budgetHub_show_modal_window(loc, 450, 250, args);

	top.content.page.mainBudgetTable.changeComment(obj);
}

function add_budget_row()
{
	var loc = href + '&method=field_detail_modal&window_title=Add Field';

	if(toolbar_selected_row)
	{
		var paramIndex = toolbar_selected_row.index + 1;

		loc += '&position=' + paramIndex;
	}

	var obj = top.budgetHub_show_modal_window(loc, 450, 250);

	if(obj)
	{
		top.content.page.mainBudgetTable.insertRow(obj);
	}
}

function change_row_currency()
{
	if(!toolbar_selected_row)
	{
		return;
	}

	var loc = href + '&method=field_currency_modal&title=' + toolbar_selected_row.field_obj.title;

	loc += '&currency_code=' + toolbar_selected_row.field_obj.currency_code;

	var obj = top.budgetHub_show_modal_window(loc, 450, 250);

	if(obj)
	{
		obj.rate = parseFloat(obj.rate);
		top.content.page.mainBudgetTable.changeCurrency(obj);
	}
}
