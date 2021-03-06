#!/bin/bash
#author: chen dong @ fso
#Purposes: Copy file of wrong size TIO/HA data in error list from remote host to dest mannually
#Usage: ./fso-copy-wget-error-xx.sh srcip port user passwd error-file-list
#Example: ./fso-copy-wget-error-xx.sh ftp://192.168.111.120 21 tio ynao246135  error.list
#changlog:
#        20190723       Release 0.1   first prototype release 0.1
#  		 20191031 		Release 0.2   fixed errors found

#waiting pid taskname prompt
waiting() {
  local pid="$1"
  taskname="$2"
  procing "$3" &
  local tmppid="$!"
  wait $pid
#  tput rc
#  tput ed
  ctime=`date  +%H:%M:%S`
  today=`date  +%Y%m%d`
  echo "$today $ctime: $2 Task Has Done!"
  kill -6 $tmppid >/dev/null 1>&2
}

procing() {
  trap 'exit 0;' 6
  tput ed
  while [ 1 ]
  do
#    for j in '-' '\\' '|' '/'
#    do
#    tput sc
    ptoday=`date  +%Y%m%d`
    pctime=`date  +%H:%M:%S`
    echo "$ptoday $pctime: $1, please wait... "
    sleep 1
#    tput rc
#    done
  done
}

trap 'onCtrlC' INT
function onCtrlC(){
		echo "Ctrl-C Captured! "
		echo "Breaking..."
		#umount $dev
		exit 1
}

cyear=`date  +%Y`
today=`date  +%Y%m%d`
ctime=`date  +%H:%M:%S`

if [ $# -ne 7 ]  ;then
	echo "Copy file of wrong size TIO/HA data on remote host to dest mannually"
	echo "Usage: ./fso-copy-wget-error-cron-v02.sh srcip port user passwd error-file-list stdsize"
	echo "Example: ./fso-copy-wget-error-cron-v02.sh ftp://192.168.111.120 21 tio ynao246135  /lustre/data error.list 11062080"
	echo "Example: ./fso-copy-wget-error-cron-v02.sh ftp://192.168.111.122 21 ha ynao246135  /lustre/data error.list 2111040"
	exit 1
fi

#procName="lftp"
syssep="/"
destpre="/lustre/data"
homepre="/home/chd"
logpath=$homepre/log



ftpserver=$1
remoteport=$2
ftpuser=$3
password=$4
destpre=$5
errorlist=$6
stdsize=$7

datatype=`cat $errorlist|awk '{print $1}'|cut -d '/' -f 6`

#tmpfn=/home/chd/log/$(basename $0)-$errorlist-tmpfn.dat
#tmpfs=/home/chd/log/$(basename $0)-$errorlist-tmpfs.dat
#remotefile=$logpath/$datatype-remote.list
#errordir=/home/chd/log/$(basename $0)-$errorlist-dir.list
#errorfile=/home/chd/log/$(basename $0)-$errorlist-file.list

lockfile=$logpath/$(basename $0)-$datatype-$today.lock
if [ -f "$lockfile" ];then
	mypid=$(cat $lockfile)
	ps -p $mypid | grep $mypid &>/dev/null
	if [ $? -eq 0 ];then
		echo "$today $ctime: $(basename $0) is running" && exit 1
	else
		echo $$>$lockfile
	fi
else
	echo $$>$lockfile
fi
pver=0.2
pname=$(basename $0)
echo " "
echo "============ Welcome to FSO Data System@FSO! ============"
echo "                                                         "
echo "                 $pname                                  "
echo "                                                         "
echo "             Relase $pver     20191031  20:57            "
echo "                                                         "
echo "                $today    $ctime                         "
echo "                                                         "
echo "========================================================="
echo " "
#get path and file name of each error file
#cat $errorlist|awk '{print $1}'|cut -d '/' -f 5-11 > $remotefile
#cat $errorlist|awk '{print $1}' > $remotefile
#cat $errorlist|awk '{print $1}'|cut -d '/' -f 1-9 > $errordir
#cat $errorlist|awk '{print $1}'|cut -d '/' -f 1-10 > $errorfile
#datatype=`cat $errorlist|awk '{print $1}'|cut -d '/' -f 6`
#get year from errorlist for lustre
ytmp=`cat $errorlist|sed -n '1P'|cut -d '/' -f 2`
year=`expr substr "$ytmp" 1 4`

ftpserver1=${ftpserver}:${remoteport}

count=0
size=0
starttime=`date  +%H:%M:%S`
t1=`date +%s`
echo "$today $starttime: Copying From $ftpserver1 "
echo "  "
#for each file in errorlist
#sort $errorlist -o $errorlist
for line in $(cat $errorlist);
do
	ctime=`date  +%H:%M:%S`
	rfile=$ftpserver1$line
	localfile=$destpre/$year$line
	echo "$today $ctime: Copying $rfile"
	wget -O $localfile --ftp-user=$ftpuser --ftp-password=$password --no-passive-ftp  $rfile >/dev/null 2>&1 & 
	waiting "$!" "$datatype file(s) in $errorlist copying" "Copying $datatype $fileformat file(s) in $errorlist"
	if [ $? -ne 0 ];then
		ctime1=`date  +%H:%M:%S`
		echo "$today $ctime1: Failed in Copying $rfile..."
		#cd $homepre
		#exit 1
	else
	  tmps=`du -sm $localfile|awk '{print $1}'`
	  ctime1=`date  +%H:%M:%S`
	  #if [ $tmps != $stdsize ]; then 
	  #  echo "$today $ctime1: Copying Failed for  $localfile $tmps MB"
	  #else 
	  echo $localfile > $logpath/localfile-$today.tmp
      #remove corrected file from the list
	    #comm -13 $logpath/localfile-$today.tmp $errorlist | sort | uniq > $errorlist
	  awk 'NR==FNR{ a[$1]=$1 } NR>FNR{ if(a[$1] == ""){ print $1}}' $logpath/localfile-$today.tmp $errorlist > $errorlist 
      #change the permission of copied file
	  find $localfile ! -perm 777 -type f -exec chmod 777 {} \;
      size=$((size+tmps))
	  echo "$today $ctime1: $localfile copied in $tmps MB"
	    ((count++))
	  #fi
	fi  
done
endtime=`date  +%H:%M:%S`
#t1=`echo $starttime|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
#t2=`echo $endtime|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
t2=`date +%s`
timediff=`echo "$t1 $t2"|awk '{print($2-$1)}'`
if [ $timediff -le 0 ]; then
	speed=0
else
	speed=`echo "$size $timediff"|awk '{print($1/$2)}'`
fi
ctime2=`date  +%H:%M:%S`
today0=`date  +%Y%m%d`
echo " "
echo "$today $ctime2: Succeeded in Data File Error Correcting!"
echo "Synced file No.  : $count file(s)"
echo "Synced data size : $size MB"
echo "           Speed : $speed MB/s"
echo "       Time Used : $timediff secs."
echo "       Time From : $today $starttime  "
echo "              To : $today0 $ctime2 "
rm -f $lockfile
rm -f ./localtmp
cd $homepre
exit 0
