#!/bin/sh

. /usr/share/libubox/jshn.sh


# function to scan for wifi networks
#	argument 1: device for iwinfo
WifiScan () {
	# scan for networks and do some formatting to isolate the ssid's                                     
	networks=$(iwinfo $1 scan | grep ESSID | sed -e 's/[[:space:]]//g' -e 's/ESSID\://g' -e 's/\"//g')
	
	# json setup      
	json_init
	
	json_add_array results
	for id in $networks
	do
		json_add_string "" "$id"
	done
	json_close_array
	
	json_dump
}



########################
##### Main Program #####

jsonWifiscan='"wifiscan": { "device": "string" }'
jsonStatus='"status": { }'

case "$1" in
    list)
		echo "{ $jsonWifiscan, $jsonStatus }"
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
			status)
				# dummy call for now
				echo '{"status":"good"}'
		;;
		esac
    ;;
esac