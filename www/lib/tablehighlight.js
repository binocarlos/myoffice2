var thl_currRow = -1;
var thl_selRow = -1;

var thl_slColor = '#B2B8CD';
var thl_hlColor = '#D9DCE6';

function init_tablehl(element)
{
	if (element.tagName == 'TABLE')
	{
		element.attachEvent('onmouseover', thl_onMouseOver);
		element.attachEvent('onmouseout', thl_onMouseOut);
		element.attachEvent('onclick', thl_onClick);
		element.attachEvent('ondblclick', thl_onDblClick);
		element.thl_selRow = -1;
	}
	else
	{
		alert("Error: tablehl not attached to a table element");
	}
}

function thl_cleanup()
{
	thl_hilite(-1);

	element.detachEvent('onmouseover', onMouseOver);
	element.detachEvent('onmouseout', onMouseOut);
	element.detachEvent('onclick', onClick);
}

function thl_onDblClick()
{
	var edit_button_id = 'object_button_edit';

	var button = document.getElementById(edit_button_id);

	if(button)
	{
		srcElem = window.event.srcElement;

		//crawl up the tree to find the table row
		while (srcElem.tagName != "TR" && srcElem.tagName != "TABLE")
			srcElem = srcElem.parentElement;

		if(srcElem.tagName != "TR") return;

		if(srcElem.rowIndex == 0 ) return;

		srcElem.style.cursor='wait';
		document.body.style.cursor='wait';

		button.click();
	}
}

function thl_onClick()
{
	srcElem = window.event.srcElement;

	//crawl up the tree to find the table row
	while (srcElem.tagName != "TR" && srcElem.tagName != "TABLE")
		srcElem = srcElem.parentElement;

	if(srcElem.tagName != "TR") return;

	if(srcElem.rowIndex == 0 ) return;

	var parentTable = srcElem;

	while (parentTable.tagName != "BODY" && parentTable.tagName != "TABLE")
		parentTable = parentTable.parentElement;

	if(!parentTable)
	{
		return;
	}

	if (parentTable.thl_selRow != -1) parentTable.thl_selRow.runtimeStyle.backgroundColor = '';

	srcElem.runtimeStyle.backgroundColor = thl_slColor;
	parentTable.thl_selRow = srcElem;

	thl_selRow = srcElem;
}

function thl_onMouseOver()
{
	srcElem = window.event.srcElement;
	//crawl up to find the row
	while (srcElem.tagName != "TR" && srcElem.tagName != "TABLE")
		srcElem = srcElem.parentElement;

	if(srcElem.tagName != "TR") return;

	if (srcElem.rowIndex > 0)
		thl_hilite(srcElem);
	else
		thl_hilite(-1);

}

function thl_onMouseOut()
{
	// Make sure we catch exit from the table
	thl_hilite(-1, -1);
}

function thl_hilite(newRow)
{
	if (thl_hlColor != null )
	{
		if (thl_currRow != -1 && thl_currRow!=thl_selRow)
		{
			thl_currRow.runtimeStyle.backgroundColor = '';
		}

		if (newRow != -1 && newRow!=thl_selRow)
		{
			newRow.runtimeStyle.backgroundColor = thl_hlColor;
		}
	}

	thl_currRow = newRow;
}
