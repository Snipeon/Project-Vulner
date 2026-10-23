# Project-Vulner
So, what this script does is you give it a IP address or range. Don't abuse it. Unless you want CSA or whichever government agency that governs cyber to pay you a visit.
Then the script does a netdiscover scan.
Then nmaps all the discovered IP addresses.
Then masscans. (and that's why you don't abuse this script)
Then tries to bruteforce any telnet, FTP, RFP, or SSH services discovered, using either a default or user provided list.
Then does a searchsploit assessment based on the detected services.
Lastly the script saves all the results into a neat lil' file at a user defined location.

And it opens the file for you. lol.
