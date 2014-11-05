// questionComponent.js
//
// This represents one questionComponent object that is linked to the database
// equivalent

var questionComponents = new Object();

function questionComponent(id, type, hasMP3, htmlText)
{
	this.id = id;
	this.type = type;
	this.hasMP3 = hasMP3;
	this.htmlText = htmlText;

	questionComponents[this.id] = this;
}


