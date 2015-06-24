# mbox_spliter
Split large mbox files (from hunderbird) into smaller one, class by year of the message

# Usage
Options :
--mbox=<mbox_file>
	The mbox file you want to inspect
--dry-run
	Do only a simulation, do not write anything
--usage ou --help
	Display this message
--quiet
	Don't print anything

# Examples
%perl mbox_spliter.pl --dry-run --mbox=c:/Thunderbird/Mail/Inbox

# Statistics
At the end the script print some statitics about the job done

-----------------Statistics-----------------
Read 2128714 lines in 2 seconds
Found   368 messages
Keep    275 messages (74.7%)
Moved    93 messages (25.3%)
           55 messages (14.9%) into c:/Thunderbird/Mail/Inbox.sbd/2014
            4 messages ( 1.1%) into c:/Thunderbird/Mail/Inbox.sbd/2012
            2 messages ( 0.5%) into c:/Thunderbird/Mail/Inbox.sbd/2011
           28 messages ( 7.6%) into c:/Thunderbird/Mail/Inbox.sbd/2013
            4 messages ( 1.1%) into c:/Thunderbird/Mail/Inbox.sbd/2010
