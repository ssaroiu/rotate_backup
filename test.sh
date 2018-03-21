#!/bin/bash

#
# Test script for rotate_backup
#

rootBackupDir="./BACKUP_TEST"

if [ -d "$rootBackupDir" ]; then
  echo "$rootBackupDir" exists. This test won\'t overwrite it.
  exit -1
fi

#
# Test with a single directory with today's date
#

mkdir $rootBackupDir

# Generate today's date of the form MM-DD-YY
todayDate=$(date +"%m-%d-%y")

# Create 1 directory with today's timestamp
mkdir $rootBackupDir/TEST-$todayDate

./rotate_backup.sh -b $rootBackupDir

# Check directory has been moved correctly
if [ ! -d "$rootBackupDir/000-013--DAYS-AGO/TEST-$todayDate" ]; then
  echo Test failed. Directory TEST-$todayDate not found in $rootBackupDir/000-013--DAYS bucket.
  exit 1
fi

# Cleanup all test files
rm -rf $rootBackupDir

echo Test with a single directory with today\'s date passed.

#
# Test with a directory for each of the past 365 days
#

mkdir $rootBackupDir

for i in `seq 0 1 365`;
do
    # Generate a date of the form MM-DD-YY
    iDate=$(date --date "$i days ago" +"%m-%d-%y")

    mkdir $rootBackupDir/TEST-$iDate
done

./rotate_backup.sh -b $rootBackupDir

# Check that 000-013 has 14 directories in it
c=$( ls -d $rootBackupDir/000-013--DAYS-AGO/* | wc -l)
if [ $c != 14 ]; then
  echo Test failed. Directory 000-013--DAYS-AGO should have 14 subdirectories inside of it.
  exit 1
fi

# Check that 014-020 has 1 directory in it
c=$( ls -d $rootBackupDir/014-020--DAYS-AGO/* | wc -l)
if [ $c != 1 ]; then
  echo Test failed. Directory 014-020--DAYS-AGO should have 1 subdirectory inside of it.
  exit 1
fi

# Check that 175-365 has 1 directory in it
c=$( ls -d $rootBackupDir/175-365--DAYS-AGO/* | wc -l)
if [ $c != 1 ]; then
  echo Test failed. Directory 175-365--DAYS-AGO should have 1 subdirectory inside of it.
  exit 1
fi

# Cleanup all test files
rm -rf $rootBackupDir

echo Test with a directory for each of the past 365 days passed.

#
# Test with a directory for each of the 1 through 366 days ago.
#  (as if testing with a workload generated "yesterday")
#

mkdir $rootBackupDir

for i in `seq 1 1 366`;
do
    # Generate a date of the form MM-DD-YY
    iDate=$(date --date "$i days ago" +"%m-%d-%y")

    mkdir $rootBackupDir/TEST-$iDate
done

./rotate_backup.sh -b $rootBackupDir

# Check that 000-013 has 13 directories in it
c=$( ls -d $rootBackupDir/000-013--DAYS-AGO/* | wc -l)
if [ $c != 13 ]; then
  echo Test failed. Directory 000-013--DAYS-AGO should have 13 subdirectories inside of it.
  exit 1
fi

# Check that 014-020 has 1 directory in it
c=$( ls -d $rootBackupDir/014-020--DAYS-AGO/* | wc -l)
if [ $c != 1 ]; then
  echo Test failed. Directory 014-020--DAYS-AGO should have 1 subdirectory inside of it.
  exit 1
fi

# Check that 175-365 has 1 directory in it
c=$( ls -d $rootBackupDir/175-365--DAYS-AGO/* | wc -l)
if [ $c != 1 ]; then
  echo Test failed. Directory 175-365--DAYS-AGO should have 1 subdirectory inside of it.
  exit 1
fi

# Cleanup all test files
rm -rf $rootBackupDir

echo Test with a directory for each of the 1 through 366 days ago passed.

#
# Test with three directories 173, 174, and 175 days ago
#

mkdir $rootBackupDir

for i in `seq 173 1 175`;
do
    # Generate a date of the form MM-DD-YY
    iDate=$(date --date "$i days ago" +"%m-%d-%y")

    mkdir $rootBackupDir/TEST-$iDate
done

./rotate_backup.sh -b $rootBackupDir

# Check that 000-013 has 0 directories in it
c=$( ( ls -d $rootBackupDir/000-013--DAYS-AGO/* ) 2>/dev/null | wc -l)
if [ $c != 0 ]; then
  echo Test failed. Directory 000-013--DAYS-AGO should have 0 subdirectories inside of it.
  exit 1
fi

# Check that 014-020 has 0 directories in it
c=$( ( ls -d $rootBackupDir/014-020--DAYS-AGO/* ) 2>/dev/null | wc -l)
if [ $c != 0 ]; then
  echo Test failed. Directory 014-020--DAYS-AGO should have 0 subdirectory inside of it.
  exit 1
fi

# Check that 063-174 has 1 directory in it
c=$( ls -d $rootBackupDir/063-174--DAYS-AGO/* | wc -l)
if [ $c != 1 ]; then
  echo Test failed. Directory 063-174--DAYS-AGO should have 1 subdirectory inside of it.
  exit 1
fi

# Check that 175-365 has 1 directory in it
c=$( ls -d $rootBackupDir/175-365--DAYS-AGO/* | wc -l)
if [ $c != 1 ]; then
  echo Test failed. Directory 175-365--DAYS-AGO should have 1 subdirectory inside of it.
  exit 1
fi

# Cleanup all test files
rm -rf $rootBackupDir

echo Test with three directories 173, 174, and 175 days ago passed.

echo All tests pass.
