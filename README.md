# rotate_backup
Bash script to rotate backup files. The backup files must have timestamps encoded in their names. This script rotates the files based on the timestamps found in the file names, and **not** based on the files' timestamps.

### Description
This script operates on a (root) backup directory holding files that include timestamps in their names. These files can appear anywhere inside this backup directory (including inside nested subdirectories). The timestamp included the filename is assumed to be in the MM-DD-YY format. For example: file `backup_file_01-01-16.tgz` encodes Jan 1st, 2016 in its name

When run, the script places all files in one of seven subdirectories based on the timestamp encoded in the file name. Each subdirectory corresponds a time interval in the past. These subdirectories are named:

- 000-013--DAYS-AGO
- 014-020--DAYS-AGO
- 021-027--DAYS-AGO
- 028-034--DAYS-AGO
- 035-062--DAYS-AGO
- 063-174--DAYS-AGO
- 175-365--DAYS-AGO

**All files whose timestamps are older than 365 days, are deleted**.

### Usage
```
./rotate_backup.sh -b rootBackupDirName [-d]
```
