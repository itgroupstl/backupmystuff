# backupmystuff
A bash script to assist in the backup of files and folders.


 Thing 1
 The purpose of this script is to backup files and folders of your choice

 Thing 2
 Installation is done by making the sure this file is executable. (sudo chmod +x backupmystuff.sh)

 Thing 3
 You can run it from the command line as a regular user for a more interactive experience (sudo ./backupmystuff.sh) or
 You can run it as a cron job by passing the "c" flag. (sudo ./backupmystuff.sh c)
 It utilizes openssl s_client smtp to send a notification email without the need for a local mail server.


 Thing 4
 In the FAT32 file system, the maximum file size is 4 GB.
 In case the files to be backed up are larger than 4 GB, this script will split up the backup into parts
 When all the parts are located on a drive that can handle large files sizes, you can
 Reassemble the .gz files back into one by using the cat command
 Example 1: cat backup_FILE_TIMESTAMP.tar.gz.part* > backup_FILE_TIMESAMP.tar.gz
 Replace "FILE_TIMESTAMP" with the timestamp of your files
 You can also use the -out flag
 Example 2: cat backup_FILE_TIMESTAMP.tar.gz.part* -out backup_FILE_TIMESAMP.tar.gz
