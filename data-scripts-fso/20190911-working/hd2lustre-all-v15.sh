#!/bin/bash
#author: chen dong @FSO
#Purposes: mount HD to /data directory, copy HD to /lustre/data and safely unmount HD
#Usage: ./hd2lustre-all-v15.sh srcdir destdir year(in 4 digits) datatype(TIO or HA)
#Example: ./hd2lustre-all-v15.sh  /data  /lustre/data 2019 TIO
#Changelog:
#         20190420 Release 0.1, first working script
#         20190421 Release 0.2, fixed minor errors, and using cp instead of rsync
#         20190423 Release 0.3, fixed error in reading parameters inputed
#         20190423 Release 0.4, judge the srcdir is empty or not
#         20190424 Release 0.5, fixed some error in copying 
#         20190424 Release 0.6, add datatype as input to improve speed for chmoding
#         20190425 Release 0.7, add more info for chmod
#                  Release 0.8, sum of the data copied in MB
#                  Release 0.9, sum of file numbers both in src and dest
#         20190625 Release 1.0, add speed info 
#         20190708 Release 1.1, add checking dest dir in year specified
#                               add datatype to destdir if missing in src
#         20190710 Release 1.3, add multithreading to copy process
#         20190711 Release 1.5, using tar & pv to copy data

trap 'onCtrlC' INT
function onCtrlC(){
    echo "Ctrl-C Captured! "
    echo "Breaking..."
    umount $dev
    exit 1
}


cyear=`date  +%Y`
today=`date  +%Y%m%d`
ctime=`date  +%H:%M:%S`
syssep="/"
devpre="/dev/"

echo " "
echo " "
echo "====== Welcome to HD-->Lustre data Archiving System @FSO ======"
echo "                 (Release 1.5 20190711 08:25)                  "
echo "                                                               "
echo "       Syncing $datatype data from local HD to Lustre          "
echo "                                                               "
echo "                     $today   $ctime                           "
echo "                                                               " 
echo "==============================================================="
echo " "

#if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]] ;then
if [ $# -ne 4 ];then
  echo "Usage: ./hd2lustre-all-v15.sh srcdir destdir year(4 digits) datatype(TIO or HA)"
  echo "Example: ./hd2lustre-all-v15.sh /data  /lustre/data 2019 TIO"
  exit 1
fi

srcdir1=$1
destdir1=$2
ayear=$3
datatype=$4
srcdir=${srcdir1}${syssep}
destdir=${destdir1}${syssep}${ayear}${syssep}

# test the srcdir is empty or not
# if empty, mount the device
# else copy directly

stat=`ls $srcdir1|wc -w`
#stat less or equal 0 means srcdir is empty
if [ $stat -gt 0 ];then
  echo "$srcdir1 is not empty...."
  echo "please choose another mount point other then $srcdir1!"
  exit 1
fi

#searching for all available disk devices...
out=$(lsblk -l|grep 'sd[b-z][1-9]' | awk '{print($1)}')
OLD_IFS="$IFS"
IFS=" "
hdlist=($out)
IFS="$OLD_IFS"
len1=0
echo "$today $ctime: Please select target drive to archiving..."
echo "Available devices:"
for i in ${hdlist[@]}
do
  echo "$len1: $i"
  let len1++
done

if [ $len1 -le 0 ];then
  echo "No devices available..."
  exit 1
fi 

echo "Pls select:"
read  uchoice
index=$(($uchoice+0))
if [[ "$index" -lt 0 ]] || [[ "$index">"$len1" ]];then
  echo "input error, pls try again!"
  exit 1
fi
s=0
for i in ${hdlist[@]}
do
  if [ "$s" -eq "$index" ];then
    hdname=$i
    break
  fi
  let s++
done
ctime=`date  +%H:%M:%S`
echo "$today $ctime: $hdname selected"

dev=${devpre}${hdname}
#echo $dev
mount -t ntfs-3g $dev $srcdir1
if [ $? -ne 0 ];then
  echo "$today $ctime: mount $dev to $srcdir1 failed!"
  echo "                   please check!"
  exit 1
fi
echo "$today $ctime: Calculating size and file number in $src..."
srcsize=`du -sm $src|awk '{print $1}'`
srcfilenum=`ls -lR $src| grep "^-" | wc -l`
#mount device ended,start copying then
#create dir in year specified if not exist
#if [ ! -d "${destdir}${ayear}${syssep}${datatype}" ];then
#  mkdir -p -m 777 ${destdir}${ayear}${syssep}${datatype}
#fi
destsizetmp=0
destfilenumtmp=0
destsizetotal=0
destfilenumtotal=0
timetotal=0
ctime=`date  +%H:%M:%S`
t1=`echo $ctime|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`

dir=$(ls -l $srcdir1 |awk '/^d/ {print $NF}')
for i in $dir
do
  if [ ! -d "${destdir}${i}" ];then
#    mkdir -p -m 777 ${destdir}${i}${syssep}${datatype}
     mkdir -p -m 777 ${destdir}${i}
  fi
#  dest=${destdir}${i}${syssep}${datatype}
  src=${srcdir}${i}
  dest=${destdir}${i}

  ctime1=`date  +%H:%M:%S`
  echo " "
  echo "==============================================================="
  echo "$today $ctime1: Archiving @datatype data from HD to lustre....."
  echo "                   From: $src on $dev"
  echo "                   To  : $dest"
  echo "$today $ctime1: Copying...."
  echo "                   Please Wait..."
  echo "==============================================================="
  cd $src
#  SRC="/lustre/data/2019/20190707/";cd $SRC; TRG="/home/chd/tmp"; tar cf - . | pv -s $(du -sb "$SRC" | cut -f1) | tar xf - -C "$TRG";cd $TRG
  
  #cp -ruf  . $dest 
  tar cf - . | pv -s $(du -sb "$src" | cut -f1) | tar xf - -C "$dest"
  if [ $? -ne 0 ];then
    ctime1=`date  +%H:%M:%S`
    echo "$today $ctime1: Archiving $src on $dev to $dest failed!"
    echo "                   please check!"
    umount $dev
    exit 1
  fi

  ctime1=`date  +%H:%M:%S`
  
  t2=`echo $ctime1|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
  destsizetmp=`du -sm $dest|awk '{print $1}'`
  destfilenumtmp=`ls -lR $dest| grep "^-" | wc -l`
  destsizetotal=`echo "$destsizetotal $destsizetmp"|awk '{print($2+$1)}'`
  destfilenumtotal=`echo "$destfilenumtotal $destfilenumtmp"|awk '{print($2+$1)}'`
  timetotal=`echo "$timetotal $t1 $t2"|awk '{print($1+($3-$2))}'`
  echo "$today $ctime1: Copying From $src To $dest Finished!....."
done
  
#speed of copy 
ctime2=`date  +%H:%M:%S`
if [ $timetotal -eq 0 ]; then
	speed=0
fi
speed=`echo "$destsizetotal $timetotal"|awk '{print($1/$2)}'`

echo "==============================================================="
echo "$today $ctime1: Succeeded in Archiving Data:"
echo "                   From: $srcdir on $dev"
echo "                   To  : $destdir"
echo "        Source File Num: $srcfilenum"
echo "            Source Size: $srcsize MB"
echo "          Dest File Num: $destfilenumtotal"
echo "              Dest Size: $destsizetotal MB"
echo "                  Speed: $speed MB/s"
echo "              Time Used: $timetotal secs."
echo "              Time From: $ctime "
echo "			               To: $ctime2"
echo "==============================================================="
exit 0
