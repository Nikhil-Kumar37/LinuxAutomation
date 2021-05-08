#!/bin/sh
#Authors:      Nikhil Kumar <nikhil.i.kumar@abc.com>
#scriptName:   Scripts_disk_IO_Alerts
#Description:  This script is to identify the process & disk which is under high disk IO utilization and report to support team.
#				1. Assign all server IP's in "serverList" File, Keep it where the main script is present.
#				2. It will create output where the main script is present in "CPU_Reports.csv" file.
#				3. Script will first ping servers one by one and it will check server is up or not and it will show up or down status.
#				4. It will give output as hostname, % of CPU in I/O wait,Disk having high I/O,Process causing high I/O,Files which Process is writing,Load Average and Files Which Process is reading.
#               5. Run with sudo user and give NOPASSWD: ALL for that sudo user in sudoers file.
#				6. Script is for RHEL 5,6,7 and suse
#               
#
# Version 1.0

#################################################################################
###To be at first line of the Main Code to capture the start time of the script###
##################################################################################

emailBotStartTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotFileName="Scripts_disk_IO_Alerts"
#You can have the $endpointName as the endpoints of the server which this script touches as an [String.Array] object or leave as is if the endpoint is this server itself.
endpointName=`hostname` # File name should be of the format '<Geo Prefix><Customer Prefix>_<Tower Prefix>_<Request Portal ID>_<Script/Other Automation type>_Short Name' example Script_Check Exchange Mail Store Status "Register the script at ""https://troom.abc.com/sites/program and development/automation/lists/automation requests/allitems.aspx" and use the same name
emailBotFromAddress="no_reply@abc.com" # your from address
emailBotToAddress="hpoperations.in@abc.com" # please don't change this
emailBotExecutionID="123" # link to raise execution ID as well to register the Script "https://troom.abc.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx"
emailBotSubject="AUR-$emailBotFileName"

#########################################################################

####################    INPUT Section     ####################################################


#Creating the csv file
(echo "Region,Account Name,Endpoint Name,Host Name,% of CPU in I/O wait,Disk having high I/O,Process causing high I/O,Files which Process is writing,Files Which Process is reading,Load Average" | sed 's/\"\"/,/g') > CPU_Reports.csv

#Region Account Input

echo "Enter the region name: "
read region
echo "Enter the Account name: "
read account
echo "Enter the login username: "
read userName
#Function Starts here

function disk_io()
{
	serverIp=$1
	#Taking SSH Connection
	
	ssh -q -o 'StrictHostKeyChecking no'  -T $userName@$serverIp 'bash -s' << 'ENDSSH'
	endpointName="$serverIp"
	#% of CPU in IO wait
	cpu_wa=`top -b -n 1 | grep Cpu | awk '{print $6}' | cut -d, -f1`
	echo "$cpu_wa"
	#Server Name
	serverName=`sudo hostname`
	echo "$serverName"
	#Process causing High IO
	process=`sudo iotop -b -n 1 | sed -n 3p | awk '{print $1 " " $12 " = " $10 " % "}'`
	echo "$process"
	p=$(echo $process | cut -d ' ' -f 1)
	#Load Average
	#load=`sudo top -b -n 1 | head -1 | awk '{print $10 " " $11 " " $12 $13 $14}'`
	load=`sudo uptime | grep -ohe 'load average.*' | awk '{print $1 " " $2 $3}'`
	echo "$load"
	#File which process is reading and writing
	read=`sudo cat /proc/$p/io | sed -n 1p | awk '{print $2}'`
	read1=$((read / (1024*1024)))
	echo "$read1"
	write=`sudo cat /proc/$p/io | sed -n 2p | awk '{print $2}'`
	write1=$((write / (1024*1024)))
	echo "$write1"
	file=`sudo lsof -p $p | sed -n 2p | awk '{print $9}'`
	
	#Disk having high IO
	sort=`sudo iostat -kx 2 2 | sed -n -e '/Device/,$p' | sed -n -e '/%user/,$p' | sed -n -e '/Device:/,$p' | awk '{print $12"\t" $1}' | sort -r  | sed -n 2p | awk '{print $1 " " $2}'`
	echo "$sort"
	echo "$file"
ENDSSH
}
echo "This Script is regarding Disk IO alerts "
for serverIp in `cat serverList`
do
	echo " Working with $serverIp server"
	((serverCount++))
	#Checking server is up or not by pinging.
	ping -c 4 $serverIp > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		serverStatus='Down'
	else
		serverStatus='Up'
	fi
	if [ $serverStatus == "Down" ]; then
		echo "Server $serverIp is down"
		continue
	else
		echo "Server $serverIp is up"
		output=$(disk_io $serverIp)
		cpu_wa1=$output
		serverName1=$output
		process1=$output
		load1=$output
		rchar=$output
		wchar=$output
		utilisation1=$output
		cpu_wa1=$(echo $cpu_wa1 | awk '{print $1}')
		serverName1=$(echo $serverName1 | awk '{print $2}')
		process1=$(echo $process1 | awk '{print "Tid=" $3 " " $4 $5 $6 $7}')
		load1=$(echo $load1 | awk '{print $8 " " $9}')
		rchar=$(echo $rchar | awk '{print $14 " = " $10"mb"}')
		wchar=$(echo $wchar | awk '{print $14 " = " $11"mb"}')
		utilisation1=$(echo $utilisation1 | awk '{print "Device : " $13 " = " $12"%"}')
		#Writing the outputs in File
		(echo $region,$account,$serverIp,$serverName1,$cpu_wa1,$utilisation1,$process1,$wchar,$rchar,$load1 | sed 's/\"\"/,/g') >> CPU_Reports.csv
		echo "Kindly check output in CPU_Reports.csv"
		echo "Thank You"
	fi
done







####  put this in the end of the file/script	################################
################################################################################

emailBotEndTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotBody=`/usr/bin/printf "##AUR_START##\nAutomationName:$emailBotFileName\nEndPointName:$emailBotHostName\nStartTime:$emailBotStartTimeOfScript\nDurationToFinish:$emailBotEndTimeOfScript\nStatusOfRun:Success\nExecutionID:$emailBotExecutionID\nInputType:Email\n##AUR_END##\n"`
/usr/sbin/sendmail -t << !
To: $emailBotToAddress
Subject: $emailBotSubject
Content-Type: text

"$emailBotBody"
.
!

####################################################################################
