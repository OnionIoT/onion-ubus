# onion-ubus
Collection of Onion ubus tools

## Wifi Scan
Scans for wifi networks, returns an array of wifi networks containing the SSID and encryption type

### Usage
`ubus call onion wifi-scan '{"device":"wlan0"}'`

### Return
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


## Wifi Setup
Ubus interface for the `wifisetup` application.

### Usage
`ubus call onion wifi-setup '{"params":{"argument":"argument value"}'`

### Example
Connect to network called MyNetwork with PSK2 password that is superduper:
```
ubus call onion wifi-setup '{"params":{"ssid":"MyNetwork", "auth":"psk2", "password":"superduper"}}'
```

*Lazar to expand*



## Oupgrade
Ubus interface for the `oupgrade` application.

### Usage
`ubus call onion oupgrade '{"params":{"argument":"argument value"}'`

### Example
Force a firmware upgrade
```
ubus call onion oupgrade '{"params":{"force":""}}'
```

*Lazar to expand*



## Omega LED
Interface to control the triggering of the LED on the Omega

### Read Possible Triggers
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

### Set Trigger
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



## Fast-GPIO
Interface to the Fast-GPIO application

### Usage
`ubus call onion fast-gpio '{"params":{"argument":"argument value"}'`

### Example
*Lazar to add*



## I2C Scan
Perform a scan of all I2C devices currently on the bus, return all slave addresses.

### Usage
`ubus call onion i2c-scan '{}'`

### Return
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


