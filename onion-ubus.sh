#!/bin/sh

# include the Onion sh lib
. /usr/lib/onion/lib.sh


# function to scan for wifi networks
#   argument 1: device for iwinfo
WifiScan () {

	if [ "$(GetDeviceType)" == "$DEVICE_OMEGA" ];
	then
		(Omega1WifiScan "$1")
	else
		(Omega2WifiScan "$1")
	fi
}

Omega2WifiScanNormalizeEncryption () {
	local input=$1
	local output=""

	case "$input" in
		WPA1PSKWPA2PSK|WPA2PSK|wpa2|psk2|WPA2|PSK2)
		output="psk2"
		;;
		WPA1PSK|WPAPSK|wpa|psk|WPA|PSK)
		output="psk"
		;;
		wep|WEP)
		output="wep"
		;;
		none|*)
		output="none"
		;;
	esac

	echo $output
}

Omega2WifiScan () {
	local networkDevice=$1

    # json setup
	json_init

	json_add_array results

	iwpriv $networkDevice set SiteSurvey=1

	sleep 1

	line=1

	var="nonempty"
	while [ "$var" != "" ]
	do
		var=$(iwpriv $networkDevice get_site_survey | grep '^[0-9]' | sed -n "${line}p")
		ch=$(echo "${var:0:3}" | xargs)
		ssid=$(echo "${var:4:32}" | xargs)
		bssid=$(echo "${var:37:19}" | xargs)
		security=$(echo "${var:57:22}" | xargs)
		cipher=${security#*/}
		encryptionString=${security%%/*}
		encryption=$(Omega2WifiScanNormalizeEncryption $encryptionString)
		rssi=$(echo "${var:80:5}" | xargs)
		signal=$(echo "${var:86:8}" | xargs)
		wmode=$(echo "${var:95:7}" | xargs)
		extch=$(echo "${var:103:6}" | xargs)


		# add to the json results array
		if [ "$bssid" != "" ]; then
			json_add_object
			json_add_string "channel" "$ch"
			json_add_string "ssid" "$ssid"
			json_add_string "bssid" "$bssid"
			json_add_string "cipher" "$cipher"
			json_add_string "encryptionString" "$encryptionString"
			json_add_string "encryption" "$encryption"
			json_add_string "signalStrength" "$signal"
			json_add_string "wirelessMode" "$wmode"
			json_add_string "ext-ch" "$extch"
			json_add_string "rssi" "$rssi"
			json_close_object
		fi
		line=$((line + 1))
	done

	# finish the array
	json_close_array

	# print the json
	json_dump
}

Omega1WifiScan () {
	# scan for networks and do some formatting to isolate the ssid and encryption type
	#	networks looks like ssid1:encr1;ssid2:encr2;ssid3:encr3
	networks=$(iwinfo wlan0 scan | grep 'ESSID\|Encryption' | awk '{printf "%s", $0; if (getline) print " " $0; else printf "\n"}' | sed -e 's/[[:space:]]*E/E/g' -e 's/\"//g' -e 's/ESSID\: //g' -e 's/Encryption\: /:/g' -e 's/$/;/' |  sed -e ':a;N;$!ba;s/\n//g')

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
#   run 'wifisetup -help' for info on the arguments
WifiSetup () {
	# find the command
	local cmd=""
	json_get_var cmd "command"
	# check for base64
	local arg=""
	local base64=""
	json_get_var base64 "base64"
	if [ $base64 -eq 1 ]; then
		arg="$arg -b64"
	fi

	# parse the arguments object
	local argumentString=$(_ParseArgumentsObject)

	# call wifisetup with the arguments (and -u for json output)
	cmd="wifisetup -j $arg $cmd $argumentString"
	eval "$cmd"
}

# function to setup wdb40 wireless network manager
#   run 'wdb40setup -help' for info on the arguments
Wdb40Setup () {
	# find the command
	local cmd=""
	json_get_var cmd "command"

	# parse the arguments object
	local argumentString=$(_ParseArgumentsObject nodash)

	# call wifisetup with the arguments (and -u for json output)
	Log "Running wdb40setup $cmd $argumentString"
	cmd="wifisetup --json $cmd $argumentString"
	eval "$cmd"
}

# function to facilitate firmware updates
#   run 'oupgrade -help' for info on the arguments
OUpgrade () {
	# parse the arguments object
	local argumentString=$(_ParseArgumentsObject)

	# call oupgrade with the arguments (and -u for json output)
	cmd="oupgrade -u $argumentString"
	eval "$cmd"
}

# function to return an array of all directories
#   argument 1: directory to check
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
#   argument 1: path to trigger file
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
#   argument 1: path to trigger file
#   argument 2: new trigger to set
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
	if  [ "$readTriggers" != "" ] &&
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

	# call fast-gpio with the arguments (and -u for json output)
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

	json=$(echo $json | sed -e 's/.$//')    #remove last comma
	json="$json]}'"

	# print the json
	echo "$json"
}

# function to program the RGB LED on the Expansion Dock
RgbLed () {
	# find the command
	json_get_var cmd "command"
	local colour=""

	if [ "$cmd" == "set" ]; then
		# select the parameters
		json_select params
		json_get_keys keys

		# read the colour specified in the parameters
		for key in $keys
		do
			if  [ "$key" == "colour" ] ||
				[ "$key" == "color" ];
			then
				# get the key value
				json_get_var colour "$key"
			fi
		done

		# perfrom the rgb led setup
		if [ "$colour" != "" ]; then
			expled $colour >& /dev/null
			echo "{\"rgb-led\":\"$colour\"}"
		fi
	fi

	# error-checking
	if [ "$colour" == "" ]; then
		echo "{\"success\":False}"
	fi
}

### functions to control the Omega GPIOs
GpioBase="/sys/class/gpio"

# get the value of a GPIO
#   $1  - gpio pin
#   return value via echo
GpioCtlGet () {
	# get the value
	local value=$(cat $GpioBase/gpio$1/value)

	echo "$value"
}

# get the direction of a GPIO
#   $1  - gpio pin
#   return direction via echo
GpioCtlGetDirection () {
	# read the sysfs file
	local dir=$(cat $GpioBase/gpio$1/direction)

	if [ "$dir" == "in" ]; then
		ret="input"
	elif [ "$dir" == "out" ]; then
		ret="output"
	fi

	echo "$ret"
}


GpioCtl () {
	# find the command
	json_get_var cmd command
	local gpio=""
	local value=""

	## read the parameters
	# select the parameters
	json_select params
	json_get_keys keys

	# read the colour specified in the parameters
	for key in $keys
	do
		if  [ "$key" == "gpio" ]; then
			# get the key value
			json_get_var gpio "$key"
		elif [ "$key" == "value" ]; then
			# get the key value
			json_get_var value "$key"
		fi
	done


	if [ "$gpio" != "" ]; then
		# export the pin
		echo "$gpio" > $GpioBase/export

		# perform the action
		case "$cmd" in
			"set")
				# set the gpio to the selected value
				if [ "$value" == "0" ]; then
					echo "0" > $GpioBase/gpio$gpio/value
				else
					echo "1" > $GpioBase/gpio$gpio/value
				fi

				echo "{\"success\":True, \"pin\":\"$gpio\", \"value\":\"$value\"}"
			;;
			"get")
				# get the value
				value=$(GpioCtlGet $gpio)

				echo "{\"success\":True, \"pin\":\"$gpio\", \"value\":\"$value\"}"
			;;
			"set-direction")
				local dir="out"
				if  [ "$value" == "input" ] ||
					[ "$value" == "in" ];
				then
					dir="in"
				fi
				echo "$dir" > $GpioBase/gpio$gpio/direction

				echo "{\"success\":True, \"pin\":\"$gpio\", \"direction\":\"$dir\", \"recv_direction\": \"$value\"}"
			;;
			"get-direction")
				value=$(GpioCtlGetDirection $gpio)

				echo "{\"success\":True, \"pin\":\"$gpio\", \"direction\":\"$value\"}"
			;;
			"status")
				local val=$(GpioCtlGet $gpio)
				local dir=$(GpioCtlGetDirection $gpio)

				echo "{\"success\":True, \"pin\":\"$gpio\", \"value\":\"$val\", \"direction\":\"$dir\"}"
			;;
			*)
				# unrecognized command
				echo "{\"success\":False}"
			;;
		esac

		# unexport the pin
		echo "$gpio" > $GpioBase/unexport

	fi
}

LaunchProcess () {
	# find the command
	json_get_var cmd command

	# set the command to run in the background
	#cmd="$cmd &"

	# debug
	echo "{\"resp\": \"Command to launch in background: $cmd\"}"

	# run the command
	Log "Running command: '$cmd'"
	`$cmd &`
}


########################
##### Main Program #####

# define the commands
cmdWifiScan="wifi-scan"
cmdWifiSetup="wifi-setup"
cmdWdb40Setup="wdb40-setup"
cmdOUpgrade="oupgrade"
cmdDirList="dir-list"
cmdOmegaLed="omega-led"
cmdFastGpio="fast-gpio"
cmdI2cScan="i2c-scan"
cmdRgbLed="rgb-led"
cmdGpio="gpio"
cmdLaunchProcess="launch-process"

cmdStatus="status"


# define the command input
jsonWifiScan='"'"$cmdWifiScan"'": { "device": "string" },'
jsonWifiSetup='"'"$cmdWifiSetup"'": { "params": { "key": "value" } },'
jsonWdb40Setup='"'"$cmdWdb40Setup"'": { "command":"value", "params": { "key": "value" } },'
jsonOUpgrade='"'"$cmdOUpgrade"'": { "params": { "key": "value" } },'
jsonDirList='"'"$cmdDirList"'": { "directory": "value" },'
jsonOmegaLed='"'"$cmdOmegaLed"'": { "set_trigger": "value", "read_triggers": true },'
jsonFastGpio='"'"$cmdFastGpio"'": { "params": { "key": "value" } },'
jsonI2cScan='"'"$cmdI2cScan"'": { },'
jsonRgbLed='"'"$cmdRgbLed"'": { "command":"value", "params": { "key": "value" } },'
jsonGpio='"'"$cmdGpio"'": { "command":"value", "params": { "key": "value" } },'
#jsonLaunchProcess='"'"$cmdLaunchProcess"'": { "command":"value", "params": { "key": "value" } },'
jsonLaunchProcess='"'"$cmdLaunchProcess"'": { "command":"value" },'

jsonStatus='"'"$cmdStatus"'": { }'


## ensure command packages are installed
# wifisetup
if [ ! -e "/usr/bin/wifisetup" ]; then
	jsonWifiSetup=""
fi

# wdb40setup
if [ ! -e "/usr/bin/wdb40" ]; then
	jsonWdb40Setup=""
fi


## parse command line arguments
case "$1" in
	list)
		echo "{ $jsonWifiScan $jsonWifiSetup $jsonWdb40Setup $jsonOUpgrade $jsonDirList $jsonOmegaLed $jsonFastGpio $jsonI2cScan $jsonRgbLed $jsonGpio $jsonLaunchProcess $jsonStatus }"
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
			$cmdWdb40Setup)
				# read the json arguments
				read input;
				Log "Json argument: $input"

				# parse the json
				json_load "$input"

				# parse the json and run wifisetup
				Wdb40Setup
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
			$cmdRgbLed)
				# read the json arguments
				read input
				Log "Json argument: $input"

				# parse the json
				json_load "$input"

				# parse the json and perform the rgb-led actions
				RgbLed
			;;
			$cmdGpio)
				# read the json arguments
				read input
				Log "Json argument: $input"

				# parse the json
				json_load "$input"

				# parse the json and perform the gpio actions
				GpioCtl
			;;
			$cmdLaunchProcess)
				# read the json arguments
				read input
				Log "Json argument: $input"

				# parse the json
				json_load "$input"

				# parse the json and perform the launch-process actions
				LaunchProcess
			;;
			$cmdStatus)
				# dummy call for now
				echo '{"status":"good"}'
		;;
		esac
	;;
esac
