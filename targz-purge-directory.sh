#!/bin/bash

DIRPATH="$1"

#
# Check if this is actually a directory
#
if [ ! -d "$DIRPATH" ]; then
	echo "Expected the target to be a directory!"
	echo ""
	echo "Usage: targz-purge-directory.sh <directory-path>"
	exit 1
else
	# it is a directory but may be a symbolic link
	# in that case we resolve the link to the actual path
	DIRPATH=$(readlink -f "$DIRPATH")
fi

#
# Remove trailing slash if there is any
#
DIRPATH=${DIRPATH%/}

#
# Archive the directory
#
GZIP=-1 tar -czf "$DIRPATH.tar.gz" -C "$DIRPATH" --remove-files .

