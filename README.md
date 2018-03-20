# rotate_backup
Bash script to rotate backup directories. The backup directories must have timestamps encoded in their names. This script rotates the dirs based on the timestamps found in the dirs names, and **not** based on the dirs' timestamps.

### Description
This script operates on a (root) backup directory holding directories that include timestamps in their names. These (sub)directories can appear anywhere inside this backup directory (including inside nested subdirectories). The timestamp included in the directory names is assumed to be in the MM-DD-YY format. For example: directory `backup_dir_01-01-16` encodes Jan 1st, 2016 in its name

When run, the script places all dirs in one of seven buckets based on the timestamp encoded in the directory name. Each bucket corresponds a time interval in the past. These buckets are named:

- 000-013--DAYS-AGO
- 014-020--DAYS-AGO
- 021-027--DAYS-AGO
- 028-034--DAYS-AGO
- 035-062--DAYS-AGO
- 063-174--DAYS-AGO
- 175-365--DAYS-AGO

**All directories whose timestamps are older than 365 days, are deleted**.

### Usage
```
./rotate_backup.sh -b rootBackupDirName [-d]
```
