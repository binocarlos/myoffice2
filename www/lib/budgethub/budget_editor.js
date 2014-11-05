var mainBudgetTable = null;

function init_budget_table()
{
	var table_elem = document.getElementById('editor_container');

	mainBudgetTable = new budget_table();

	var editorTable = mainBudgetTable.getElem('table');

	table_elem.innerText = '';

	table_elem.appendChild(editorTable);	
}

function set_department(department_obj)
{
	mainBudgetTable.setDepartment(department_obj);
}


