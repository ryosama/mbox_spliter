# mbox_spliter
Split large mbox files (from _Mozilla Thunderbird_) into smaller one

# Usage

Options :

* __--mbox__=<mbox_file> (required) The mbox file you want to inspect

* __--dry-run__ Do only a simulation, do not write anything

* __--compact__ Compact the mbox file (delete messages marked as "deleted")

* __--delete-older-than__=_yyyy-mm-dd_ Delete messages older than this date

* __--split-by__=_year|mounth|week|day_  Split the mbox file into separate files

* __--usage__ or __--help__ Display this message

* __--quiet__ Don't print anything


# Examples
`perl mbox_spliter.pl --dry-run --mbox=c:/Thunderbird/Mail/Inbox` --compact --split-by=year

# Statistics
At the end the script print some statitics about the job done
```

-----------------Statistics-----------------

Read  1393216 lines in 1 seconds

Found     431 messages

Compact   409 messages (94.9%)

Keep       67 messages (15.5%)

Moved     364 messages (84.5%)

           42 messages ( 9.7%) into /home/foo/.Mail/Local Folders/Sent.sbd/2009

          106 messages (24.6%) into /home/foo/.Mail/Local Folders/Sent.sbd/2014

           63 messages (14.6%) into /home/foo/.Mail/Local Folders/Sent.sbd/2010

          119 messages (27.6%) into /home/foo/.Mail/Local Folders/Sent.sbd/2013

            1 messages ( 0.2%) into /home/foo/.Mail/Local Folders/Sent.sbd/2012

           33 messages ( 7.7%) into /home/foo/.Mail/Local Folders/Sent.sbd/2011
```