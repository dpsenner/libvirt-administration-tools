#!/bin/bash

#
# Parse and validate script arguments
#
DOMAIN="$1"
BACKUP="$2"
DEBUG="$3"

if [ -z "$BACKUP" -o -z "$DOMAIN" ]
then
	echo "Usage: ./vm-live-backup <domain> <backup-destination>"
	exit 1
fi

if [ -z "$DEBUG" ]
then
	DEBUG=0
else
	DEBUG=1
fi

#
# Determine location of the shell script
#
SCRIPT_PATH="`dirname \"$0\"`"              # relative
SCRIPT_PATH="`( cd \"$SCRIPT_PATH\" && pwd )`"  # absolutized and normalized
if [ -z "$SCRIPT_PATH" ]
then
	# error; for some reason, the path is not accessible
	# to the script (e.g. permissions re-evaled after suid)
	exit 1  # fail
fi

#
# Generate a few backup properties
#
SNAPSHOT_SUFFIX="snapshot"

#
# Get the list of targets (disks) and the image paths.
#
TARGETS=`virsh domblklist "$DOMAIN" --details | grep "^file[[:space:]]*disk" | awk '{print $3}'`
IMAGES=`virsh domblklist "$DOMAIN" --details | grep "^file[[:space:]]*disk" | awk '{print $4}'`

#
# Check if another backup is still in progress
# This is the case when the disk contains the pattern snapshot
# 
for i in $IMAGES
do
	if [[ $i == *".$SNAPSHOT_SUFFIX" ]]
        then
		echo "Refusing to make a live backup of '$DOMAIN'!"
		echo "The disk image '$i' appears to be a snapshot file while it should be a qcow2 base image."
		echo "Making a snapshot of a snapshot is not a good idea and therefore the operation is aborted. At this point the intervention of a human is required."
		echo "The first thing to try is to abort the blockjob and then retry to blockcommit the snapshot image."
		exit 1
	fi
done

#
# Create backup directory
#
mkdir -p "$BACKUP"

if [ $DEBUG -eq 1 ]
then
	echo "Dumping domain configuration to xml .."
fi

#
# Dump the configuration information.
#
virsh dumpxml "$DOMAIN" > "$BACKUP/$DOMAIN.xml"

#
# Create the snapshot.
#
DISKSPEC=""
for t in $TARGETS
do
    DISKSPEC="$DISKSPEC --diskspec $t,snapshot=external"
done

if [ $DEBUG -eq 1 ]
then
	echo "Creating snapshot by using $DISKSPEC .."
fi

virsh snapshot-create-as --domain "$DOMAIN" --name $SNAPSHOT_SUFFIX --no-metadata \
	--atomic --disk-only $DISKSPEC >/dev/null
if [ $? -ne 0 ]
then
	echo "Failed to create snapshot for $DOMAIN"
	exit 1
fi

#
# Copy disk images
#
for t in $IMAGES
do
	if [ $DEBUG -eq 1 ]
	then
		echo "Backing up disk image $t .."
	fi

	NAME=`basename "$t"`
	cp "$t" "$BACKUP"/"$NAME"
done

#
# Merge changes back.
#
BACKUPIMAGES=`virsh domblklist "$DOMAIN" --details | grep "^file[[:space:]]*disk" | awk '{print $4}'`
for t in $TARGETS
do
	for retry_blockcommit in {1..5}
	do
		if [ $DEBUG -eq 1 ]
		then
			echo "Blockcommitting snapshot of disk $t .."
		fi
		if [ $retry_blockcommit -eq 1 ]
		then
			virsh blockcommit "$DOMAIN" "$t" --wait --active --pivot > /dev/null
		else
			virsh blockcommit "$DOMAIN" "$t" --wait --active --pivot
		fi
		if [ $? -eq 0 ]
		then
			# abort if all was fine
			if [ $DEBUG -eq 1 ]
			then
				echo "Blockcommit of the snapshot on disk $t was successful."
			fi
			break
		else
			echo "Blockcommit of the snapshot on disk $t failed on retry #$retry_blockcommit."
		fi
		# check if the job was retried too often
		if [ $retry_blockcommit -eq 5 ]
		then
			echo "Error: Could not merge changes for disk $t of $DOMAIN after $retry_blockcommit retries. VM may be in an invalid state now."
			echo ""
			echo "I need the help of a human!"
			exit 1
		else
			echo "Warning: Could not merge changes for disk $t of $DOMAIN on attempt #$retry_blockcommit, retrying in 5 minutes .."
			sleep 300

			echo "Aborting blockjobs on domain $DOMAIN .."
			virsh blockjob "$DOMAIN" "$t" --abort
			if [ ! $? -eq 0 ]
			then
				echo "Error: Could not abort the blockjob on disk $t after a failed blockcommit. VM may be in an invalid state now."
				echo ""
				echo "I need the help of a human!"
				exit 1
			fi
		fi
	done
done

#
# Cleanup left over backup images.
#
for t in $BACKUPIMAGES
do
	if [ $DEBUG -eq 1 ]
	then
		echo "Cleaning up snapshot file $t .."
	fi
	rm -f "$t"
done

if [ $DEBUG -eq 1 ]
then
	echo "Finished backup"
	echo ""
fi
