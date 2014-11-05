//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Total Cost - this represents a field that
// is linked to other fields and will present the sum
// of them all.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

var totalCost_fields = new Array("orig", "extra", "total", "markup_total", "wdays_total");

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


function totalCost(parent_code, id, title, type)
{
	this.parent = field;

	this.parent(parent_code, id, title, type);

	delete this.parent;

	this.rowAssign = totalCost_assign_row;

	this.update = totalCost_update;
	this.calculate = totalCost_calculate;
	this.calculateAll = totalCost_recalculate_all;

	this.addField = totalCost_add_field;
	this.resetFields = totalCost_reset_fields;

	this.getXml = totalCost_get_xml;

	this.calcFields = new Object();

	return this;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is called to remove any referenece to the other fields.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function totalCost_reset_fields()
{
	for(var field_id in this.calcFields)
	{
		var field_obj = this.calcFields[field_id];

		if(this.isDepartmentTotal)
		{
			field_obj.mainTotalField = null;
		}
		else
		{
			field_obj.totalField = null;			
		}
	}

	this.calcFields = new Object();
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is called to add a reference to another field
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function totalCost_add_field(field_obj)
{
	this.calcFields[field_obj.id] = field_obj;

	if(this.isDepartmentTotal)
	{
		field_obj.mainTotalField = this;
	}
	else
	{
		field_obj.totalField = this;
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Calculate, this is called to calculate the fields total
// If a field is passed, it is assumed that this field
// is the only to have changed and that we should use
// the oldValues to do a quick total.
// If there is no field, it will loop every dependent field
// to actual an absolute total.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function totalCost_calculate(field_obj)
{
	var props = totalCost_fields;

	for(var i=0; i<props.length; i++)
	{
		var prop = props[i];

		var thisvalue = this.getValue(prop);

		var oldvalue = field_obj.getOldValue(prop);
		var newvalue = field_obj.getValue(prop);

		thisvalue -= oldvalue;

		thisvalue += newvalue;

		this.setValue(prop, reformat_float(thisvalue));
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// RecalculateAll - this will reset all totals,
// and loop through each dependent field, adding them up.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function totalCost_recalculate_all()
{
	for(var i=0; i<totalCost_fields.length; i++)
	{
		var f = totalCost_fields[i];

		this.setValue(f, 0);
	}

	for(var field_id in this.calcFields)
	{
		var field_obj = this.calcFields[field_id];

		for(var i=0; i<totalCost_fields.length; i++)
		{
			var f = totalCost_fields[i];

			var cvalue = this.getValue(f);

			cvalue += field_obj.getValue(f);

			this.setValue(f, cvalue);
		}
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Update - this will apply the total values to the row.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function totalCost_update()
{
	var brow = this.guiRow;

	for(var i=0; i<totalCost_fields.length; i++)
	{
		var f = totalCost_fields[i];

		brow.setValue(f, this.getValue(f));
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Assign row - this will apply the initial value to the row
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function totalCost_assign_row(budget_row)
{
	for(var i=0; i<totalCost_fields.length; i++)
	{
		var f = totalCost_fields[i];

		budget_row.addValue(f, this.getValue(field));
	}
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will return the XML packet for this field
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function totalCost_get_xml()
{
	if(this.isDepartmentTotal)
	{
		return '';
	}

	var packet = 	"		<field type=\"sub_total\"/>\n";

	return packet;
}

totalCost.prototype = new field;




