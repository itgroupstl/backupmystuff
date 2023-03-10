#!/bin/bash


# Read list of items (individual items or folders) to be backed up from file
# Example: "/var/www/html /home/user/Documents/file1.txt /home/user/Desktop"
items="/var/www/html "

# Define path to backup drive
backup_drive="/bkupdrive"

# Define type backup drive (USB, SATA, SCSI, NVMe, PCIe, SAS, SAS-SSD, SATA-SSD)
# This just provides a default transfer speed
backup_drive_type="USB"


# SMTP MAIL SETTINGS
# These settings are designed to use the Amazon SES (Simple Email Service)
# For Amazon SES setup instructions visit: https://docs.aws.amazon.com/ses/latest/dg/send-email.html
server="awsmail.yourdomain.com"
username_hash="QUtJQVlJxxxxxxxxxxxxSUVKUEI="
password_hash="QkRjSjA1Y2MrbUI3SGxxxxxxxxxxxxxxxxxxNmb1BZU2JXcHptQ21YL2k="
from_name="AWS - Local"
from_email_address="awsmail@yourdomain.com"
to_name="Admin Billy"
to_email_address="billy@yourdomain.com"
email_subject="Weekly Local Backup"

#####################################################################################
#####################################################################################
### READ THIS ##############################
#####################################################################################
#####################################################################################

# Thing 1
# The purpose of this script is to backup files and folders of your choice by compressing
# items in your list into a single file

# Thing 2
# Installation is done by making the sure this file is executable. (sudo chmod +x backupmystuff.sh)

# Thing 3
# You can run it from the command line as a regular user for a more interactive experience (sudo ./backupmystuff.sh) or
# You can run it as a cron job by passing the "c" flag. (sudo ./backupmystuff.sh c)
# It utilizes openssl s_client smtp to send a notification email without the need for a local mail server.


# Thing 4
# In the FAT32 file system, the maximum file size is 4 GB.
# In case the files to be backed up are larger than 4 GB, this script will split up the backup into parts
# When all the parts are located on a drive that can handle large files sizes, you can
# Reassemble the .gz files back into one by using the cat command
# Example 1: cat backup_FILE_TIMESTAMP.tar.gz.part* > backup_FILE_TIMESAMP.tar.gz
# Replace "FILE_TIMESTAMP" with the timestamp of your files
# You can also use the -out flag
# Example 2: cat backup_FILE_TIMESTAMP.tar.gz.part* -out backup_FILE_TIMESAMP.tar.gz


#####################################################################################
#####################################################################################
### Probably do not need to modify anything below here ##############################
#####################################################################################
#####################################################################################




# Define the format of the backup drive
# Defaults to automatcially detect
file_system=$(df -T "$backup_drive" | awk 'NR==2 {print $2}')

printf "Backup Drive Format: $file_system \n"
# Manually specify backup drive format
# Options include(vfat,exfat,ntfs,hfsplus,ext2,ext3,ext4)
#file_system="vfat"


# Perform a read/write test on the drive
start_time=$(date +%s%N)
dd if="/dev/zero" of="$backup_drive/test_file" bs=1M count=100 conv=fdatasync > /dev/null 2>&1
end_time=$(date +%s%N)

# Calculate the elapsed time (in milliseconds)
elapsed_time=$(((end_time - start_time)/1000000))

# Calculate the transfer speed (in bytes per second)
test_transfer_speed=$((100*1024*1024/elapsed_time))

# Calculate the transfer speed (in bytes/second)
if [ "$elapsed_time" -eq 0 ]; then
  printf "Testing the backup drive: $elapsed_time ms \n"
  printf "Make sure backup drive is available and able to write to"
  printf "Backup Cancelled\xF0\x9F\x92\xA5\n"
  printf "\n"
  exit 1
else
  printf "Testing the backup drive: $elapsed_time ms OK\n"
fi

printf "Test transferred at: $test_transfer_speed bytes/sec \n"

case "$backup_drive_type" in
  "USB") transfer_speed=50000;;
  "SATA") transfer_speed=200000;;
  "SCSI") transfer_speed=500000;;
  "NVMe") transfer_speed=3500000;;
  "PCIe") transfer_speed=1000000;;
  "SAS") transfer_speed=1500000;;
  "SAS-SSD") transfer_speed=2400000;;
  "SATA-SSD") transfer_speed=600000;;
  *) transfer_speed=500000;;
esac

if [[ $test_transfer_speed -gt $transfer_speed ]]; then
  transfer_speed=$test_transfer_speed
fi


# Clean up the test file
rm "$backup_drive/test_file"



# Define items to skip (currently skips hidden files and folders)
skip=".*/"


# Get current timestamp
timestamp=$(date +%m-%d-%Y-%H_%M_%S)


