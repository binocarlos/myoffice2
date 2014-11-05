//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Nic Cost - this represents a field that will total
// up all of the time_cost orig values, and then apply
// the nicRate to it (usually 0.1) to get the nicTotal
// This value will then itself, belong to a sub-total.
// I.e. the nicTotal is an actual amount of money that
// will be paid and is a multi-linked field.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function nicCost(parent_code, id, title, type)
{
	this.parent = field;

	this.parent(parent_code, id, title, type);

	delete this.parent;

	this.rowAssign = nicCost_assign_row;
	this.update = nicCost_update;
	this.calculate = nicCost_calculate;

	this.calculateField = nicCost_calculate_field;
	this.calculateAll = nicCost_recalculate_all;
	this.resetFields = nicCost_reset_fields;

	this.addField = nicCost_add_field;

	this.getXml = nicCost_get_xml;

	this.calcFields = new Object();

	return this;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is called to remove any referenece to the other fields.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function nicCost_reset_fields()
{
	for(var field_id in this.calcFields)
	{
		var field_obj = this.calcFields[field_id];

		field_obj.nicField = null;
	}

	this.calcFields = new Object();
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is called to add a reference to another field
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function nicCost_add_field(field_obj)
{
	this.calcFields[field_obj.id] = field_obj;

	field_obj.nicField = this;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is called to work out the current Nic based on the current rate
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function nicCost_calculate(field_obj, nicChanged)
{
	if(field_obj)
	{
		this.calculateField(field_obj, nicChanged);
	}

	var rate = this.getValue('rate');

	var orig = reformat_float(rate * budget.nicRate);

	this.setValue('rate', rate);
	this.setValue('orig', orig);
	this.setValue('total', orig);
	this.setValue('markup_total', orig);
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This is called if the calculate method is passed a field
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function nicCost_calculate_field(field_obj, nicChanged)
{
	this.setOldValue('rate');

	var thisvalue = this.getValue('rate');

	var oldvalue = field_obj.getOldValue('orig');
	var newvalue = field_obj.getValue('orig');


	if(nicChanged)
	{
		if(field_obj.getValue('nic')==true)
		{
			thisvalue += newvalue;
		}
		else
		{
			thisvalue -= newvalue;
		}
	}
	else
	{
		if(field_obj.getValue('nic'))
		{
			thisvalue -= oldvalue;
			thisvalue += newvalue;
		}
	}

	this.setValue('rate', thisvalue);
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// RecalculateAll - this will reset all totals,
// and loop through each dependent field, adding them up.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


function nicCost_recalculate_all()
{
	var props = new Array("rate", "orig", "total", "markup_total");

	for(var i=0; i<props.length; i++)
	{
		var f = props[i];

		this.setValue(f, 0);
	}

	for(var field_id in this.calcFields)
	{
		var field_obj = this.calcFields[field_id];

		if(field_obj.getValue('nic'))
		{
			var cvalue = this.getValue('rate');

			cvalue += field_obj.getValue('orig');

			this.setValue('rate', cvalue);
		}
	}

	this.calculate();
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Update - this will apply the total values to the row.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function nicCost_update()
{
	var brow = this.guiRow;

	brow.setValue('rate', this.getValue('rate'));
	brow.setValue('orig', this.getValue('orig'));
	brow.setValue('total', this.getValue('total'));
	brow.setValue('markup_total', this.getValue('markup_total'));
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Assign row - this will apply the initial value to the row
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function nicCost_assign_row(budget_row)
{
	budget_row.addValue('rate', this.getValue('rate'));
	budget_row.addValue('orig', this.getValue('orig'));
	budget_row.addValue('total', this.getValue('total'));
	budget_row.addValue('markup_total', this.getValue('markup_total'));
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will return the XML packet for this field
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


function nicCost_get_xml()
{
	var packet = 	"		<field type=\"nic\"/>\n";

	return packet;
}

nicCost.prototype = new field;
