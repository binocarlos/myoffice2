var digits = "0123456789";
var lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
var uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
var blanks = " \t\n\r";  // aka whitespace chars

var decimalPointDelimiter = "."
var phoneNumberDelimiters = "()- ";
var validUSPhoneChars = digits + phoneNumberDelimiters;
var digitsInUSPhoneNumber = 10;
var ZIPCodeDelimiters = "-";
var ZIPCodeDelimeter = "-"
var digitsInZIPCode1 = 5
var digitsInZIPCode2 = 9
var USStateCodeDelimiter = "|";
var USStateCodes = "AL|AK|AS|AZ|AR|CA|CO|CT|DE|DC|FM|FL|GA|GU|HI|ID|IL|IN|IA|KS|KY|LA|ME|MH|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|MP|OH|OK|OR|PW|PA|PR|RI|SC|SD|TN|TX|UT|VT|VI|VA|WA|WV|WI|WY|AE|AA|AE|AE|AP|al|ak|as|az|ar|ca|co|ct|de|dc|fm|fl|ga|gu|hi|id|il|in|ia|ks|ky|la|me|mh|md|ma|mi|mn|ms|mo|mt|ne|nv|nh|nj|nm|ny|nc|nd|mp|oh|ok|or|pw|pa|pr|ri|sc|sd|tn|tx|ut|vt|vi|va|wa|wv|wi|wy|ae|aa|ae|ae|ap"
var formstatus = '';

function isEmpty(s)
  {
  return ((s == null) || (s.length == 0));
  }

function isBlank(s)
  {
  var i;

  if (isEmpty(s))
    return true;

  for (i=0; i<s.length; i++)
    {   
    var c = s.charAt(i);
    if (blanks.indexOf(c) == -1) 
      return false;
    }
  return true;
  }

function stripCharsInBag (s, bag)
  {
  var i;
  var returnString = "";

  for (i = 0; i < s.length; i++)
    {   
    var c = s.charAt(i);
    if (bag.indexOf(c) == -1) 
      returnString += c;
    }
  return returnString;
  }

function stripCharsNotInBag (s, bag)
  {
  var i;
  var returnString = "";

  for (i = 0; i < s.length; i++)
    {   
    var c = s.charAt(i);
    if (bag.indexOf(c) != -1) 
      returnString += c;
    }
  return returnString;
  }

function stripBlanks(s)
  {
  return stripCharsInBag(s, blanks)
  }

function stripLeadingBlanks(s)
  { 
  var i = 0;
  while ((i < s.length) && (blanks.indexOf(s.charAt(i)) != -1))
     i++;
  return s.substring(i, s.length);
  }


function stripTrailingBlanks(s)
  { 
  var i = s.length - 1;
  while ((i >= 0) && (blanks.indexOf(s.charAt(i)) != -1))
     i--;
  return s.substring(0, i+1);
  }

function stripLeadingTrailingBlanks(s)
  { 
  s = stripLeadingBlanks(s);
  s = stripTrailingBlanks(s);
  return s;
  }

function isLetter(c)
  {
  return (((c >= "a") && (c <= "z")) || ((c >= "A") && (c <= "Z")));
  }

function isDigit(c)
  {
  return ((c >= "0") && (c <= "9"));
  }
 
function validate_id(s, req, title)
{
	if((!isBlank(s))&&(!isInteger(s)))
	{
		formstatus = "The " + title + " field must be a number";
		return false;
	}
	
	if((req)&&(parseInt(s)<=0))
	{
		formstatus = "The " + title + " field is required";
		return false;
	}
	
	return true;
}

function validate_price(value)
{
	var value_st = "" + value;

	if(value_st.length==0)
	{
		return false;
	}
		
	var found_dot = false;
	var post_dot_digits = 0;
	
	for(i=0; i<value_st.length; i++)
	{
		var ch = value_st.charAt(i);
				
		if(ch==".")
		{
			if(found_dot) { return false; }
			else { found_dot = true; }
		}
		else
		{
			if(isDigit(ch))
			{
				if(found_dot)
				{
					if(post_dot_digits==2)
					{
						return false;
					}
					else
					{
						post_dot_digits++;
					}
				}
			}
			else { return false; }
		}
	}
	
	return true;
}
				
function validate_float(s, req, title)
{
	if((req)&&(isBlank(s)))
	{ 
		formstatus = "The " + title + " field is required";
		return false;
	}
	
	if((!isBlank(s))&&(!isFloat(s)))
	{
		formstatus = "The " + title + " field<br>must be a floating point number";
		return false;
	}

	return true;
}

