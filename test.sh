#!/bin/bash

#
# Test script for rotate_backup
#

rootBackupDir="./BACKUP_TEST"

if [ -d "$rootBackupDir" ]; then
  echo "$rootBackupDir" exists. This test won\'t overwrite it.
  exit -1
fi

function main() {
  test1
  test2
  test3
  test4
  test5
  test6
  echo All tests pass.
}

function test1() {
  #
  # Test with a single directory with today's date
  #

  mkdir $rootBackupDir

  # Generate today's date of the form MM-DD-YY
  todayDate=$(date +"%m-%d-%y")

  # Create 1 directory with today's timestamp
  mkdir $rootBackupDir/TEST-$todayDate

  ./rotate_backup.sh -b $rootBackupDir -p

  __check_test 0 0 0 0 0 0 1

  # Check directory has been moved correctly
  if [ ! -d "$rootBackupDir/000-013--DAYS-AGO/TEST-$todayDate" ]; then
    echo Test failed. Directory TEST-$todayDate not found in $rootBackupDir/000-013--DAYS bucket.
    exit 1
  fi

  # Cleanup all test files
  rm -rf $rootBackupDir

  echo Test with a single directory with today\'s date passed.
}

function test2() {
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

  ./rotate_backup.sh -b $rootBackupDir -p

  __check_test 1 1 1 1 1 1 14

  # Cleanup all test files
  rm -rf $rootBackupDir

  echo Test with a directory for each of the past 365 days passed.
}

function test3 {
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

  ./rotate_backup.sh -b $rootBackupDir -p

  __check_test 1 1 1 1 1 1 13

  # Cleanup all test files
  rm -rf $rootBackupDir

  echo Test with a directory for each of the 1 through 366 days ago passed.
}

function test4 {
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

  ./rotate_backup.sh -b $rootBackupDir -p

  __check_test 1 1 0 0 0 0 0

  # Cleanup all test files
  rm -rf $rootBackupDir

  echo Test with three directories 173, 174, and 175 days ago passed.
}

function test5 {
  #
  # Test with two directories for each day for the past 365 days
  #

  mkdir $rootBackupDir

  for i in `seq 1 1 365`;
  do
      # Generate a date of the form MM-DD-YY
      iDate=$(date --date "$i days ago" +"%m-%d-%y")

      mkdir $rootBackupDir/TEST-$iDate $rootBackupDir/TEST-$iDate.2
  done

  ./rotate_backup.sh -b $rootBackupDir -p

  __check_test 2 2 2 2 2 2 26

  # Cleanup all test files
  rm -rf $rootBackupDir

  echo Test with two directories for each day for the past 365 days passed.
}

function test6 {
  #
  # Test with a directory from 366 days ago.
  #

  mkdir $rootBackupDir

  # Generate a date of the form MM-DD-YY
  iDate=$(date --date "366 days ago" +"%m-%d-%y")

  mkdir $rootBackupDir/TEST-$iDate

  ./rotate_backup.sh -b $rootBackupDir -p

  __check_test 0 0 0 0 0 0 0

  # Check directory has been moved correctly
  if [ ! -d "$rootBackupDir/TEST-$iDate" ]; then
    echo Test failed. Directory TEST-$iDate not found in $rootBackupDir.
    exit 1
  fi

  # Cleanup all test files
  rm -rf $rootBackupDir

  echo Test with a directory from 366 days ago passed.
}

## Checks a test by checking whether each bucket holds the correct number
#  of dirs
#
# Takes 7 integers corresponding to the number of files in each bucket
# ordered from the oldest to the youngest
function __check_test {
  # Assign input parameters
  local b175_365=${1-$DEFAULT}     
  local b063_174=${2-$DEFAULT}     
  local b035_062=${3-$DEFAULT}     
  local b028_034=${4-$DEFAULT}     
  local b021_027=${5-$DEFAULT}     
  local b014_020=${6-$DEFAULT}     
  local b000_013=${7-$DEFAULT}

  c=$( ( ls -d $rootBackupDir/175-365--DAYS-AGO/* ) 2>/dev/null | wc -l)
  if [ $c != $b175_365 ]; then
    echo Test failed. Directory 175-365--DAYS-AGO should have $b175_365 subdirectories inside of it.
    exit 1
  fi
  c=$( ( ls -d $rootBackupDir/063-174--DAYS-AGO/* ) 2>/dev/null | wc -l)
  if [ $c != $b063_174 ]; then
    echo Test failed. Directory 063-174--DAYS-AGO should have $b063_174 subdirectories inside of it.
    exit 1
  fi
  c=$( ( ls -d $rootBackupDir/035-062--DAYS-AGO/* ) 2>/dev/null | wc -l)
  if [ $c != $b035_062 ]; then
    echo Test failed. Directory 035-062--DAYS-AGO should have $b035_062 subdirectories inside of it.
    exit 1
  fi
  c=$( ( ls -d $rootBackupDir/028-034--DAYS-AGO/* ) 2>/dev/null | wc -l)
  if [ $c != $b028_034 ]; then
    echo Test failed. Directory 028-034--DAYS-AGO should have $b028_034 subdirectories inside of it.
    exit 1
  fi
  c=$( ( ls -d $rootBackupDir/021-027--DAYS-AGO/* ) 2>/dev/null | wc -l)
  if [ $c != $b021_027 ]; then
    echo Test failed. Directory 021-027--DAYS-AGO should have $b021_027 subdirectories inside of it.
    exit 1
  fi
  c=$( ( ls -d $rootBackupDir/014-020--DAYS-AGO/* ) 2>/dev/null | wc -l)
  if [ $c != $b014_020 ]; then
    echo Test failed. Directory 014-020--DAYS-AGO should have $b014_020 subdirectories inside of it.
    exit 1
  fi
  c=$( ( ls -d $rootBackupDir/000-013--DAYS-AGO/* ) 2>/dev/null | wc -l)
  if [ $c != $b000_013 ]; then
    echo Test failed. Directory 000-013--DAYS-AGO should have $b000_013 subdirectories inside of it.
    exit 1
  fi
}

main "$@"
