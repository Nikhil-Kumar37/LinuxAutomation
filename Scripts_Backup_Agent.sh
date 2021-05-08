#!/bin/sh
#Authors:      Nikhil Kumar (nikhil.i.kumar@abc.com)
#scriptName:   Scripts_Backup_Agent
#Description: 
#               
#
# Version 1.0

#################################################################################
###To be at first line of the Main Code to capture the start time of the script###
##################################################################################

emailBotStartTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotFileName="Scripts_Backup_Agent"
#You can have the $endpointName as the endpoints of the server which this script touches as an [String.Array] object or leave as is if the endpoint is this server itself.
endpointName=`hostname` # File name should be of the format '<Geo Prefix><Customer Prefix>_<Tower Prefix>_<Request Portal ID>_<Script/Other Automation type>_Short Name' example Script_Check Exchange Mail Store Status "Register the script at ""https://troom.abc.com/sites/program and development/automation/lists/automation requests/allitems.aspx" and use the same name
emailBotFromAddress="no_reply@abc.com" # your from address
emailBotToAddress="hpoperations.in@abc.com" # please don't change this
emailBotExecutionID="123" # link to raise execution ID as well to register the Script "https://troom.abc.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx"
emailBotSubject="AUR-$emailBotFileName"

#########################################################################

####################    INPUT Section     ####################################################

#A menu driven shell script which has following options
#installation
#uninstallation
#troubleshooting
clear
echo "Please Enter the login username : "
read user
while :
do
	echo "M A I N - M E N U"
	echo "1. For Installation"
	echo "2. For Uninstallation"
	echo "3. For Troubleshooting"
	echo "4. For Exit"
	echo "Please enter options [1-4]"
	read opt
	case $opt in
	1)
		echo "Performing Installation . . . \n"
 		echo "Enter the ip/hostname to install Networker"
        	read ip
        	echo "Enter the location to install Networker"
		read path
        	echo "Enter Networker package name present along with full path"
        	read package
        	ssh -o StrictHostKeyChecking=no -l $user@$ip ip="$ip" path="$path" package="$package" 'bash -s' << 'ENDSSH'
        		cd /
        		mkdir /nsr
        		cp $package $path
        		tar xvf nw91_linux_x86_64.tar.gz
        		cd nw91_linux_x86_64
        		rpm -ivh --relocate /usr=/nsr lgtoclnt*.rpm lgtoman*.rpm
        		/etc/init.d/networker start
		ENDSSH
}

		;;
	2)
		echo "Performing Uninstallation . . ."
		echo "Enter the ip/hostname to uninstall Networker"
        	read ip
        	ssh -o StrictHostKeyChecking=no $user@$ip 'bash -s' <<'ENDSSH'
        		rpm -evh lgtoclnt*.rpm lgtoman*.rpm
        		rm -fr /nsr
