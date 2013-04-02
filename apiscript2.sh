

#!/bin/bash

# : Title	: API challenge 2 script
# : Date	: Sun Mar 24 2013
# : Author	: Brian King (brian.king@rackspace.com)
# : Version	: 0.1a
# : Description	: A script to clones server and deploy the image as a new server
# : Options 	: [none]

#Checking for nova, the script will not work without it.

command -v nova >/dev/null 2>&1 || { printf "%s\n" "This script requires nova. Install it and/or add it to your PATH, then rerun. Aborting."; exit 1;}

printf "%s\n" "We will clone one of your servers and deploy it as a new server. Which server do you want to use?"

read SERVER_CLONE

RANDOM_EXTRA_NUMBERS=$(python -S -c "import random; print random.randrange(1000,9999)")

printf "%s\n" "OK, cloning $SERVER_CLONE as clone-$SERVER_CLONE-$RANDOM_EXTRA_NUMBERS"

#Checking to see if the requested server exists

nova show $SERVER_CLONE > /dev/null 2>&1

if [ $? -ne 0 ]

	then printf "%s\n" "ERROR: We couldn't find a server with that name. Please run nova list and try again."

	else
	
	nova image-create $SERVER_CLONE base-$SERVER_CLONE-$RANDOM_EXTRA_NUMBERS 
	
	IMAGE_NAME="base-$SERVER_CLONE-$RANDOM_EXTRA_NUMBERS"
	
	IMAGE_UUID=$(nova image-list | grep $IMAGE_NAME | awk '{print $2}' )
	
	echo -e "$IMAGE_UUID"
	
fi

#Initializing variable for our next test

BUILD_STATUS=1

until [ $BUILD_STATUS -eq 0 ]

	do 
	
	printf "%s\n" "Snapshotting base server...please wait..."
		
	#This is a check to see whether or not the image is still snapshotting. Once done, we will deploy the new server with the base image.
	
	BUILD_STATUS=$(nova image-list | grep $SERVER_CLONE | grep -c SAVING)
	
	printf "%s\n $(nova image-list | grep SAVING)" 
	
	sleep 5
	
	done
	
#Once the image is created, we deploy a server

printf "%s\n" "Deploying server from image..."

nova boot --flavor 2 --image $IMAGE_UUID clone-$SERVER_CLONE-$RANDOM_EXTRA_NUMBERS >> /tmp/cloudinfo

#Initializing variable for our next test

BUILD_STATUS=1
	
	until [ $BUILD_STATUS -eq 0 ]

	do 
	
	printf "%s\n" "Image deploying...please wait..."
	
	BUILD_STATUS=$(nova list | grep -c BUILD)
	
	printf "%s\n $(nova list | grep BUILD)" 
	
	sleep 5
	
	done

#Once build is confirm-complete reveal server information such as root pw and IPv4 address

SERVER_NAME=( $(grep name /tmp/cloudinfo | awk '{print $4}') )

SERVER_IPV4=( $(nova show $SERVER_NAME| grep accessIPv4 | awk '{print $4}') )

sleep 1
		
SERVER_PASSWORD=( $(grep -A1 $SERVER_NAME /tmp/cloudinfo | grep adminPass | awk '{print $4}') )
		
	printf "%s\n" "Server $SERVER_NAME is deployed with IPv4 $SERVER_IPV4 and root password $SERVER_PASSWORD"

rm -f /tmp/cloudinfo

exit 0
	

	

