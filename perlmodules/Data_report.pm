#!/usr/bin/perl -w
#
# Chop_files.pm
#
# This file is released under the terms of the Artistic License.  Please see
# the file LICENSE, included in this package, for details.
#
# Copyright (C) 2003 Open Source Development Lab, Inc.
# Author: Jenny Zhang
#
package Data_report;

use strict;
use English;
use FileHandle;
use vars qw(@ISA @EXPORT);
use Exporter;

=head1 NAME

extract_columns()

=head1 SYNOPSIS

extract columns from input file.  
the separator is spaces

=head1 ARGUMENTS

 -infile < the input file >
 -outfile < the output file name >
 -column < the columns to extract >

=cut

@ISA = qw(Exporter);
@EXPORT = qw(extract_columns extract_rows extract_columns_rows get_header extract_columns_rows_sar convert_time_format);

sub extract_columns
{
	my ( $infile, $outfile, @column ) = @_;
	my ($fin, $fout, @data); 
	
	$fin = new FileHandle;		
	unless ( $fin->open( "< $infile" ) ) 
		{ die "can't open file $infile: $!"; }

	$fout = new FileHandle;		
	unless ( $fout->open( "> $outfile" ) ) 
		{ die "can't open file $outfile: $!"; }

	while (<$fin>)
	{
		chop;
		@data = split /\s+/;
		for (my $i=0; $i<$#column; $i++)
		{
			print $fout "$data[$column[$i]] ";
		}
		# the last column
		print $fout "$data[$column[$#column]]\n";
	}
	close($fin);
	close($fout);
}

=head1 NAME

extract_rows()

=head1 SYNOPSIS

extract rows from input file.  The output format can be cvs or gnuplot data

=head1 ARGUMENTS

 -infile < the input file >
 -outfile < the output file name, the output file will be:
         [name].dat: gnuplot data file
         [name].csv: csv file >
 -key < the lines extracted must contain key >
 -format < the format is either csv or gnuplot data >

=cut

sub extract_rows
{
	my ( $infile, $outfile, $key, $comment_key, $format ) = @_;
	my ($fin, $fout, @data, $comment_flag, $lcnt); 
	
	$fin = new FileHandle;		
	unless ( $fin->open( "< $infile" ) ) 
		{ die "can't open file $infile: $!"; }

	$fout = new FileHandle;		
	unless ( $fout->open( "> $outfile" ) ) 
		{ die "can't open file $outfile: $!"; }

	$comment_flag = 0;
	$lcnt = 1;

	while (<$fin>)
	{
		chop;
		@data = split /\s+/;
		if ( $format eq 'csv' )
		{
			# comment is printed once
			if ( /$comment_key/ && $comment_flag == 0 )
			{
				@data = split /\s+/;
				print $fout join(',', @data), "\n";
				$comment_flag = 1;
			}
			elsif ( /^$key$/ )
			{
				print $fout join(',', @data), "\n";
			}
		}
		elsif ( $format eq 'gnuplot' )
		{
			# comment is printed once
			if ( /$comment_key/ && $comment_flag == 0 )
			{
				print $fout '#';
				print $fout join(' ', @data), "\n";
				$comment_flag = 1;
			}
			elsif ( /^$key$/ )
			{
				print $fout "$lcnt ";
				print $fout join(' ', @data), "\n";
				$lcnt++;
			}
		}
	}
	close($fin);
	close($fout);
}

=head1 NAME

extract_columns_rows()

=head1 SYNOPSIS

extract rows and columns from input file.  
The output format can be cvs or gnuplot data

=head1 ARGUMENTS

 -infile < the input file >
 -outfile < the output file name, the output file will be:
         [name].dat: gnuplot data file
         [name].csv: csv file >
 -key < the lines extracted must contain key >
 -comment_key < if a line has comment_key then it is printed as comment >
 -comment < comment the the beginning of the file >
 -columns < columns to be extracted >
 -format < the format is either csv or gnuplot data >

=cut

sub extract_columns_rows
{
	my ( $infile, $outfile, $key, $comment_key, $comment, $format, @column ) = @_;
	my ($finput, $foutput, @data, $comment_flag, $lcnt, $sum); 
	
	$finput = new FileHandle;		
	unless ( $finput->open( "< $infile" ) ) 
		{ die "can't open file $infile: $!"; }

	$foutput = new FileHandle;		
	unless ( $foutput->open( "> $outfile" ) ) 
		{ die "can't open file $outfile: $!"; }

	$comment_flag = 0;
	$lcnt = 0;
	$sum = 0;
	if ( $comment )
	{
		print $foutput "# $comment\n";
	}

	while (<$finput>)
	{
		chop;
		# get rid of leading spaces
		s/^\s+//;
		# skit empty line
		next if (/^$/);
		@data = split /\s+/;
		if ( $format eq 'csv' )
		{
			# comment is printed once
			if ( $comment_key && $comment_flag == 0 )
			{
				if ( /^$comment_key/ )
				{
					for (my $i=0; $i<$#column; $i++)
					{
						print $foutput "$data[$column[$i]],";
					}
					# the last column
					print $foutput "$data[$column[$#column]]\n";
					$comment_flag = 1;
				}
			}
			if ( $data[0] =~ /^$key$/ )
			{
				for (my $i=0; $i<$#column; $i++)
				{
					print $foutput "$data[$column[$i]],";
					$sum += $data[$column[$i]];
				}
				# the last column
				print $foutput "$data[$column[$#column]]\n";
				$sum += $data[$column[$#column]];
			}
		}
		elsif ( $format eq 'gnuplot' )
		{
			# comment is printed once
			if ( $comment_key && $comment_flag == 0 )
			{
				if ( /^$comment_key/ )
				{
					print $foutput '#';
					for (my $i=0; $i<$#column; $i++)
					{
						print $foutput "$data[$column[$i]] ";
					}
					# the last column
					print $foutput "$data[$column[$#column]]\n";
					$comment_flag = 1;
				}
			}
			if ( $data[0] =~ /^$key$/ )
			{
				print $foutput "$lcnt ";
				for (my $i=0; $i<$#column; $i++)
				{
					print $foutput "$data[$column[$i]] ";
					$sum += $data[$column[$i]];
				}
				# the last column
				print $foutput "$data[$column[$#column]]\n";
				$sum += $data[$column[$#column]];
				$lcnt++;
			}
		}
		else
		{
			die "invalid format $format\n";
		}
	}
	close($finput);
	close($foutput);

	# if there is no data, remove this file
	if ( $sum == 0 )
	{
		print "data is all zero\n";
		unlink( $outfile );
	}
}


=head1 NAME

get_header()

=head1 SYNOPSIS

read key file and return headers

=head1 ARGUMENTS

 -infile < the input file >
 -option < the application option >
 -type < ap or hr >

=cut
sub get_header
{
	my ($infile, $option, $type) = @_;

	my ( @retstr, $line, $nf);
	my $fkey = new FileHandle;
	unless ( $fkey->open( "< $infile" ) ) { die "can not open file $infile: $!";}
	$nf = 1;
	while ( ( $line = $fkey->getline ) && ( $nf == 1 ) ) {
		next if ( $line =~ /^#/ || $line =~ /^\s*$/ );
		chomp $line;
		@retstr = split /;/, $line;
		if ( ( $retstr[ 0 ] eq $option ) && ( $retstr[ 1 ] eq $type ) )
		{
			$nf = 0;
			shift @retstr;    # Remove option
			shift @retstr;    # Remove type
		}
	}
	$fkey->close;
	if ( $nf == 1 ) { die "did not find line starting with $option;$type"; }
	return @retstr;
}

=head1 SYNOPSIS

extract rows and columns from input file.  
The output format can be cvs or gnuplot data

=head1 ARGUMENTS

 -infile < the input file >
 -outfile < the output file name, the output file will be:
         [name].dat: gnuplot data file
         [name].csv: csv file >
 -key < the lines extracted must contain key >
 -comment_key < if a line has comment_key then it is printed as comment >
 -comment < comment the the beginning of the file >
 -columns < columns to be extracted >
 -format < the format is either csv or gnuplot data >

=cut

sub extract_columns_rows_sar
{
	my ( $infile, $outfile, $key, $comment_key, $comment, $format, $start_column, @column ) = @_;
	my ($finput, $foutput, @data, $comment_flag, $lcnt, $sum); 
	
	open(SARIN, $infile) ||  die "can't open file $infile: $!"; 

	$foutput = new FileHandle;		
	unless ( $foutput->open( "> $outfile" ) ) 
		{ die "can't open file $outfile: $!"; }

	$comment_flag = 0;
	$lcnt = 0;
	$sum = 0;
	if ( $comment )
	{
		print $foutput "# $comment\n";
	}

	while (<SARIN>)
	{
		chop;
		# get rid of leading spaces
		s/^\s+//;
		# skit empty line
		next if (/^$/);
		@data = split /\s+/;
		
		# skip short lines
		next if ( $#data < $start_column || /^Linux/ ) ;
		if ( $format eq 'csv' )
		{
			# comment is printed once
			if ( $comment_key && $comment_flag == 0 )
			{
				if ( /^$comment_key/ )
				{
					for (my $i=0; $i<$#column; $i++)
					{
						print $foutput "$data[$column[$i]],";
					}
					# the last column
					print $foutput "$data[$column[$#column]]\n";
					$comment_flag = 1;
				}
			}
			if ( $data[$start_column] =~ /^$key/ )
			{
				for (my $i=0; $i<$#column; $i++)
				{
					print $foutput "$data[$column[$i]],";
					$sum += $data[$column[$i]];
				}
				# the last column
				print $foutput "$data[$column[$#column]]\n";
				$sum += $data[$column[$#column]];
			}
		}
		elsif ( $format eq 'gnuplot' )
		{
			# comment is printed once
			if ( $comment_key && $comment_flag == 0 )
			{
				if ( /^$comment_key/ )
				{
					print $foutput '#';
					for (my $i=0; $i<$#column; $i++)
					{
						print $foutput "$data[$column[$i]] ";
					}
					# the last column
					print $foutput "$data[$column[$#column]]\n";
					$comment_flag = 1;
				}
			}
			if ( $data[$start_column] =~ /^$key/ )
			{
				if ( ! ($data[0] eq "Average:") )
				{
				print $foutput "$lcnt ";
				for (my $i=0; $i<$#column; $i++)
				{
					print $foutput "$data[$column[$i]] ";
					$sum += $data[$column[$i]];
				}
				# the last column
				print $foutput "$data[$column[$#column]]\n";
				$sum += $data[$column[$#column]];
				$lcnt++;
				}
			}
		}
		elsif ( $format eq 'txt' )
		{
			$sum = 1;
			print $foutput "$_\n";
		}
		else
		{
			die "invalid format $format\n";
		}
	}
	close(SARIN);
	close($foutput);

	# if there is no data, remove this file
	if ( $sum == 0 )
	{
		print "data is all zero\n";
		unlink( $outfile );
	}
}

sub convert_time_format
{
	my ($num_seconds) = @_;

        my ($h, $m, $s, $tmp_index, @ret);
	$h = $num_seconds/3600;
	#find the maximum integer that is less than $h
	for ( $tmp_index=1; $tmp_index<$h; $tmp_index++ ) {};
	$h = $tmp_index - 1;
	$num_seconds = $num_seconds - $h*3600;
	$m = $num_seconds/60;
	#find the maximum integer that is less than $h
	for ( $tmp_index=1; $tmp_index<$m; $tmp_index++ ) {};
	$m = $tmp_index - 1;
	$s = $num_seconds - $m*60;
	$ret[0] = $h;
	$ret[1] = $m;
	$ret[2] = $s;

	return @ret;
}

1;