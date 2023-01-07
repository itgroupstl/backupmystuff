# backupmystuff
A bash script to assist in the backup of files and folders. 

 **Email Setup** <br />
 No need to have a mail server installed <br />
 This script utilizes the Amazon SES (Simple Email Service) <br />
 Visit: https://docs.aws.amazon.com/ses/latest/dg/send-email.html <br />
 
 **Installation** <br />
 Installation is done by making the sure this file is executable. (sudo chmod +x backupmystuff.sh) <br />

 **Execution** <br />
 You can run it from the command line as a regular user for a more interactive experience (sudo ./backupmystuff.sh) or <br />
 You can run it as a cron job by passing the "c" flag. (sudo ./backupmystuff.sh c) <br />
 It utilizes openssl s_client smtp to send a notification email without the need for a local mail server. <br />


 **Storage Details** <br />
 In the FAT32 file system, the maximum file size is 4 GB. <br />
 In case the files to be backed up are larger than 4 GB, this script will split up the backup into parts <br />
 When all the parts are located on a drive that can handle large files sizes, you can <br />
 Reassemble the .gz files back into one by using the cat command <br />
 **Example 1:** cat backup_FILE_TIMESTAMP.tar.gz.part* > backup_FILE_TIMESAMP.tar.gz <br />
 Replace "FILE_TIMESTAMP" with the timestamp of your files <br />
 You can also use the -out flag <br />
 **Example 2:** cat backup_FILE_TIMESTAMP.tar.gz.part* -out backup_FILE_TIMESAMP.tar.gz <br />
