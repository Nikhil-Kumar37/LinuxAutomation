"""

        .SYNOPSIS
          To check CPU utilisation.

        .DESCRIPTION
          The script will check the CPU utilisation

        .INPUTS
          Inputs are coming by CMD Line argument - Server, User, Password

        .OUTPUT
          A Outupt will be sent to the workflow with CPU utilisation.
          output = {"retCode" : "1", "result" : "NULL", "retDesc" : "output"}
          

        .EXAMPLE
                  > python E:\Linux_HighCPU_v1.0.py --Server=SERVERNAME --User=USERNAME --Password=PASSWORD  
                           

         
        .NOTES

          Script Name    : Linux_HighCPU_v1.0.py
          Script Version : 1.0
          Author         : Nikhil Kumar
          Creation Date  : 16-06-2020

"""

##### Importing all required modules and Automation module #####

#!/usr/bin/env python
from sys import path
import sys, os
import argparse
import time
import datetime
from os import system, getcwd, path, makedirs
import paramiko
import os
import json
import random
import string
from ITOPSA_STANDALONE_LIB_PY import *


##### Parsing the argument to script with mapping to the variable #####

parser=argparse.ArgumentParser()

parser.add_argument('--Server')
parser.add_argument('--User')
parser.add_argument('--Password')

args=parser.parse_args()

##### Variables #####

Server = args.Server
User = args.User
Password = args.Password
"""

##### Variables - Hardcoded values - for testing #####
Server = ""
User = ""
Password = ""
##### Log Path for the module #####
"""
logPath=os.path.realpath(__file__)
path(logPath)

##### Mandatory Variables #####

check_mandatory_vars([Server, User, Password])

##### Logging to Serevr #####

try:
        dssh = paramiko.SSHClient()
        dssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        dssh.connect(Server, username=User, password=Password)
        write_log(1, "Server Login Successful")
        
except:
        #error1 = err.message
        error1 = "Server Login Failed"
        #print (error1)
        output = {"retCode" : "1",  "retDesc" : error1 }
        write_log(3, "Server Login Failed")
        print (output)
        exit_script(1,"Server Login Failed", output)



################## Checking CPU Utilisation #################

try:                                
        
        #command1 = "top -b -n 1 | grep Cpu | awk '{print $8}'"
        command1 = "ps -eo user --sort=-%cpu | head -2 | grep root"
        stdin, stdout, stderr = dssh.exec_command(command1)
        #stdin, stdout, stderr = dssh.exec_command(command2)
        output1 = stdout.readlines()
        if any("root" in s for s in output1):
            status = "Running"
        else:
            status = "Not running"      
        #print (type(output1))
        error1 = stderr.read()
        #output2 = stdout.read()
        #error2 = stderr.read()
        #print (error1)
        #print (output1)
        #print (error2)
        #print (output2)
        if any("bash" in s for s in error1):
            output = {"retCode" : "1", "retDesc" : "Script Execution Failed", "status" : error1}
            write_log(1, "Script Execution Failed")
            print (output)
        else:
            output = {"retCode" : "0", "retDesc" : "Success", "status" : status}
            write_log(1, "Script Executed Successfully")
            print (output)
        #exit_script(5,"Script Executed Successfully", output)
        dssh.close()
        

except:
        error3 = "Script Execution Failed"     
        output = {"retCode" : "1", "retDesc" : error3}
        write_log(3, error3)
        #exit_script(5,"Script Execution Failed", output)
        print (output)
        dssh.close()

