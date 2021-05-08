#!/bin/sh
#Authors:      Nikhil Kumar
#scriptName:   Scripts_User_Status
#Description:  This script is used to get user details in linux servers.
#		1) It will give output in /tmp/UserStatus.csv file.        
#               
#
# Version 1.0

#################################################################################
###To be at first line of the Main Code to capture the start time of the script###
##################################################################################

emailBotStartTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotFileName="Scripts_User_Status"
#You can have the $endpointName as the endpoints of the server which this script touches as an [String.Array] object or leave as is if the endpoint is this server itself.
endpointName=`uname -n` # File name should be of the format '<Geo Prefix><Customer Prefix>_<Tower Prefix>_<Request Portal ID>_<Script/Other Automation type>_Short Name' example Script_Check Exchange Mail Store Status "Register the script at ""https://troom.abc.com/sites/program and development/automation/lists/automation requests/allitems.aspx" and use the same name
emailBotFromAddress="no_reply@abc.com" # your from address
emailBotToAddress="hpoperations.in@abc.com" # please don't change this
emailBotExecutionID="123" # link to raise execution ID as well to register the Script "https://troom.abc.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx"
emailBotSubject="AUR-$emailBotFileName"

#########################################################################

####################    INPUT Section     ####################################################

#creating Excel sheet
(echo "Server_Name,User_Name,Group_Name,Last_Login_Time"| sed 's/\"\"/,/g') > /tmp/UserStatus.csv

#Function Starts here

function user_Status
{
        serverIp=$1
        #Taking SSH Connection

        ssh -q -o 'StrictHostKeyChecking no' -T userName@$serverIp << 'ENDSSH'
        	endpointName="$serverIp"

		for i in $(awk -F: '{if ($3 >= 500) {print $1}}' /etc/passwd)
		do
			#Server Name
        		serverName=`uname -n`
			echo "$serverName"
			echo ","
			echo "$i"
			echo ","
			if [ $(groups $i | cut -d ":" -f2 |awk '{print $2}'|head -1|wc -l) -ge 1 ]; then
				group=$(groups $i | cut -d ":" -f2 |awk '{print $1}'| head -1)
				echo "$group"
				echo ","
			else
				group="N/A"
				echo "$group"
				echo ","
			fi

			last=$(last | grep -i $i | tail -1 | awk '{print $4" " $5" " $6}')
			echo "$last"

			echo ";" 
		done

ENDSSH
}
echo "This Script is regarding User Status "
for serverIp in `cat serverList`
do
	echo " Working with $serverIp server"
    	#((serverCount++))
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
        	output=$(user_Status $serverIp)
		echo $output | tr ';' '\n' >> /tmp/UserStatus.csv	
		echo "Kindly check output in /tmp/UserStatus.csv"
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
echo "Scripts Ends here"
####################################################################################
