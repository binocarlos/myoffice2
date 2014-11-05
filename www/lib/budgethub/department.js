//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
/// Department - this class represents the logical grouping
// of fields - or other departments.
// It is repsponsible for looking after its own total.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


var department_highest_id = 0;
var department_hash = new Object();
var department_array = new Array();

// Department - this represents a group of fields within the budget
// Each department is used by the budget to collate a grand total
// Therefore, the department is responsible for managing all of its
// own field objects.

var grandTotalField = 'markup_total';
var totalFields = new Array("orig", "extra", "total", "markup_total", "wdays_total");

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


function department(id, title, parent_id)
{
	this.id = id;
	this.title = title;
	this.parent_id = parent_id;

	if(this.id>department_highest_id)
	{
		department_highest_id = this.id;
	}

	this.department_array = new Array();
	this.field_array = new Array();
	this.totals = new Object();
	this.old_totals = new Object();

	this.addField = department_add_field;
	this.insertField = department_insert_field;
	this.insertNewField = department_insert_new_field;
	this.deleteField = department_delete_field;
	this.moveField = department_move_field;
	this.createNewField = department_create_new_field;
	this.addDepartment = department_add_department;
	this.hasFields = department_has_fields;
	this.setTotalSpan = department_set_total_span;
	this.setTotal = department_set_total;
	this.getTotal = department_get_total;
	this.createTotalField = department_create_total_field;
	this.assignTotalField = department_assign_total_field;
	this.applyTotalField = department_apply_total_field;
	this.applyChildTotal = department_apply_child_total;
	this.getXml = department_get_xml;

	this.folder = new WebFXTreeItem();
	this.folder.action = "javascript: budget.selectDepartment(" + this.id + ");";
//	this.folder.icon = '';

	department_hash[this.id] = this;
	department_array[department_array.length] = this;

// Create the department total field
// this will be added into the field_array when the department
// is applied to the budget_table

	this.createTotalField();

	return this;
}


//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will swap the positions of the two given fields
// newIndex is passed as the array_index + 1
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_move_field(field_obj, newIndex)
{
	this.deleteField(field_obj);

	this.insertField(field_obj, newIndex);
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will delete a given field from the array
// It will call rebuildFieldArray after to make sure the
// dependencies are still entact
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_delete_field(field_obj)
{
	var oldarray = this.field_array;

	var newarray = new Array();

	for(var i=0; i<oldarray.length; i++)
	{
		var arrfield = oldarray[i];

		if(arrfield.id!=field_obj.id)
		{
			newarray[newarray.length] = arrfield;
		}
	}

	this.field_array = newarray;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will insert a given field into the array
// It will call rebuildFieldArray after to make sure the
// dependencies are still entact
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_insert_field(field_obj, position)
{
	var oldarray = this.field_array;

	var newarray = new Array();

	var fieldAdded = false;

	for(var i=0; i<oldarray.length; i++)
	{
		if(i==(position-1))
		{
			newarray[newarray.length] = field_obj;
			fieldAdded = true;
		}

		var arrfield = oldarray[i];

		newarray[newarray.length] = arrfield;
	}

	if(!fieldAdded)
	{
		newarray[newarray.length] = field_obj;
	}

	this.field_array = newarray;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will create the new field and then insert it using insertField
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_insert_new_field(obj)
{
	var field_obj = this.createNewField(obj);

	if(!field_obj)
	{
		return false;
	}

	field_obj.department = this;

	this.insertField(field_obj, obj.position);
}


//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is used to create a new field with the given params
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_create_total_field()
{
	var obj = new Object();
	obj.type = 'sub_total';
	obj.title = '<b>' + this.title + ' Total</b>';
	obj.parent_code = this.id;

	var total_field = this.createNewField(obj);

	total_field.isDepartmentTotal = true;

	this.totalField = total_field;
}

function department_create_new_field(obj)
{
	var field_obj;

	var type = obj.type;
	var parent_code = this.id;
	var title = obj.title;
	var budget = top.content.sidebar.budget;

	budget.highest_id++;

	var id = budget.highest_id;

	if(type=='simple_cost')
	{
		field_obj = new simpleCost(parent_code, id, title, type);
	}
	else if(type=='time_cost')
	{
		field_obj = new timeCost(parent_code, id, title, type);
		field_obj.setValue('itemLabel', obj.itemLabel);
	}
	else if(type=='nic')
	{
		field_obj = new nicCost(parent_code, id, title, type);
	}
	else if(type=='sub_total')
	{
		field_obj = new totalCost(parent_code, id, title, type);
	}

	return field_obj;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will actually insert the field into the field_array
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_add_field(field_obj)
{
	if(!field_obj)
	{
		alert('department add field where field is null');

		return;
	}

	this.field_array[this.field_array.length] = field_obj;

	field_obj.department = this;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Will make this department a top-level (i.e. with other departments)
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_add_department(department_obj)
{
	if(!department_obj)
	{
		alert('department add department where department is null');

		return;
	}

	this.department_array[this.department_array.length] = department_obj;

	department_obj.parent_department = this;

	this.folder.add(department_obj.folder);
}
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Checks what type this department is (i.e. sub-departments or fields)
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_has_fields()
{
	if(this.field_array.length>0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Will update the departments total span in the left-menutree
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_set_total_span(value)
{
	var link_id = this.folder.id + '-anchor';

	var elem = document.getElementById(link_id);

	elem.innerHTML = '<span style="color:#880000;width:40;text-align:right;">' + Math.round(value) + '</span> - ' + this.title;

	if(this.parent_department)
	{
		this.parent_department.setTotalSpan(this.parent_department.getTotal(grandTotalField));
	}
	else if(this.isTopDepartment)
	{
		budget.setTotalSpan();
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Applies the departmentTotal field object to the actual totals for this department
// It then recurses up the tree to the budget itself
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_apply_total_field()
{
	for(var i=0; i<totalFields.length; i++)
	{
		var field = totalFields[i];

		if(this.parent_department)
		{
			this.parent_department.applyChildTotal(field, this.getTotal(field), this.totalField.getValue(field));
		}

		this.setTotal(field, this.totalField.getValue(field));
	}

	this.setTotalSpan(this.getTotal(grandTotalField));
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is used if the department has child departments
// and their totals change (i.e. the top-level department total update
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_apply_child_total(field, oldValue, newValue)
{
	var current = this.getTotal(field);
	var oldTotal = current;

	current -= oldValue;
	current += newValue;

	if(this.parent_department)
	{
		this.parent_department.applyChildTotal(field, this.getTotal(field), current);
	}
	else if((this.isTopDepartment)&&(field==grandTotalField))
	{
		budget.applyTotal(oldTotal, current);
	}

	this.setTotal(field, current);
}

function department_set_total(key, value, applyField)
{
	this.old_totals[key] = this.getTotal(key);

	this.totals[key] = value;

	if(applyField)
	{
		this.totalField.setValue(key, value);
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Will return the total held by the actual department obj
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function department_get_total(key)
{
	var total = this.totals[key];

	if(!total)
	{
		this.totals[key] = 0;

		total = 0;
	}

	return total;
}

function department_assign_total_field()
{
	return;
}

function department_get_xml(mode)
{
	var packet =	"	<department name=\"" + this.title + "\">\n";

	for(var i=0; i<this.department_array.length; i++)
	{
		var department_obj = this.department_array[i];

		packet += department_obj.getXml(mode);
	}

	for(var i=0; i<this.field_array.length; i++)
	{
		var field_obj = this.field_array[i];

		packet += field_obj.getXml(mode);
	}

	packet +=	"	</department>\n";

	return packet;
}
