
////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////
//// MAIN MENU
////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////


function get_menu_query(query)
{
	var new_loc = href + query;

	document.content.location = new_loc;
}

function swap(image,imagefile)
{
  document.images[image].src = imagefile
}
