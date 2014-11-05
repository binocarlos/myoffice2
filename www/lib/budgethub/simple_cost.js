//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Simple Cost - this represents a field that
// has the original and extra cost with markup.
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

// The xml fields are the ones included into the fields node in the XML document

var simpleCost_xml_fields = new Array('orig', 'extra');
var simpleCost_currency_fields = new Array('orig', 'extra');

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function simpleCost(parent_code, id, title, type)
{
	this.parent = field;

	this.parent(parent_code, id, title, type);

	delete this.parent;

	this.rowAssign = simpleCost_assign_row;
	this.update = simpleCost_update;
	this.calculate = simpleCost_calculate;
	this.getLinkedFormulaFields = simpleCost_get_linked_formula_fields;

	this.getCurrencyFields = simpleCost_get_currency_fields;

	this.getXml = simpleCost_get_xml;

	return this;
}

function simpleCost_get_linked_formula_fields(tdid)
{
	var ret;

	if(tdid=='total')
	{
		ret = new Array('orig', 'extra');
	}
	else if(tdid=='markup_total')
	{
		ret = new Array('total', 'markup');
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

function simpleCost_calculate(changedCode)
{
	var orig = this.getValue('orig');
	var extra = this.getValue('extra');

	var total = orig + extra;

	this.setValue('total', total);

	var markup_total = reformat_float(total + ((this.getValue('markup')/100)*total));

	this.setValue('markup_total', markup_total);
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will update the values to the budget_row
//////////////////////////////////////////////////////
/////////////////////////////////////////////////////

function simpleCost_update(fullAssign)
{
	var brow = this.guiRow;

	if(fullAssign)
	{
		brow.setValue('orig', this.getValue('orig'));
		brow.setValue('extra', this.getValue('extra'));
	}

	brow.setValue('total', this.getValue('total'));
	brow.setValue('markup_total', this.getValue('markup_total'));
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will apply the initial values to the budget_row
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function simpleCost_assign_row(budget_row)
{
	if(!this.getValue('markup')>0)
	{
		this.setValue('markup', budget.default_markup);
	}

	budget_row.addGui('orig', this.getValue('orig'));
	budget_row.addGui('extra', this.getValue('extra'));
	budget_row.addValue('total', this.getValue('total'));
	budget_row.addGui('markup', this.getValue('markup'));
	budget_row.addValue('markup_total', this.getValue('markup_total'));
}

function simpleCost_get_currency_fields()
{
	return simpleCost_currency_fields;
}



//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// This will return the simpleCost XML packet
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

function simpleCost_get_xml(mode)
{
	var packet = 	"		<field type=\"simple_cost\" title=\"" + this.title + "\">\n";

	if(mode=='all')
	{
		for(var i=0; i<simpleCost_xml_fields.length; i++)
		{
			var field = simpleCost_xml_fields[i];

			var value = this.getValue(field);

			if(value>0)
			{
				packet += this.getXmlFieldData(field, value);
			}
		}

		if(this.getValue('markup')!=budget.default_markup)
		{
			packet += this.getXmlFieldData('markup', this.getValue('markup'));
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

simpleCost.prototype = new field;
