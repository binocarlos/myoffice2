// test.js
//
// This file is responsible for managing the test interface
// it will do things like swap checkbox images etc

var checkboxStates = new Object();

function checkboxClick(id)
{
	var img = document.getElementById(id);

	var src = '/images/nctest/checkbox_selected.gif';

	if(checkboxStates[id])
	{
		src = '/images/nctest/checkbox.gif';
	}

	img.src = src;
}
