var graphMode = false;

function resetGraphMode()
{
	graphMode = false;
	document.getElementById('graphTitle').innerText = 'Show Graph';	
}

function toggleGraph()
{
	graphMode = !graphMode;

	var buttonTitle = 'Hide Graph';
	var display = 'inline';

	if(!graphMode)
	{
		buttonTitle = 'Show Graph';
		display = 'none';
	}

	parent.content.document.getElementById('graph').style.display = display;
	document.getElementById('graphTitle').innerText = buttonTitle;

}	