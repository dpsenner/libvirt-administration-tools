# Introduction

This document serves as a resource of information and provides information on how to maintain virtual machines.

# Contributing

Please read the contributing guidelines before starting to work on a patch, writing issues or file a pull request. The contributing guidelines are available [here](CONTRIBUTING.md).

# Common operations

## Check if the virtual machine is running

```
~$ virsh list --all
```

## Starting the virtual machine


```
~$ virsh start $domain
```

## Graceful shutdown of the virtual machine

```
~$ virsh shutdown $domain
```

## Make live backup once

The following command makes a live backup of `<domain>` and creates a new archive in the path `<backup-path>/<domain>/<date>-<time>.tar.gz`. Any directory or file that does not exist it will be created.

```
~/libvirt-administration-tools$ ./vm-live-backup.sh <domain> <backup-path>
```

## Set up daily live backups

This is a check list of things that need to be done to make daily backups of a domain. The following steps assume that a domain exists on the same machine, is running 24\*7. The domain name of the virtualized guest is `<domain>`. The path where the backup should be stored is `<backup-path>`. Please note that backups will be made to the path `<backup-path>/<domain>/<date-<time>.tar.gz`.

* Clone and checkout the master branch of this repository
* Open crontab editor by executing `crontab -e`
* Add the following line to the cronjobs
* `30 23 * * * /absolute-path-to/libvirt-administration-tools/vm-live-backup.sh <domain> <backup-path>`
* Save and exit the editor

# Known issues

## Live backup fails on a domain

We observed that sometimes live backups fail with the following message:

```
error: failed to pivot job for disk hda
error: block copy still active: disk 'hda' not ready for pivot yet
Could not merge changes for disk hda of $domain. VM may be in invalid state.
```

This means that the backup was made but all the data that was written to hda of the virtual machine could not be copied over to the base image. The virtual machine keeps writing new data into the snapshot image file. To prevent undesirable side effects or even collateral damage, live backup refuses to work if a domain points to a drive that is a snapshot. This means that it is necessary to have this fixed to have live backups working again! A live backup will however send an email saying that it refuses to make a live backup.

Fixing this is quite easy and can ideally be done while the virtual machine still runs by executing the following commands in this order:

```
~/libvirt-administration-tools$ ./blockjob-abort.sh $domain
~/libvirt-administration-tools$ ./blockcommit.sh $domain
~/libvirt-administration-tools$ ./targz-purge-directory.sh <path-to-backup>
```

If the second command fails again, it is necessary to shut down the virtual machine and retry this operation while the virtual machine is offline.

Note that this error does no longer happen on newer `libvirtd` versions, especially this version has no longer shown the symptoms:

```
$ virsh --version
3.6.0
```

## Windows guest crashes with a blue screen after migrating the virtual machine to another host

While attempting to migrate a windows guest from one ubuntu host to another we observed that the guest refused to start up. It crashed with a blue screen that showed the following error message:

```
KMODE_EXCEPTION_NOT_HANDLED
```

This can be caused by KVM because it injects a #GP into the guest if that tries to access an unhandled MSRs. KVM can be configured to ignore unhandled MSRs. To check if KVM on the host computer is configured to ignore unhandled MSRs run:

```
cat /sys/modules/kvm/parameters/ignore_msrs
```

If that command returns a "N", it could be wise to change that parameter by doing:

```
echo 1 > /sys/modules/kvm/parameters/ignore_msrs
```

After that the guest blue screen should be gone and the guest should start up just fine.

