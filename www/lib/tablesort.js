//
// global variables
//
var tablesort_tbody=null;
var tablesort_theadrow=null;
var tablesort_colCount = null;


var tablesort_reverse = false;
var tablesort_lastclick = -1;					// stores the object of our last used object

var tablesort_oTR = null;
var tablesort_oStatus = null;
var tablesort_none = 0;

function tablesort_init(thead, tbody) 
{
	if((thead.tagName!='THEAD')||(tbody.tagName!='TBODY'))
	{
		alert(thead.tagName + ' - ' + tbody.tagName + ' --- you must give a thead and tbody for tablesort');
	}

	// get TBODY - take the first TBODY for the table to sort
	tablesort_tbody = tbody;

	tablesort_theadrow = thead.children[0]; //Assume just one Head row

	if (tablesort_theadrow.tagName != "TR") return;

	tablesort_colCount = tablesort_theadrow.children.length;

	var l, clickCell;

	for (var i=0; i<tablesort_colCount; i++)
	{
		// Create our blank gif
		l=document.createElement("IMG");
		l.src="/images/holiday/clear.gif";
		l.id="srtImg";
		l.width=10;
		l.height=5;

		clickCell = tablesort_theadrow.children[i];
		clickCell.selectIndex = i;
		clickCell.insertAdjacentElement("beforeEnd", l)
		clickCell.runtimeStyle.cursor = 'hand';
		clickCell.attachEvent("onclick", tablesort_doClick);
	}

}

//
// doClick handler
//
//
function tablesort_doClick(e)
{
	var clickObject = e.srcElement;

	while (clickObject.tagName != "TD")
	{
		clickObject = clickObject.parentElement;
	}


	// clear the sort images in the head
	var imgcol= tablesort_theadrow.all('srtimg');

	for(var x = 0; x < imgcol.length; x++)
		imgcol[x].src = "/images/holiday/clear.gif";

	if(tablesort_lastclick == clickObject.selectIndex)
	{
		if(tablesort_reverse == false)
		{
			clickObject.children[0].src = "/images/holiday/sortdown.gif";
		      tablesort_reverse = true;
		}
		else
		{
			clickObject.children[0].src = "/images/holiday/sortup.gif";
			tablesort_reverse = false;
		}
	}
	else
	{
		tablesort_reverse = false;
		tablesort_lastclick = clickObject.selectIndex;
		clickObject.children[0].src = "/images/holiday/sortup.gif";
	}

	tablesort_insertionSort(tablesort_tbody, tablesort_tbody.rows.length-1, tablesort_reverse, clickObject.selectIndex);
}

function tablesort_insertionSort(t, iRowEnd, fReverse, iColumn)
{
	  var iRowInsertRow, iRowWalkRow, current, insert;
    for ( iRowInsert = 0 + 1 ; iRowInsert <= iRowEnd ; iRowInsert++ )
    {
        if (iColumn) {
		if( typeof(t.children[iRowInsert].children[iColumn]) != "undefined")
     		      textRowInsert = t.children[iRowInsert].children[iColumn].innerText;
		else
			textRowInsert = "";
        } else {
           textRowInsert = t.children[iRowInsert].innerText;
        }

        for ( iRowWalk = 0; iRowWalk <= iRowInsert ; iRowWalk++ )
        {
            if (iColumn) {
			if(typeof(t.children[iRowWalk].children[iColumn]) != "undefined")
				textRowCurrent = t.children[iRowWalk].children[iColumn].innerText;
			else
				textRowCurrent = "";
            } else {
			textRowCurrent = t.children[iRowWalk].innerText;
            }

		//
		// We save our values so we can manipulate the numbers for
		// comparison
		//
		current = textRowCurrent;
		insert  = textRowInsert;


		//  If the value is not a number, we sort normally, else we evaluate
		//  the value to get a numeric representation
		//
		if ( !isNaN(current) ||  !isNaN(insert))
		{
			current= eval(current);
			insert= eval(insert);
		}
		else
		{
			current	= current.toLowerCase();
			insert	= insert.toLowerCase();
		}


            if ( (   (!fReverse && insert < current)
                 || ( fReverse && insert > current) )
                 && (iRowInsert != iRowWalk) )
            {
		    eRowInsert = t.children[iRowInsert];
                eRowWalk = t.children[iRowWalk];
                t.insertBefore(eRowInsert, eRowWalk);
                iRowWalk = iRowInsert; // done
            }
        }
    }
}

