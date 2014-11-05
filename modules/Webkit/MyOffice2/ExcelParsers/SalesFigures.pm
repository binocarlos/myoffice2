package Webkit::MyOffice2::ExcelParsers::SalesFigures;

use vars qw(@ISA);

use strict;

use Webkit::MyOffice2::Tour;
use Webkit::MyOffice2::Venue;
use Webkit::MyOffice2::Booking;
use Webkit::MyOffice2::Deal;
use Webkit::MyOffice2::Tourdate;
use Webkit::MyOffice2::Showing;
use Webkit::MyOffice2::Print;
use Webkit::MyOffice2::Venue;
use Webkit::MyOffice2::ExcelParser;
use Webkit::MyOffice2::SalesFigures;
use Webkit::MyOffice2::SalesFiguresEntry;

@ISA = qw(Webkit::MyOffice2::ExcelParser);

my $basedir = '/home/myoffice/data_files/sales_figures';

my $col_keys = {
	brochure_date => 0,
        date => 1,
        venuename => 2,
        venuecity => 3,
        capacity => 4,
        availiable => 5,
        boxofficeno => 6,
        figuresno => 7,
        figuresstart => 8 };

my $figures_keys = {
        soldseats => 0,
        soldcash => 1,
        reservedseats => 3,
        reservedcash => 4 };

my $month_hash = {
        jan => 1,
        feb => 2,
        mar => 3,
        apr => 4,
        may => 5,
        jun => 6,
        jul => 7,
        aug => 8,
        sep => 9,
        oct => 10,
        nov => 11,
        dec => 12 };


sub new
{
        my ($classname, $db, $tour_id) = @_;

	if(!$tour_id)
	{
		return;
	}

        my $self = &Webkit::MyOffice2::ExcelParser::new($classname, $db);

        $self->{tour} = Webkit::MyOffice2::Tour->load($db, {
        	id => $tour_id });

        $self->load_showings;

        return $self;
}

sub load_showings
{
        my ($self) = @_;
        
        my $tour = $self->{tour};

        $tour->load_children('Webkit::MyOffice2::Showing');
        $tour->load_children('Webkit::MyOffice2::Tourdate');
        $tour->add_children('Webkit::MyOffice2::Venue', {
        	table => 'myoffice2.venue',
        	cols => 'venue.*' });
        $tour->load_children('Webkit::MyOffice2::SalesFigures');
        $tour->load_children('Webkit::MyOffice2::SalesFiguresEntry');

        foreach my $showing (@{$tour->ensure_child_array('showing')})
        {
                $showing->{venue_obj} = $tour->get_child('venue', $showing->venue_id);
        }
        
        foreach my $tourdate (@{$tour->ensure_child_array('tourdate')})
        {
                if($tourdate->showing_id>0)
                {
                        my $showing = $tour->get_child('showing', $tourdate->showing_id);
                        $tourdate->{showing_obj} = $showing;

			$showing->add_child($tourdate);
                }
        }

        foreach my $showing (@{$tour->ensure_child_array('showing')})
        {
                if($showing->has_children('tourdate'))
                {
                        @{$showing->{tourdate_array}} = sort { $a->date->Epoch <=> $b->date->Epoch } @{$showing->{tourdate_array}};
                        
                        my $first_date = $showing->{tourdate_array}->[0];

			if($first_date)
			{
                        	$showing->{_earliest_tourdate_epoch} = $first_date->date->Epoch;
                        }
                }
        }

        @{$tour->{showing_array}} = sort { $a->{_earliest_tourdate_epoch} <=> $b->{_earliest_tourdate_epoch} } @{$tour->{showing_array}};

        foreach my $sales_figures (@{$tour->ensure_child_array('sales_figures')})
        {
                my $sales_entry = $tour->get_child('sales_figures_entry', $sales_figures->sales_figures_entry_id);

		$sales_entry->add_child($sales_figures);

                $sales_figures->{sales_figures_entry_obj} = $sales_entry;
        }

        foreach my $sales_entry (@{$tour->ensure_child_array('sales_figures_entry')})
        {
                my $tourdate = $tour->get_child('tourdate', $sales_entry->tourdate_id);

                $tourdate->{sales_figures_entry_obj} = $sales_entry;

                $sales_entry->{tourdate_obj} = $tourdate;

                if($sales_entry->has_children('sales_figures'))
                {
                        @{$sales_entry->{sales_figures_array}} = sort { $a->week_start->Epoch <=> $b->week_start->Epoch } @{$sales_entry->{sales_figures_array}};
                }
        }

        foreach my $tourdate (@{$tour->ensure_child_array('tourdate')})
        {
                if(!$tourdate->showing_id>0)
                {
                	next;
                }
                	        	
                my $showing = $tourdate->{showing_obj};
                my $venue = $showing->{venue_obj};

		eval {
		$tourdate->{_venue_id} = $showing->venue_id; };

		my $epoch = $tourdate->date->epoch_days;

		push(@{$self->{_tourdate_epoch_map}->{$epoch}}, $tourdate);

                push(@{$venue->{_tourdate_array}}, $tourdate);

		foreach my $figs (@{$tourdate->{sales_figures_entry_obj}->{sales_figures_array}})
		{
			$tourdate->{figs_map}->{$figs->week_start->epoch_days} = $figs;
		}
        }

        foreach my $venue (@{$self->{tour}->{venue_array}})
        {
                my $city = $venue->city;
                $city =~ s/\W//g;
                $city = lc($city);

                push(@{$self->{venue_city_hash}->{$city}}, $venue);
        }
}

