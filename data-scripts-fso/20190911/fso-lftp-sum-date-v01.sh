#!/bin/bash
#author: chen dong @fso
#purposes:  get file number & size @ ftp server over lftp
#Usage: ./fso-lftp-sum-date-vxx.sh ip port  destdir yyyymmdd(8 digits) user password datatype(TIO or HA) threadnumber
#Example: ./fso-lftp-sum-date-vxx.sh  192.168.111.120 21 /lustre/data 20190716 tio ynao246135 TIO 40
#changlog: 
#       20190716    Release 0.1     first version for tio-sync.sh for specific day
# 
#waiting pid taskname prompt
waiting() {
  local pid="$1"
  taskname="$2"
  procing "$3" &
  local tmppid="$!"
  wait $pid
#恢复光标到最后保存的位置
  tput rc
  tput ed
  wctime=`date  +%H:%M:%S`
	wtoday=`date  +%Y%m%d`
               
  echo "$wtoday $wctime: $2 Task Has Done!"
  dt1=`echo $wctime|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
  echo "                   Finishing...."
  kill -6 $tmppid >/dev/null 1>&2
  echo "$dt1" > /home/chd/log/$(basename $0)-$datatype-sdtmp.dat
}

#   输出进度条, 小棍型
procing() {
  trap 'exit 0;' 6
  tput ed
  while [ 1 ]
  do
    for j in '-' '\\' '|' '/'
      do
        tput sc
        ptoday=`date  +%Y%m%d`
        pctime=`date  +%H:%M:%S`
        echo -ne  "$ptoday $pctime: $1...   $j"
        sleep 1
        tput rc
      done
  done
}

#procName="lftp"
cyear=`date  +%Y`
today1=`date  +%Y%m%d`
ctime=`date  +%H:%M:%S`
syssep="/"

if [ $# -ne 8 ];then
  echo "Usage: ./fso-lftp-sum-date-vxx.sh ip port  destdir yyyymmdd(8 digits) user password datatype(TIO or HA) threadnumber"
  echo "Example: ./fso-lftp-sum-date-vxx.sh  192.168.111.120 21 /lustre/data 20190716 tio ynao246135 TIO 40"
  exit 1
fi
server=$1
port=$2
destpre0=$3
today=$4
user=$5
password=$6
datatype=$7
pnum=$8

server=${server}:${port}

#umask 0000

filenumber=/home/chd/log/$(basename $0)-$datatype-number.dat
filesize=/home/chd/log/$(basename $0)-$datatype-size.dat
filenumber1=/home/chd/log/$(basename $0)-$datatype-number-1.dat
filesize1=/home/chd/log/$(basename $0)-$datatype-size-1.dat

lockfile=/home/chd/log/$(basename $0)-$datatype.lock

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
    echo "$today $ctime1: $(basename $0) is running for syncing $datatype data..." 
    exit 1
  else
    echo $$>$lockfile
  fi
else
  echo $$>$lockfile
fi

st1=`echo $ctime|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
echo "                                                       "
echo "======= Welcome to Data Archiving System @ FSO! ======="
echo "                fso-lftp-sum-date                      "
echo "          (Release 0.1 20190716 16:55)                 "
echo "                                                       "
echo "               Compare $datatype data                  "
echo "            between $server and $destpre0              "
echo "                                                       "
echo "                $today1 $ctime                          "
echo "======================================================="
echo " "
#procCmd=`ps ef|grep -w $procName|grep -v grep|wc -l`
#pid=$(ps x|grep -w $procName|grep -v grep|awk '{print $1}')
#if [ $procCmd -le 0 ];then
destdir=${destpre0}${syssep}${cyear}${syssep}${today}${syssep}
targetdir=${destdir}${datatype}

srcdir=${syssep}${today}${syssep}${datatype}
srcdir1=${srcpre0}

n1=$(cat $filenumber)
s1=$(cat $filesize)

ctime=`date  +%H:%M:%S`
echo "$today1 $ctime: Comparing $datatype Data Between $server and $destdir on $today @ FSO..."
echo "             From: $server$srcdir "
echo "             To  : $targetdir "
echo "$today1 $ctime: Counting Task Started, Please Wait ... "
#cd $destdir
ctime1=`date  +%H:%M:%S`
mytime1=`echo $ctime1|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
server=ftp://$user:$password@$server

lftp  $server -e "du -sm $srcdir; quit">srcfssum-$datatype@$1.dat &
waiting "$!" "$datatype size counting @ $1" "Counting $datatype Data Size @ $1"
if [ $? -ne 0 ];then
	ctime3=`date  +%H:%M:%S`
  echo "$today1 $ctime3: Counting $datatype Data Size @ $1 Failed!"
  cd /home/chd/
  exit 1
fi
ctime3=`date  +%H:%M:%S`

lftp  $server -e "find $srcdir| wc -l ; quit">srcfnsum-$datatype@$1.dat &
#lftp -p 2121 -u tio,ynao246135 -e "mirror --only-missing --continue  --parallel=40  /20190704/TIO /lustre/data/2019/20190704/TIO; quit" ftp://192.168.111.120 >/dev/null 2>&1 &
#wget  --tries=3 --timestamping --retry-connrefused --timeout=10 --continue --inet4-only --ftp-user=tio --ftp-password=ynao246135 --no-host-directories --recursive  --level=0 --no-passive-ftp --no-glob --preserve-permissions $srcdir1
waiting "$!" "$datatype file No. counting @ $1" "Counting $datatype Data File No. @ $1"
if [ $? -ne 0 ];then
	ctime3=`date  +%H:%M:%S`
  echo "$today1 $ctime3: Counting $datatype File No. @ $1 Failed!"
  cd /home/chd/
  exit 1
fi
ctime3=`date  +%H:%M:%S`

srcfssum=$(cat srcfssum-$datatype@$1.dat|awk '{print $1}')
srcfnsum=$(cat srcfnsum-$datatype@$1.dat|awk '{print $1}')

if [[ $srcfssum -eq 0 || $srcfnsum -eq 0 ]];then
	echo "$today1 $ctime3: Failed to get file size and number @ $server!"
  exit 1
fi

ctime2=`date  +%H:%M:%S`

mytime2=$(cat /home/chd/log/$(basename $0)-$datatype-sdtmp.dat)
#mytime2=`echo $ttmp|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`

#curhm=`date  +%H%M`
#if [ $curhm -ge 1501 ]; then
#chmod 777 -R $targetdir &
#find $targetdir ! -perm 777 -type f -exec chmod 777 {} \; &
#  waiting "$!" "$datatype Files Permission Changing" "Changing $datatype Files Permission"
#  if [ $? -ne 0 ];then
#    ctime3=`date  +%H:%M:%S`
#    echo "$today $ctime3: Changing Permission of $datatype Failed!"
#    cd /home/chd/
#    exit 1
#  fi
#fi

ctime2=`date  +%H:%M:%S`
echo "$today1 $ctime2: Summerizing $datatype File Numbers & Size @ $destdir..."
if [ ! -d "$targetdir" ]; then
	echo "$today1 $ctime2: $targetdir doesn't exists!"
  exit 0
fi
#n2=`ls -lR $targetdir | grep "^-" | wc -l` 
#s2=`du -sm $targetdir|awk '{print $1}'` 

ls -lR $targetdir | grep "^-" | wc -l > $filenumber1 &
waiting "$!" "$datatype File Number Sumerizing @ $destdir" "Sumerizing $datatype File Number @ $destdir"
if [ $? -ne 0 ];then
  ctime3=`date  +%H:%M:%S`
  echo "$today1 $ctime3: Sumerizing File Number of $datatype @ $destdir Failed!"
  cd /home/chd/
  exit 1
fi

du -sm $targetdir|awk '{print $1}' > $filesize1 &
waiting "$!" "$datatype File Size Summerizing @ $destdir" "Sumerizing $datatype File Size @ $destdir"
if [ $? -ne 0 ];then
  ctime3=`date  +%H:%M:%S`
  echo "$today1 $ctime3: Sumerizing File Size of $datatype @ $destdir Failed!"
  cd /home/chd/
  exit 1
fi
if [ ! -d "$targetdir" ]; then
  echo "0" > $filesize1
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

ctime4=`date  +%H:%M:%S`
st2=`echo $ctime4|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
stdiff=`echo "$st1 $st2"|awk '{print($2-$1)}'`

echo "$today1 $ctime4: Succeeded in Counting $datatype data Between $server and $destdir on $today @ FSO..."
#echo "          Synced : $sn file(s)"
#echo "          Synced : $ss MB "
#echo "  Sync Time Used : $timediff secs."
#echo "        @  Speed : $speed MB/s"
echo "        Dest Dir : $n2 file(s)"
echo "       Dest Size : $s2 MB"
echo "         Src Dir : $srcfnsum file(s)"
echo "        Src Size : $srcfssum MB"
echo " Total Time Used : $stdiff secs."
echo " Total Time From : $ctime1"
echo "              To : $ctime4"
echo "======================================================="
rm -rf $lockfile
cd /home/chd/
exit 0
#else
#  echo "$today $ctime: $procName  is running..."
#  echo "              PID: $pid                    "
#  exit 0
#fi

