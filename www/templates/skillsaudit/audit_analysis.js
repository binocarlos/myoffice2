var groupStates = new Object();
var ictStates = new Object();

groupStates.help = true;

	function toggleICTGroup(id)
	{
		var state = ictStates[id];
		
		if(!state) { state = false; }
		
		state = !state;
		
		ictStates[id] = state;
		
		var display = 'inline';
		var img = 'minus';
		
		if(!state)
		{
			display = 'none';
			img = 'plus';
		}
		
		document.getElementById('icttr' + id).style.display = display;
		document.getElementById('ictimg' + id).src = '/images/nav/' + img + '.gif';
	}
	
function setGroup(id, state)
{
	groupStates[id] = state;
	
	var display = 'none';
	var image = 'plus';
	
	if(state)
	{
		display = 'inline';
		image = 'minus';
	}
	
	document.getElementById('tr' + id).style.display = display;
	document.getElementById('img' + id).src = '/images/nav/' + image + '.gif';
}		

	function toggleGroup(id)
	{
		var state = groupStates[id];
		
		if(!state) { state = false; }
		
		state = !state;
		
		groupStates[id] = state;
		
		var display = 'inline';
		var img = 'minus';
		
		if(!state)
		{
			display = 'none';
			img = 'plus';
		}
		
		document.getElementById('tr' + id).style.display = display;
		document.getElementById('img' + id).src = '/images/nav/' + img + '.gif';
	}
