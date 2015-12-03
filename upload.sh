#!/bin/sh

# check for argument
if [ "$1" == "" ]
then
    echo "ERROR: expecting Omega hex code as argument!"
    echo "$0 <hex code>"
    exit
fi

cmd="rsync -va --progress onion-ubus.sh root@omega-$1.local:/usr/libexec/rpcd/onion"
echo "$cmd"
eval "$cmd"

