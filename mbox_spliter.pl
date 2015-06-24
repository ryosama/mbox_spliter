#!/usr/bin/perl

=begin
split a big mbox file into multi mbox file suffix with the year of the messages

Example : 
	input mbox file  : Inbox

	output mbox file : Inbox 				(contains the message from the current year)
	output mbox file : Inbox.sbd/2014   	(contains the message from 2014)
	output mbox file : Inbox.sbd/2013   	(contains the message from 2013)
	...

Options 	
	--mbox=<mbox_file>
		The mbox file you want to inspect
	--dry-run
		Do only a simulation, do not write anything
	--usage ou --help
		Display this message
	--quiet
		Don't print anything
=cut

use strict;
use Getopt::Long;				# manage options
use File::Basename;				# dirname()
use POSIX qw(strftime); 		# get the current year
use File::Copy;					# move temp file to old one
use Data::Uniqid qw(luniqid); 	# copy message into a temp file
$| = 1 ;

my $start_time = time;

my $year 	= strftime('%Y', localtime);
my $uniqid 	= luniqid;

# options
my ($mbox,$dry_run,$help,$quiet);
GetOptions('mbox=s'=>\$mbox, 'dry-run!'=>\$dry_run, 'help|usage!'=>\$help, 'quiet!'=>\$quiet) ;
die "Option --mbox=<mbox_file> is needed" unless length($mbox)>0;
die <<EOT if ($help);
Options :
--mbox=<mbox_file>
	The mbox file you want to inspect
--dry-run
	Do only a simulation, do not write anything
--usage ou --help
	Display this message
--quiet
	Don't print anything
EOT

# main program
my $ouput_mbox = dirname($mbox).'/'.$uniqid;
my $last_output_mbox = '';
my $line = 0 ;
my ($total_message,$total_moved_message) = (0,0);
my %stats = ();

open(OUTPUT,">>$ouput_mbox") or die "Could not write into '$ouput_mbox' ($!)" unless $dry_run; 
open(F,"<$mbox") or die "Could not open '$mbox' ($!)";
while(<F>) { # foreach line
	$line++;

	if (/^From\s+-\s+\w{3}\s+\w{3}\s+\d{2}\s+\d{2}:\d{2}:\d{2}\s+(\d{4})$/i) {  # new message syntax : From - Mon Jan 05 08:37:43 2012
		$total_message++;
		my $year_message = $1;

		if ($year_message < $year) {
			$total_moved_message++;
			$ouput_mbox = "$mbox.sbd/$year_message";
			mkdir "$mbox.sbd" or die "Could not create output directory '$mbox.sbd' ($!)" if !-d "$mbox.sbd" && !$dry_run;
			printf "Found message on line %08d (%04d), moved to %s\n", $line , $year_message, $ouput_mbox unless $quiet;
			$stats{$ouput_mbox}++;
		} else {
			$ouput_mbox = dirname($mbox).'/'.$uniqid
		}

		if ($last_output_mbox ne $ouput_mbox) {
			unless ($dry_run) { 
				close(OUTPUT);
				open(OUTPUT,">>$ouput_mbox") or die "Could not write into '$ouput_mbox' ($!)";
			}
		}
	}
	
	print OUTPUT $_ unless $dry_run; # write the line into the output file
}
close(OUTPUT) unless $dry_run;
close F;

unless ($quiet) {
	printf "\n-----------------Statistics-----------------\n";
	printf "Read %d lines in %d seconds\n", $line, time() - $start_time;
	printf "Found %5d messages\n", $total_message ;
	printf "Keep  %5d messages (%4.1f%%)\n", $total_message - $total_moved_message, ($total_message - $total_moved_message)/$total_message * 100 ;
	printf "Moved %5d messages (%4.1f%%)\n", $total_moved_message, $total_moved_message/$total_message * 100 ;
	printf "\t%5d messages (%4.1f%%) into $_\n", $stats{$_}, $stats{$_}/$total_message * 100 foreach (keys %stats) ;
}

# remove old Inbox file by new one
unless ($dry_run) {
	unlink($mbox) 							or die "Could not delete '$mbox' ($!)";
	move(dirname($mbox).'/'.$uniqid, $mbox) or die "Could not rename '$uniqid' into '$mbox' ($!)";
}