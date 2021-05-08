#!/bin/sh
#Authors:      Nikhil Kumar <nikhil.i.kumar@abc.com>
#scriptName:   Scripts_OAC_Check
#Description:  This script is used for OAC check. It is for SUSE and RHEL 6 and 5. For RHEL 7 we need to some minor changes.
# Before running the script please create ip.txt file and keep all server's IP in that file. Script will give output in csv format.
#	Script will check below details :-
#	1) It will check Hostname.
#	2) It will test ping and SSH connectivity to target server
#	3) It will check uptime of server.
#	4) It will check OS version, kernel version, CPU Name, Manfacturer Name, and product details.
#	5) It will check NTP service and NTP synchronization status.
#	6) It will check total RAM, free RAM, total swap and free swap.
#	7) It will check mount points (Total size(GB)--Used percent--Mount Point)
#   8) It will check NIC status , IP, Netmask, DNS address, Broadcast Ip and MAC address
#	9) It will check Patching Tool Status Besclient service 
#	10) It will check Portmap Service,Yppasswd Service,Yserv Service and CGOS Package status
#	11) It will check NIC Bonding Mode,Slave Interfaces,Primary Slave and Currently Active Slave status
#	12) It will check yp tools,ypbind,ypserv and lgto (for backup) packages are present or not.
#	13) It will check kdump status.
#	14) It will check system monitoring file, process monitoring file and status of monitoring agent
#	15) It will check listening ports, permit root login SSH or not and which runlevel it is running.
#	16) It will check var/crash and NFS export status
#	17) It will check antivirus version and last update date status.
#
# Version 1.0

#################################################################################
###To be at first line of the Main Code to capture the start time of the script###
##################################################################################

emailBotStartTimeOfScript=`date +%Y-%m-%d' '%H:%M:%S`
emailBotFileName="Scripts_OAC_Check"
#You can have the $endpointName as the endpoints of the server which this script touches as an [String.Array] object or leave as is if the endpoint is this server itself.
endpointName=`hostname` # File name should be of the format '<Geo Prefix><Customer Prefix>_<Tower Prefix>_<Request Portal ID>_<Script/Other Automation type>_Short Name' example Script_Check Exchange Mail Store Status "Register the script at ""https://troom.abc.com/sites/program and development/automation/lists/automation requests/allitems.aspx" and use the same name
emailBotFromAddress="no_reply@abc.com" # your from address
emailBotToAddress="hpoperations.in@abc.com" # please don't change this
emailBotExecutionID="123" # link to raise execution ID as well to register the Script "https://troom.abc.com/sites/cis-automation/program and development/automation/lists/automation requests/allitems.aspx"
emailBotSubject="AUR-$emailBotFileName"

#########################################################################

####################    INPUT Section     #####################################################!/bin/bash

### Create a directory named output ###
if [ ! -d /tmp/output ];then
	mkdir /tmp/output	
else 
	rm -rf /tmp/output
	mkdir /tmp/output
fi

### Column headings for OAC ###
columnHeadings=Hostname","Ping","SSH","Uptime","SUSE_Version","Kernel_Version","CPU_Name","Manufacturer","Product_details","NTP_service","NTP_synchronization","Total_RAM","Free_RAM","Total_Swap","Free_Swap","Mount_Points'(Total size(GB)--Used percent--Mount Point)'","No_of_NICs","IP_Address","Netmask","Broadcast_IP","MAC_Address","DNS","Patching_Tool_Status_Besclient_service","yp_tools","ypbind","Ypserv","CGOS_Package","NIC_Bonding_Mode","Slave_Interfaces","Primary_Slave","Currently_Active_Slave","Portmap_Service","Yppasswd_service","Yserv_Service","lgto","kdump_status","System_Monitoring_File","Process_monitoring_File","Status_of_Monitoring_Agent","Listening_Ports","PermitRootLogin_SSH","RunLevel","var/crash","NFS_export","Anti-Virus_Version","Anti-Virus_Last_Update_Date
echo $columnHeadings > /tmp/output/unixoacreport.csv

### The missings servers are noted down in a text 
echo "The Missing servers are as follows:" > /tmp/output/missingservers.txt



