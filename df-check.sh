#!/bin/bash
limitp=75
excludes="tmpfs|cdrom|udev|cgmfs"
df -H | grep -vE "^Filesystem|$excludes" | while read output;
do
	usep=$(echo $output | awk '{print $5}' | cut -d'%' -f1)
	usep=$(($usep + 0))
	if [ $usep -ge $limitp ]; then
		echo "Warning: disk usage is higher than $limitp%!"
		echo ""
		df -H | grep -vE "$excludes"
	fi
done
