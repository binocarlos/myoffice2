package Webkit::DBObject;

#################
# Webkit::DBObject
##################
# This class acts as the base class for any object that wants
# to write to the database.
###################
# The schema must be a hash of table fields (excluding the id - which the
# table must have).
#
# Each entry in the schema must have a type (id, datetime, date, time, string, integer, int, float)
# and optionally a required
#
# The following logical methods are given to interact with the
# database
#
# Load
# Save
# Create
# Delete
# Load Children
####################

use strict qw(vars);

use vars qw(@ISA $AUTOLOAD);

############
# Quoted Types, these are the property types that must be quoted before inserted.

my $quoted_types = {
	string => 1,
	date => 1,
	datetime => 1,
	time => 1 };

#############
# Parse map - this maps property types onto the modules used to parse & flatten them

my $parsemap = {
	date => 'Webkit::Date',
	datetime => 'Webkit::DateTime',
	time => 'Webkit::Time' };

################################################
################################################
## CONSTRUCTORS

#########
# Blank creates a single clear blessed object
# Initial properties:
# ------------
# classname
# data
# error_text

sub blank
{
	my ($classname) = @_;

	my $self = {};

	bless($self, $classname);

	$self->{classname} = $classname;
	$self->{data} = undef;
	$self->{error_text} = undef;
	$self->{changed} = undef;

	return $self;
}

#########
# Constructor creates a sql enabled clear blessed object

sub constructor
{
	my ($classname, $db) = @_;

	if(!$db)
	{
		Webkit::Error->wkerror("You need a db to call $classname->constructor");

		return undef;
	}

	my $self = &blank($classname);

	$self->{db} = $db;

	return $self;
}

sub clone
{
	my ($self) = @_;

	my $clone = &constructor($self->{classname}, $self->{db});

	foreach my $key (keys %{$self->{data}})
	{
		if($key ne 'id')
		{
			$clone->{data}->{$key} = $self->{data}->{$key};
		}
	}

	return $clone;
}

#########
# AUTOLOAD - defines accessor catches

