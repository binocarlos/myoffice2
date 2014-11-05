var field_highest_id = 0;
var field_hash = new Object();
var field_array = new Array();

// Field - A field represents one spreadsheet row logically
// the field is responsible for handling the various extensions
// in terms of calculating one row (i.e. time X rate or simple value etc).

function field(parent_code, id, title, type)
{
	this.id = id;
	this.title = title;
	this.parent_code = parent_code;
	this.type = type;

// old_values is to hold the previous value for the total object
// to deduct before adding the new value

	this.actual_values = new Object();
	this.values = new Object();
	this.old_values = new Object();

// update the current highest_id

	if(this.id>field_highest_id)
	{
		field_highest_id = this.id;
	}

// Give the titles a little bold

	if(type=='nic')
	{
		this.title = '<b>NIC Sub-total</b>';
	}

	if(type=='sub_total')
	{
		this.title = '<b>Sub-total</b>';
	}

// add the field to the main holding variables (field_hash/field_array)

	field_hash[this.id] = this;
	field_array[field_array.length] = this;

// method assign

	this.setValue = field_set_value;
	this.v = field_set_value;
	this.av = field_set_actual_value;
	this.getValue = field_get_value;
	this.getInputValue = field_get_input_value;
	this.setInputValue = field_set_input_value;
	this.getActualValue = field_get_actual_value;
	this.setActualValue = field_set_actual_value;
	this.getOldValue = field_get_old_value;
	this.setOldValue = field_set_old_value;

	this.setCurrency = field_set_currency;
	this.resetCurrency = field_reset_currency;
	this.getCommentValue = field_get_comment_value;
	this.getComment = field_get_comment;
	this.shouldApplyCurrency = field_should_apply_currency;

	this.getCurrencyFields = field_get_currency_fields;

	this.applyCurrencyRates = field_apply_currency_rates;
	this.resetCurrencyRates = field_reset_currency_rates;

	this.applyRate = field_apply_rate;

	this.rowAssign = field_row_assign;

	this.calculate = field_calculate;
	this.update = field_update;
	this.hasChanged = field_has_changed;

	this.getLinkedFormulaFields = field_get_linked_formula_fields;

	this.getXmlFieldData = field_get_xml_fieldData;
	this.getXml = field_get_xml;

	return this;
}

// applies the given value to the values hash.
// Before this however, it will call this.setOldValue
// which should act transparently to keep the old value
// system working.

function field_set_value(key, value)
{
	if((key=='currency_code')||(key=='currency_rate'))
	{
		this[key] = value;

		return;
	}

	this.old_values[key] = this.values[key];

	this.values[key] = value;
}

function field_get_value(key)
{
	if(!this.values[key])
	{
		this.values[key] = 0;

		return 0;
	}
	else
	{
		return this.values[key];
	}
}

function field_get_comment_value()
{
	var val = this.getValue('comment');

	if(val=='0')
	{
		val = '';

	}

	return val;
}

// applied the current value for key to the old_values hash
// This is used by total_fields to determine the change
// after calculation.

function field_set_old_value(key)
{
	this.old_values[key] = this.getValue(key);
}

// Will return the old value using key

function field_get_old_value(key)
{
	if(!this.old_values[key])
	{
		return 0;
	}
	else
	{
		return this.old_values[key];
	}
}

function field_get_input_value(key)
{
	var ret = 0;

	if(!this.currency_code)
	{
		ret = this.getValue(key);
	}
	else
	{
		ret = this.getActualValue(key);
	}

	return reformat_float(ret);
}

function field_set_input_value(key, value)
{
	if(!this.shouldApplyCurrency(key))
	{
		this.setValue(key, value);
	}
	else
	{
		this.actual_values[key] = value;

		this.applyRate(key);
	}
}

// returns the value for key

function field_get_actual_value(key)
{
	if(this.actual_values[key])
	{
		return this.actual_values[key];
	}
	else
	{
		return this.getValue(key);
	}
}

function field_set_actual_value(key, value)
{
	this.actual_values[key] = value;
}

function field_get_currency_fields()
{
	return new Array();
}


function field_apply_rate(key)
{
	var actual_value = this.getActualValue(key);

	this.actual_values[key] = actual_value;

	var rate_value = actual_value * this.currency_rate;

	this.setValue(key, rate_value);
}

function field_set_currency(code, rate)
{
	if(this.currency_code)
	{
		this.resetCurrency();
	}

	this.currency_code = code;
	this.currency_rate = rate;

	this.applyCurrencyRates();
}

function field_reset_currency()
{
	if(!this.currency_code)
	{
		return;
	}

	this.currency_code = null;
	this.currency_rate = null;

	this.resetCurrencyRates();
}

function field_get_comment(key)
{
	var value = reformat_float(this.getValue(key));

	var field_title = top.editTableRow_code_titles[key];

	var ret = this.title + ' - ' + field_title + ' = ' + value;

	if(!this.currency_code)
	{
		return ret;
	}

	ret += ' ( ';

	if(this.getActualValue(key)!=this.getValue(key))
	{
		ret += '<b>' + reformat_float(this.getActualValue(key)) + '</b>';
	}
	
	var country_obj = top.country[this.currency_code];

	ret +=  ' in ' + country_obj.name + ' @ ' + this.currency_rate + ' / unit )';

	return ret;
}

function field_should_apply_currency(key)
{
	if(!this.currency_code)
	{
		return false;
	}

	var field_array = this.getCurrencyFields();

	for(var i=0; i<field_array.length; i++)
	{
		if(key==field_array[i])
		{
			return true;
		}
	}

	return false;
}

function field_apply_currency_rates()
{
	var field_array = this.getCurrencyFields();

	for(var i=0; i<field_array.length; i++)
	{
		var field = field_array[i];

		this.applyRate(field);
	}
}

function field_reset_currency_rates()
{
	var field_array = this.getCurrencyFields;

	for(var i=0; i<field_array.length; i++)
	{
		var field = field_array[i];

		var actual_value = this.getActualValue(field);

		this.setValue(field, actual_value);
	}
}

// This is the new access point for calculating the values
// of any field.

function field_calculate()
{

}

// This is the new access point for appling the fields
// values to its budget_row (which will make them appear on the spreadsheet)

function field_update()
{

}

// This is used to determine if an update needs to be done

function field_has_changed()
{
	var arr = new Array('markup_total', 'wdays_total');

	for(var i=0; i<arr.length; i++)
	{
		var prop = arr[i];

		var oldValue = this.getOldValue(prop);
		var currentValue = this.getValue(prop);

		if((oldValue!=currentValue)&&(oldValue!=null))
		{
			return true;
		}
	}

	return false;
}

// This is called initially to attach the field to the row
// and initialise the row tds with values and guis.

function field_row_assign(budget_row)
{

}

// Overide this method to obtain a more specific field description

function field_get_xml_fieldData(key, value)
{
	return "			<fielddata key=\"" + key + "\" value=\"" + value + "\"/>\n";
}

function field_get_xml()
{
	var packet = 	"		<field type=\"" +  this.type + "\" title=\"" + this.title + "\"/>\n";

	return packet;
}

function field_get_linked_formula_fields()
{
	return new Array();
}

