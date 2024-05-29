#!/bin/bash

#Note: to run the script remove initial carriage returns by running command  "sed -i 's/\r//g' LinuxVmUtilities.sh"

ErrorMsg="Initial ping failed"

#Function to set affinity list of passed interface
#In 	: destination Ip
#Out 	: Get-PathMtu
#################
#How to use this function
# examples
# source LinuxVmUtilities.sh;Get-PathMtu <destination-ip> <initial-packet-size> <interface-name>
# source LinuxVmUtilities.sh;Get-PathMtu 8.8.8.8 1200 eth0
# note: 
# 1. give initial packet size (1200 in above example) always a successfull ping packet-size
# 2. give correct interface name, code failes if interface name is wrong

function Get-PathMtu() {
    
    destinationIp="$1"
    startSendBufferSize=$2 
    interfaceName="$3" 

	if [[ -z "$interfaceName" ]]; then
		initialPingOutput=$(ping -4 -M do -c 1 -s $startSendBufferSize $destinationIp)
	else
		initialPingOutput=$(ping -4 -M do -c 1 -s $startSendBufferSize $destinationIp -I $interfaceName)
	fi

	if [[ $initialPingOutput = *'0 received'* ]]; then
		echo $ErrorMsg
		echo "Initial ping should be successfull, check Destination-IP or lower initial size"
		return
	fi

    sendBufferSize=0
    tempPassedBufferSize=$startSendBufferSize
	  echo -n "Test started ...."
    while [ $tempPassedBufferSize -ne $sendBufferSize ]; do

        sendBufferSize=$tempPassedBufferSize

        counter=0
        tempSendBufferSize=$sendBufferSize
        successfullBufferSize=$sendBufferSize
        while [ true ]; do
		
            if [[ -z "$interfaceName" ]]; then
                ping -4 -M do -c 1 -s $tempSendBufferSize $destinationIp &> /dev/null
            else
                ping -4 -M do -c 1 -s $tempSendBufferSize $destinationIp -I $interfaceName &> /dev/null
            fi
            
            if [ $? -eq 1 ]
            then
                break
            fi
			echo -n "...."
            successfullBufferSize=$tempSendBufferSize
            tempSendBufferSize=$(($tempSendBufferSize + 2**$counter))
            counter=$(($counter + 1))
        done
        tempPassedBufferSize=$successfullBufferSize
    done
    finalMtuInTopology=$(($sendBufferSize + 28))          
	echo ""
    echo  "$finalMtuInTopology"
}
