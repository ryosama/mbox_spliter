#!/usr/bin/perl

use 5.010;
use strict;
use Getopt::Long;				# manage options
use File::Basename;				# dirname()
use POSIX qw(strftime mktime);	# date manipulation
use File::Copy;					# move temp file to old one
use File::Path;					# directories creation
use Data::Uniqid qw(luniqid); 	# copy message into a temp file

use constant MSG_FLAG_EXPUNGED => 0x0008 ;

$| = 1 ;

my $start_time = time;

my ($current_year,$current_mounth,$current_day,$current_week) = split(/-/,strftime('%Y-%m-%d-%W', localtime));
my $uniqid 	= luniqid;

# constant
my %possible_split_value = qw/year 1 mounth 1 week 1 day 1/;
my %mounths = qw/Jan 01 Feb 02 Mar 03 Apr 04 May 05 Jun 06 Jul 07 Aug 08 Sep 09 Oct 10 Nov 11 Dec 12/;

# options
my ($mbox,$dry_run,$split_by,$compact,$help,$quiet);
GetOptions('mbox=s'=>\$mbox, 'dry-run!'=>\$dry_run, 'split-by=s'=>\$split_by, 'compact!'=>\$compact, 'help|usage!'=>\$help, 'quiet!'=>\$quiet) ;
die <<EOT if ($help);
Options :
--mbox=<mbox_file> (required)
	The mbox file you want to inspect

--dry-run
	Do only a simulation, do not write anything

--compact
	Compact the mbox file (delete messages marked as "deleted")

--split-by=year|mounth|week|day
	Split the mbox file into separate files

--usage ou --help
	Display this message

--quiet
	Don't print anything
EOT

# some checks
die "Option --mbox=<mbox_file> is needed" 	unless length($mbox)>0;
die "Unable to find '$mbox' file" 			unless -e $mbox;
my $must_split = length($split_by)>0 ? 1 : 0;
if ($must_split) {
	die "Option --split-by must be 'year', 'mounth', 'week' or 'day', not '$split_by'" unless exists $possible_split_value{$split_by};
}

# main program
my $mbox_size = (stat($mbox))[7];
my $buffer = ''; # buffer for current message
my $skip_message = 0;
my $ouput_mbox = dirname($mbox).'/'.$uniqid;
my $last_output_mbox = '';
my ($total_message,$total_moved_message,$total_deleted_message) = (0,0,0);
my %stats = ();
my $current_size_read = 0;
my $line = 0 ;

open(OUTPUT,">>$ouput_mbox") or die "Could not write into '$ouput_mbox' ($!)" unless $dry_run; 
open(F,"<$mbox") or die "Could not open '$mbox' ($!)";
while(<F>) { # foreach line
	$line++;

	if (/^From\s+-\s+\w{3}\s+(\w{3})\s+(\d{2})\s+\d{2}:\d{2}:\d{2}\s+(\d{4})\b/i) {  # new message syntax : From - Mon Jan 05 08:37:43 2012

		print OUTPUT $buffer unless $dry_run || $skip_message; # write buffer into the output file

		$buffer = '';		# reset buffer
		$skip_message = 0; 	# reset deleted flag
		$total_message++;

		my ($mounth_message,$day_message,$year_message) = ($1,$2,$3);
			$mounth_message = $mounths{$mounth_message};
		my 	$week_message = strftime('%W', 0, 0, 0, $day_message, $mounth_message, $year_message );

		#print Dumper($_,$day_message, $mounth_message, $year_message,$week_message) ;

		$ouput_mbox = dirname($mbox).'/'.$uniqid if !$must_split;

		# split by year ?
		if ($must_split && $split_by eq 'year') {
			if ($year_message < $current_year) {
				$total_moved_message++;
				$ouput_mbox = "$mbox.sbd/$year_message";
				mkpath("$mbox.sbd") if !$dry_run;
				$stats{$ouput_mbox}++;
			} else {
				$ouput_mbox = dirname($mbox).'/'.$uniqid;
			}
		}

		# split by mounth ?
		elsif ($must_split && $split_by eq 'mounth') {
			if ($year_message.$mounth_message < $current_year.$current_mounth) {
				$total_moved_message++;
				$ouput_mbox = "$mbox.sbd/$year_message.sbd/$mounth_message";
				mkpath("$mbox.sbd/$year_message.sbd") if !$dry_run;
				$stats{$ouput_mbox}++;
			} else {
				$ouput_mbox = dirname($mbox).'/'.$uniqid;
			}
		}

		# split by day ?
		elsif ($must_split && $split_by eq 'day') {
			if ($year_message.$mounth_message.$day_message < $current_year.$current_mounth.$current_day) {
				$total_moved_message++;
				$ouput_mbox = "$mbox.sbd/$year_message.sbd/$mounth_message.sbd/$day_message";
				mkpath("$mbox.sbd/$year_message.sbd/$mounth_message.sbd") if !$dry_run;
				$stats{$ouput_mbox}++;
			} else {
				$ouput_mbox = dirname($mbox).'/'.$uniqid;
			}
		}

		# split by week ?
		elsif ($must_split && $split_by eq 'week') {
			if ($year_message.$week_message < $current_year.$current_week) {
				$total_moved_message++;
				$ouput_mbox = "$mbox.sbd/$year_message.sbd/Week $week_message";
				mkpath("$mbox.sbd/$year_message.sbd") if !$dry_run;
				$stats{$ouput_mbox}++;
			} else {
				$ouput_mbox = dirname($mbox).'/'.$uniqid;
			}
		}


		# check if we need to open a new file
		if ($last_output_mbox ne $ouput_mbox) {
			unless ($dry_run) { 
				close(OUTPUT);
				open(OUTPUT,">>$ouput_mbox") or die "Could not write into '$ouput_mbox' ($!)";
			}
		}

		# print some stats and progress bar
		draw_progress_bar($current_size_read, $mbox_size) unless $quiet;
	}

	# delete message ?
	if ($compact && /^X-Mozilla-Status:\s+(\d+)/i) { # check status of the message
		my $status = hex("0x$1");
		if ($status & MSG_FLAG_EXPUNGED) { # mark "deleted"
			$skip_message = 1;
			$total_deleted_message++;
		}
	}
	
	$buffer .= $_ ; # put line into buffer
	$current_size_read += length($_);
}
close(OUTPUT) unless $dry_run;
close F;

