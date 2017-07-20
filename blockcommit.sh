#!/bin/bash

domain="$1"
if [ -z "$domain" ]; then
	echo "Error: missing domain argument!"
	echo ""
	echo "Usage: blockcommit.sh [domain]"
	exit 1
fi

virsh blockcommit $domain hda --active --pivot
