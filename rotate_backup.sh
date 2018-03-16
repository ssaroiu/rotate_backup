#!/bin/bash

# MIT License

# Copyright (c) 2018 Stefan Saroiu

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

## declare array of buckets
declare -a buckets=(\
   "$rootBackupDir/000-013--DAYS-AGO" \
   "$rootBackupDir/014-020--DAYS-AGO" \
   "$rootBackupDir/021-027--DAYS-AGO" \
   "$rootBackupDir/028-034--DAYS-AGO" \
   "$rootBackupDir/035-062--DAYS-AGO" \
   "$rootBackupDir/063-174--DAYS-AGO" \
   "$rootBackupDir/175-365--DAYS-AGO" \
   )

## Simple usage routine
usage() 
{ 
  echo "Usage: ./rotate_backup.sh -b rootBackupDirName [-n]"
  echo 
  echo   -n: Shows a log of all actions. No actions are taken.
} 

# Parse the input and save the options passed in by the caller
while getopts ":bn:" opt; do
  case $opt in
    b)
      rootBackupDir=$OPTARG
      ;;
    b)
      supress=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >& 2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Check that the root and backup subdirectories exist
if ! [ "$supress" == true ] ; then
  check_root_and_buckets_exist "$rootBackupDir"
fi

## Start moving files

move_files_to_bucket 175 365 ${buckets[6]}
move_files_to_bucket 63 174 ${buckets[5]}
move_files_to_bucket 35 62  ${buckets[4]}
move_files_to_bucket 28 34 ${buckets[3]}
move_files_to_bucket 21 27 ${buckets[2]}
move_files_to_bucket 14 20 ${buckets[1]}
move_files_to_bucket 0 13 ${buckets[0]}

## Prune the buckets (we don't prune 000-013)
delete_all_but_oldest 175 365 ${buckets[6]}
delete_all_but_oldest 63 174 ${buckets[5]}
delete_all_but_oldest 35 62  ${buckets[4]}
delete_all_but_oldest 28 34 ${buckets[3]}
delete_all_but_oldest 21 27 ${buckets[2]}
delete_all_but_oldest 14 20 ${buckets[1]}

# End of main program. Only routines from this point onward.

## Routine that checks 
#
#  1. The existence of root backup directory. If it doesn't exist, stop.
#  2. The existence of buckets. Create them if they don't exist.
#  
check_root_and_buckets_exist()
{
  if [ -z "$1" ]                           # Is parameter #1 zero length?
  then
    echo "-Parameter #1 is zero length.-"  # Or no parameter passed.
    exit
  fi

  # Assign input parameters
  rootBackupDir=${1-$DEFAULT}          

  # Check if the backup directories exist. Start with the root backup
  if [ ! -d "$rootBackupDir" ]; then
    echo "Directory $rootBackupDir doesn't exist. Cannot continue."
    echo 
    usage
    exit
  fi
  ## now loop through the buckets and check if they exist.
  #  Create them if they don't.
  for i in "${buckets[@]}"
  do
    # First create the directory (-p only if it does not exist)
    mkdir -p $i
    
    # If directory still not there, exit
    if [ ! -d $i ]; then
      echo "Bucket $i doesn't exist. Cannot continue."
      echo 
      usage
      exit
    fi
  done
}

## Routine that moves all relevant files to their corresponding bucket
## Takes three parameters:
##   a start and an end date whose formats are MM-DD-YY,
##   a bucket name
move_files_to_bucket()
{
  if [ -z "$1" ]                           # Is parameter #1 zero length?
  then
    echo "-Parameter #1 is zero length.-"  # Or no parameter passed.
    exit
  fi

  if [ -z "$2" ]                           # Is parameter #2 zero length?
  then
    echo "-Parameter #2 is zero length.-"  # Or no parameter passed.
    exit
  fi
  
  if [ -z "$3" ]                           # Is parameter #3 zero length?
  then
    echo "-Parameter #3 is zero length.-"  # Or no parameter passed.
    exit
  fi

  # Assign input parameters
  startDate=${1-$DEFAULT}          
  endDate=${2-$DEFAULT}          
  bucket=${3-$DEFAULT}

  # For each MM-DD-YY between the start and end dates
  for i in `seq $startDate 1 $endDate`;
  do
    # Generate a date of the form MM-DD-YY
    iDate=$(date --date "$i days ago" +"%m-%d-%y")

    # Check if any files whose names include iDate exist
    # Unfortunately, the only way I know how to do that is by counting
    c=$(find $rootBackupDir -path $bucket -prune -o -type d -name "*$iDate*" -print | wc -l)

    # If any such files exist, gather their names (rerun the command), and move them
    if [ $c -ne 0 ]; then
      dirs=$(find $rootBackupDir -path $bucket -prune -o -type d -name "*$iDate*" -printf "%p ")

      # Move the files
      if [ "$supress" == true ] ; then
        echo mv $dirs $bucket
      else 
        mv $dirs $bucket
      fi    
    fi
  done
}

## Routine that deletes all files from a bucket except for the ones with the oldest
#  timestamp
## Takes three parameters:
##   a start and an end date whose formats are MM-DD-YY,
##   a bucket name
delete_all_but_oldest()
{
  if [ -z "$1" ]                           # Is parameter #1 zero length?
  then
    echo "-Parameter #1 is zero length.-"  # Or no parameter passed.
    exit
  fi

  if [ -z "$2" ]                           # Is parameter #2 zero length?
  then
    echo "-Parameter #2 is zero length.-"  # Or no parameter passed.
    exit
  fi
  
  if [ -z "$3" ]                           # Is parameter #3 zero length?
  then
    echo "-Parameter #3 is zero length.-"  # Or no parameter passed.
    exit
  fi

  # Assign input parameters
  startDate=${1-$DEFAULT}          
  endDate=${2-$DEFAULT}          
  bucket=${3-$DEFAULT}

  # For each MM-DD-YY between the start and end dates and reverse chrono order
  for i in `seq $startDate -1 $endDate`;
  foundOldest=false
  do
    # Generate a date of the form MM-DD-YY
    iDate=$(date --date "$i days ago" +"%m-%d-%y")

    # Check if any files whose names include iDate exist
    # Unfortunately, the only way I know how to do that is by counting
    c=$(find $rootBackupDir -path $bucket -prune -o -type d -name "*$iDate*" -print | wc -l)

    # If any such files exist, check if they correspond to the oldest timestamp.
    # If not, delete them
    if [ $c -ne 0 ]; then
      if [ $foundOldest == false ] ; then
        foundOldest=true
      else

        dirs=$(find $rootBackupDir -path $bucket -prune -o -type d -name "*$iDate*" -printf "%p ")

        # Delete the files
        if ["$supress" == true] ; then
          echo rm -rf $dirs
        else 
          rm -rf $dirs
        fi    
    fi
  done
}