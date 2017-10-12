#!/bin/bash

#
# Parse and validate script arguments
#
DOMAIN="$1"
BACKUPDEST="$2"

if [ -z "$BACKUPDEST" ]
then
    BACKUPDEST="/var/data/virtuals/backups"
fi

if [ -z "$BACKUPDEST" -o -z "$DOMAIN" ]
then
    echo "Usage: ./vm-live-backup <domain> [backup-folder]"
    exit 1
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
BACKUPDATE=`date "+%Y-%m-%d.%H-%M-%S"`
BACKUPDOMAIN="$BACKUPDEST/$DOMAIN"
BACKUP="$BACKUPDOMAIN/$BACKUPDATE"
SNAPSHOT_SUFFIX="snapshot"

#
# Get the list of targets (disks) and the image paths.
#
TARGETS=`virsh domblklist "$DOMAIN" --details | grep "^file[[:space:]]*disk" | awk '{print $3}'`
IMAGES=`virsh domblklist "$DOMAIN" --details | grep "^file[[:space:]]*disk" | awk '{print $4}'`

#
# Check if another backup is still in progress
# This is the case when teh disk contains the pattern snapshot
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
        virsh blockcommit "$DOMAIN" "$t" --active --pivot > /dev/null
        status=$?
        if [ $? -eq 0 ]
        then
            # abort if all was fine
            break
        fi
        # check if the job was retried too often
        if [ $retry_blockcommit -eq 5 ]
        then
            echo "Error: Could not merge changes for disk $t of $DOMAIN after $retry_blockcommit retries. VM may be in an invalid state now."
            echo ""
            echo "I need the help of a human!"
            exit 1
        else
            echo "Warning: Could not merge changes for disk $t of $DOMAIN on attempt #$retry_blockcommit, retrying in 5 seconds .."
            sleep 5

            virsh blockjob "$DOMAIN" "$t" --abort > /dev/null
            if [ ! $? -eq 0 ]
            then
                echo "Error: Could not abort the blockjob after a failed blockcommit. VM may be in an invalid state now."
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
    # echo "Cleaning up backup image $t"
    rm -f "$t"
done

#
# Archive the backup
#
$SCRIPT_PATH/targz-purge-directory.sh "$BACKUP" > /dev/null

#
# Cleanup older backups.
#
$SCRIPT_PATH/cleanup.py "--working-dir=$BACKUPDOMAIN" --no-dry-run --silent

$SCRIPT_PATH/df-check.sh

# echo "Finished backup"
# echo ""

