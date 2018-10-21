#!/bin/sh -f

#############################
#Function declaration
#############################

function_set_pshighcpu(){
  
  PROC_PID=$( ps -eo pid --sort=-pcpu --no-headers | head -n 1 ); #Get PID of the process with highest CPU usage
  CPU_LIMIT_VALUE=$(sed -n "$PREVIOUS_LINE_COUNT"p "$FILE_SNMP_PASS_SET") #Get the cpulimit value set by the user through the SNMP agent log
  echo timeout 20s cpulimit -p $PROC_PID -l $CPU_LIMIT_VALUE    #print to the user the command to be executed
  timeout 20s cpulimit -p $PROC_PID -l $CPU_LIMIT_VALUE &  #Limit the process with the CPU usage set by the user through the SNMP agent log for 20 seconds
}


#################
#program setup
#################

#Define the expected file to be created by SNMP agent
FILE_SNMP_PASS_SET="/tmp/passsnmpset.log"

#Check the number of records present in snmp logfile
if [ -e "$FILE_SNMP_PASS_SET" ]; then
    PREVIOUS_LINE_COUNT=$(cat "$FILE_SNMP_PASS_SET" | wc -l)
else
    #File not found
    PREVIOUS_LINE_COUNT=0
fi

#Sync actual index counter with read value
ACTUAL_LINE_COUNT=$PREVIOUS_LINE_COUNT


################
#program start 
################

while true; do

    #Check if file exists or has been removed
    if [ -e "$FILE_SNMP_PASS_SET" ]; then

        #Update line counter
        ACTUAL_LINE_COUNT=$(cat "$FILE_SNMP_PASS_SET" | wc -l)

        #If file countains new records, process each one of them 
        while [ $PREVIOUS_LINE_COUNT -lt $ACTUAL_LINE_COUNT ]; do
            PREVIOUS_LINE_COUNT=$(expr $PREVIOUS_LINE_COUNT + 1)     #Increment counter

            #Execute implemented functions
            function_set_pshighcpu
            
        done
    else
        #File not found: restart counters
        PREVIOUS_LINE_COUNT=0
        ACTUAL_LINE_COUNT=0
    fi  

    sleep 1 #Wait a while to execute this routine again
done
