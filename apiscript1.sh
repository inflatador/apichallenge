#!/bin/bash

# : Title	: API challenge 1 script
# : Date	: Sun Mar 24 2013
# : Author	: Brian King (brian.king@rackspace.com)
# : Version	: 0.1a
# : Description	: A script to build 3 512 MB cloud servers and return the IP and root password for each server
# : Options 	: [none]


#Checking for nova, the script will not work without it.

command -v nova >/dev/null 2>&1 || { printf "%s\n" "This script requires nova. Install it and/or add it to your PATH, then rerun. Aborting."; exit 1;}

printf "%s\n" "We will create 3 CentOS 6.3 512MB servers.  What would you like the prefix to be?"

read PREFIX

printf "%s\n" "OK, creating servers $PREFIX-0 $PREFIX-1, and $PREFIX-2"

for n in 0 1 2
	
	do 

	nova boot --flavor 2 --image c195ef3b-9195-4474-b6f7-16e5bd86acd0 $PREFIX-$n >> /tmp/cloudid; 

	done
	
#This is a check to see whether or not the servers are still building. We will wait until they are done before we 
#provide server information
	

	BUILD_STATUS=1

until [ $BUILD_STATUS -eq 0 ]

	do 
	
	printf "%s\n" "Servers building...please wait..."
	
	BUILD_STATUS=$(nova list | grep -c BUILD)
	
	printf "%s\n $(nova list | grep BUILD)" 
	
	sleep 5
	
	done
	
#Once build is confirm-complete reveal server information such as root pw and IPv4 address


declare array SERVER_NAMES

IFS=$'\n'

SERVER_NAMES=( $(grep name /tmp/cloudid | awk '{print $4}') )


for n in ${SERVER_NAMES[@]}

	do
	
		SERVER_IPV4=( $(nova show $n | grep accessIPv4 | awk '{print $4}') )
		
		sleep 1
		
		SERVER_PASSWORD=( $(grep -A1 $n /tmp/cloudid | grep adminPass | awk '{print $4}') )
		
	printf "%s\n" "Server $n has IPv4 $SERVER_IPV4 and root password $SERVER_PASSWORD"
	
	printf "\n"

	done
	
unset IFS

rm -f /tmp/cloudid

exit 0
