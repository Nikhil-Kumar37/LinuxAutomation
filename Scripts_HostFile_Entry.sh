#!/bin/sh
#Authors:      Nikhil Kumar <nikhil.i.kumar@abc.com>
#scriptName:   Scripts_HostFile_Entry
#Description:  This script is used to give entry in /etc/hosts file.
#               
#
# Version 1.0

#################################################################################
###To be at first line of the Main Code to capture the start time of the script###
##################################################################################

emailBotStartTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotFileName="Scripts_HostFile_Entry"
#You can have the $endpointName as the endpoints of the server which this script touches as an [String.Array] object or leave as is if the endpoint is this server itself.
endpointName=`hostname` # File name should be of the format '<Geo Prefix><Customer Prefix>_<Tower Prefix>_<Request Portal ID>_<Script/Other Automation type>_Short Name' example Script_Check Exchange Mail Store Status "Register the script at ""https://troom.abc.com/sites/program and development/automation/lists/automation requests/allitems.aspx" and use the same name
emailBotFromAddress="no_reply@abc.com" # your from address
emailBotToAddress="hpoperations.in@abc.com" # please don't change this
emailBotExecutionID="123" # link to raise execution ID as well to register the Script "https://troom.abc.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx"
emailBotSubject="AUR-$emailBotFileName"

#########################################################################

####################    INPUT Section     ####################################################


#Function Starts here

function host()
{
        serverIp=$1
        #Taking SSH Connection

        ssh -q -o 'StrictHostKeyChecking no' -T ansible@$serverIp serverIp="$serverIp" backupIp="$backupIp" hostName="$hostName" fqdn="$fqdn" 'bash -s' << 'ENDSSH'
        endpointName="$serverIp"
	day=$(sudo date +"%d_%m_%y")	
	`echo ansible | sudo -S cp /etc/hosts /etc/hosts_${day}_bkp`
	`echo ansible | sudo -S sed -i -e '/bus-nw/,$d' /etc/hosts`
	`echo ansible | sudo -S chmod 777 /etc/hosts`
	cat >> /etc/hosts <<- "EOF"
	10.250.255.61   bus-nwsn-09-bu          bus-nwsn-09-bu.cap.local        bus-nwsn-09
	10.250.255.62   bus-nwsrv-06-bu         bus-nwsrv-06-bu.cap.local       bus-nwsrv-06
	10.250.255.63   bus-nwsn-10-bu          bus-nwsn-10-bu.cap.local        bus-nwsn-10
	10.250.255.68   bus-nwsn-11-bu          bus-nwsn-11-bu.cap.local        bus-nwsn-11
	10.250.255.69   bus-nwsn-14-bu          bus-nwsn-14-bu.cap.local        bus-nwsn-14
	10.250.255.57   bus-nwnmc-03-bu         bus-nwnmc-03-bu.cap.local       bus-nwnmc-03
	10.250.255.36   bus-nwdd-04-bu          bus-nwdd-04-bu.cap.local
	10.250.255.37   bus-nwdd-05-bu          bus-nwdd-05-bu.cap.local
	10.250.255.67   bus-nwdd-08-bu          bus-nwdd-08-bu.cap.local
	10.250.255.65   bus-nwdd-07-bu          bus-nwdd-07-bu.cap.local
	10.250.255.66   bus-nwdd-09-bu          bus-nwdd-09-bu.cap.local
	EOF
	echo $backupIp"    "$hostName"    "$fqdn >> /etc/hosts
	`echo ansible | sudo -S chmod 644 /etc/hosts`
ENDSSH
}
variable=`cat serverList`
echo "This Script is regarding hosts file entry "
while read -r line;
do
	serverIp=`echo $line | awk '{print $1}'`
	backupIp=`echo $line | awk '{print $2}'`
	hostName=`echo $line | awk '{print $3}'`
	fqdn=`echo $line | awk '{print $4}'`
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
		host $serverIp
        	echo "Thank You"
    	fi
done <<< "$variable"






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
echo "Scripts Ends here"
####################################################################################