# Initialize spinner (a couple to choose from)
spinner='????????????????????????????????????'
#spinner='????????????'
#spinner='??????????????????????????????'
#spinner='??????????????????????????????????????????'
#spinner='???????????????????????????????????????????????????'
delay=0.1


#####################################################################################
#####################################################################################
### Probably really do not need to modify anything below here #######################
#####################################################################################
#####################################################################################

# Define spinner function
spinner() {
  while true
  do
    for i in `seq 0 9`
    do
      printf "\r$1${spinner:$i:1}"
      sleep $delay
    done
  done
}

# Define backup function for user
backitupuser(){

  # Set message
  msg="Compressing files and folders ...... \xF0\x9F\x97\x9C  "

  # Start spinner
  spinner "$msg" &

  # Save spinner PID
  spinner_pid=$!

  # Create temp file and backup filename
  tmp_file=$(mktemp)
  bkup_file=backup_$timestamp.tar.gz

  # Run tar command and store output
  output=$(tar -cz --exclude=$skip $items > $tmp_file 2> /dev/null)

  # Stop spinner
  kill $spinner_pid

  printf "done \n"

  # Print tar output
  printf "\rCompressed ... $output"

  size=$(stat -c%s $tmp_file)

  pv -s $size -t -r $tmp_file > $bkup_file

  rm $tmp_file


  printf "\n"

  # Set message
  msg="Copying compressed file to backup drive... \xF0\x9F\x92\xBE  "

  # Start spinner
  spinner "$msg" &

  # Save spinner PID
  spinner_pid=$!




  case "$file_system" in
    "vfat")
      # Split file into smaller chunks and copy separately
      split -b 3GB $bkup_file $bkup_file.part
      for file in $bkup_file.part*; do
        output_copy=$(rsync -v $file $backup_drive)
        rm $file
      done
      if [[ $size -lt 4000000000 ]]; then
        # Reassemble split parts
        cat $backup_drive/$bkup_file.part* > $backup_drive/$bkup_file
        rm $backup_drive/$bkup_file.part*
      fi
      ;;
    "exfat")
      # Split file into smaller chunks and copy separately
      split -b 3GB $bkup_file $bkup_file.part
      for file in $bkup_file.part*; do
        output_copy=$(rsync -v $file $backup_drive)
        rm $file
      done
      if [[ $size -lt 4000000000 ]]; then
        # Reassemble split parts
        cat $backup_drive/$bkup_file.part* > $backup_drive/$bkup_file
        rm $backup_drive/$bkup_file.part*
      fi
      ;;
    "ntfs")
      # Copy file without splitting
      output_copy=$(rsync -v $bkup_file $backup_drive)
      ;;
    "hfsplus")
      # Copy file without splitting
      output_copy=$(rsync -v $bkup_file $backup_drive)
      ;;
    "ext2"|"ext3"|"ext4")
      # Copy file without splitting
      output_copy=$(rsync -v $bkup_file $backup_drive)
      ;;
  esac





  # Stop spinner
  kill $spinner_pid

  printf "done \n"

  # Get the actual filesize 
  actual_file_size_bytes=$(du -b $bkup_file)
  actual_file_size_gigabytes=$(bc <<< "scale=2; $actual_file_size_bytes / 1000000000")
  printf "Compressed File Size (bytes): $actual_file_size_bytes \n"
  printf "Compressed File Size (gb): $actual_file_size_gigabytes \n"


  # Print rsync output
  printf "Copied ... $output_copy"

  # Set message
  msg="Cleaning Up... \xF0\x9F\xA7\xB9  "

  # Start spinner
  spinner "$msg" &

  # Remove backup file
  rm $bkup_file

  # Save spinner PID
  spinner_pid=$!

  # Stop spinner
  kill $spinner_pid
  printf ""
  printf "done \n Backup Complete \xF0\x9F\x9A\x80 \n"

  exit 0
}



# Define backup cron function
backitupcron(){
  # Create temp file and backup filename
  tmp_file=$(mktemp)
  bkup_file=backup_$timestamp.tar.gz

  # Run tar command and store output
  output=$(tar -cz --exclude=$skip $items > $tmp_file 2> /dev/null)
  
  size=$(stat -c%s $tmp_file)


  cp $tmp_file $bkup_file

  rm $tmp_file



  case "$file_system" in
  "vfat")
    # Split file into smaller chunks and copy separately
    split -b 4GB $bkup_file $bkup_file.part
    for file in $bkup_file.part*; do
      output_copy=$(rsync -v $file $backup_drive)
      rm $file
    done
    if [[ $size -lt 4000000000 ]]; then
      # Reassemble split parts
      cat $backup_drive/$bkup_file.part* > $backup_drive/$bkup_file
      rm $backup_drive/$bkup_file.part*
    fi
    ;;
  "exfat")
    # Split file into smaller chunks and copy separately
    split -b 4GB $bkup_file $bkup_file.part
    for file in $bkup_file.part*; do
      output_copy=$(rsync -v $file $backup_drive)
      rm $file
    done
    if [[ $size -lt 4000000000 ]]; then
      # Reassemble split parts
      cat $backup_drive/$bkup_file.part* > $backup_drive/$bkup_file
      rm $backup_drive/$bkup_file.part*
    fi
    ;;
  "ntfs")
    # Copy file without splitting
    output_copy=$(rsync -v $bkup_file $backup_drive)
    ;;
  "hfsplus")
    # Copy file without splitting
    output_copy=$(rsync -v $bkup_file $backup_drive)
    ;;
  "ext2"|"ext3"|"ext4")
    # Copy file without splitting
    output_copy=$(rsync -v $bkup_file $backup_drive)
    ;;
