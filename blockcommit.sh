#!/bin/bash

domain="$1"
target="$2"
if [ -z "$domain" ]
then
	echo "Error: missing domain argument!"
	echo ""
	echo "Usage: blockcommit.sh [domain] [target=hda]"
	exit 1
fi

if [ -z "$target" ]
then
	target="hda"
fi

virsh blockcommit $domain $target --active --pivot

if [ $? -ne 0 ]
then
	exit 1
fi

exit 0
