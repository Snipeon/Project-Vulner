#!/bin/bash

#~ Project Vulner
#~ Name: 		Lam Bing Qing Andrew
#~ Student: 	s5
#~ Unit: 		CFC060524
#~ Trainer: 	Samson

#~ References: 
#~ https://devhints.io/bash
#~ https://cheatography.com/davechild/cheat-sheets/regular-expressions/
#~ the man command

#~ Standard Regex expressions for validation checking of IP address and range
rangevalid="^(0?(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}(0?(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5])))/(0?([1-2]?[0-9]|3[0-2]))$"
IPvalid="(0?(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}(0?(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5])))"

#~ Function for input of IP address/range
function uinIP()
{
	echo 
	read -p 'Key in IP range or address to scan: ' scantar
		
	#~ Prompting user that input was invalid and looping the function
	if [[ (! ($scantar =~ $rangevalid)) && (! ($scantar =~ $IPvalid)) ]]; then 
		echo 'Invalid input! Please input a valid IPv4 range or address!'
		uinIP
		
	fi
	
}

#~ Function for input of type of scan
function uinop()
{
	echo 
	echo 'Please choose an option: '
	echo '1. Full scan'
	echo '2. Basic scan'
	read -p 'Select 1 or 2: ' option
	
	#~ Loops if invalid input
	if [[ ! ($option =~ [1-2]) ]]; then
		echo 'Invalid input! Please select a valid option!'
		uinop
		
	fi
	
}

#~ Function to write into the result files as well as saving files to be zipped
function filemgr()
{
	#~ Different variables for netdiscover and the rest
	if [ "$2" == "netdiscover" ]; then
		echo "$2 scan results on $scantar: " >> "full_results_$resultname"
		echo '' >> "full_results_$resultname"
		cat "$1_$resultname" >> "full_results_$resultname"
		echo '' >> "full_results_$resultname"
		echo '' >> "full_results_$resultname"
		echo 
		echo "$2 scan done on $scantar! Results saved to $savepath/$1_$resultname!"
		
		zipfiles="$zipfiles $1_$resultname"
		
	else
		echo "$2 scan results on $scanIP: " >> "full_results_$resultname"
		echo '' >> "full_results_$resultname"
		cat "$1_$scanIP" >> "full_results_$resultname"
		echo '' >> "full_results_$resultname"
		echo '' >> "full_results_$resultname"
		echo 
		echo "$2 scan done on $scanIP! Results saved to $savepath/$1_$scanIP!"
		
		zipfiles="$zipfiles $1_$scanIP"
		
	fi
	
}

#~ Function to read and validate user provided name list
function brutenlist
{
	read -p "Please input your username list file name/path: " unamelst

	
	if !(test -f $unamelst); then
		echo 
		echo "Username list file name/path does not exist! Please input a valid username list file!"
		
		brutenlist
		
	fi
	
}

#~ Function to read and validate user provided password list
function bruteplist
{
	read -p "Please input your password list file name/path: " passlst
	
	if !(test -f $passlst); then
		echo 
		echo "Password list file name/path does not exist! Please input a valid password list file!"
		
		bruteplist
		
	fi
	
}

#~ Script starts here
echo 'Welcome to Project Vulner!'
echo 'To use, key in an IPv4 range(eg. 192.168.0.0/24) or address(eg. 192.168.0.1).' 

uinIP
uinop

#~ Save directory location
echo 
read -p "Please specify a save directory for the output files (Default is the current directory): " savepath

#~ Setting save location to default directory if no input
if [ -z $savepath ]; then
	savepath='.'
	
fi

#~ Testing for and creating save location if needed
if !(test -d $savepath); then
	echo 'Directory path does not exist! It will be created.'
	mkdir -p $savepath

fi

cd $savepath
zipfiles="full_results_$resultname"

#~ netdiscover
if [[ $scantar =~ $rangevalid ]]; then
	resultname=$(echo $scantar | tr '/' '-')
	
	echo 
	echo 'Proceeding with netdiscover...'
	sudo netdiscover -r "$scantar" -P > "netdiscover_$resultname"
	filemgr netdiscover "netdiscover"
	
	#~ Setting IP address(es) to be scanned
	echo 
	echo 'Proceeding to scan all available IP addresses in range...'
	target=$(cat "netdiscover_$resultname" | grep -E "$IPvalid" | awk '{print $1}')
	
else
	resultname="$scantar"
	target="$scantar"
	
fi

