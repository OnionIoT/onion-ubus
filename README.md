# onion-ubus
Collection of Onion ubus tools

# Wifi Scan
Scans for wifi networks, returns an array of wifi networks containing the SSID and encryption type

## Usage
`ubus call onion wifi-scan '{"device":"wlan0"}'`

## Return
Sample return:
```
{
	"results": [
		{
			"ssid": "OnionWiFi",
			"encryption": "mixed WPA\/WPA2 PSK (TKIP, CCMP)"
		},
		...
	]
}
```


# Wifi Setup
Ubus interface for the `wifisetup` application.

## Usage
`ubus call onion wifi-setup '{"command":"command name", "base64":false, "params":{"argument":"argument value"}}'`

* `command`
  * Specifies what operation wifisetup is meant to perform
* `base64`
  * Specifies if params arguments are base64 encoded
  * Default is false
* `params`
  * Additional parameter arguments to be passed to wifisetup script
  
Run `wifisetup --help` on the Omega to get a better idea of what is available

## Example
Connect to network called MyNetwork with PSK2 password that is superduper:
```
ubus call onion wifi-setup '{"command":"add", "base64":false, "params":{"ssid":"MyNetwork", "auth":"psk2", "password":"superduper"}}'
```

*Lazar to expand*



# Oupgrade
Ubus interface for the `oupgrade` application.

## Usage
`ubus call onion oupgrade '{"params":{"argument":"argument value"}}'`

## Example
Force a firmware upgrade
```
ubus call onion oupgrade '{"params":{"force":""}}'
```

*Lazar to expand*



# Omega LED
Interface to control the triggering of the LED on the Omega

## Read Possible Triggers
List the available triggers.

**Usage**
```
ubus call onion omega-led '{"read_triggers": true}'
```

**Return Value**
Returns an array of all possible triggers:
```
{
	"triggers": [
		"none",
		"timer",
		"default-on",
		"gpio",
		"heartbeat",
		...
	]
}
```

## Set Trigger
Select trigger to be used

**Usage**
```
ubus call onion omega-led '{"set_trigger": "<trigger>"}'
```

**Return Value**
Returns which trigger was selected:
{
	"trigger": "<trigger>"
}



# Fast-GPIO
Interface to the Fast-GPIO application

## Usage
`ubus call onion fast-gpio '{"params":{"argument":"argument value"}'`

## Example
*Lazar to add*



# I2C Scan
Perform a scan of all I2C devices currently on the bus, return all slave addresses.

## Usage
`ubus call onion i2c-scan '{}'`

## Return
Sample return:
```
{
	"devices": [
		"0x20",
		"0x27",
		"0x3c"
	]
}
```



# RGB LED
Sets the colour of the RGB LED on the Expansion Dock using the `expled` script

## Usage
`ubus call onion rgb-led '{"command":"<command>", "params":{"colour":"<hex colour value>"}}'`

The only available command is `set`, it will program the RGB LED to the hex colour value found in the `params` object.

## Return

If successfull:
```
{
	"colour": "<hex colour value>"
}
```

If not successfull:
```
{
	"success": False
}
```

## Example
Set the RGB LED to purple: 
```
ubus call onion rgb-led '{"command":"set", "params":{"colour":"0x7700e6"}}'
```



# GPIO
Control the Omega GPIOs.

Implemented using the sysfs gpio interface.

## Usage
`ubus call onion gpio '{"command":"<command>", "params":{"gpio":"<gpio number>"}}'`

Available Commands:
* get
* set
* get-direction
* set-direction
* status


## Get Command
Get the current value of the GPIO

Usage:
```
ubus call onion gpio '{"command":"get", "params":{"gpio":"<gpio number>"}}'
```

Sample Return:
```
{
        "success": true,
        "pin": "7",
        "value": "0"
}
```


## Set Command
Set the value of the GPIO (if output direction)

Usage:

Set to 0 (LOW):
```
ubus call onion gpio '{"command":"set", "params":{"gpio":"7", "value":"0"}}'
```

Set to 1 (HIGH):
```
ubus call onion gpio '{"command":"set", "params":{"gpio":"7", "value":"1"}}'
```

Sample Return:
```
{
        "success": true,
        "pin": "7",
        "value": "0"
}
```



## Get Direction Command
Get the current direction of the GPIO

Usage:
```
ubus call onion gpio '{"command":"get-direction", "params":{"gpio":"<gpio number>"}}'
```

Sample Return:
```
{
        "success": true,
        "pin": "7",
        "direction": "output"
}
```

The `direction` value will be either **`input` or `output`**


## Set Direction Command
Set the direction of the GPIO

Usage:

Set to OUTPUT:
```
ubus call onion gpio '{"command":"set-direction", "params":{"gpio":"7", "value":"output"}}'
```

Set to INPUT:
```
ubus call onion gpio '{"command":"set-direction", "params":{"gpio":"7", "value":"input"}}'
```

Sample Return:
```
{
        "success": true,
        "pin": "7",
        "direction": "out"
}
```


## Status Command
Get all available info of a GPIO

Usage:
```
ubus call onion gpio '{"command":"status", "params":{"gpio":"<gpio number>"}}'
```

Sample Return:
```
{
        "success": true,
        "pin": "7",
        "value": "0",
        "direction": "out"
}
```



