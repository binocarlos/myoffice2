var security_titles = new Object();
	
security_titles.readwrite = 'Read/Write';
security_titles.readonly = 'Read Only';
security_titles.noaccess = 'No Access';
security_titles.hidden = 'Hidden';
	
var security_keys = new Array("readwrite", "readonly", "noaccess", "hidden");

var orgs = new Object();
var org_arr = new Array();
var departments = new Object();
var department_arr = new Array();
var users = new Object();
var users_arr = new Array();
var privilages = new Object();
var privilage_arr = new Array();

var selection_mode = null;
var selected_id = null;
	
var new_privilage_id = 0;
	
var item_access_code = 'readwrite';
var item_title = 'Resource/Folder';
	
function get_item_access_code()
{
	return item_access_code;
}

function new_org(id, name, xTree)
{
	this.id = id;
	this.name = name;
	this.xTree = xTree;
	this.iconId = xTree.id + '-icon';

	orgs[this.id] = this;
	org_arr[org_arr.length] = this;

	this.department_array = new Array();

	this.addDepartment = org_add_department;

	this.updateIcons = org_update_icons;
	this.updateIcon = org_update_icon;

	this.assignCode = org_assign_code;
	this.assignPriv = org_assign_priv;
	this.getPriv = org_get_priv;
	this.getCode = org_get_code;

	return this;
}

function org_add_department(departmentObj)
{
	this.department_array[this.department_array.length] = departmentObj;
}

function org_update_icon()
{
	var icon = this.getCode();
	var xTree = this.xTree;
	
	if(icon=='inherit') { icon = 'readonly'; }
	
	var icon = '/wk/images/icons/16/folder_' + icon + '.gif';

	xTree.icon = icon;
	xTree.openIcon = icon;

	document.getElementById(this.iconId).src = icon;
}
	
function org_update_icons()
{
	this.updateIcon();
	
	for(var i=0; i<this.department_array.length; i++)
	{
		var department_obj = this.department_array[i];
			
		department_obj.updateIcons();
	}
}

function org_assign_priv(priv)
{
	this.priv_obj = priv;
}
	
function org_get_priv()
{
	return this.priv_obj;
}
	
function org_get_code()
{
	var code = item_access_code;
	
	if(this.getPriv())
	{
		var priv = this.getPriv();

		code = priv.code;
	}
		
	return code;
}

function org_assign_code(code)
{		
	if(code==item_access_code)
	{
		this.assignPriv(null);
		this.updateIcon();		
	}
	else
	{
		if(this.getPriv())
		{
			var priv = this.getPriv();
			priv.code = code;
		}
		else
		{
			var priv = new_privilage(this.id, null, null, code);
			this.assignPriv(priv);	
		}
		
		this.updateIcon();
	}
	
	for(var i=0; i<this.department_array.length; i++)
	{
		var department_obj = this.department_array[i];
			
		department_obj.assignPriv(null);
		department_obj.updateIcon();

		for(var j=0; j<=department_obj.users_array.length; j++)
		{
			var user_obj = department_obj.users_array[j];

			if(user_obj)
			{
				user_obj.assignPriv(null);
				user_obj.updateIcon();
			}
		}
	}
}

function new_department(id, org_id, name, xTree)
{
	this.id = id;
	this.org_id = org_id;
	this.name = name;
	this.xTree = xTree;
	this.iconId = xTree.id + '-icon';	

	departments[this.id] = this;
	department_arr[department_arr.length] = this;
		
	this.users_array = new Array();
	
	// assigns a user to the dept	
	this.addUser = department_add_user;
	
	// this will actually change the icons
	this.updateIcons = department_update_icons;
	this.updateIcon = department_update_icon;
	
	this.assignCode = department_assign_code;
	this.assignPriv = department_assign_priv;
	this.getPriv = department_get_priv;
	this.getCode = department_get_code;	
		
	return this;
}

function department_add_user(userobj)
{
	this.users_array[this.users_array.length] = userobj;
}

function department_update_icon()
{
	var icon = this.getCode();
	var xTree = this.xTree;
	
	if(icon=='inherit') { icon = 'readonly'; }
	
	var icon = '/wk/images/icons/16/folder_' + icon + '.gif';

	xTree.icon = icon;
	xTree.openIcon = icon;

	document.getElementById(this.iconId).src = icon;
}
	
function department_update_icons()
{
	this.updateIcon();
	
	for(var i=0; i<this.users_array.length; i++)
	{
		var users_obj = this.users_array[i];
			
		users_obj.updateIcon();
	}
}

function department_assign_priv(priv)
{
	this.priv_obj = priv;
}
	
