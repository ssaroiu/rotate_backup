#!/bin/bash

#
# Test script for rotate_backup
#

rootBackupDir="./BACKUP_TEST"

if [ -d "$rootBackupDir" ]; then
  echo "$rootBackupDir" exists. This test won\'t overwrite it.
  exit -1
fi
mkdir $rootBackupDir

# Generate today's date of the form MM-DD-YY
todayDate=$(date +"%m-%d-%y")

# Create 1 file with today's timestamp
touch $rootBackupDir/TEST-$todayDate.tmp



# Cleanup all test files
rm -rf $rootBackupDir