function validate_date(day, month, year, req, title)
{
	var blanks = 0;
	
	if(day == -1) { blanks++; }
	if(month == -1) { blanks++; }
	if(year == -1) { blanks++; }
	
	if(blanks==0) { return true; }
	
	if((req)&&(blanks>0))
	{
		formstatus = "The " + title + " field is required";
		return false;
	}
	
	if((blanks>0)&&(blanks<3))
	{
		formstatus = "The " + title + " field is invalid";
		return false;
	}		
		
	return true;
}
	
function validate_integer(s, req, title)
{
	if((req)&&(isBlank(s)))
	{ 
		formstatus = "The " + title + " field is required";
		return false;
	}

	if((!isBlank(s))&&(!isInteger(s)))
	{ 
		formstatus = "The " + title + " field must be an integer";
		return false;
	}

	return true;
}

function validate_string(s, req, title)
{
	if((req)&&(isBlank(s)))
	{ 
		formstatus = "The " + title + " field is required";		
		return false; 
	}

	return true;
}

function isInteger(s)
  {
  if (isBlank(s))
    return false;

  if ((s.charAt(0) == "-") || (s.charAt(0) == "+"))
    var i = 1;
  else
    var i = 0;

  for (i; i<s.length; i++)
    {   
    var c = s.charAt(i);
    if (!isDigit(c)) 
      return false;
    }
  return true;
  }

function isFloat(s)
  { 
  var seenDecimalPoint = false;

  if (isBlank(s)) 
    return false;
  if (s == decimalPointDelimiter) 
    return false;
  if ((s.charAt(0) == "-") || (s.charAt(0) == "+"))
    var i = 1;
  else
    var i = 0;

  for (i; i<s.length; i++)
    {   
    var c = s.charAt(i);

    if (c == decimalPointDelimiter) 
	{
		if(seenDecimalPoint) { return false; }
		else { seenDecimalPoint = true; }
	}
    else if (!isDigit(c)) 
      return false;
    }
  return true;
  }

function isAlphabetic(s)
  {
  var i;

  if (isBlank(s)) 
     return false;

  for (i = 0; i < s.length; i++)
  {   

  var c = s.charAt(i);

  if (!isLetter(c))
    return false;
  }

  return true;
  }


function isAlphanumeric(s)
  {
  var i;

  if (isBlank(s)) 
     return false;

  for (i = 0; i < s.length; i++)
    {   
    // Check that current character is number or letter
    var c = s.charAt(i);

    if (! (isLetter(c) || isDigit(c) ) )
    return false;
    }

  return true;
  }

function isEmail(s)
  { 
  if (isBlank(s)) 
    return false;
  
  var i = 1;
  var sLength = s.length;
  while ((i < sLength) && (s.charAt(i) != "@"))
    i++

  if ((i >= sLength) || (s.charAt(i) != "@")) 
    return false;
  else 
    i += 2;
  while ((i < sLength) && (s.charAt(i) != "."))
    i++

  if ((i >= sLength - 1) || (s.charAt(i) != ".")) 
    return false;
  else 
    return true;
  }


function isIntegerInRange (s, a, b)
  { 
  if (isBlank(s)) 
    return false;
  if (!isInteger(s)) 
    return false;
  var num = parseInt(s);
  return ((num >= a) && (num <= b));
  }

function getCheckedRadioButton(radioSet)
  { 
  for (var i=0; i<radioSet.length; i++)
    if (radioSet[i].checked)
      return i;
  return -1;
  }


function getCheckedCheckboxes(checkboxSet)
  {
  var arr = new Array();
  for (var i=0,j=0; i<checkboxSet.length; i++)
    if (checkboxSet[i].checked)
      arr[j++] = i;
  if (arr.length > 0)
    return arr;
  else
    return -1;
  }


function getCheckedSelectOptions(select)
  {
  var arr = new Array();
  for (var i=0,j=0; i<select.length; i++)
    if (select.options[i].selected)
      arr[j++] = i;
  if (arr.length > 0)
    return arr;
  else
    return -1;
  }


function check_null_gui(gui, title, status)
{
	var value = gui.value;
	
	if(value==-1)
	{
		status.innerText = 'You must select a ' + title;

		return false;
	}
	else
	{
		return true;
	}
}

function check_null_date(form, id, title, status)
{
	var date_value = form[id + '_date'].value;
	var month_value = form[id + '_month'].value;
	var year_value = form[id + '_year'].value;

	if((date_value==-1)||(month_value==-1)||(year_value==-1))
	{
		status.innerText = 'The ' + title + ' field is invalid';

		return false;
	}
	else
	{
		return true;
	}
}