function department_get_priv()
{
	return this.priv_obj;
}
	
function department_get_code()
{
	var org_obj = orgs[this.org_id];
	
	var code = item_access_code;
	
	if(org_obj)
	{
		code = org_obj.getCode();
	}
	
	if(this.getPriv())
	{
		var priv = this.getPriv();
		
		code = priv.code;
	}
		
	return code;
}

function department_assign_code(code)
{		
	if(code==item_access_code)
	{
		this.assignPriv(null);
		this.updateIcon();		
	}
	else
	{
		if(this.getPriv())
		{
			var priv = this.getPriv();
			priv.code = code;
		}
		else
		{
			var priv = new_privilage(null, this.id, null, code);
			this.assignPriv(priv);	
		}
		
		this.updateIcon();
	}
	
	for(var i=0; i<this.users_array.length; i++)
	{
		var users_obj = this.users_array[i];
			
		users_obj.assignPriv(null);
		users_obj.updateIcon();
	}
}

	
function new_user(id, dept_id, name, xTree)
{
	this.id = id;
	this.department_id = dept_id;
	this.name  = name;
	this.xTree = xTree;
	this.iconId = xTree.id + '-icon';
		
	users[this.id] = this;
	users_arr[users_arr.length] = this;
		
	this.assignPriv = user_assign_priv;
	this.getPriv = user_get_priv;

	this.getCode = user_get_code;
	this.updateIcon = user_update_icon;
	this.assignCode = user_assign_code;
		
	return this;
}

function user_update_icon()
{
	var icon = this.getCode();
	var xTree = this.xTree;
	
	if(icon=='inherit') { icon = 'readonly'; }
	
	var icon = '/wk/images/icons/16/user_' + icon + '.gif';

	xTree.icon = icon;
	xTree.openIcon = icon;	
			
	document.getElementById(this.iconId).src = icon;
}

function user_assign_priv(priv)
{
	this.priv_obj = priv;
}
	
function user_get_priv()
{
	return this.priv_obj;
}
	
function user_get_code()
{
	var department_obj = departments[this.department_id];
	
	var code = item_access_code;
	
	if(department_obj)
	{
		code = department_obj.getCode();
	}
	
	if(this.getPriv())
	{
		var priv = this.getPriv();
		
		code = priv.code;
	}
		
	return code;
}
	
// changes the users code
	
function user_assign_code(code)
{		
	var original_code = this.getCode();
	
	if(code==item_access_code)
	{		
		this.assignPriv(null);
	}
	else
	{	
		if(this.getPriv())
		{
			var priv = this.getPriv();
				
			priv.code = code;
		}
		else
		{
			var priv = new new_privilage(null, null, this.id, code);				
				
			this.assignPriv(priv);
		}
	}

	this.updateIcon();
}
	
function new_privilage(org_id, department_id, users_id, code)
{
	new_privilage_id++;
		
	this.id = new_privilage_id;
	this.org_id = org_id;
	this.department_id = department_id;
	this.users_id = users_id;
	this.code = code;
		
	privilages[this.id] = this;
	privilage_arr[privilage_arr.length] = this;
		
	return this;
}

function initialise_objects()
{
	for(var priv_id in privilages)
	{
		var priv_obj = privilages[priv_id];
		
		if(priv_obj.users_id!=null)
		{
			var users_obj = users[priv_obj.users_id];
			
			if(users_obj)
			{
				users_obj.assignPriv(priv_obj);
			}
		}
		else if(priv_obj.department_id!=null)
		{
			var department_obj = departments[priv_obj.department_id];
				
			if(department_obj)
			{
				department_obj.assignPriv(priv_obj);
			}
		}
		else if(priv_obj.org_id!=null)
		{
			var org_obj = orgs[priv_obj.org_id];

			if(org_obj)
			{
	
				org_obj.assignPriv(priv_obj);
			}
		}
	}

	for(var department_id in departments)
	{
		var department_obj = departments[department_id];
		var org_obj = orgs[department_obj.org_id];

		if(org_obj)
		{
			org_obj.addDepartment(department_obj);
		}
	}
		
	for(var user_id in users)
	{
		var user_obj = users[user_id];
		var department_obj = departments[user_obj.department_id];
			
		if(department_obj)
		{
			department_obj.addUser(user_obj);
		}
	}
		
	update_all_icons();
	
	if(parent.apply_security_details)
	{
		parent.apply_security_details(get_descriptive_string());
	}
}
	
function update_all_icons()
{
	for(var i=0; i<org_arr.length; i++)
	{
		var org_obj = org_arr[i];
			
		org_obj.updateIcons();
	}
}
	
