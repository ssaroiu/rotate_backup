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

## declare array of bucket names
declare -a bucketNames=(\
   "000-013--DAYS-AGO" \
   "014-020--DAYS-AGO" \
   "021-027--DAYS-AGO" \
   "028-034--DAYS-AGO" \
   "035-062--DAYS-AGO" \
   "063-174--DAYS-AGO" \
   "175-365--DAYS-AGO" \
   )

## Simple usage routine
function usage() 
{ 
  echo
  echo "Usage: ./rotate_backup.sh -b rootBackupDir [-n]"
  echo  "   -n: Shows a log of all actions. No actions are taken."
  echo  "   -v: Verbose mode."
} 

# Main program
function main() {

  # Parse the input and save the options passed in by the caller
  while getopts ":b:nv" opt; do
    case $opt in
      b)
        rootBackupDir=$OPTARG
        ;;
      n)
        supress=true
        ;;
      v)
        verbose=true
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >& 2
        usage
        exit 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        usage
        exit 1
        ;;
    esac
  done

  if [ -z "$rootBackupDir" ]
  then
    echo "rootBackupDir must be declared."  # Or no parameter passed.
    usage
    exit 1
  fi

  # Check that the root and backup subdirectories exist
  if ! [ "$supress" == true ] ; then
    __check_root_and_buckets_exist "$rootBackupDir"
  fi

  ## Start moving dirs
  if [ "$verbose" ==  true ]; then
    echo Start moving dirs...
  fi
  __move_dirs_to_bucket 175 365 $rootBackupDir/${bucketNames[6]}
  __move_dirs_to_bucket 63 174 $rootBackupDir/${bucketNames[5]}
  __move_dirs_to_bucket 35 62  $rootBackupDir/${bucketNames[4]}
  __move_dirs_to_bucket 28 34 $rootBackupDir/${bucketNames[3]}
  __move_dirs_to_bucket 21 27 $rootBackupDir/${bucketNames[2]}
  __move_dirs_to_bucket 14 20 $rootBackupDir/${bucketNames[1]}
  __move_dirs_to_bucket 0 13 $rootBackupDir/${bucketNames[0]}
  if [ "$verbose" ==  true ]; then
    echo Moving done.
  fi

  ## Prune the buckets (we don't prune 000-013)
  if [ "$verbose" ==  true ]; then
    echo Start pruning dirs...
  fi
  __delete_all_but_oldest 175 365 $rootBackupDir/${bucketNames[6]}
  __delete_all_but_oldest 63 174 $rootBackupDir/${bucketNames[5]}
  __delete_all_but_oldest 35 62  $rootBackupDir/${bucketNames[4]}
  __delete_all_but_oldest 28 34 $rootBackupDir/${bucketNames[3]}
  __delete_all_but_oldest 21 27 $rootBackupDir/${bucketNames[2]}
  __delete_all_but_oldest 14 20 $rootBackupDir/${bucketNames[1]}
  if [ "$verbose" ==  true ]; then
    echo Pruning done.
  fi
}

# End of main program. Only routines from this point onward.

## Routine that checks 
#
#  1. The existence of root backup directory. If it doesn't exist, stop.
#  2. The existence of buckets. Create them if they don't exist.
#  
function __check_root_and_buckets_exist()
{
  if [ -z "$1" ]                           # Is parameter #1 zero length?
  then
    echo "-Parameter #1 is zero length.-"  # Or no parameter passed.
    usage
    exit 1
  fi

  # Assign input parameters
  rootBackupDir=${1-$DEFAULT}          

  if [ "$verbose" ==  true ]; then
    echo Checking if rootBackup dir exists...
  fi

  # Check if the backup directories exist. Start with the root backup
  if [ ! -d "$rootBackupDir" ]; then
    echo "Directory \"$rootBackupDir\" (rootBackupDir) doesn't exist. Cannot continue."
    usage
    exit 1
  fi

  if [ "$verbose" ==  true ]; then
    echo Checked.
  fi

  ## now loop through the buckets and check if they exist.
  #  Create them if they don't.
  for i in "${bucketNames[@]}"
  do

    if [ "$verbose" ==  true ]; then
      echo Creating directory $rootBackupDir/$i...
    fi

    # First create the directory (-p only if it does not exist)
    mkdir -p $rootBackupDir/$i

    # If directory still not there, exit
    if [ ! -d $rootBackupDir/$i ]; then
      echo "Bucket $i doesn't exist. Cannot continue."
      echo 
      usage
      exit
    fi

    if [ "$verbose" ==  true ]; then
      echo Done.
    fi
  done
}