sub AUTOLOAD
{
	my $self = shift;
	my $attr = $AUTOLOAD;
	$attr =~ s/.*:://;
	return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods

	my $js_mode = undef;

	if($attr =~ s/^js_//)
	{
		$js_mode = 1;
	}

	my $schema = $self->schema;

	if($schema->{$attr})
	{
		if(@_)
		{
			$self->set_value($attr, shift);
		}

		my $val = $self->get_value($attr);

		if($js_mode)
		{
			$val =~ s/'/\\'/g;
			$val =~ s/\r?\n/\\n/g;
		}

		return $val;
	}
	else
	{
		my ($package, $filename, $line) = caller;

		my $table = $self->table;
		my $method = $attr;

		my $text=<<"+++";
No Method - $method in $table<hr>
Package: $package<br>
Filename: $filename<br>
Line: $line
+++

		die $text;
	}

	return;
}


#########
# Load (new_with_id) will load one object from a clause or id
# -------
# id - if this is set then it creates a "where id = $id" clause
# clause - if this is set, it is used as the clause (e.g. "where email='someone@somewhere.net'")
# 

sub load
{
	my ($classname, $db, $attr) = @_;

	if(!$db)
	{
		Webkit::Error->wkerror("You need a db to call $classname->load_object");

		return undef;
	}

	if($attr->{id}!~/\w/&&$attr->{clause}!~/\w/)
	{
		Webkit::Error->wkerror("You have to give either an id or a clause to call $classname->load_object");

		return undef;
	}

	my $object = &constructor($classname, $db);

	if($attr->{id}=~/\w/)
	{
		$attr->{table} = $object->table;
		$attr->{binds} = [$attr->{id}];
		$attr->{clause} = "id = ?";
	}
	elsif($attr->{clause}=~/\w/)
	{
		$attr->{table} = $object->table;
	}

	my $data = $db->get_select_ref($attr);

	if(!$data)
	{
		if(($attr->{id}=~/\d/)&&(!$attr->{ignore_null}))
		{
			die "There is no $object->{classname} with the id of $attr->{id}";
		}

		return undef;
	}

	$object->assign_data($data);

	return $object;
}

################################################
################################################
## INSTANCE METHODS

#######
# Removes the following properties:
# --------
# sql
# data
# classname

sub DESTROY
{
	my ($self) = @_;

	foreach my $key (keys %$self)
	{
		if($self->{$key})
		{
			$self->{$key} = undef;
		}
	}

	$self = undef;
}

#######
# ABSTRACT - returns the classes database table
# --------

sub table
{
	return undef;
}

#########
# Single Table
# This is used by other functions to get the table name without the ^webkit.

sub single_table
{
	my ($self) = @_;

	my $wholetable = $self->table;

	$wholetable =~ s/^\w+\.//;

	return $wholetable;
}

#######
# ABSTRACT - returns the classes schema
# --------

sub schema
{
	return undef;
}

#######
# returns the schema entry for $key
# --------

sub schemaentry
{
	my ($self, $key) = @_;

	return $self->schema->{$key};	
}

#########
# get_id - this returns the id of this object

sub get_id
{
	my ($self) = @_;

	return $self->get_value('id');
}

########
# has_property - checks whether this object has a particular property
# within its schema
# -------
# key - the property to check

sub has_property
{
	my ($self, $key) = @_;

	if(!$self)
	{
		Webkit::Error->wkerror("Not a Blessed Object");
	}

	my $schema = $self->schema;

	if(!$schema)
	{
		Webkit::Error->wkerror("Not a Blessed Object");
	}

	if(($self->schema->{$key})||($key eq 'id'))
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

##### This will return true if the object existed BEFORE a save_or_create

sub existed
{
	my ($self) = @_;

	return $self->{_existed};
}

#######
# exists - checks the id data entry for /^\d+$/

sub exists
{
	my ($self) = @_;

	if(($self->{data}->{id}=~/^\d+$/)&&($self->{data}->{id}>0))
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

sub save_or_create
{
	my ($self) = @_;

	if($self->exists)
	{
		$self->{_existed} = 1;
		$self->save;
	}
	else
	{
		$self->create;
	}
}

sub remove_db
{
	my ($self) = @_;

	delete($self->{db});
}

sub assign_db
{
	my ($self, $db) = @_;

	$self->{db} = $db;
}

##########
# should_parse_property - checks if the parsemap contains a class 
# i.e. should the database value be converted into an object before used (e.g. DateTime etc).

sub should_parse_property
{
	my ($self, $property) = @_;

	my $schemaentry = $self->schemaentry($property);

	if(!$schemaentry)
	{
		return undef;
	}

	if($parsemap->{$schemaentry->{type}})
	{
		return 1;
	}
	else
	{
		return undef;
	}
}

#######
# Will clear any of the children from the $table class
# that were previously loaded.

sub clear_children
{
	my ($self, $table) = @_;

	$self->{$table.'_array'} = undef;
	$self->{$table.'_hash'} = undef;
}


#######
# Simple Accessor for the object array loaded by load_children
# Turns the argument into the property

sub get_child_count
{
	my ($self, $table) = @_;

	my $arr = $self->get_child_array($table);

	if(!$arr)
	{
		return 0;
	}
	else
	{
		my $count = @$arr;

		return $count;
	}
}

sub get_first_child
{
	my ($self, $table) = @_;

	my $arr = $self->get_child_array($table);

	my $obj = $arr->[0];

	return $obj;
}

sub get_child
{
	my ($self, $table, $id) = @_;

	my $hash = $self->get_child_hash($table);

	my $obj = $hash->{$id};

	return $obj;
}

sub has_children
{
	my ($self, $table) = @_;
	
	return $self->get_child_array($table);
}

sub ensure_child_array
{
	my ($self, $table) = @_;

	my $arr = $self->get_child_array($table);

	if(!$arr)
	{
		return [];
	}
	else
	{
		return $arr;
	}
}

sub get_child_array
{
	my ($self, $table) = @_;

	return $self->{$table.'_array'};
}

sub replace_children_from_array
{
	my ($self, $table, $arr) = @_;

	my $hash = Webkit::AppTools->get_id_hash($arr);

	$self->replace_child_array($table, $arr);
	$self->replace_child_hash($table, $hash);
}

sub replace_child_array
{
	my ($self, $table, $arr) = @_;

	$self->{$table.'_array'} = $arr;
}

sub replace_child_hash
{
	my ($self, $table, $hash) = @_;

	$self->{$table.'_hash'} = $hash;
}

#######
# Simple Accessor for the object hash loaded by load_children
# Turns the argument into the property

sub ensure_child_hash
{
	my ($self, $table) = @_;

	my $hash = $self->get_child_hash($table);

	if(!$hash)
	{
		return {};
	}
	else
	{
		return $hash;
	}
}

sub get_child_hash
{
	my ($self, $table) = @_;

	return $self->{$table.'_hash'};
}

sub get_html_value
{
	my ($self, $key) = @_;

	my $value = $self->get_value($key);

	$value =~ s/\r?\n/<br>/g;

	return $value;
}

sub get_js_number_value
{
	my ($self, $key) = @_;

	my $ret = $self->get_value($key);

	if($ret!~/\w/)
	{
		$ret = 'null';
	}

	return $ret;
}

sub get_xml_value
{
	my ($self, $key) = @_;

	my $value = $self->get_value($key);

	$value =~ s/'/\\'/g;
	$value =~ s/"/\\"/g;
	$value =~ s/&/&amp;/g;

	return $value;
}

sub get_js_value
{
	my ($self, $key, $html) = @_;

	my $value = $self->get_value($key);

	$value =~ s/'/\\'/g;
	$value =~ s/"/\\"/g;

	if($html)
	{
		$value =~ s/\r?\n/<br>/g;
	}
	else
	{
		$value =~ s/\r?\n/\\n/g;
	}

	return $value;
}

sub get_data
{
	my ($self, $key) = @_;

	return $self->{data}->{$key};
}

#######
# get_value - another way of saying get_name
# ------
# key - the value to get

sub get_value
{
	my ($self, $key) = @_;

	if(!$self->has_property($key))
	{
		Webkit::Error->wkerror("You cannot call $self->{classname} - set_$key no such property");
		return undef;
	}

	my $value = $self->{data}->{$key};

	if($self->should_parse_property($key))
	{
		my $ref = ref($value);

		if(ref($value)=~/\w/)
		{
			return $value;
		}

		my $newvalue = $self->get_parsed_value($key);

		$self->{data}->{$key} = $newvalue;

		return $newvalue;

	}	

	return $value;
}

#######
# set_value - another way of saying set_name
# ------
# key - the property to set
# value - the value to set it to

sub set_value
{
	my ($self, $key, $value) = @_;

	if(!$self->has_property($key))
	{
		Webkit::Error->wkerror("You cannot call $self->{classname} - set_$key no such property");
		return undef;
	}

	if($key eq 'id')
	{
		Webkit::Error->wkerror("You cannot set the id of an object, this is done by MySQL and will be assigned to the object when it is created.");
		return undef;
	}

	$self->{data}->{$key} = $value;
	$self->{changed}->{$key} = 1;

	return $self->{data}->{$key};
}

##################
# Get parsed value
# This will return the parsed value for an objects property
# A ref check is done and if the existing value is a ref, it is simple returned,
# otherwise ->parse_from_sql is called in the corresponding module

sub get_parsed_value
{
	my ($self, $key) = @_;

	if(!$self->has_property($key))
	{
		Webkit::Error->wkerror("You cannot call $self->{classname} - get_parsed_value - $key no such property");
		return undef;
	}

	my $existing_value = $self->{data}->{$key};

	if(ref($existing_value)=~/\w/)
	{
		return $existing_value;
	}

	if($self->should_parse_property($key))
	{
		my $schemaentry = $self->schemaentry($key);

		my $module = $parsemap->{$schemaentry->{type}};

		my $classname = $parsemap->{$schemaentry->{type}};

		my $newvalue = &{$classname.'::parse_from_sql'}($classname, $existing_value);

		return $newvalue;
	}
	else
	{
		return $existing_value;
	}
}

##################
# Get flattened value
# This will return the flattened value for an objects property
# In other words, if the property is currently an object, this
# method will return the string representation of it, as was passed
# originally by the database (and therefore suitable to re-insert).

sub get_flattened_value
{
	my ($self, $key) = @_;

	if(!$self->has_property($key))
	{
		Webkit::Error->wkerror("You cannot call $self->{classname} - get_flattened_value - $key no such property");
		return undef;
	}

	my $existing_value = $self->get_value($key);

	if(ref($existing_value)!~/\w/)
	{
		return $existing_value;
	}

	if($self->should_parse_property($key))
	{
		my $schemaentry = $self->schemaentry($key);

		my $classname = $parsemap->{$schemaentry->{type}};

		my $newvalue = &{$classname.'::parse_to_sql'}($classname, $existing_value);

		return $newvalue;
	}
	else
	{
		return $existing_value;
	}
}

#######
# assign_data - sets the current dataset
# TODO - assign the datafields from the schema, 
# not just raw copy
# --------

sub assign_data
{
	my ($self, $data) = @_;

	if($data)
	{
		$self->{data} = $data;
	}
}

#######
# get_quoted_value - this will check the objects schema
# and then quote the value if it is one of, 'string', 'date', 'datetime', 'time'
# -------
# key - the quoted value to get

sub get_quoted_value
{
	my ($self, $key) = @_;

	if(!$self->has_property($key))
	{
		Webkit::Error->wkerror("There is no $key property for a $self->{classname}");

		return undef;
	}

#	###############
#	# This is to ensure that any objects residing as properties are flattened
#	# BEFORE thet are inserted or updated.

	my $flat_value = $self->get_flattened_value($key);

	my $schemaentry = $self->schemaentry($key);

	if(!$quoted_types->{$schemaentry->{type}})
	{
		return $flat_value;
	}
	else
	{
		return $self->{db}->quote($flat_value);
	}
}

#######
# add_child - adds the element into the _table_hash and _table_array properties

sub add_child
{
	my ($self, $child) = @_;

	if(!$self->{$child->single_table.'_hash'}->{$child->get_id})
	{
		push(@{$self->{$child->single_table.'_array'}}, $child);
		$self->{$child->single_table.'_hash'}->{$child->get_id} = $child;
	}
}

###########
# add_children - this will take the classname and attr for the children
# then call load_objects with the childs classname, passing self as the parent
# (and therefore having each child added to self).

sub add_children
{
	my ($self, $childclass, $attr) = @_;

	return &load_objects($childclass, $self->{db}, $attr, $self);
}

###########
# load_children - this will take the classname and attr for the children
# before appending the link field to the clause (i.e. table_id = self.id)
# then call load_objects with the childs classname, passing self as the parent
# (and therefore having each child added to self).

sub load_children
{
	my ($self, $childclass, $attr) = @_;

	$attr->{table} = &{$childclass.'::table'};

	if($attr->{clause} =~ /\w/)
	{
		$attr->{clause} = "\n and \n(\n".$attr->{clause}."\n)";
	}

	$attr->{clause} = "\n(\n".$self->single_table.'_id = '.$self->get_id."\n)\n".$attr->{clause};

	return &load_objects($childclass, $self->{db}, $attr, $self);
}

###############
# delete_children - this will call DB->delete using the table_id = self.id link
# 

sub delete_children
{
	my ($self, $childclass, $attr) = @_;

	$attr->{table} = &{$childclass.'::table'};

	if($attr->{clause} =~ /\w/)
	{
		$attr->{clause} = ' and '.$attr->{clause};
	}

	$attr->{clause} = $self->single_table.'_id = '.$self->get_id.$attr->{clause};

	$self->{db}->delete($attr);
}

#########
# create - calls the insert method of the DB, after having
# cycled through the data and quoting where neccessary

sub create
{
	my ($self) = @_;

	if($self->exists)
	{
		Webkit::Error->wkerror("You cannot call create on an existing object $self->{classname}");
	}

	my $insertattr = {
		table => $self->table };

	my $insertdata;

	foreach my $schemakey (keys %{$self->schema})
	{
		my $value = $self->get_quoted_value($schemakey);

		$insertdata->{$schemakey} = $value;
	}

	$self->{db}->insert($insertattr, $insertdata);

	$self->{data}->{id} = $self->{db}->get_last_insert_id;

	return 1;
}

#########
# save - calls the update method of DB, it only includes
# the values from $self->{changed}.

sub save
{
	my ($self) = @_;

	if(!$self->exists)
	{
		Webkit::Error->wkerror("You cannot call save on a non-existing object $self->{classname}");
	}

	if(!$self->{changed})
	{
		return;
	}

	my $updateattr = {
		clause => ' id = '.$self->get_id,
		table => $self->table };

	my $updatedata;

	foreach my $updatekey (keys %{$self->schema})
	{
		if($self->{changed}->{$updatekey})
		{
			my $value = $self->get_quoted_value($updatekey);

			$updatedata->{$updatekey} = $value;
		}
	}

	$self->{db}->update($updateattr, $updatedata);

	return 1;
}

###########
# delete - will delete the current object

sub delete
{
	my ($self) = @_;

	if(!$self->exists)
	{
		Webkit::Error->wkerror("You cannot call delete on a non-existing object");

		return undef;
	}

	my $id = $self->get_id;

	my $delete_attr = {
		table => $self->table,
		clause => " id = $id " };

	$self->{db}->delete($delete_attr);

	return 1;
}

sub delete_with_clause
{
	my ($classname, $db, $attr) = @_;

	$attr->{table} = &{$classname.'::table'};

	if($attr->{clause} !~ /\w/)
	{
		die "You cannot call delete_with_clause without a clause!";
	}

	$db->delete($attr);

	return 1;
}

#########
# Error - cycles through the objects schema,
# if the definition says 'required' and the value
# contains nothing, it will add error_text to the object

sub error
{
	my ($self, $ignore) = @_;

	foreach my $key (keys %{$self->schema})
	{
		if($ignore->{$key})
		{
			next;
		}

		my $definition = $self->schemaentry($key);

		if($definition->{ignore_error})
		{
			next;
		}

		if(!$definition->{required})
		{
			next;
		}

		my $value = $self->get_value($key);

		if($value!~/\w/)
		{
			$self->{error_text} = "The $key field is required";

			return 1;
		}
	}

	return undef;
}

sub get_existing_object_with_same_value
{
	my ($self, $field) = @_;

	my $clause=<<"+++";
$field = ?
+++

	my $binds = [$self->get_value($field)];

	if($self->exists)
	{
		$clause.=<<"+++";
and id != ?
+++

		push(@$binds, $self->get_id);
	}

	my $existing_object = &load($self->{classname}, $self->{db}, {
		clause => $clause,
		binds => $binds });

	return $existing_object;
}

################################################
################################################
## CLASS METHODS

########
# Load Objects will take the following attr
# It must only be called as a result of having
# called a public accessor (i.e. load_single, load_array etc).
# if parent is defined, $parent->add_child() will be called
# for each object loaded

sub load_objects
{
	my ($classname, $db, $attr, $parent) = @_;

	if($attr->{table}!~/\w/)
	{
		$attr->{table} = &{$classname.'::table'};
	}

	my $datarows = $db->get_select_refs($attr);

	my $objects;

	foreach my $datarow (@$datarows)
	{
		my $object = &constructor($classname, $db);

		$object->assign_data($datarow);

		push(@$objects, $object);

		if($parent)
		{
			$parent->add_child($object);
		}
	}

	return $objects;
}

sub get_calendar_value
{
	my ($self, $key) = @_;

	my $value = $self->get_value($key);

	if(!$value)
	{
		return '';
	}

	my $day = $value->Day;
	my $month = $value->Month;
	my $year = $value->Year;

	$day =~ s/^(\d)$/0$1/;
	$month =~ s/^(\d)$/0$1/;

	my $st = $day.'/'.$month.'/'.$year;

	return $st;
}

sub set_calendar_value
{
	my ($self, $key, $value) = @_;

	if($value =~ /(\d+) ?\/ ?(\d+) ?\/ ?(\d+)/)
	{
		my $newdate = Webkit::Date->new($2.'/'.$1.'/'.$3);

		$self->set_value($key, $newdate);
	}
}

sub save_calendar_value
{
	my ($self, $key, $params) = @_;

	my $value = $params->{$key.'date'};

	if(!$value)
	{
		$value = $params->{$key};
	}

	if($value!~/\d/)
	{
		return;
	}

	if($value =~ /(\d+) ?\/ ?(\d+) ?\/ ?(\d+)/)
	{
		my $newdate = Webkit::Date->new($2.'/'.$1.'/'.$3);

		$self->set_value($key, $newdate);
	}
}

sub radio_checked
{
	my ($self, $field, $value) = @_;

	if($self->{data}->{$field} eq $value) { return ' CHECKED'; }
	else { return ''; }
}

1;
