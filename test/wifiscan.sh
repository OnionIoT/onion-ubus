#!/bin/sh

. /usr/share/libubox/jshn.sh

# scan for networks
networks=$(iwinfo wlan0 scan | grep 'ESSID\|Encryption' | awk '{printf "%s", $0; if (getline) print " " $0; else printf "\n"}' | sed -e 's/[[:space:]]*E/E/g' -e 's/\"//g' -e 's/ESSID\: //g' -e 's/Encryption\: /:/g' -e 's/$/;/' |  sed -e ':a;N;$!ba;s/\n//g')

#json setup
json_init

json_add_array results

# split the list of networks
rest=$networks
while [ "$rest" != "" ]
do
        val=${rest%%;*}
        rest=${rest#*;}

        #val now holds "ssid":"encryption type"
        ssid=${val%%:*}
        auth=${val#*:}

        #echo "ssid is $ssid, auth is $auth"

        json_add_object
        json_add_string "ssid" "$ssid"
        json_add_string "encryption" "$auth"
        json_close_object
done

json_close_array

json_dump