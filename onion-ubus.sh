#!/bin/sh

. /usr/share/libubox/jshn.sh


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

		#val now holds ssid:encr
		ssid=${val%%:*}
		auth=${val#*:}

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
	# get the script arguments from the json
	json_get_values args arguments

	# call wifisetup with the arguments (and -u for json output)
	wifisetup -u $args
}

# function to facilitate firmware updates
#	run 'oupgrade -help' for info on the arguments
OUpgrade () {
	# get the script arguments from the json
	json_get_values args arguments

	# call oupgrade with the arguments (and -u for json output)
	oupgrade -u $args
}



########################
##### Main Program #####

jsonWifiScan='"wifiscan": { "device": "string" }'
jsonWifiSetup='"wifisetup": { "arguments": ["string","string","string"] }'
jsonOUpgrade='"oupgrade": { "arguments": ["string","string","string"] }'
jsonStatus='"status": { }'

case "$1" in
    list)
		echo "{ $jsonWifiScan, $jsonWifiSetup, $jsonOUpgrade, $jsonStatus }"
    ;;
    call)
		case "$2" in
			wifiscan)
				# read the json arguments
				read input;

				# parse the json
				json_load "$input"
				json_get_var netDevice device

				# run the wifi scan
				WifiScan $netDevice
			;;
			wifisetup)
				# read the json arguments
				read input
				json_load "$input"

				# parse the json and run wifisetup
				WifiSetup
			;;
			oupgrade)
				# read the json arguments
				read input
				json_load "$input"

				# parse the json and run wifisetup
				OUpgrade
			;;
			status)
				# dummy call for now
				echo '{"status":"good"}'
		;;
		esac
    ;;
esac