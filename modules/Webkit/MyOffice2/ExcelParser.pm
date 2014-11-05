package Webkit::MyOffice2::ExcelParser;

use strict;

use Spreadsheet::ParseExcel;
use Data::Dumper;

sub new
{
        my ($classname, $db, $filepath) = @_;

        my $self = {};

        bless($self, $classname);

        if($filepath)
        {
                my $parser = new Spreadsheet::ParseExcel;

                my $book = $parser->Parse($filepath);

                $self->{book} = $book;
        }

        $self->{db} = $db;

        return $self;
}

sub get_sheet
{
        my ($self, $index) = @_;

        return $self->{book}->{Worksheet}[$index];
}

sub parse_book
{
        my ($self) = @_;

}

sub parse_sheet
{
        my ($self, $sheet_index) = @_;

}

sub gccv
{
        my ($self, $row, $col, $sheet) = @_;

        return $self->get_cell_coords_value($row, $col, $sheet);
}

sub get_cell_coords_value
{
        my ($self, $row, $col, $sheet) = @_;

        my $cell = $sheet->{Cells}[$row][$col];

        if($cell)
        {
                return $cell->Value;
        }
        else
        {
                return undef;
        }
}

sub get_cell_value
{
        my ($self, $field, $sheet) = @_;

        my $coords = $self->{coords}->{$field};

        my $cell = $sheet->{Cells}[$coords->[0]-1][$coords->[1]-1];

        if($cell)
        {
                return $cell->Value;
        }
        else
        {
                return undef;
        }
}

sub get_string_key
{
	my ($self, $string) = @_;

	$string =~ s/\W//g;
	$string = lc($string);

	return $string;
}

sub parse_tabbed_file
{
	my ($self, $path) = @_;

	my $rows;

	open(IN, $path);

	while(<IN>)
	{
		my @cols = split(/\t/, $_);

		push(@$rows, \@cols);
	}

	close(IN);

	return $rows;
}

sub parse_ticket_prices
{
	my ($self, $st) = @_;

	my @parts = split(/[\/&\+]/, $st);

	my $ret;

	foreach my $part (@parts)
	{
		my $price = $self->parse_price_string($part);

		if($price>0)
		{
			push(@$ret, $price);
		}	
	}

	return $ret;
}

sub parse_yn_st
{
	my ($self, $st) = @_;

	if($st =~ /y/i)
	{
		return 'y';
	}
	elsif($st =~ /n/i)
	{
		return 'n';
	}
	else
	{
		return undef;
	}
}

sub parse_frontback_string
{
	my ($self, $st) = @_;

	if($st =~ /f/)
	{
		return 'front';
	}
	elsif($st =~ /b/)
	{
		return 'back';
	}
	else
	{
		return undef;
	}
}

sub parse_guarantee_string
{
	my ($self, $st) = @_;

	if($st =~ /£([\d\.]+)/)
	{
		return $1;
	}
	else
	{
		return undef;
	}
}

sub parse_deal_string
{
	my ($self, $st) = @_;

	if($st =~ /([\d\.]+)\/([\d\.]+)/)
	{
		return $1;
	}
	else
	{
		return undef;
	}
}

sub parse_integer_string
{
	my ($self, $st) = @_;

	$st =~ s/[^\d-]//g;

	if($st !~ /\d/)
	{
		$st = '0';
	}

	return $st;
}

sub parse_price_string
{
	my ($self, $st) = @_;

	$st =~ s/[^\d\.-]//g;

	if($st !~ /\d/)
	{
		$st = '0';
	}

	return $st;
}

sub parse_date_string
{
	my ($self, $string, $force_year) = @_;

	my $date = undef;

	if($string =~ /(\d+)-(\d+)-(\d+)/)
	{
		my $year = $3;

		if($year<2000)
		{
			$year += 2000;
		}

		if($force_year)
		{
			$year = $force_year;
		}

		my $check = undef;

		if(($2>=1)&&($2<=31))
		{
			if(($1>=1)&&($1<=12))
			{
				$check = 1;
			}
		}

		if($check)
		{
			return Webkit::Date->from_params('date', {
				date_day => $2,
				date_month => $1,
				date_year => $year });
		}
		else
		{
			return undef;
		}
	}

	if($string =~ /(\d+)\/(\d+)\/(\d+)/)
	{
		my $year = $3;
	
		if($year<2000)
		{
			$year += 2000;
		}

		if($force_year)
		{
			$year = $force_year;
		}

		my $check = undef;

		if(($1>=1)&&($1<=31))
		{
			if(($2>=1)&&($2<=12))
			{
				$check = 1;
			}
		}
			
		if($check)
		{
			return Webkit::Date->from_params('date', {
				date_day => $1,
				date_month => $2,
				date_year => $year });
		}
		else
		{
			return undef;
		}
	}

	return undef;
}

sub parse_pl_dump
{
	my ($self, $filepath) = @_;

	my $dump;

	open(IN, $filepath);

	while(<IN>)
	{
		$dump.=$_;
	}

	close(IN);

	my $showing_values;

	eval($dump);

	return $showing_values;
}

1;
