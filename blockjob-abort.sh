#!/bin/bash

domain="$1"
if [ -z "$domain" ]; then
	echo "Error: missing domain argument!"
	echo ""
	echo "Usage: blockjob-abort.sh [domain]"
	exit 1
fi

virsh blockjob $domain hda --abort
