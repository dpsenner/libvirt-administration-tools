# Generic

This document serves as a resource of information and provides information on how to maintain virtual machines.

# Common operations

## Check if the virtual machine is running

`
virsh list --all
`

## Starting the virtual machine


`
virsh start $domain
`

## Graceful shutdown of the virtual machine

`
virsh shutdown $domain
`

# Known issues

## Live backup fails on a domain

We observed that sometimes live backup fails with the following message:

`
error: failed to pivot job for disk hda
error: block copy still active: disk 'hda' not ready for pivot yet
Could not merge changes for disk hda of $domain. VM may be in invalid state.
`

This means that the backup was made but all the data that was written to hda of the virtual machine could not be copied over to the base image. The virtual machine keeps writing new data into the image.snapshot file. To prevent undesirable side effects or even collateral damage, live backup refuses to work if a domain points to a drive that is a snapshot. This means that it is necessary to have this fixed to have live backups working again! A live backup will however send an email saying that it refuses to make a live backup.

Fixing this is quite easy and can ideally be done while the virtual machine still runs by executing the following commands in this order:

`
virsh blockjob $domain hda --abort
virsh blockcommit $domain hda --active --pivot
`

If the second command fails again, it is necessary to shut down the virtual machine and retry this operation while the virtual machine is offline.

## Virtual machine crashes with a blue screen after migrating the virtual machine to another host

If the host machine runs ubuntu and the blue screen shows the following error message:

`
KMODE_EXCEPTION_NOT_HANDLED
`

this can be caused by KVM because it injects a #GP into the guest if that tries to access an unhandled MSRs. KVM can be configured to ignore unhandled MSRs. To check if KVM on the host computer is configured to ignore unhandled MSRs run:

`
cat /sys/modules/kvm/parameters/ignore_msrs
`

If that command returns a "N", it could be wise to change that parameter by doing:

`
echo 1 > /sys/modules/kvm/parameters/ignore_msrs
`

After that the guest blue screen should be gone and the guest should start up just fine.