esac



# Remove backup file
rm $bkup_file

if [[ $? -eq 0 ]]; then
  # no errors
  return 0
else
  # we have errors will robinson
  return 1
fi
}



email_results(){
  local data=$1

  email_template=$(mktemp)
  echo "EHLO $server" > $email_template
  echo "AUTH LOGIN" >> $email_template
  echo "$username_hash" >> $email_template
  echo "$password_hash" >> $email_template
  echo "MAIL FROM: $from_email_address" >> $email_template
  echo "RCPT TO: $to_email_address" >> $email_template
  echo "DATA" >> $email_template
  echo "From: $from_name <$from_email_address>" >> $email_template
  echo "To: $to_name <$to_email_address>" >> $email_template
  echo "Subject: $email_subject" >> $email_template
  echo "" >> $email_template
  echo "$data" >> $email_template
  echo "" >> $email_template
  echo "This message was sent using a cool bash script by ITG and the Amazon SES SMTP interface." >> $email_template
  echo "." >> $email_template
  echo "QUIT" >> $email_template
  
  openssl s_client -crlf -quiet -starttls smtp -connect email-smtp.us-east-2.amazonaws.com:587  < $email_template
  
  rm $email_template
}


# Calculate the total size of all items in bytes
printf "Calculating size of items to be backed up...  \xF0\x9F\x96\xA9  \n"

file_size_bytes=$(du -c -b --exclude=$skip $items | awk 'END {print $1}')
printf "Pre-Compression Size (bytes): $file_size_bytes \n"

# Calculate the total size of all items in gigabytes
file_size_gigabytes=$(bc <<< "scale=2; $file_size_bytes / 1024 / 1024 / 1024")
printf "Pre-Compression  (gb): $file_size_gigabytes \n"


printf "Transfer Speed (bytes/second): $transfer_speed \n"


# Calculate the estimated final size of the items after compression (in bytes)
# Since its impossible to know much compression will happen, 30% is used
estimated_compressed_size_bytes=$(bc <<< "$file_size_bytes * 0.7")

# Calculate the estimated compressed size in gigabytes
estimated_compressed_size_gigabytes=$(bc <<< "scale=2; $estimated_compressed_size_bytes / 1024 / 1024 / 1024")

# Calculate the estimated time to copy the compressed items (in seconds)
estimated_time=$(bc <<< "$estimated_compressed_size_bytes / $transfer_speed")


# Convert the number of seconds into a more readable format
# The 'awk' command is used to format the output
readable_time=$(awk -v t=$estimated_time 'BEGIN{t=int(t*1000)/1000; printf "%d:%02d:%02d\n", t/3600, t/60%60, t%60}')

printf "Estimated compressed file size (gb): $estimated_compressed_size_gigabytes \n"
printf "Estimated backup time: $readable_time \n"


# Display the prompt
if [[ "$1" == "c" ]]; then
  ANSWER="c"
else
# Get the width of the terminal window
width=$(tput cols)

# Draw the top line
for i in $(seq 1 $width); do
  printf "="
done
printf "\n"

# Display the text
echo -e "\033[1m"
read -p "Is the backup file size ok? Proceed? (y/n/c) " -r -i "y" ANSWER
echo -e "\033[0m"

# Draw the bottom line
for i in $(seq 1 $width); do
  printf "="
done
printf "\n"


fi





case "$ANSWER" in
  y)
    # do something if the user answers "y"
    backitupuser
    ;;
  n)
    # do something if the user answers "n"
    printf "Backup Cancelled\xF0\x9F\x92\xA5\n"
    printf "\n"
    exit 1
    ;;
  c)
    # do something if the user answers "c"
    backitupcron
    result=$(backitupcron)
    if [[ $? -eq 0 ]]; then
    
      result_msg="Backup successfully completed $timestamp"
    else
      result_msg="Backup encountered errors $timestamp"
    fi

     email_results "$result_msg"
    ;;
  *)
    # do something if the user answers something else
    printf "Backup Cancelled\xF0\x9F\x92\xA5\n"
    printf "\n"
    exit 1
    ;;
esac


# If the script reaches this point, there were no errors
exit 0
