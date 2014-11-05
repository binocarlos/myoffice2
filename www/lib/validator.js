// Validator Object
var valid = new Object();

// REGEX Elements

// matches something entered
valid.string = /\w/;

// matches an integer (signed)
valid.integer = /^\d+$/;

// matches a float or integer (signed)
valid.number = /^-?[\d\.]+$/;

// matches zip codes
valid.zipCode = /\d{5}(-\d{4})?/;

// matches $17.23 or $14,281,545.45 or ...
valid.Currency = /\$\d{1,3}(,\d{3})*\.\d{2}/;

// matches 5:04 or 12:34 but not 75:83
valid.Time = /^([1-9]|1[0-2]):[0-5]\d$/;

//matches email
valid.emailAddress = /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/;

// matches phone ###-###-####
valid.phoneNumber = /^\(?\d{3}\)?\s|-\d{3}-\d{4}$/;

// International Phone Number
valid.phoneNumberInternational = /^\d(\d|-){7,20}/;

// IP Address
valid.ipAddress = /^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$/;

// Date xx/xx/xxxx
valid.Date = /^\d{1,2}(\-|\/|\.)\d{1,2}\1\d{4}$/;

function validateForm(theForm)
{
	var elArr = theForm.elements; 

	for(var i = 0; i < elArr.length; i++)
	{
		var elem = elArr[i];
		var v = elem.validator; 
		var required = elem.required;
		var value = elem.value;

		if(!v) { continue; }

		var thePat = valid[v];

		if(required)
		{
			if(value=="")
			{
				return foundError(elem);
			}
			else
			{
				var result = thePat.exec(value); 	 

				if(!result) { return foundError(elem); }
			}
		}
		else
		{
			if(value!="")
			{
				var result = thePat.exec(value); 	 

				if(!result) { return foundError(elem); }
			}
		}
	}

	return true;
}

function foundError(elem)
{
	alert(elem.name + " is incorrect or required - please try again");

	return false;
}
