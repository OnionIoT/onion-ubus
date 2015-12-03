#!/bin/sh

# include the Onion sh lib
. /usr/lib/onion/lib.sh

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
	
	# check if the directory exists
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

# function to read and respond with possible Omega LED settings
#	argument 1: path to trigger file
omegaLedRead () {
	# read the possible trigger modes
	modes=`cat $1`
	modes=`echo $modes | sed -e 's/\[//g' -e 's/\]//g'`

	# create the trigger mode array
	json_add_array triggers

	# add each mode
	for mode in $modes
	do
		json_add_string "mode" "$mode"
	done

	# finish the array
	json_close_array
}

# function to set Omega LED trigger
#	argument 1: path to trigger file
#	argument 2: new trigger to set
omegaLedSet () {
	# set the trigger
	echo $2 > $1

	# output the selected trigger
	json_add_string "trigger" "$2"
}

# function to set the Omega LED
omegaLed () {
	triggerFile="/sys/class/leds/onion:amber:system/trigger"

	# check the operations
	json_get_var readTriggers read_triggers
	json_get_var triggerSel set_trigger

	# init the output json
	json_init

	# check if returning the possible trigger options (check this)
	if 	[ "$readTriggers" != "" ] &&
		[ "$readTriggers" == 1 ]; 
	then
		omegaLedRead $triggerFile
	fi

	# check if setting the trigger
	if [ "$triggerSel" != "" ]; then
		omegaLedSet $triggerFile $triggerSel
	fi

	# print the json
	json_dump
}

# function to run fast-gpio application
FastGpio () {
	# parse the arguments object
	local argumentString=$(_ParseArgumentsObject "nodash")
	argumentString=`echo $argumentString | sed -e 's/_/-/'`
	Log "arguments: $argumentString"
	
	# call wifisetup with the arguments (and -u for json output)
	cmd="fast-gpio -u $argumentString"
	Log "$cmd"
	eval "$cmd"
}

# function to find all I2C devices on the bus
I2cScan () {
	# find all slave addresses on i2c bus, format so they're all on one line, separated by multiple spaces
	addrs=$(i2cdetect -y 0 | tail -n +2 | sed -e 's/^[0-9][0-9]://' -e 's/ --//g' -e 's/\([0-9abcdef][0-9abcdef]\)/0x\1/g' | tr '\n' ' ')

	# generate a json array using text
	json='{"devices":['
	
	# add each device address to the array
	for addr in $addrs
	do
		json="$json\"$addr\","
	done

	json=$(echo $json | sed -e 's/.$//')	#remove last comma
	json="$json]}'"

	# print the json
	echo "$json"
}


########################
##### Main Program #####

cmdWifiScan="wifi-scan"
cmdWifiSetup="wifi-setup"
cmdOUpgrade="oupgrade"
cmdDirList="dir-list"
cmdOmegaLed="omega-led"
cmdFastGpio="fast-gpio"
cmdI2cScan="i2c-scan"
cmdStatus="status"

jsonWifiScan='"'"$cmdWifiScan"'": { "device": "string" }'
jsonWifiSetup='"'"$cmdWifiSetup"'": { "params": { "key": "value" } }'
jsonOUpgrade='"'"$cmdOUpgrade"'": { "params": { "key": "value" } }'
jsonDirList='"'"$cmdDirList"'": { "directory": "value" }'
jsonOmegaLed='"'"$cmdOmegaLed"'": { "set_trigger": "value", "read_triggers": true }'
jsonFastGpio='"'"$cmdFastGpio"'": { "params": { "key": "value" } }'
jsonI2cScan='"'"$cmdI2cScan"'": { }'

jsonStatus='"'"$cmdStatus"'": { }'

case "$1" in
    list)
		echo "{ $jsonWifiScan, $jsonWifiSetup, $jsonOUpgrade, $jsonDirList, $jsonOmegaLed, $jsonFastGpio, $jsonI2cScan, $jsonStatus }"
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
			$cmdOmegaLed)
				# read the json arguments
				read input
				Log "Json argument: $input"

				# parse the json
				json_load "$input"

				# parse the json and perform the LED actions
				omegaLed
			;;
			$cmdFastGpio)
				# read the json arguments
				read input
				Log "Json argument: $input"

				# parse the json
				json_load "$input"

				# parse the json and perform the fast-gpio actions
				FastGpio
			;;
			$cmdI2cScan)
				# call the i2c-scan function
				I2cScan	
			;;
			$cmdStatus)
				# dummy call for now
				echo '{"status":"good"}'
		;;
		esac
    ;;
esac

# take care of the log file
CloseLog