#!/bin/bash

# This script rotates daily backup directories within a root backup directory. The backup directories rotated 
# must encode timestamps in their names using MM-DD-YY format. Note that this script assumes you do not have more than
# one backup directory with the same timestamp.
#  
# The rotation places these directories into a set of seven buckets as follows:
# - 000-013--DAYS-AGO: stores all directories whose timestamps appear in the last 14 days including today
# - 014-020--DAYS-AGO (2-3 weeks ago), 021-027-DAYS--AGO (3-4 weeks ago), 
#   028-034--DAYS-AGO (4-5 weeks ago), 035-062--DAYS-AGO (5-9 weeks ago), 
#   063-174--DAYS-AGO (9-25 weeks ago), 175-365--DAYS-AGO (25-52 weeks ago)
# 
# All older backups are deleted (USE AT YOUR OWN RISK!!!)
#
# This script must be run like this:
#  ./rotate_backup.sh -b rootBackupDirName [-d]

## Simple usage routine
usage() 
{ 
  echo "Usage: ./rotate_backup.sh -b rootBackupDirName [-d]"
  echo 
  echo "When a user creates daily backups, the following trade-off arises."
  echo "On one hand, the old backups must be deleted to make room for more recent backups."
  echo "On the other hand, it is a good idea to keep at least a few copies of old backups, just in case."
  echo "This script places all backup directories in seven buckets, one storing all backups taken within"
  echo "the last 14 days (including today), and six each storing one backup whose timestamp is the most"
  echo "recent but not more than k weeks ago where k is 2, 3, 4, 8, 26, and 52."
  echo 
  echo "The backups are assumed to encode their timestamps into their names" 
  echo "in the MM-DD-YY format."
  echo 
  echo "For example: BLDC_01-01-16_XXX encodes Jan 1st, 2016."
} 

## Routine that checks the existence of directories
check_directories()
{
  if [ -z "$1" ]                           # Is parameter #1 zero length?
  then
    echo "-Parameter #1 is zero length.-"  # Or no parameter passed.
    exit
  fi

  # Assign input parameters
  rootBackupDir=${1-$DEFAULT}          

  # Check if the backup directories exist. Start witht the root backup
  if [ ! -d "$rootBackupDir" ]; then
    echo "Directory $rootBackupDir doesn't exist. Cannot continue."
    echo 
    usage
    exit
  fi
  ## now loop through the above array and check if directories exist. Create them if they don't.
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

## Routine that takes four parameters:
##   a start and an end date whose formats are MM-DD-YY,
##   a bucket name
##   and a flag that says whether to keep oldest only and delete all others within the bucket 
## The routine finds all directories whose names include MM-DD-YY and moves them to the buckets
move_to_bucket()
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

  if [ -z "$4" ]                           # Is parameter #3 zero length?
  then
    echo "-Parameter #3 is zero length.-"  # Or no parameter passed.
    exit
  fi

  # Assign input parameters
  startDate=${1-$DEFAULT}          
  endDate=${2-$DEFAULT}          
  bucketToMoveto=${3-$DEFAULT}
  keepOldestOnly=${4-$DEFAULT}

  # Go in reverse order by day
  foundAny=false
  for i in `seq $endDate -1 $startDate`;
  do
    # Generate a date of the form MM-DD-YY and call that 
    # a directory name     
    dateToSearchFor=$(date --date "$i days ago" +"%m-%d-%y")
  
    # Count how many backup directories with DirectoryName we have
    c=$(find $rootBackupDir -path $bucketToMoveto -prune -o -type d -name "*$dateToSearchFor*" -print | wc -l)

    # If any directories found, rerun the find command and place all directories found on a single line
    # separated by spaces. Then move them.
    if [ $c -ne 0 ]; then
      dirs=$(find $rootBackupDir -path $bucketToMoveto -prune -o -type d -name "*$dateToSearchFor*" -printf "%p ")
      if [ $foundAny == "false" ] || [ $keepOldestOnly == "false" ]; then
        echo "Moving $dirs to $bucketToMoveto"
        mv $dirs $bucketToMoveto
      else
        echo "Deleting $dirs"
        rm -rf $dirs
      fi
      foundAny=true
    fi
  done
}

#
# Start main code
# 

# The script accepts two input parameters -b and -r
#  -b: root backup directory
# Parse the input and save the options passed in by the caller
while getopts ":b:" opt; do
  case $opt in
    b)
      rootBackupDir=$OPTARG
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

# Check that the backup directories exist
check_directories "$rootBackupDir"

# delete all backups older than one year -- up to 10 years ago
mkdir "$rootBackupDir/TO_BE_DELETED"
move_to_bucket 365 3650 "$rootBackupDir/TO_BE_DELETED" false
rm -rf "$rootBackupDir/TO_BE_DELETED"

# fifty two weeks ago: 175 - 365
move_to_bucket 175 365 ${buckets[6]} true

# twenty four weeks ago: 63 - 63+16*7-1
move_to_bucket 63 174 ${buckets[5]} true

# eight weeks ago: 35 - 62
move_to_bucket 35 62  ${buckets[4]} true

# four weeks ago: 28 - 34
move_to_bucket 28 34 ${buckets[3]} true

# three weeks ago: 21 - 27
move_to_bucket 21 27 ${buckets[2]} true

# two weeks ago: 14 - 20
move_to_bucket 14 20 ${buckets[1]} true

# 14 days: 0 - 13
move_to_bucket 0 13 ${buckets[0]} false

