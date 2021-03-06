#!/bin/bash
#author: chen dong @fso
#purposes: periodically syncing data from remoteip to local lustre storage via lftp
#usage:  run in crontab every 1 min.  from 08:00-20:00
#example: 
#         /home/chd/fso-sync-lftp-v08.sh  192.168.111.120 21 /lustre/data tio ynao246135 TIO 40 >> /home/chd/log/fso-sync-tio.log
#         /home/chd/fso-sync-lftp-v08.sh  192.168.111.122 21 /lustre/data ha ynao246135 HA 100 >> /home/chd/log/fso-sync-ha.log
#
#changlog: 
#       20190603    Release 0.1     first version for tio-sync.sh
#       20190625    Release 0.2     revised lftp performance & multi-thread
#       20190703    Release 0.3     fix some errors 
#       20190705    Release 0.4     timing logic revised
#       20190715    Release 0.5     reduce time of changing permission
#       20190716    Release 0.6     add parallel permission changing
#                   Release 0.7     input parallel lftp thread number
#       20190718    Release 0.8     add remote data info 
#       20190914    Release 0.9     revised display info and some minor errors
#       20191015    Release 0.91    correct the time calculating
#       20200103    Release 0.92    modify to use for ha level1 reduction
# 
#waiting pid taskname prompt
waiting() {
  local pid="$1"
  taskname="$2"
  procing "$3" &
  local tmppid="$!"
  wait $pid
#恢复光标到最后保存的位置
#        tput rc
#        tput ed
  wctime=`date  +%H:%M:%S`
  wtoday=`date  +%Y%m%d`
               
  echo "$wtoday $wctime: $2 Task Has Done!"
  #dt1=`echo $wctime|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
  dt1=`date +%s`
  echo "                   Finishing...."
  kill -6 $tmppid >/dev/null 1>&2
  echo "$dt1" > $logpre/$(basename $0)-$datatype-sdtmp.dat
}

#   输出进度条, 小棍型
procing() {
  trap 'exit 0;' 6
  tput ed
  while [ 1 ]
  do
    sleep 1
    ptoday=`date  +%Y%m%d`
    pctime=`date  +%H:%M:%S`
    echo "$ptoday $pctime: $1, Please Wait...   "
  done
}

#procName="lftp"
cyear=`date  +%Y`
today=`date  +%Y%m%d`
today0=`date  +%Y-%m-%d`
ctime=`date  +%H:%M:%S`
syssep="/"