ENDSSH


		;;
	3)
		echo "Performing Troubleshooting . . ."
		echo "Enter networker server IP"
		read serverIp
		echo "Enter networker server Hostname"
		read serverHostName
		echo "Enter networker server fqdn"
		read fqdn
		echo "Enter dns server ip"
		read dnsIp
		echo "Enter dns server hostname"
		read dnsHostName
		function troubleShooting()
		{
			serverIp=$1
			ssh -q -o 'StrictHostKeyChecking=no' -T $user@$ip user="$user" serverIp="$serverIp" serverHostName="$serverHostName" fqdn="$fqdn" dnsIp="$dnsIp" dnsHostName="$dnsHostName" 'bash -s' <<  'ENDSSH'
				endpointName="$Ip"
				day=$(sudo date +"%d_%m_%y")
				`echo $user | sudo -S cp /etc/hosts /etc/hosts_${day}_bkp`
				`echo $user | sudo -S cp /etc/resolv.conf /etc/resolv.conf_${day}_bkp`
				`echo $user | sudo -S chmod 777 /etc/hosts`
				`echo $user | sudo -S chmod 777 /etc/resolv.conf`
        			if (( $(ps -ef | grep -v grep | grep nsr | wc -l) > 0 )); then
					echo "nsr service is running"
					echo ";"
				else
                			`echo $user | sudo -S service nsr stop`
                			`echo $user | sudo -S mv /nsr/tmp /nsr/tmp.old_${day}`
                			`echo $user | sudo -S service nsr start`
					echo "nsr service was stop, restarted"
					echo ";"
				fi
                		ping -c 4 serverIp > /dev/null 2>&1
                		if [ $?==1 ]; then
					serverStatus='Pinged backup server with Ip, Not pinging'
					echo $serverStatus
					echo ";" 
					var=$(grep $serverIp /etc/hosts)
					if [ $var==0 ]; then
						exit 0
					else
						`echo $user | sudo -S sed -i -e '/$serverIP/,$d' /etc/hosts`
						`echo $user | sudo -S sed -i -e '/$serverHostName/,$d' /etc/hosts`
						`echo $user | sudo -S sed -i -e '/$fqdn/,$d' /etc/hosts`
						cat >> /etc/hosts <<- "EOF"
						$serverIp $serverHostName $fqdn
						EOF
					fi
				fi
                		ping -c 4 serverHostName > /dev/null 2>&1
                		if [ $?==1 ]; then
					serverStatus='Pinged backup server with hostname, Not pinging'
					echo $serverStatus
					echo ";"
					var=$(grep $serverHostName /etc/hosts)
					if [ $var==0 ]; then
						exit 0
					else
						`echo $user | sudo -S sed -i -e '/$serverIP/,$d' /etc/hosts`
						`echo $user | sudo -S sed -i -e '/$serverHostName/,$d' /etc/hosts`
						`echo $user | sudo -S sed -i -e '/$fqdn/,$d' /etc/hosts`
						cat >> /etc/hosts <<- "EOF"
						$serverIp $serverHostName $fqdn
						EOF
					fi
        			else
                			ping -c 4 serverIp > /dev/null 2>&1
                			if [ $?==1 ]; then
						serverStatus='Pinged with hostname and Ip server is up'
						echo $serverStatus
						echo ";"
					else
						echo "All task done still not pinging backup server"
						echo ";"
					fi
				fi
                		ping -c 4 dnsIp > /dev/null 2>&1
                		if [ $?==1 ]; then
					dnsPing='Pinged dns server with Ip, Not pinging'
					echo $dnsPing
					echo ";"
					var1=$(grep $dnsIp /etc/resolv.conf)
					if [ $var1==0 ]; then
						exit 0
					else
						`echo $user | sudo -S sed -i -e '/$dnsIP/,$d' /etc/resolv.conf`
						`echo $user | sudo -S sed -i -e '/$dnsHostName/,$d' /etc/resolv.conf`
						cat >> /etc/resolv.conf <<- "EOF"
						nameserver $dnsIp
						EOF
					fi
        			fi
                		ping -c 4 dnsHostName > /dev/null 2>&1
                		if [ $?==1 ]; then
					dnsPing='Pinged dns server with hostname, Not pinging'
					echo $dnsPing
					echo ";"
					var1=$(grep $dnsHostName /etc/resolv.conf)
					if [ $var1==0 ]; then
						exit 0
					else
						`echo $user | sudo -S sed -i -e '/$dnsIP/,$d' /etc/resolv.conf`
						`echo $user | sudo -S sed -i -e '/$dnsHostName/,$d' /etc/resolv.conf`
						cat >> /etc/resolv.conf <<- "EOF"
						nameserver $dnsIp
						EOF
					fi
        			else
                			ping -c 4 dnsIp > /dev/null 2>&1
                			if [ $?==1 ]; then
						dnsPing='Pinged dns server with hostname and Ip, pinging'
						echo $dnsPing
						echo ";"
					else
						echo "All task done still not pinging dns server"
						echo ";"
					fi
				fi
				`echo $user | sudo -S service iptables stop`
				
        			if (( $(ps -ef | grep -v grep | grep nsr | wc -l) > 0 )); then
					echo "This is auto generated mail for backup agent troubleshooting script" | mail -s "nsr service is running" -r nikhil.i.kumar@abc.com nikhil.i.kumar@abc.com
					echo ";"
				else
					echo "This is auto generated mail for backup agent troubleshooting script.
Tried basic troubleshooting still not fixed" | mail -s "nsr service is not running" -r nikhil.i.kumar@abc.com nikhil.i.kumar@abc.com
					
				fi

#	checks()
#	{
#		var=$(grep $serverHostName /etc/hosts)
#		if [ $var -eq 0 ]; then
#			exit 0
#		else
#			cat >> /etc/hosts <<- "EOF"
#			$serverIp $serverHostName $fqdn
#			EOF
#		fi
#	}
#
#	dnsChecks()
#	{
#		var1=$(grep $dnsIp /etc/resolv.conf)
#		if [ $var1 -eq 0 ]; then
#			exit 0
#		else
#			cat >> /etc/resolv.conf <<- "EOF"
#			$dnsHostName $dnsIp
#			EOF
#		fi
#	}
				`echo $user | sudo -S chmod 644 /etc/hosts`
				`echo $user | sudo -S chmod 644 /etc/resolv.conf`
ENDSSH
}

		for ip in `cat serverList`
		do
			echo " Working with $ip server"
			((serverCount++))
			ping -c 4 $ip > /dev/null 2>&1
			if [ $? -ne 0 ]; then
				serverStatus='Down'
			else
				serverStatus='up'
			fi
			if [ $serverStatus == "Down" ]; then
				echo "server $ip is down"
				continue
			else
				echo "server $ip is up"
				output=$(troubleShooting $ip)
				echo $output > output.txt
				sed 's/;/\n/g' output.txt >> output.txt
				echo "Kindly check output in output.txt"
				echo "Thank you"

			fi
		done

		;;
	4)
		echo "Exit"
		exit 1
		;;
	*)
		echo "$opt is an invalid option"
		echo "Press [enter] key to continue ..."
		read enterKey
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
echo "Scripts Ends here"
####################################################################################

