#!/bin/bash

trap 'onCtrlC' INT
function onCtrlC(){
    echo "Ctrl-C Captured! "
    echo "Breaking..."
    #umount $dev
    exit 1
}

lockfile=/fso-cache/$(basename $0)-rpi.lock
day=$(date "+%Y-%m-%d %H:%M:%S")

if [ $# -ne 2 ];then
  echo "Usage: ./temp-monitor.sh delaytime upper_cpuload"
  echo "Example: ./temp-monitor.sh 10 16"
  exit 1
fi

delaytime=$1
upper_cpuload=$2

if [ -f $lockfile ];then
  mypid=$(cat $lockfile)
  ps -p $mypid | grep $mypid &>/dev/null
  if [ $? -eq 0 ];then
    echo "$day : $(basename $0) is running for reading temp & cpu data of rpi2 @FSO..."
    exit 1
  else
    echo $$>$lockfile
  fi
else
  echo $$>$lockfile
fi

temp=$(/opt/vc/bin/vcgencmd measure_temp)
day=$(date "+%Y-%m-%d %H:%M:%S")
cpup=`top -b -n 1 | grep Cpu | awk '{print $2}' | cut -f 1 -d "%"`
cpul=`uptime | awk '{print $9}' | cut -f 1 -d ','`
cputl=`vmstat -n 1 1 | sed -n 3p | awk '{print $1}'`
while :
do 
  day=$(date "+%Y-%m-%d %H:%M:%S")
  temp=$(/opt/vc/bin/vcgencmd measure_temp)
  cpup=`top -b -n 1 | grep Cpu | awk '{print $2}' | cut -f 1 -d "%"`
  cpul=`uptime | awk '{print $11}' | cut -f 1 -d ','`
  cputl=`vmstat -n 1 1 | sed -n 3p | awk '{print $1}'`
  echo "$day : $temp  cpu_usage=$cpup%   cpu_load=$cpul     cpu_task_length=$cputl"
  if (echo ${cpul} upper_cpuload | awk '!($1>$2){exit 1}') then
  	echo "$day : CPU Load is too high...Killing Processes....." 
    /home/pi/pid-kill.sh ToSql > /dev/null 
	  /home/pi/pid-kill.sh rtspIMG > /dev/null 
	  /home/pi/pid-kill.sh curl > /dev/null 
	  #/home/pi/pid-kill.sh temp-monitor > /dev/null 
	  /home/pi/pid-kill.sh fso_draw > /dev/null 
	  /home/pi/pid-kill.sh stats_backuo> /dev/null 
	  /home/pi/pid-kill.sh warning> /dev/null 
  fi
  sleep  $delaytime
done