sub search_tourdate
{
        my ($self, $city, $date, $mat_mode) = @_;


        $city =~ s/\W//g;
        $city = lc($city);

	my $venues = $self->{venue_city_hash}->{$city};

	my $epoch = 0;

	if($date)
	{
		$epoch = $date->epoch_days;
	}

	my $tourdate_array = $self->{_tourdate_epoch_map}->{$epoch};

	if(!$tourdate_array)
	{
		return undef;
	}
	else
	{
		my $length = @$tourdate_array;

		if($length==0)
		{
			return undef;
		}
		elsif($length==1)
		{
			return $tourdate_array->[0];
		}
		else
		{
			my $relevent_tourdates;

			if($venues)
			{
				foreach my $venue (@$venues)
				{
					foreach my $tourdate (@$tourdate_array)
					{
						if($venue->get_id==$tourdate->{_venue_id})
						{
							push(@$relevent_tourdates, $tourdate);
						}
					}
				}
			}
			else
			{
				$relevent_tourdates = $tourdate_array;
			}

			my $relevent_length = @$relevent_tourdates;

			if($relevent_length==0)
			{
				return undef;
			}
			elsif($relevent_length==1)
			{
				return $relevent_tourdates->[0];
			}
			else
			{
				if($mat_mode eq 'f')
				{
					return $relevent_tourdates->[2];
				}
				elsif($mat_mode eq 'e')
				{
					return $relevent_tourdates->[1];
				}
				else
				{
					return $relevent_tourdates->[0];
				}
			}
		}
	}

        return undef;
}

sub write_to_db
{
        my ($self) = @_;


}

sub parse_date_string
{
        my ($self, $string) = @_;

        my $day;
        my $month;
        my $year = $self->{year};

        if($string =~ /(\d{1,2})\/(\d{1,2})\/(\d{2,4})/)
        {
                $month = $2;
                $day = $1;
        }
        elsif($string =~ /(\d{1,2})\/(\d{1,2})/)
        {
                $month = $2;
                $day = $1;
        }        
        else
        {
                while($string =~ /([a-z]+)/gi)
                {
                        my $st = lc($1);
                        $st = substr($st, 0, 3);

                        if($month_hash->{$st})
                        {
                                $month = $month_hash->{$st};
                        }
                }

                while($string =~ /(\d{1,2})/g)
                {
                        my $num = $1;

                        if(($num>=1)&&($num<=31))
                        {
                                $day = $num;
                        }
                }
        }

        if(!$self->{start})
        {
                if($month<6)
                {
                        $year++;
                }
        }
        
        my $date;
        
        eval {

        $date = Webkit::Date->from_params('date', {
                date_date => $day,
                date_month => $month,
                date_year => $year });
                
        };
       	if($@) { return undef; }

        return $date;
}

