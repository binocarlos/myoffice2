package Webkit::ExcelSheet;

use strict;

use Spreadsheet::WriteExcel ();
use Spreadsheet::ParseExcel ();
use Spreadsheet::WriteExcel::Utility ();
use File::Temp ();

sub new
{
	my ($classname) = @_;

	my $self = {};

	bless($self, $classname);

	$self->{row} = 0;
	$self->{col} = 0;
	$self->{current_worksheet} = undef;
	$self->{color_number} = 33;

	$self->generate_file;

	$self->{workbook} = Spreadsheet::WriteExcel->new($self->file_path);

	return $self;
}

sub write
{
	my ($self, $attr) = @_;

	my $row = $attr->{row};
	my $col = $attr->{col};
	my $sheet = $attr->{sheet};

	if(!$row)
	{
		$row = $self->row;
	}

	if(!$col)
	{
		$col = $self->col;
	}

	if(!$sheet)
	{
		$sheet = $self->current_worksheet;
	}
	
	if(!$sheet)
	{
		die "You must have a current worksheet to write";
	}

	my $format;

	if($attr->{format}=~/\w/)
	{
		$format = $self->get_format($attr->{format});
	}

	my $value = $attr->{value};

	if($value=~/^=/)
	{
		$sheet->write_formula($row, $col, $value, $format);
	}
	else
	{
		$sheet->write($row, $col, $value, $format);
	}
}

sub set_row
{
	my ($self, $value) = @_;

	$self->{row} = $value;

	return $self->{row};
}

sub set_col
{
	my ($self, $value) = @_;

	$self->{col} = $value;

	return $self->{col};
}

sub reset_row
{
	my ($self) = @_;

	$self->{row} = 0;
}

sub reset_col
{
	my ($self) = @_;

	$self->{col} = 0;
}

sub row
{
	my ($self, $value) = @_;

	if($value)
	{
		$self->{row} += $value;
	}

	return $self->{row};
}

sub col
{
	my ($self, $value) = @_;

	if($value)
	{
		$self->{col} += $value;
	}

	return $self->{col};
}

sub generate_worksheet
{
	my ($self, $key, $title) = @_;

	my $sheet = $self->{workbook}->add_worksheet($title);

	return $self->worksheet($key, $sheet);
}

sub current_worksheet
{
	my ($self, $sheet) = @_;

	if($sheet)
	{
		$self->{current_worksheet} = $sheet;
	}

	return $self->{current_worksheet};
}

sub worksheet
{
	my ($self, $key, $sheet) = @_;

	if($sheet)
	{
		$self->{_worksheets}->{$key} = $sheet;
	}

	return $self->{_worksheets}->{$key};
}

sub generate
{
	my ($self) = @_;


}

sub get_download_filename
{
	my ($self) = @_;

	return 'spreadsheet.xls';
}

sub get_mime_type
{
	my ($self) = @_;

	return 'application/excel';
}

sub generate_file
{
	my ($self) = @_;

	my $fh = File::Temp->new();
	my $fname = $fh->filename;
	
	$self->{file_path} = $fname;
}

sub get_file_contents
{
	my ($self) = @_;

	return Webkit::AppTools->read_file_contents($self->file_path);
}

sub file_path
{
	my ($self) = @_;

	return $self->{file_path};
}

sub get_format
{
	my ($self, $key) = @_;

	if($self->{_formats}->{$key})
	{
		return $self->{_formats}->{$key};
	}
	else
	{
		my $props = $self->get_format_prop($key);

		if(!$props)
		{
			return undef;
		}

		if($props->{formats})
		{
			my $extra_fields = $props->{formats};

			delete($props->{formats});

			foreach my $field (@$extra_fields)
			{
				my $sub_props = $self->get_format_prop($field);

				foreach my $key (keys %$sub_props)
				{
					if(!$props->{$key})
					{
						$props->{$key} = $sub_props->{$key};
					}
				}
			}
		}

		if($props)
		{
			my @color_checks = qw(bg_color color border_color);

			foreach my $color_check (@color_checks)
			{
				my $value = $props->{$color_check};

				if($value=~/^#\w{6}$/)
				{
					$self->{color_number}++;

					$self->{workbook}->set_custom_color($self->{color_number}, $value);

					$props->{$color_check} = $self->{color_number};
				}
			}

			if($props->{bg_color})
			{
				$props->{pattern} = 1;
			}

			my $format = $self->{workbook}->add_format(%$props);

			$self->{_formats}->{$key} = $format;

			return $format;
		}
		else
		{
			return undef;
		}
	}
}

sub get_format_props
{
	my ($self) = @_;

	return;
}

sub get_format_prop
{
	my ($self, $field) = @_;

	my $props = $self->get_format_props;

	if($props)
	{
		return $props->{$field};
	}
	else
	{
		return undef;
	}
}

sub get_col_letter
{
	my ($self, $col) = @_;

	my $notation = xl_rowcol_to_cell(1, $col);

	if($notation=~/^([a-z]+)\d+$/i)
	{
		return $1;
	}
	else
	{
		return $col;
	}
}

1;