# print some stats and progress bar
draw_progress_bar($mbox_size, $mbox_size) unless $quiet;

unless ($quiet) {
	printf "\n-----------------Statistics-----------------\n";
	printf "Read  %d lines in %d seconds\n", $line, time() - $start_time;
	printf "Found   %5d messages\n", $total_message ;
	printf "Compact %5d messages (%4.1f%%)\n", $total_deleted_message, $total_deleted_message/$total_message * 100 if $compact;
	printf "Keep    %5d messages (%4.1f%%)\n", $total_message - $total_moved_message, ($total_message - $total_moved_message)/$total_message * 100 ;
	printf "Moved   %5d messages (%4.1f%%)\n", $total_moved_message, $total_moved_message/$total_message * 100 ;
	printf "\t%5d messages (%4.1f%%) into $_\n", $stats{$_}, $stats{$_}/$total_message * 100 foreach (keys %stats) ;
}

# remove old Inbox file by new one
unless ($dry_run) {
	unlink($mbox) 							or die "Could not delete '$mbox' ($!)";
	move(dirname($mbox).'/'.$uniqid, $mbox) or die "Could not rename '$uniqid' into '$mbox' ($!)";

	# clean up index .msf file
	if (-e "$mbox.msf") {
		printf "Remove '$mbox.msf' index file\n" unless $quiet;
		unlink("$mbox.msf") or warn "Unable to remove '$mbox.msf' ($!)";
	}
}

########################################################################################################
sub draw_progress_bar($$) {
	# first parameter is current value
	# second paramater is total value
	my ($pg_current,$pg_total) = @_;
	
	state $cursors_loop = 0;
	use constant CURSORS => ('-',"\\",'|','/');
	use constant PROGRESSBAR_SIZE => 20;

	my $pourcent	= $pg_current * 100 / $pg_total;
	my $pgb_size	= int($pourcent * PROGRESSBAR_SIZE / 100);
	printf "\r[".('#' x $pgb_size).((CURSORS)[$cursors_loop]).('-' x (PROGRESSBAR_SIZE - $pgb_size - 1)).	#progress bar
				'] %0.1f%%  %.01f/%.01f Mb | %d Msg, %d Moved, %d Deleted', # some stats
				 $pourcent, $pg_current/1048576, $pg_total/1048576, $total_message, $total_moved_message, $total_deleted_message;

	# change cursor aspect
	if ($cursors_loop >= 3) { $cursors_loop=0; }
	else 					{ $cursors_loop++; }
}