#!/bin/sh

. /usr/share/libubox/jshn.sh

bLogEnabled=0
logFile="/tmp/$logName"

# function to setup logging
SetupLog () {
	if [ $bLogEnabled == 1 ]; then
		if [ -f $logFile ]; then
			rm -rf $logFile
		fi

		touch $logFile
	fi
}

# function to perform logging
#	argument 1: message to be logged
Log () {
	if [ $bLogEnabled == 1 ]; then
		echo "$1" >> $logFile
	fi
}


# function to scan for wifi networks
#	argument 1: device for iwinfo
WifiScan () {
	# scan for networks and do some formatting to isolate the ssid and encryption type
	#	networks looks like ssid1:encr1;ssid2:encr2;ssid3:encr3
	networks=$(iwinfo $1 scan | grep 'ESSID\|Encryption' | awk '{printf "%s", $0; if (getline) print " " $0; else printf "\n"}' | sed -e 's/[[:space:]]*E/E/g' -e 's/\"//g' -e 's/ESSID\: //g' -e 's/Encryption\: /:/g' -e 's/$/;/' |  sed -e ':a;N;$!ba;s/\n//g')

	# json setup      
	json_init
	
	# create the results array
	json_add_array results

	# split the list of networks
	rest=$networks
	while [ "$rest" != "" ]
	do
		val=${rest%%;*}
		rest=${rest#*;}

		# val now holds ssid:encr
		ssid=${val%%:*}
		auth=${val#*:}

		# modify hidden networks to be an empty string
		if [ "$ssid" == "unknown" ]; then
			ssid=""
		fi 

		# create and populate object for this network
		json_add_object
		json_add_string "ssid" "$ssid"
		json_add_string "encryption" "$auth"
		json_close_object
	done

	# finish the array
	json_close_array

	# print the json
	json_dump
}

# function to parse json params object
# returns a string via echo
_ParseArgumentsObject () {
	local retArgumentString=""

	# select the arguments object
	json_select params
	
	# read through all the arguments
	json_get_keys keys

	for key in $keys
	do
		# get the key value
		json_get_var val "$key"
		
		# specific key modifications
		if 	[ "$key" == "ssid" ] ||
			[ "$key" == "password" ];
		then
			# add double quotes around ssid and password
			val="\"$val\""
		fi

		retArgumentString="$retArgumentString-$key $val "
	done

	echo "$retArgumentString"
}

# function to setup wifi connection
#	run 'wifisetup -help' for info on the arguments
WifiSetup () {
	# parse the arguments object
	local argumentString=$(_ParseArgumentsObject)
	
	# call wifisetup with the arguments (and -u for json output)
	cmd="wifisetup -u $argumentString"
	eval "$cmd"
}

# function to facilitate firmware updates
#	run 'oupgrade -help' for info on the arguments
OUpgrade () {
	# parse the arguments object
	local argumentString=$(_ParseArgumentsObject)

	# call oupgrade with the arguments (and -u for json output)
	cmd="oupgrade -u $argumentString"
	eval "$cmd"
}

# function to return an array of all directories
# 	argument 1: directory to check
DirList () {
	bExists=0

	# json setup           
	json_init              
	
	# create the directory array
	json_add_array directories
	
	#check if the directory exists
	if [ -d $1 ]
	then
		# denote that the directory exists
		bExists=1

		# go to the directory
		cd $1
		
		# grab all the directories and correct the formatting                          
		dirs=`find . -type d -maxdepth 1 -mindepth 1 | sed -e 's/\.\///' | tr '\n' ';'`
		
		
		
		# split the list of directories
		rest=$dirs
		while [ "$rest" != "" ]
		do
			val=${rest%%;*}
			rest=${rest#*;}

			# val now holds a directory
			json_add_string "dir" "$val"
		done	
	fi

	# finish the array
	json_close_array
	
	# add the note that the directory exists
	json_add_boolean exists $bExists

	# print the json
	json_dump
}


########################
##### Main Program #####

cmdWifiScan="wifi-scan"
cmdWifiSetup="wifi-setup"
cmdOUpgrade="oupgrade"
cmdDirList="dir-list"
cmdStatus="status"

jsonWifiScan='"'"$cmdWifiScan"'": { "device": "string" }'
jsonWifiSetup='"'"$cmdWifiSetup"'": { "params": { "key": "value" } }'
jsonOUpgrade='"'"$cmdOUpgrade"'": { "params": { "key": "value" } }'
jsonDirList='"'"$cmdDirList"'": { "directory": "value" }'
jsonStatus='"'"$cmdStatus"'": { }'

case "$1" in
    list)
		echo "{ $jsonWifiScan, $jsonWifiSetup, $jsonOUpgrade, $jsonDirList, $jsonStatus }"
    ;;
    call)
		Log "Function: call, Method: $2"

		case "$2" in
			$cmdWifiScan)
				# read the json arguments
				read input;
				Log "Json argument: $input"

				# parse the json
				json_load "$input"
				json_get_var netDevice device

				# run the wifi scan
				WifiScan $netDevice
			;;
			$cmdWifiSetup)
				# read the json arguments
				read input;
				Log "Json argument: $input"

				# parse the json
				json_load "$input"

				# parse the json and run wifisetup
				WifiSetup
			;;
			$cmdOUpgrade)
				# read the json arguments
				read input;
				Log "Json argument: $input"

				# parse the json
				json_load "$input"

				# parse the json and run oupgrade
				OUpgrade
			;;
			$cmdDirList)
				# read the json arguments
				read input;
				Log "Json argument: $input"

				# parse the json
				json_load "$input"
				json_get_var targetDir directory

				# run directory list
				DirList $targetDir
			;;
			$cmdStatus)
				# dummy call for now
				echo '{"status":"good"}'
		;;
		esac
    ;;
esac