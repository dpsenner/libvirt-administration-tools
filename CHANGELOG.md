# Changelog

## 1.2.1 - 2017-11-14

### Fixed

* vm-live-backup.sh does now properly retry when blockcommit fails.

## 1.2.0 - 2017-10-12

### Added

* vm-live-backup.sh does now try up to 5 times to blockcommit while backing up. This
  should reduce the frequency of human interventions on automated backups.

## 1.1.1 - 2017-07-26

### Added

* Added CHANGELOG file to track the changes between one version and the next

### Changed

* The domain definition xml is now dumped into the backup before creating the snapshot
  such that if the backup fails for some reason the xml is available in the backup.
* Extracted the targz operation into a separate script to allow easier targz of a
  backup directory in the case that a live backup failed for some reason.

## 1.1 - 2017-07-20

### Changed

* Updated README to include much more useful information

## 1.0 - 2017-07-20

### Added

* First release of the backup script