## Routine that moves a set of relevant dirs to their corresponding bucket
## The set of relevant dirs are all dirs whose names contain timestamps
## found between two landmarks: [older_than_n_days_ago; yonger_than_n_days_ago]
## Note: the landmarks are inclusive
##
## e.g., __move_dirs_to_bucket 1 2 _bucketName_
## moves all dirs from yesterday and the day before yesterday to bucket         
##
##  
## Takes three parameters:
##   older_than_n_days_ago
##   younger_than_n_days ago
##   a bucket name
function __move_dirs_to_bucket()
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
  local olderThanN=${1-$DEFAULT}          
  local youngerThanN=${2-$DEFAULT}          
  local bucket=${3-$DEFAULT}

  # For each MM-DD-YY between the end and start dates in reverse chrono order
  for i in `seq $youngerThanN -1 $olderThanN`;
  do
    # Generate a date of the form MM-DD-YY
    iDate=$(date --date "$i days ago" +"%m-%d-%y")

    if [ "$verbose" ==  true ]; then
      echo Checking how many dirs matching date $iDate in $rootBackup exist...
    fi

    # Check if any dirs whose names include iDate exist
    # Unfortunately, the only way I know how to do that is by counting
    local c=$( (find $rootBackupDir -path $bucket -prune -o -type d -name "*$iDate*" -print) 2>/dev/null | wc -l)

    if [ "$verbose" ==  true ]; then
      echo Found $c.
    fi

    # If any such dirs exist, gather their names (rerun the command), and move them
    if [ $c -ne 0 ]; then
      local dirs=$(find $rootBackupDir -path $bucket -prune -o -type d -name "*$iDate*" -printf "%p ")

      if [ "$verbose" ==  true ]; then
        echo Moving all dirs to bucket $bucket...
      fi

      # Move the dirs
      if [ "$supress" == true ] ; then
        echo mv $dirs $bucket
      else 
        mv $dirs $bucket
      fi    

      if [ "$verbose" ==  true ]; then
        echo Moved.
      fi
    fi


  done
}

## Routine that deletes all dirs from a bucket except for the ones with the oldest
#  timestamp
## Takes two parameters:
##   older_than_n_days_ago
##   younger_than_n_days ago
function __delete_all_but_oldest()
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
  
  # Assign input parameters
  local olderThanN=${1-$DEFAULT}          
  local youngerThanN=${2-$DEFAULT}           

  # For each MM-DD-YY between the start and end dates and reverse chrono order
  local foundOldest=false
  for i in `seq $youngerThanN -1 $olderThanN`;
  do
    # Generate a date of the form MM-DD-YY
    iDate=$(date --date "$i days ago" +"%m-%d-%y")

    if [ "$verbose" ==  true ]; then
      echo Checking how many dirs matching date $iDate in $rootBackup exist...
    fi

    # Check if any dirs whose names include iDate exist
    # Unfortunately, the only way I know how to do that is by counting
    local c=$( (find $rootBackupDir -type d -name "*$iDate*" -print) 2>/dev/null | wc -l)

    if [ "$verbose" ==  true ]; then
      echo Found $c.
    fi

    # If any such dirs exist, check if they correspond to the oldest timestamp.
    # If not, delete them
    if [ $c -ne 0 ]; then
      if [ $foundOldest == false ] ; then
        if [ "$verbose" ==  true ]; then
          echo Oldest dir between [$olderThanN; $youngerThanN] is from $iDate. Not pruned.
        fi

        foundOldest=true
      else

        local dirs=$( (find $rootBackupDir -type d -name "*$iDate*" -printf "%p ") 2>/dev/null )

        if [ "$verbose" ==  true ]; then
          echo Pruning $dirs...
        fi

        # Delete the dirs
        if ["$supress" == true] ; then
          echo rm -rf $dirs
        else 
          rm -rf $dirs
        fi    

        if [ "$verbose" ==  true ]; then
          echo Pruned.
        fi
      fi
    fi
  done
}

main "$@"