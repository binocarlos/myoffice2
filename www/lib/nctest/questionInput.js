// questionInput.js
//
// This represents one questionInput object that is linked to the database
// equivalent

var questionInputs = new Object();

function questionInput(id, type, marks, htmlText)
{
	this.id = id;
	this.type = type;
	this.marks = marks;
	this.htmlText = htmlText;

	questionInputs[this.id] = this;
}



