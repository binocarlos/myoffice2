function budgetHub_get_budget_xml(mode)
{
	return budget.getXml(mode);
}

function budget(id, title, nic, default_markup, country_id, highest_id)
{
	this.id = id;
	this.title = title;
	this.nicRate = nic;
	this.default_markup = default_markup;
	this.country_id = country_id;
	this.highest_id = highest_id;

	this.department_array = new Array();
	this.currency_map = new Object();
	this.currency_array = new Array();

	this.addDepartment = budget_add_department;
	this.newDepartment = budget_new_department;
	this.nd = budget_new_department;
	this.newField = budget_new_field;
	this.nf = budget_new_field;
	this.setTotalSpan = budget_set_total_span;
	this.addCurrency = budget_add_currency;
	this.ac = budget_add_currency;
	this.selectDepartment = budget_select_department;

	this.xTree = new WebFXTree(this.title);

	this.setTotal = budget_set_total;
	this.applyTotal = budget_apply_total;
	this.initTotalSpans = budget_init_total_spans;
	this.getXml = budget_get_xml;

	top.editBudget = this;

	return this;
}

function budget_add_currency(to_code, rate)
{
	var existing = this.currency_map[to_code];

	if(!existing)
	{
		existing = new Array();

		this.currency_map[to_code] = existing;
	}

	var check = false;

	for(var i=0; i<existing.length; i++)
	{
		var currency_obj = existing[i];

		if(currency_obj.rate==rate)
		{
			check = true;
		}
	}

	if(!check)
	{
		var new_currency_obj = new Object();

		new_currency_obj.country_code = to_code;
		new_currency_obj.rate = rate;

		existing[existing.length] = new_currency_obj;

		this.currency_map[to_code] = existing;
		this.currency_array[this.currency_array.length] = new_currency_obj;
	}
}

function budget_add_department(department_obj)
{
	if(!department_obj)
	{
		alert('budget.addDepartment with null department');

		return;
	}

	this.department_array[this.department_array.length] = department_obj;

	department_obj.isTopDepartment = true;

	this.xTree.add(department_obj.folder);
}

// Budget - A budget will have a collection of departments

function budget_new_department(id, title, parent_id)
{
	var department_obj = new department(id, title, parent_id);

	if(department_obj.parent_id==null)
	{
		this.addDepartment(department_obj);
	}
	else
	{
		var parent_department = department_hash[department_obj.parent_id];

		parent_department.addDepartment(department_obj);
	}

	return department_obj;
}

function budget_new_field(parent_code, id, title, type, noDepartmentAdd)
{
	var field_obj;

	if(type=='simple_cost')
	{
		field_obj = new simpleCost(parent_code, id, title, type);
	}
	else if(type=='time_cost')
	{
		field_obj = new timeCost(parent_code, id, title, type);
	}
	else if(type=='nic')
	{
		field_obj = new nicCost(parent_code, id, title, type);
	}
	else if(type=='sub_total')
	{
		field_obj = new totalCost(parent_code, id, title, type);
	}

	if(!noDepartmentAdd)
	{
		var department_obj = department_hash[field_obj.parent_code];

		department_obj.addField(field_obj);
	}

	return field_obj;
}

function budget_apply_total(oldValue, newValue)
{
	this.total -= oldValue;
	this.total += newValue;
}

function budget_set_total(total)
{
	this.total = total;
}

function budget_set_total_span()
{
	var link_id = this.xTree.id + '-anchor';

	var elem = document.getElementById(link_id);

	elem.innerHTML = '<span style="font-weight:bold;color:#880000;width:40;text-align:right;">' + Math.round(this.total) + '</span> - ' + this.title;
}

function budget_init_total_spans()
{
	for(var i=0; i<department_array.length; i++)
	{
		var department_obj = department_array[i];

		department_obj.setTotalSpan(department_obj.getTotal('markup_total'));
	}

	this.setTotalSpan();
}

function budget_select_department(department_id)
{
	var department_obj = department_hash[department_id];

	if(department_obj.hasFields())
	{
		parent.page.set_department(department_obj);
	}
}

function budget_get_xml(mode)
{
	var packet = 	"<?xml version=\"1.0\"?>\n"
	+		"<field_schema>\n";

	for(var i=0; i<this.currency_array.length; i++)
	{
		var currency_obj = this.currency_array[i];

		packet += "<currency country_code=\"" + currency_obj.country_code + "\" rate=\"" + currency_obj.rate + "\"/>\n";
	}
	
	for(var i=0; i<this.department_array.length; i++)
	{
		var department_obj = this.department_array[i];

		packet += department_obj.getXml(mode);
	}

	packet += 	"</field_schema>\n";

	return packet;
}