#~ Loop for each IP address in network range
for scanIP in $target; do
	#~ nmap TCP scan
	echo
	echo 
	echo "Starting nmap TCP scan on $scanIP..."
	echo 
	sudo nmap $scanIP -sV -Pn -A -oN "nmap_TCP_$scanIP"
	filemgr nmap_TCP "nmap TCP"
	
	#~ masscan UDP scan first
	echo 
	echo 
	echo "Starting masscan UDP scan on $scanIP..."
	echo 
	sudo masscan $scanIP --rate=10000 -pU:0-65535 -oL "masscan_UDP_$scanIP"
	filemgr masscan_UDP "masscan UDP"
	
	UDPresults=$(cat "masscan_UDP_$scanIP" | awk '{print $3}' | grep . | tr '\n' ',')
	
	#~ if masscan shows results, enumerate UDP ports with nmap
	if [ -n "$UDPresults" ]; then
		echo
		echo
		echo "Open UDP ports detected. Enumerating open UDP ports."
		echo "Starting nmap UDP scan on $scanIP..."
		echo 
		sudo nmap $scanIP -sV -sU -p $UDPresults -A -oN "nmap_UDP_$scanIP"
		filemgr nmap_UDP "nmap UDP"
		
	fi
	
	#~ Detecting telnet, FTP, RDP or SSH services
	loginser='telnet ftp rdp ssh'
	brute=''
	
	for ser in $loginser; do
		if [[ $(cat "nmap_TCP_$scanIP" | grep -i $ser) ]]; then
			brute=$ser;
			
		fi
		
	done
	
	#~ Allow user to set their own username and password list
	if [ -n "$brute" ]; then
		echo
		echo 
		echo "$scanIP has services that can be bruteforced."
		echo "Default list is /usr/share/seclists/Usernames/top-usernames-shortlist.txt."
		read -p "Would you like to use your own username and password list?(y/n): " bruteop
		
		if [ "$bruteop" == "y" ]; then
			brutenlist
			bruteplist
			
		else
			unamelst="/usr/share/seclists/Usernames/top-usernames-shortlist.txt"
			passlst="/usr/share/seclists/Usernames/top-usernames-shortlist.txt"
			
		fi
		
		#~ Bruteforce with medusa. Best to be used with SSH. Metasploitable's telnet interface isn't recognised by the tool, FTP allows anonymous logins
		echo "Proceeding with bruteforce..."
		echo 
		medusa -h "$scanIP" -U "$unamelst" -P "$passlst" -M "$brute" -t 32 -v 4 -w 0 -O "medusa_$scanIP"
		filemgr medusa "Bruteforce"
	
	fi
	
	#~ Full scan
	if [ $option == 1 ]; then
		echo
		echo
		echo "Full scan selected. Proceeding with vulnerability assessment."
		
		cat nmap_*_$scanIP | grep -w "open" >> serlist
		
		#~ I opted to do this instead of searchsploit --nmap because --nmap's output would be a whole lot longer
		#~ Also I can make the output neater this way
		cat serlist | while read -r serv; do
			serport=$(echo $serv | awk '{print $1}')
			serscan=$(echo $serv | awk '{print substr($0, index($0,$3))}')
			
			echo "searchsploit vulnerability assessment for $serport $serscan: " >> "searchsploit_$scanIP"
			searchsploit $serscan >> "searchsploit_$scanIP"
			echo '' >> "searchsploit_$scanIP"
			
		done
		
		#~ Writing results to output file
		echo '' >> "searchsploit_$scanIP"
		echo 
		echo "searchsploit vulnerability assessment done! Results saved to $savepath/searchsploit_$scanIP!"
		
		#~ Writing results to full results file
		echo "searchsploit vulnerability assessment result for $scanIP: " >> "full_results_$resultname"
		echo '' >> "full_results_$resultname"
		cat "searchsploit_$scanIP" >> "full_results_$resultname"
		echo '' >> "full_results_$resultname"
		echo '' >> "full_results_$resultname"
		
		zipfiles="$zipfiles searchsploit_$scanIP"
		rm serlist
		
	fi

done

echo "Full results saved to $savepath/full_results_$resultname!"

#~ Zip files to archive
echo 
read -p "Would you like to zip all result files into an archive?(y/n) " zipf

if [ "$zipf" == "y" ]; then
	zip "Vulner_$resultname.zip" $zipfiles
	
fi

#~ Open in geany
echo 
read -p "Would you like to open $savepath/full_results_$resultname in geany?(y/n) " geanyfile

if [ "$geanyfile" == "y" ]; then
	geany "full_results_$resultname"
	
fi

#~ End script
