var htmlBlocks = new Object();

function addHTMLBlock(key, text)
{
	htmlBlocks[key] = text;
}

function getHTMLBlock(key, hash)
{
	var text = htmlBlocks[key];
	
	if(!text) { return ''; }
	
	for(var key in hash)
	{
		var value = hash[key];
		var key = '__' + key + '__';
		
		var eval_st = 'text = text.replace(/' + key + '/g, value);';
		
		eval(eval_st);
	}
	
	return text;
}

function round2dp(value)
{
	value *= 100;
	value = Math.round(value);
	value /= 100;
	return value;
}

function pad2dp(value)
{
	var re = /\.(\d+)$/;
	
	var details = re.exec(value);
	
	if(!details)
	{
		return value + '.00';
	}
	
	if(details[1].length==1)
	{
		return value + '0';
	}
	
	return value;
}

function showVenueInfo(id)
{
	return get_modal_window_return('&method=venue_info_window&venue_id=' + id, 800, 600);
}

function showTimeline()
{
	return get_modal_window_return('&method=modal_timeline_frame', 780, 500);
}

function editTdOver(td)
{
	td.bgColor='#ffffcc';
}

function editTdOut(td)
{
	td.bgColor='';
}

function getMultiDateNoteReturn(arr)
{
	var parts = new Array();
	
	for(var i=0; i<arr.length; i++)
	{
		var ref = arr[i];
		parts[parts.length] = ref.date + '=' + ref.note;
	}
		
	var st = parts.join('+++');
	
	return st;
}

function getMultiDateNoteText(arr)
{
	if(arr.length<=0) { return ''; }
		
	var note = '';
		
	var dateSts = new Array();
		
	for(var i=0; i<arr.length; i++)
	{
		var ref = arr[i];
		
		dateSts[dateSts.length] = ref.date;
			
		if(i==arr.length-1)
		{
			note = ref.note;
		}
	}
		
	var st = dateSts.join(',<br>');
	note.replace(/\n/, '<br>');
	st += '<br><span style="font-size:9px;color:blue;">' + note + '</span>';
		
	return st;
}