sub parse_file
{
        my ($self, $sheetpath, $year) = @_;

        my $parser = new Spreadsheet::ParseExcel;

        my $book = $parser->Parse($sheetpath);

        $self->{year} = $year;

        if($self->{year}=~/_start$/)
        {
                $self->{start} = 1;
                $self->{year} =~ s/_start$//;
        }

        my $figures;

	print "<table width=100% cellpadding=20 border=2>";

        for(my $iSheet=0; $iSheet < $book->{SheetCount}; $iSheet++)
        {
                my $sheet = $book->{Worksheet}[$iSheet];

		my $weekrefs;

		print<<"+++";
<tr><td>
<table border=1>
<tr>
<td></td>
+++

		for(my $col_index = $col_keys->{figuresstart}; $col_index <= $sheet->{MaxCol}; $col_index+=6)
		{
			my $entrydatest = $self->gccv(0, $col_index, $sheet);

			my $entrydate;

			if($entrydatest =~ /(\d{1,2})\/(\d{1,2})\/(\d{2,4})/)
			{
				my $day = $1;
				my $month = $2;
				my $year = $3;

				$day=~s/^0+//;
				$month=~s/^0+//;
				$year=~s/^0+//;

				if($year<2000)
				{
					$year+=2000;
				}

				$entrydate = Webkit::Date->from_params('date', {
					date_date => $day,
					date_month => $month,
					date_year => $year });
			}

			if($entrydatest =~ /(\d{1,2})-(\d{1,2})-(\d{2,4})/)
			{
				my $day = $2;
				my $month = $1;
				my $year = $3;

				$day=~s/^0+//;
				$month=~s/^0+//;
				$year=~s/^0+//;

				if($year<2000)
				{
					$year+=2000;
				}

				$entrydate = Webkit::Date->from_params('date', {
					date_date => $day,
					date_month => $month,
					date_year => $year });
			}


			if($entrydate)
			{
				my $weekref = {
					weekdate => $entrydate,
					weekcol => $col_index };


				print<<"+++";
<td>$entrydate</td>
+++

				push(@$weekrefs, $weekref);
			}
			else
			{
				print<<"+++";
<td><b>$entrydatest</b></td>
+++
			}
			
		}

		print "</tr>";

                for(my $row_index = 3; $row_index <= 200; $row_index++)
                {
                        my $datest = $self->gccv($row_index, $col_keys->{date}, $sheet);

                        if($datest =~ /\w/)
                        {
                                my $mat_mode = undef;

				if($datest =~ /\(([mef])\)/i)
				{
					$mat_mode = $1;
				}

                                my $date = $self->parse_date_string($datest);
                                
                                if(!$date)
                                {
                                	next;	
                                }

                                my $sales_row = {
                                        row => $row_index,
                                        sheet => $iSheet,
                                        datest => $datest,
                                        mat_mode => $mat_mode,
                                        date => $date };

                                foreach my $col_key (keys %$col_keys)
                                {
                                        if($col_key ne 'date')
                                        {
                                                $sales_row->{$col_key} = $self->gccv($row_index, $col_keys->{$col_key}, $sheet);
                                        }
                                }

				print<<"+++";
<tr><td>$sales_row->{date} - 
+++

				my $tourdate = $self->search_tourdate($sales_row->{venuecity}, $sales_row->{date}, $sales_row->{mat_mode});

				if(!$tourdate)
				{
					print<<"+++";
<B>NO TOURDATE</b>
+++
				}
				else
				{
					print<<"+++";
$tourdate </td>
+++
				}

				if($tourdate)
				{
					my $figures_entry = $tourdate->{sales_figures_entry_obj};

					if(!$figures_entry)
					{
						$figures_entry = Webkit::MyOffice2::SalesFiguresEntry->constructor($self->{db});
		                                $figures_entry->tour_id($self->{tour}->get_id);
		                                $figures_entry->tourdate_id($tourdate->get_id);
					}

					my $showing = $self->{tour}->get_child('showing', $tourdate->showing_id);
					my $venue = $self->{tour}->get_child('venue', $showing->venue_id);

					if($sales_row->{surfheld}=~/^\d+$/)
	                                {
	                                        $figures_entry->surf_held($sales_row->{surfheld});
	                                }

	                                if($sales_row->{availiable}=~/^\d+$/)
	                                {
	                                        $figures_entry->tickets_avail($sales_row->{availiable});
	                                }
	
	                                if($sales_row->{figuresno}=~/\w/)
	                                {
	                                        $figures_entry->figures_number($sales_row->{figuresno});
	
						$self->{figures_map}->{$tourdate->showing_id} = $figures_entry->figures_number;
	                                }
					elsif($sales_row->{boxofficeno}=~/\w/)
					{
						$figures_entry->figures_number($sales_row->{boxofficeno});
	
						$self->{figures_map}->{$tourdate->showing_id} = $figures_entry->figures_number;
					}
	                                else
	                                {
	                                        $figures_entry->figures_number($self->{figures_map}->{$tourdate->showing_id});
	                                }

					$figures_entry->save_or_create;

					if(!$tourdate->{sales_figures_entry_obj})
					{
						$tourdate->{sales_figures_entry_obj} = $figures_entry;
					}


	 				foreach my $weekref (@$weekrefs)
					{
						my $entry = $tourdate->{figs_map}->{$weekref->{weekdate}->epoch_days};

						if(!$entry)
						{
							$entry = Webkit::MyOffice2::SalesFigures->constructor($self->{db});

							$entry->org_id(29);
	                                                $entry->tour_id($self->{tour}->get_id);
	                                                $entry->sales_figures_entry_id($figures_entry->get_id);
							$entry->tourdate_id($tourdate->get_id);
	                                                $entry->week_start($weekref->{weekdate});
						}

						my $found_data;
						
						foreach my $key (keys %$figures_keys)
						{
							$found_data->{$key} = 0;	
						}

	                                        foreach my $key (keys %$figures_keys)
	                                        {
	                                                $found_data->{$key} = $self->gccv($row_index, $weekref->{weekcol} + $figures_keys->{$key}, $sheet);
	                                        }
	                                        
	                                        if($found_data->{soldseats}=~/\D/) { $found_data->{soldseats} = 0; }
	                                        if($found_data->{soldcash}=~/[^\d\.]/) { $found_data->{soldcash} = 0; }	                                        

                                                $entry->sold_seats($found_data->{soldseats} || 0);
						$entry->reserved_seats($found_data->{reservedseats} || 0);
                                                $entry->sold_gross($found_data->{soldcash} || 0);
						$entry->reserved_gross($found_data->{reservedcash} || 0);

						my @propsarr = qw(sold_gross reserved_gross);

						foreach my $prop (@propsarr)
						{
							my $value = $entry->get_value($prop);
							$value=~s/\.\./\./;
							
							$entry->set_value($prop, $value);
						}
						
						my $st = '';
						
						eval {
						$entry->save_or_create; };
						
						$st = $@;
						
						my $sold = $entry->sold_seats;	
						my $gross = $entry->sold_gross;			
						
						print "<td>$sold - $gross - $st</td>";

						if(!$tourdate->{figs_map}->{$entry->week_start->epoch_days})
						{
							$tourdate->{figs_map}->{$entry->week_start->epoch_days} = $entry;
						}
					}

					print "</tr>";
				}
			}
		}

		print<<"+++";
</table></td></tr>
+++
	}

	print<<"+++";
</table>
+++
}

1;
