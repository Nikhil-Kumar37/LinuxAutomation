#!/bin/sh
#Authors:      Nikhil Kumar <nikhil.i.kumar@abc.com>
#scriptName:   Script_AD_User_Creation
#Description:  This script is used to Add and delete user in access.conf file and sudoers file, there are few steps
#               1.Take inputs from the person who is going to run this script for addition or deletion of the user from file. 
#               2.Take inputs from user like userName which has to add and sudo permission has to give or not to the user.
#               3.If user addition is there, then giving entry in access.conf file and sudoers file(if user needs sudo access). 
#               4.Checking RHEL version 6 or 7 and restarting Winbind service.
#               5.If user deletion is there, then deleting entry in access.conf file and sudoers file(if user has sudo access)
#               6.Checking RHEL version 6 or 7 and restarting Winbind service.
#               
#
# Version 1.0

#################################################################################
###To be at first line of the Main Code to capture the start time of the script###
##################################################################################

emailBotStartTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotFileName="Script_AD_User_Creation"
#You can have the $endpointName as the endpoints of the server which this script touches as an [String.Array] object or leave as is if the endpoint is this server itself.
endpointName=`hostname` # File name should be of the format '<Geo Prefix><Customer Prefix>_<Tower Prefix>_<Request Portal ID>_<Script/Other Automation type>_Short Name' example NLAHR_WIN_2002_Script_Check Exchange Mail Store Status "Register the script at ""https://troom.abc.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx" and use the same name
emailBotFromAddress="no_reply@abc.com" # your from address
emailBotToAddress="hpoperations.in@abc.com" # please don't change this
emailBotExecutionID="231" # link to raise execution ID as well to register the Script "https://troom.abc.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx"
emailBotSubject="AUR-$emailBotFileName"

#########################################################################

####################    INPUT Section     ####################################################


echo "Enter the IP of the server"
read ip
echo "Enter login Username"
read userName
while :
do
	echo " MENU "
	echo "1. For Addition"
	echo "2. For Deletion"
	echo "3. For Exit"
	echo "Please Enter option :"
	read opt
	case $opt in
	1)
		#User adding section
		#Taking input
		echo "Enter username which you want to add in lowercase:"
		read user
		echo "User need sudo permission?"
		echo "Enter yes or no in lowercase:"
		read permission
		sudo="yes"
		day=$(sudo date +"%d_%m_%y") 
			
		#Taking SSH Connection
		ssh -t $userName@$ip "
		
		#Taking backup of access.conf file
		sudo touch "/etc/security/access.conf_${day}_bkp"
		sudo cp -p /etc/security/access.conf /etc/security/access.conf_${day}_bkp
		
		#User addition in access.conf File
		sudo sed -i '/$user/d' /etc/security/access.conf
		sudo sed -i '120 i + : $user : ALL' /etc/security/access.conf
		#Checking sudo permission and assigning
		if [ $permission == $sudo ]; then
			#Taking backup of sudoers file
			sudo touch "/etc/sudoers_${day}_bkp"
			sudo cp -p /etc/sudoers /etc/sudoers_${day}_bkp
			sudo sed -i '/$user/d' /etc/sudoers
			sudo sed -i '122 i $user	ALL=(ALL)	ALL' /etc/sudoers
		else
				sudo sed -i "/$user/d" /etc/sudoers
		fi
		
		#checking RHEL version
		if [ `echo $(sudo cat /etc/redhat-release | cut -d ' ' -f 7 | cut -d '.' -f 1)` -eq 6 ]; then
			sudo service winbind restart
		else
			sudo systemctl restart winbind
		fi	
		"
		;;
		
	2)
		#Delete Section
		#Taking Input	
		echo "Enter username which you want to delete in lowercase:"
		read user
		echo "User also has sudo access and want to remove?"
		echo "Enter yes or no in lowercase:"
		read permission
		sudo="yes"
		#day=$(sudo date +"%d_%m_%y") 
		
		#Taking SSH connection
		ssh -t $userName@$ip "
		
		#Taking backup of access.conf file
		
		sudo touch "/etc/security/access.conf_${day}_bkp"
		sudo cp -p /etc/security/access.conf /etc/security/access.conf_${day}_bkp
		#Removing user from access.conf file
		sudo sed -i "/$user/d" /etc/security/access.conf
		
		#Removing Sudo permission
		if [ $permission == $sudo ]; then
			#Taking backup of sudoers file
			sudo touch "/etc/sudoers_${day}_bkp"
			sudo cp -p /etc/sudoers /etc/sudoers_${day}_bkp
			sudo sed -i "/$user/d" /etc/sudoers
		fi
		#checking RHEL version
		if [ `echo $(sudo cat /etc/redhat-release | cut -d ' ' -f 7 | cut -d '.' -f 1)` -eq 6 ]; then
			sudo service winbind restart
		else
			sudo systemctl restart winbind
		fi
		"
		;;
	3)
		echo "Exiting"
		exit 1
		;;
	*)
		echo "Opt is an invalid option"
		echo "Press [enter] key to continue ..."
		read enterkey
		;;
	esac
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
