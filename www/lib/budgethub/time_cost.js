//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Time Cost - this represents a field that
// has a rate and time, with overtime to calculate the orig.
// It then has extras and can be applied to a nicField, also weather days.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

// The xml fields are the ones included into the fields node in the XML document

var timeCost_xml_fields = new Array('for', 'rate', 'ot_hrs', 'ot_rate', 'extra');
var timeCost_currency_fields = new Array('rate', 'ot_rate', 'extra');

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////


function timeCost(parent_code, id, title, type)
{
	this.parent = field;

	this.parent(parent_code, id, title, type);

	delete this.parent;

	this.rowAssign = timeCost_assign_row;
	this.update = timeCost_update;
	this.calculate = timeCost_calculate;
	this.getLinkedFormulaFields = timeCost_get_linked_formula_fields;

	this.getCurrencyFields = timeCost_get_currency_fields;

	this.getXml = timeCost_get_xml;

	return this;
}

function timeCost_get_linked_formula_fields(tdid)
{
	var ret;

	if(tdid=='orig')
	{
		ret = new Array('for', 'rate', 'ot_hrs', 'ot_rate');
	}
	else if(tdid=='total')
	{
		ret = new Array('orig', 'extra');
	}
	else if(tdid=='markup_total')
	{
		ret = new Array('total', 'markup');
	}
	else if(tdid=='wdays_total')
	{
		ret = new Array('rate');
	}
	else
	{
		ret = new Array();
	}

	return ret;
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will work out the calculation for this field
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function timeCost_calculate(changedCode)
{
	var forv = this.getValue('for');
	var rate = this.getValue('rate');

	var normal = reformat_float(forv*rate);

	var ot_hours = this.getValue('ot_hrs');
	var ot_rate = this.getValue('ot_rate');

	var ot = reformat_float(ot_hours*ot_rate);

	var orig = normal + ot;

	this.setValue('orig', orig);

	var extra = this.getValue('extra');

	var total = orig + extra;

	this.setValue('total', total);

	var markup_total = reformat_float(total + ((this.getValue('markup')/100)*total));

	this.setValue('markup_total', markup_total);

	if(this.getValue('wdays'))
	{
		this.setValue('wdays_total', this.getValue('rate'));
	}
	else
	{
		this.setValue('wdays_total', 0);
	}
}


function timeCost_get_currency_fields()
{
	return timeCost_currency_fields;
}



//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will update the values to the budget_row
//////////////////////////////////////////////////////
/////////////////////////////////////////////////////

function timeCost_update(fullAssign)
{
	var brow = this.guiRow;

	if(fullAssign)
	{
		brow.setValue('rate', this.getValue('rate'));
		brow.setValue('ot_rate', this.getValue('ot_rate'));
		brow.setValue('extra', this.getValue('extra'));
	}

	brow.setValue('orig', this.getValue('orig'));
	brow.setValue('total', this.getValue('total'));
	brow.setValue('markup_total', this.getValue('markup_total'));
	brow.setValue('wdays_total', this.getValue('wdays_total'));
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will apply the initial values to the budget_row
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function timeCost_assign_row(budget_row)
{
	if(!this.getValue('markup'))
	{
		this.setValue('markup', budget.default_markup);
	}

	var itemLabel = this.getValue('itemLabel');

	if(!itemLabel)
	{
		itemLabel = 'days';
	}

	budget_row.addGui('for', this.getValue('for'));
	budget_row.addGui('rate', this.getValue('rate'));
	budget_row.setContent('itemLabel', itemLabel);
	budget_row.addGui('ot_hrs', this.getValue('ot_hrs'));
	budget_row.addGui('ot_rate', this.getValue('ot_rate'));
	budget_row.addValue('orig', this.getValue('orig'));
	budget_row.addGui('extra', this.getValue('extra'));
	budget_row.addValue('total', this.getValue('total'));
	budget_row.addGui('markup', this.getValue('markup'));
	budget_row.addValue('markup_total', this.getValue('markup_total'));
	budget_row.addCheckbox('nic', this.getValue('nic'));
	budget_row.addCheckbox('wdays', this.getValue('wdays'));
	budget_row.addValue('wdays_total', this.getValue('wdays_total'));
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will return the timeCost XML packet
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function timeCost_get_xml(mode)
{
	var packet = 	"		<field type=\"time_cost\" title=\"" + this.title + "\">\n";

	if(mode=='all')
	{
		for(var i=0; i<timeCost_xml_fields.length; i++)
		{
			var field = timeCost_xml_fields[i];

			var value = this.getValue(field);

			if(value>0)
			{
				packet += this.getXmlFieldData(field, value);
			}
		}

		var itemLabel = this.getValue('itemLabel');

		if((itemLabel!='days')&&(itemLabel!='0'))
		{
			packet += this.getXmlFieldData('itemLabel', itemLabel);
		}

		var markup = this.getValue('markup');

		if((markup)&&(markup!=budget.default_markup))
		{
			packet += this.getXmlFieldData('markup', markup);
		}

		if(this.getValue('nic'))
		{
			packet += this.getXmlFieldData('nic', 'true');
		}

		if(this.getValue('wdays'))
		{
			packet += this.getXmlFieldData('wdays', 'true');
		}

		if(this.currency_code)
		{
			packet += this.getXmlFieldData('currency_code', this.currency_code);
			packet += this.getXmlFieldData('currency_rate', this.currency_rate);

			var field_array = this.getCurrencyFields();

			for(var i=0; i<field_array.length; i++)
			{
				var key = field_array[i];

				var actual_value = this.getActualValue(key);

				packet += this.getXmlFieldData('actual_' + key, actual_value);
			}
		}

		if(this.getValue('comment'))
		{
			packet += "			<comment>\n";
			packet += "				" + this.getValue('comment') + "\n";
			packet += "			</comment>\n";
		}
	}

	packet += "		</field>\n";

	return packet;
}

timeCost.prototype = new field;