function cancel_selection()
{
	selection_mode = null;
	selected_id = null;
}
	
function select_tree()
{
	parent.show_security_table('All Users', item_access_code);
	selection_mode = 'all';
	selected_id = null
}

function select_org(id)
{
	var org = orgs[id];
		
	parent.show_security_table('All Users In The ' + org.name + ' Organisation', org.getCode());
	selection_mode = 'org';
	selected_id = id;
}
	
function select_department(id)
{
	var dept = departments[id];
	var org = orgs[dept.org_id];
		
	parent.show_security_table('All Users In The ' + dept.name + ' (' + org.name + ') Group', dept.getCode());
	selection_mode = 'department';
	selected_id = id;
}
	
function select_user(id)
{
	var user = users[id];
		
	parent.show_security_table(user.name, user.getCode());
	selection_mode = 'user';
	selected_id = id;
}
	
function apply_all_new_code(code)
{
	item_access_code = code;
	
	for(var i=0; i<org_arr.length; i++)
	{
		var org = org_arr[i];
		
		org.assignCode(code);
	}
}
	
function applyCode(code)
{
	if(selection_mode=='all')
	{
		apply_all_new_code(code);
	}
	else if(selection_mode=='org')
	{
		var org_obj = orgs[selected_id];
		org_obj.assignCode(code);
	}
	else if(selection_mode=='department')
	{
		var department_obj = departments[selected_id];
		department_obj.assignCode(code);
	}
	else if(selection_mode=='user')
	{
		var user_obj = users[selected_id];
		user_obj.assignCode(code);
	}
		
	cancel_selection();
	parent.apply_security_details(get_descriptive_string());
}
	
function get_security_title(code)
{
	var title = security_titles[code];
		
	return title;
}
	
function get_privilage_packet()
{
	var packet = "<privilages>\n";
	var codes = new Array();
	
	for(var k=0; k<org_arr.length; k++)
	{
		var org_obj = org_arr[k];

		if(org_obj.getPriv())
		{
			var priv = org_obj.getPriv();
			
			packet += "<privilage id=\"" + priv.id + "\" department_id=\"" + priv.department_id + "\" code=\"" + priv.code + "\"/>\n";			
			codes[codes.length] = 'org' + org_obj.id + '=' + priv.code;
		}
	
		for(var i=0; i<org_obj.department_array.length; i++)
		{
			var dept_obj = org_obj.department_array[i];
		
			if(dept_obj.getPriv())
			{
				var priv = dept_obj.getPriv();
			
				packet += "<privilage id=\"" + priv.id + "\" department_id=\"" + priv.department_id + "\" code=\"" + priv.code + "\"/>\n";			
				codes[codes.length] = 'department' + dept_obj.id + '=' + priv.code;
			}

			for(var j=0; j<dept_obj.users_array.length; j++)
			{
				var user_obj = dept_obj.users_array[j];
			
				if(user_obj.getPriv())
				{
					var priv = user_obj.getPriv();
				
					packet += "<privilage id=\"" + priv.id + "\" users_id=\"" + priv.users_id + "\" code=\"" + priv.code + "\"/>\n";
					codes[codes.length] = 'user' + user_obj.id + '=' + priv.code;
				}
			}
		}
	}					
			
	packet += "</privilages>\n";
	var codes_st = codes.join('&');
	
	return codes_st;
}
	
function get_descriptive_string()
{
	var main_title = get_security_title(item_access_code);
	
	var string = 'All users are set as default to ' + main_title + ' for this ' + item_title;

	for(var k=0; k<org_arr.length; k++)
	{
		var org_obj = org_arr[k];

		var orgcode = org_obj.getCode();

		if(orgcode!=item_access_code)
		{
			string += '<br>The <b>' + org_obj.name + '</b> Organisation is set to ' + security_titles[orgcode];
		}
	
		for(var i=0; i<org_obj.department_array.length; i++)
		{
			var dept_obj = org_obj.department_array[i];
		
			var deptcode = dept_obj.getCode();
		
			if((deptcode!=item_access_code)&&(deptcode!=orgcode))
			{
				string += '<br>The <b>' + dept_obj.name + '</b> (' + org_obj.name + ') Department is set to ' + security_titles[deptcode];
			}
		
			for(var j=0; j<dept_obj.users_array.length; j++)
			{
				var user_obj = dept_obj.users_array[j];
			
				var userscode = user_obj.getCode();
			
				if((userscode!=item_access_code)&&(userscode!=deptcode))
				{
					string += '<br><i>' + user_obj.name + '</i> is set to ' + security_titles[userscode];
				}
			}
		}
	}
		
	return string;
}