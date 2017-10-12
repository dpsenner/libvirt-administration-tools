#!/bin/bash

domain="$1"
target="$2"
if [ -z "$domain" ]
then
	echo "Error: missing domain argument!"
	echo ""
	echo "Usage: blockjob-abort.sh [domain]"
	exit 1
fi

if [ -z "$target" ]
then
	target="hda"
fi

virsh blockjob $domain $target --abort

if [ $? -ne 0 ]
then
	exit 1
fi

exit 0