if [ $# -ne 7 ];then
  echo "Usage: ./fso-sync-lftp.sh ip port  destdir user password datatype(TIO or HA) threadnumber"
  echo "Example: ./fso-sync-lftp.sh  192.168.100.238 21 /home/user/data ha ynao246135 ha 40"
  exit 1
fi
server1=$1
port=$2
destpre0=$3
user=$4
password=$5
datatype=$6
pnum=$7

server=${server1}:${port}
logpre=./log
#umask 0000

filenumber=$logpre/$(basename $0)-$datatype-number.dat
filesize=$logpre/$(basename $0)-$datatype-size.dat
filenumber1=$logpre/$(basename $0)-$datatype-number-1.dat
filesize1=$logpre/$(basename $0)-$datatype-size-1.dat

srcsize=$logpre/$datatype-$today-$server1-filesize.dat
srcnumber=$logpre/$datatype-$today-$server1-filenumber.dat

lockfile=$logpre/$(basename $0)-$datatype-$today.lock

if [ ! -f $filenumber ];then
  echo "0">$filenumber
fi
if [ ! -f $filesize ];then 
  echo "0">$filesize
fi
if [ ! -f $filenumber1 ];then
  echo "0">$filenumber1
fi
if [ ! -f $filesize1 ];then
  echo "0">$filesize1
fi

if [ -f $lockfile ];then
  mypid=$(cat $lockfile)
  ps -p $mypid | grep $mypid &>/dev/null
  if [ $? -eq 0 ];then
    echo "$today $ctime: $(basename $0) is running for syncing $datatype data..." 
    exit 1
  else
    echo $$>$lockfile
  fi
else
  echo $$>$lockfile
fi

#st1=`echo $ctime|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
st1=`date +%s`
echo "                                                       "
echo "======= Welcome to Data Archiving System @ FSO! ======="
echo "                fso-sync-lftp.sh                       "
echo "         (Release 0.91 20191015 15:20)                 "
echo "                                                       "
echo "         sync $datatype data to $destpre0              "
echo "                                                       "
echo "            Started @ $today $ctime                    "
echo "======================================================="
echo " "
#procCmd=`ps ef|grep -w $procName|grep -v grep|wc -l`
#pid=$(ps x|grep -w $procName|grep -v grep|awk '{print $1}')
#if [ $procCmd -le 0 ];then
if [ $datatype == "SP" ];then
  destdir=${destpre0}${syssep}${cyear}${syssep}${today}${syssep}${datatype}
else
  destdir=${destpre0}${syssep}${cyear}${syssep}${today}${syssep}
fi

targetdir=${destdir}${datatype}
if [ ! -d "$targetdir" ]; then
  mkdir -m 777 -p $targetdir
else
  echo "$today $ctime: $targetdir exists!"
fi

if [ $datatype == "SP" ];then
  destdir=${destpre0}${syssep}${cyear}${syssep}${today}${syssep}${datatype}
fi

srcdir=${syssep}${today}${syssep}${datatype}
srcdir0=${syssep}${today}${syssep}
srcdir1=${srcpre0}

#n1=$(cat $filenumber)
#s1=$(cat $filesize)

ctime=`date  +%H:%M:%S`
echo "$today $ctime: Syncing $datatype data @ FSO..."
echo "             From: $server$srcdir "
echo "             To  : $targetdir "
echo "$today $ctime: Sync Task Started, Please Wait ... "
#cd $destdir
ctime1=`date  +%H:%M:%S`
#mytime1=`echo $ctime1|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
mytime1=`date +%s`
server=ftp://$user:$password@$server
#lftp  $server -e "mirror --ignore-time --continue  --parallel=$pnum  $srcdir $targetdir; quit">/dev/null 2>&1 &
lftp  $server -e "mirror  --parallel=$pnum  $srcdir0 $destdir; quit">/dev/null 2>&1 &
#lftp -p 2121 -u tio,ynao246135 -e "mirror --only-missing --continue  --parallel=40  /20190704/TIO /lustre/data/2019/20190704/TIO; quit" ftp://192.168.111.120 >/dev/null 2>&1 &
#wget  --tries=3 --timestamping --retry-connrefused --timeout=10 --continue --inet4-only --ftp-user=tio --ftp-password=ynao246135 --no-host-directories --recursive  --level=0 --no-passive-ftp --no-glob --preserve-permissions $srcdir1

waiting "$!" "$datatype Syncing" "Syncing $datatype Data"
ctime3=`date  +%H:%M:%S`
if [ $? -ne 0 ];then
  echo "$today $ctime3: Syncing $datatype Data @ FSO Failed!"
  cd /home/chd/
  exit 1
fi
ctime2=`date  +%H:%M:%S`

mytime2=$(cat $logpre/$(basename $0)-$datatype-sdtmp.dat)
#mytime2=`echo $ttmp|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`

#curhm=`date  +%H%M`
#if [ $curhm -ge 1501 ]; then
#chmod 777 -R $targetdir &
#find $targetdir ! -perm 777 -type f -exec chmod 777 {} \; & 
find $targetdir ! -perm 777 -type d -exec chmod 777 {} \; &
#  waiting "$!" "$datatype Files Permission Changing" "Changing $datatype Files Permission"
#  if [ $? -ne 0 ];then
#    ctime3=`date  +%H:%M:%S`
#    echo "$today $ctime3: Changing Permission of $datatype Failed!"
#    cd /home/chd/
#    exit 1
#  fi
#fi

ctime2=`date  +%H:%M:%S`
echo "$today $ctime2: Summerizing $datatype File Numbers & Size..."

#n2=`ls -lR $targetdir | grep "^-" | wc -l` 
#s2=`du -sm $targetdir|awk '{print $1}'` 

filetmp=${target}${syssep}*.fits

find $targetdir | grep fits | wc -l > $filenumber1 &
waiting "$!" "$datatype File Number Sumerizing" "Sumerizing $datatype File Number"
if [ $? -ne 0 ];then
  ctime3=`date  +%H:%M:%S`
  echo "$today $ctime3: Sumerizing File Number of $datatype Failed!"
  cd /home/chd/
  exit 1
fi

du -sm $targetdir|awk '{print $1}' > $filesize1 &
waiting "$!" "$datatype File Size Summerizing" "Sumerizing $datatype File Size"
if [ $? -ne 0 ];then
  ctime3=`date  +%H:%M:%S`
  echo "$today $ctime3: Sumerizing File Size of $datatype Failed!"
  cd /home/chd/
  exit 1
fi
if [ ! -d "$targetdir" ]; then
  echo "0" > $filesize1
  echo "0" > $filenumber1
fi

n2=$(cat $filenumber1)
s2=$(cat $filesize1)

sn=`echo "$n1 $n2"|awk '{print($2-$1)}'`
ss=`echo "$s1 $s2"|awk '{print($2-$1)}'`

timediff=`echo "$mytime1 $mytime2"|awk '{print($2-$1)}'`
if [ $timediff -le 0 ]; then
	timediff=1
fi
speed=`echo "$ss $timediff"|awk '{print($1/$2)}'`

echo $n2>$filenumber
echo $s2>$filesize

if [ -f $srcsize ]; then 
  srcs=$(cat $srcsize|awk '{print $3}')
  srcday=$(cat $srcsize|awk '{print $1}')
  srctime=$(cat $srcsize|awk '{print $2}')
else
  srcs=0
  srcday=$today
  srctime=$ctime2
fi
if [ -z $srcs ];then
  srcs=0
fi

if [ -f $srcnumber ]; then
  srcn=$(cat $srcnumber|awk '{print $3}')
#  srcday=$(cat $srcnumber|awk '{print $1}')
#  srctime=$(cat $srcnumber|awk '{print $2}')
else
  srcn=0
  srcday=$today
  srctime=$ctime2
fi
if [ -z $srcn ];then
  srcn=0
fi

ctime4=`date  +%H:%M:%S`
#st2=`echo $ctime4|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
st2=`date +%s`
stdiff=`echo "$st1 $st2"|awk '{print($2-$1)}'`
today1=`date +%Y-%m-%d`
echo "$today $ctime4: Succeeded in Syncing $datatype data @ $server1!"
echo "======================================================="
echo "$srcday $srctime: @ $server1             "
echo "      Source Dir : $srcdir"
echo "   Source Number : $srcn file(s)"
echo "     Source Data : $srcs MB "
echo "*******************************************************"
echo "$today $ctime4: @ $targetdir          "
echo "          Synced : $sn file(s)"
echo "          Synced : $ss MB "
echo "  Sync Time Used : $timediff secs."
echo "        @  Speed : $speed MB/s"
echo "    Total Synced : $n2 File(s)"
echo "                 : $s2 MB"
echo " Total Time Used : $stdiff secs."
echo "            From : $today0 $ctime1"
echo "              To : $today1 $ctime4"
echo "======================================================="
rm -rf $lockfile
cd /home/chd/
exit 0
#else
#  echo "$today $ctime: $procName  is running..."
#  echo "              PID: $pid                    "
#  exit 0
#fi