### The function to get the OAC report ###
function session()
{
ssh -o  'StrictHostKeyChecking no' -t -T $server << 'ENDSSH'	
#suseversion=`cat /etc/*-release | grep SUSE | cut -d ' '  -f5 | sed -n 1p`
uname -a | cut -d ' ' -f2
echo "#"
uptime | cut -d "," -f1 | cut -d " " --complement -s -f2
echo "#"
#cat /etc/*-release | grep SUSE | cut -d ' ' -f5 | sed -n 1p
cat /etc/*-release | grep VERSION | sed -n 1p | cut -d "=" -f2
echo "#"
uname -r 
echo "#"
cat /proc/cpuinfo | grep 'model name' | cut -d ":" -f2 | sed -n 1p  
echo "#"
#cat /proc/meminfo | grep MemTotal | cut -d ":" -f2 
cat /proc/meminfo | grep MemTotal | cut -d ":" -f2 | tr -s ' ' | tr ' ' '&' | cut -d "&" -f2
echo "#"
#cat /proc/meminfo | grep MemFree |  cut -d ":" -f2 
cat /proc/meminfo | grep MemFree |  cut -d ":" -f2 |  tr -s ' ' | tr ' ' '&' | cut -d "&" -f2
echo "#"
#cat /proc/meminfo | grep SwapTotal | cut -d ":" -f2
cat /proc/meminfo | grep SwapTotal | cut -d ":" -f2 |  tr -s ' ' | tr ' ' '&' | cut -d "&" -f2
echo "#"
#cat /proc/meminfo | grep SwapFree | cut -d ":" -f2 
cat /proc/meminfo | grep SwapFree | cut -d ":" -f2 |  tr -s ' ' | tr ' ' '&' | cut -d "&" -f2
echo "#"
fdisk -l 2> /dev/null | grep Disk | grep -v identifier | grep -v mapper | grep -v 'label type' | cut -d ',' -f1 | cut -d " " -f2,3,4
echo "#"
#df -k | grep "%" | grep -v Filesystem | tr -s ' ' | grep -oP '\d+\w+ \d+\w+ \d+\w+ \d+% *.'* | tr ' ' '-' | cut -d "-" -f1,4,5| sed 's/-/-----/g' | tr '\n' '&'
df -h | grep -v Size | tr -s ' ' | cut -d " " -f2,5,6 | tr ' ' "#"  | sed 's/#/-------/g' | tr '\n' '&'
echo "#"
ip addr show | grep -w inet | grep -v 127.0.0.1 | tr -s ' ' | tr ' ' '-' | cut -d '-' -f3 | cut -d '/' -f1
#ip addr show | grep -w inet | tr -s ' ' | tr ' ' '-' | cut -d '-' -f3 | cut -d '/' -f1
echo "#"
ip addr show | grep -w inet | grep -v 127.0.0.1 | tr -s ' ' | tr ' ' '-' | cut -d '-' -f3 | cut -d '/' -f2
#ip addr show | grep -w inet | tr -s ' ' | tr ' ' '-' | cut -d '-' -f3 | cut -d '/' -f2
echo "#"
ip addr show | grep -w inet | grep -v 127.0.0.1 | tr -s ' ' | tr ' ' '-' | cut -d '-' -f5 
echo "#"
ifconfig | grep HWaddr | tr -s ' '  | cut -d ' '  -f1,5 | tr ' '  '-' | cut -d "-" -f2
echo "#"
cat /etc/resolv.conf | grep nameserver | grep -v "#" | cut -d "=" -f2 
echo "#"
ps -ef | grep -v grep | grep portmap | wc -l
echo "#"
ps -ef | grep -v grep | grep yppasswdd | wc -l
echo "#"
ps -ef | grep -v grep | grep ypserv | wc -l
echo "#"
test -f /opt/IBM/ITM/Instrumentation/fs.mon 2> /dev/null && echo "Present" || echo "Not Present"  
echo "#"
rpm -qa | grep CGOS-cfg2html-script-1-9.noarch 
echo "#"
grep 'Bonding Mode'  /proc/net/bonding/bond* 2> /dev/null | cut -d ":" -f2 
echo "#"
grep 'Slave Interfaces'  /proc/net/bonding/bond* 2> /dev/null | grep 'eth\d' 
echo "#"
grep 'Primary Slave'  /proc/net/bonding/bond* 2> /dev/null | grep 'eth\d' 
echo "#"
grep 'Currently Active Slave'  /proc/net/bonding/bond* 2> /dev/null| grep 'eth\d'
echo "#"
grep 'MII Status'  /proc/net/bonding/bond* 2> /dev/null 
echo "#"
ps -ef | grep -v grep | grep besclient | wc -l
echo "#"
dmidecode  | grep -A3 '^System Information' | sed -n '2p' | cut -d "," -f1 | cut -d " " -f2
#dmidecode | grep -A3 '^System Information' | sed -n '2p' | awk -F':'  '{ print $2 }'
echo "#"
dmidecode | grep -A3 '^System Information' | sed -n '3p' | awk -F':'  '{ print $2 }'
echo "#"
ps -ef | grep ntpd | grep -v grep | wc -l
echo "#"
###################### ADD COMMAND TO GET NTP SERVER IP ################
ntpstat 2> /dev/null | sed -n '1p' 
echo "#"
rpm -qa | grep yp-tools
echo "#"
rpm -qa | grep ypbind
echo "#"
rpm -qa | grep ypserv
echo "#"
rpm -qa | grep lgto
echo "#"
kdump=$(service kdump status)
#if [ $?==0]; then
	echo "$kdump"
#else
#	echo "NA"
#fi
echo "#"
/usr/bin/sudo /opt/IBM/ITM/bin/cinfo -r 2> /dev/null
echo "#"
#netstat -tulpn | grep LISTEN | grep -v "0.0.0.0." | tr -s ' ' | tr ' '  '-' | cut -d "-" -f1,4,7 | tr '/' '-' | cut -d "-" -f1,2,4 | sed 's/-/---/g' | tr '\n' '&'
netstat -tulpn | grep LISTEN | tr -s ' ' | tr ' '  '-' | cut -d "-" -f1,4,7 | tr '/' '-' | cut -d "-" -f1,2,4 | sed 's/-/---/g' | tr '\n' '&'
echo "#"
echo "#"
/usr/bin/sudo cat /etc/ssh/sshd_config | grep -v "#" | grep 'PermitRootLogin no'
echo "#"


rl=$(who -r | awk '{ print $2 }')
echo $rl
echo "#"

if [ -d /var/crash ]; 
then
    entries1=$(ls /var/crash | grep -v lost+found)
    echo $entries1
fi
echo "#"

if [ -f /etc/exports ]; 
then
	nfs=$(sudo cat /etc/exports | grep -v "#" | grep -oP "\*")
	echo $nfs
fi
echo "#"

/opt/Symantec/symantec_antivirus/sav info -p 2> /dev/null
echo "#"

/opt/Symantec/symantec_antivirus/sav info -d 2> /dev/null
echo "#"

####### System Monitoring file ############
if [ -f /opt/IBM/ITM/Instrumentation/fs.mon ];
then
	echo "PRESENT"
else
	echo "ABSENT"
fi
echo "#"

###### Process Monitoring file #############
if [ -f /opt/IBM/ITM/Instrumentation/service.mon ];
then
	echo "PRESENT"
else
	echo "ABSENT"
fi
echo "#"

ENDSSH
}


echo "This Script is regarding OAC check "
for server in `cat ip.txt`
do
	echo " Working with $server server"
	((serverCount++))
	#Checking server is up or not by pinging.
	ping -c 4 $server > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		ping='Unsuccessful'
		echo $server >> /tmp/output/missingservers.txt
	else
		ping='Successful'
		echo "Server $server is reachable"
	fi
	if [ $ping == "Unsuccessful" ]; then
		echo "Server $server is unreachable"
		continue
	else
		echo "Server $server is up"
		output=$(session $server)
	#	echo $output
		ssh="Success"
		hostname=$(echo $output | cut -d '#' -f1)
		uptime=$(echo $output | cut -d '#' -f2)
		rhelVersion=$(echo $output | cut -d '#' -f3)
		kernelVersion=$(echo $output | cut -d '#' -f4)
		cpuName=$(echo $output | cut -d '#' -f5)
		totalRam1=$(echo $output | cut -d '#' -f6)
		totalRam=$(echo "scale=2; $totalRam1 / (1024*1024)" | bc -l)
		freeRam1=$(echo $output | cut -d '#' -f7)
		freeRam=$(echo "scale=2; $freeRam1 / (1024*1024)" | bc -l)
		totalSwap1=$(echo $output | cut -d "#" -f8)
		totalSwap=$(echo "scale=2; $totalSwap1 / (1024*1024)" | bc -l)
		freeSwap1=$(echo $output | cut -d "#" -f9)
		freeSwap=$(echo "scale=2; $freeSwap1 / (1024*1024)" | bc -l)
		fileSystemDump=$(echo $output | cut -d "#" -f11 | tr -s "\n")
		fileSystem=$(echo $fileSystemDump | tr '&' '#')
		nicCount=$(echo $output | cut -d '#' -f12| wc -w)
	#	echo "nic count is $nicCount"
		ipaddress=$(echo $output | cut -d '#' -f12)
	#	echo "ip is $ipaddress"
		mask=$(echo $output | cut -d '#' -f13)
	#	echo "mask is $mask"
		broadcast=$(echo $output | cut -d '#' -f14)
	#	echo "broadcast is $broadcast"
		mac=$(echo $output | cut -d '#' -f15)
	#	echo "mac is $mac"
		dnsIpDetail=$(echo $output | cut -d '#' -f16)
		if [[ -z "$dnsIpDetail"  ]];
		then
			dnsIp="NIL"
		else
			dnsIp="$dnsIpDetail"
		fi
		zero="0"
		portmap=$(echo $output | cut -d '#' -f17) 
		#echo $portmap
		if [ $portmap == $zero ]; 
		then 
			portmapStatus="Stopped"
		else 
			portmapStatus="Running" 
		fi 
		#echo $portmapStatus
		yppasswdd=$(echo $output | cut -d '#' -f18)
		if [ $yppasswdd == $zero ]; 
		then 
			yppasswddStatus="Stopped" 
		else 
			yppasswddStatus="Running"
		fi
		ypserv=$(echo $output | cut -d '#' -f19)
		if  [ $ypserv == $zero ];
		then 
			ypservStatus="Stopped" 
		else 
			ypservStatus="Running"
		fi
		#systemFile=$(echo $output | cut -d '#' -f20)
		#processFile=$(echo $output | cut -d '#' -f21)
		package=$(echo $output | cut -d '#' -f22)
		cgos="CGOS-cfg2html-script-1-9.noarch"
		if [ $package == $cgos &> /dev/null ];
		then 
			cgosPackage="Present"
		else
			cgosPackage="Absent"
		fi
		empty=' '
		bondingMode=$(echo $output | cut -d '#' -f23)
		if [ $bondingMode == $empty ] ;
		then
			bondingMode="NIL"
		fi
		slaveInterfaces=$(echo $output | cut -d '#' -f24)
		if [ $slaveInterfaces == $empty ] ;
		then
			slaveInterfaces="NIL"
		fi
		primarySlave=$( echo $output | cut -d '#' -f25)
		if [ $primarySlave == $empty ] ;
		then
			primarySlave="NIL"
		fi
		currentlyActiveSlave=$(echo $output | cut -d '#' -f26)
		if [ $currentlyActiveSlave == $empty ] ;
		then
			currentlyActiveSlave="NIL"
		fi
		#miiStatus=$(echo $output | cut -d '#' -f27)
		#echo $miiStatus
		#if [ $miiStatus == $n ] ;
		#then
		#	miiStatus="NIL"
		#fi
		besclient=$(echo $output | cut -d '#' -f27)
		if [ $besclient == $zero ];
		then 
			besclientStatus="Stopped"
		else 
			besclientStatus="Running" 
		fi 
		####### CHANGE MADE HERE #########
		manufacturer=$(echo $output | cut -d "#" -f28)
#		echo $manufacturer
		productDetails=$(echo $output | cut -d "#" -f29)
#		echo $productDetails

		########### NTP status and synchronization #################
		ntpd=$(echo $output | cut -d "#" -f30)
		if [ $ntpd == $zero ];
		then 
			ntpdStatus="Stopped"
		else 
			ntpdStatus="Running" 
		fi 
		if [ $ntpdStatus == "Stopped" ];
		then
			ntpstat="Not Applicable"
		else
			ntpstat=$(echo $output | cut -d "#" -f31)
		fi

		######### RPM Packages presence  #################
		yptools=$(echo $output | cut -d "#" -f32)
		if echo $yptools | grep -q "yp-tools";
		then 
			yptoolsPackage="PRESENT"
		else 	
			yptoolsPackage="ABSENT"
		fi
		ypbind=$(echo $output | cut -d "#" -f33)
		if echo $ypbind | grep -q "ypbind";
		then 
			ypbindPackage="PRESENT"
		else 	
			ypbindPackage="ABSENT"
		fi
		ypserv=$(echo $output | cut -d "#" -f34)
		if echo $ypserv | grep -q "ypserv";
		then 
			ypservPackage="PRESENT"
		else 	
			ypservPackage="ABSENT"
		fi
		lgto=$(echo $output | cut -d "#" -f35)
		if echo $lgto | grep -q "lgto";
		then 
			lgtoPackage="PRESENT"
		else 	
			lgtoPackage="ABSENT"
		fi
		kdump_value=$(echo $output | cut -d "#" -f36)
		kdump_data=$(echo $kdump_value | grep -oP inactive)
		if echo $kdump_data | grep -q "inactive"
		then 
			kdump="Inactive"
		else
			kdump="Active"
		fi
		########### Monitoring process #########################
		monitor=$(echo $output | cut -d "#" -f37)
		if echo $monitor | grep -q "running";
		then 
			monitorStatus="Running"
		elif echo $monitor | grep "no known processes are running";
		then
			monitorStatus="Present but stopped"
		else
			monitorStatus="NO such process"
		fi

		######### Listening Ports ###############################
		ports=$(echo $output | cut -d "#" -f38)
		portsList=$(echo $ports | tr '&' '#')

		########### Control+Alt+Delete = Reboot Checked ################

		ctlAltDel=$(echo $output | cut -d "#" -f40)
		echo $ctlAltDel
		ctlAltDelRef1="exec  /sbin/shutdown -r"
		ctlAltDelRef2=$(echo $ctlAltDelRef1)

		ctlAltDelRef3="Cannotcheck"
		ctlAltDelRef4=$(echo $ctlAltDelRef3)

		ctlAltDelRef5=" "
		ctlAltDelRef6=$(echo $ctlAltDelRef5)

		if [[ $ctlAltDel == *"$ctlAltDelRef2"* ]];
		then
			cadStatus="ENABLED"
		elif [[ "$ctlAtlDel" == *"$ctlAltDelRef6"* ]]
		then
			cadStatus="Disabled"
		else
			cadStatus="Not found"
		fi

		######### PermitRootLogin Checked ################
		permitRootLoginStatus=$(echo $output | cut -d "#" -f41)
		permit="PermitRootLogin"
		if [[ "$permitRootLoginStatus" == *"$permit"* ]];
		then
			permitRootLogin="No"
		else
			permitRootLogin="Yes"
		fi

		######## Runlevel checked #############
		runlevelst=$(echo $output | cut -d "#" -f42)
		three="3"
		if [[ "$runlevelst" == *"$three"* ]];
		then
			runlevel="Runlevel 3"
		else
			runlevel="Warning : Runlevel is not at 3"
		fi

		#########   /var/crash  checked   ##################
		varcrashst=$(echo $output | cut -d "#" -f43)
		if [[ $varcrashst == $empty ]];
		then
			varcrash="Nil"
		else
			varcrash="Warning: /var/crash is not  empty"
		fi

		############ nfs checked   ################################
		nfsexportst=$(echo $output | cut -d "#" -f44)
		if [[ $nfsexportst == $empty ]];
		then
			nfsexport="Nil"
		else
			nfsexport="Error: Dangerous Gloabal NFS export"
		fi

		####### Antivirus ########################################
		antivirusversion=$(echo $output | cut -d "#" -f45)
		antivirusdate=$(echo $output | cut -d "#" -f46)


		######### System Monitoring File - Checked #############################
		systemMonitoringFile=$(echo $output | cut -d "#" -f47)


		#########  Process Monitoring File - Checked##########################
		processMonitoringFile=$(echo $output | cut -d "#" -f48)


		###############################################################################################################



		values=$hostname","$ping","$ssh","$uptime","$rhelVersion","$kernelVersion","$cpuName","$manufacturer","$productDetails","$ntpdStatus","$ntpstat","$totalRam","$freeRam","$totalSwap","$freeSwap","$fileSystem","$nicCount","$ipaddress","$mask","$broadcast","$mac","$dnsIp","$besclientStatus","$yptoolsPackage","$ypbindPackage","$ypservPackage","$cgosPackage","$bondingMode","$slaveInterfaces","$primarySlave","$currentlyActiveSlave","$portmapStatus","$yppasswddStatus","$ypservStatus","$lgtoPackage","$kdump","$systemMonitoringFile","$processMonitoringFile","$monitorStatus","$portsList","$permitRootLogin","$runlevel","$varcrash","$nfsexport","$antivirusversion","$antivirusdate
		echo $values >> /tmp/output/unixoacreport.csv
	fi

### Just for information ###
echo " "
echo "The output generated will be in the folder '/tmp/output' "
echo " "
echo "Copy the folder 'output' to your local windows machine"
echo " "
echo "Thank you"
echo " "
echo "End of script"
echo " "
done
