#!/bin/bash
#author: chen dong @fso
#purposes: summerize data file number and size(MiB) daily with regard to datatype
#        : from start date to end date
#changlog: 
#       20201010    Release 0.1.0     first working version 
#       20201028    Release 0.1.1     revised logics
#       20201103    Release 0.1.2     unify check & report & mail

waiting() {
  local pid="$1"
  taskname="$2"
  procing "$3" &
  local tmppid="$!"
  wait $pid
  #sleep 1
  tput rc
  tput ed
  wctime=`date  +%H:%M:%S`
  wtoday=`date  +%Y%m%d`
  #echo "$wtoday $wctime : $2 Task Has Done!"
#  dt1=`echo $wctime|tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
  dt1=`date +%s`
#  echo "                   Finishing..."
  kill -6 $tmppid >/dev/null 1>&2
  echo "$dt1" > /home/chd/log/dtmp
}

procing() {
  trap 'tput ed;tput rc;exit 0;' 6
  tput ed
  while [ 1 ]
  do
    for j in '-' '\\' '|' '/'
    do
      tput sc
      ptoday=`date  +%Y%m%d`
      pctime=`date  +%H:%M:%S`
      echo -ne  "$ptoday $pctime : $1...   $j"
      sleep 0.2
      tput rc
    done
  done
}

cyear=`date  +%Y`
today=`date  +%Y%m%d`
today0=`date  +%Y-%m-%d`
ctime=`date  +%H:%M:%S`
syssep="/"



if [ $# -ne 8 ];then
  echo "Usage: ./data-sum.sh datadir startyear startmonthday endyear endmonthday datatype(TIO or HA) report(1-report/0-no report) mail(1 mail/0-no mail)"
  echo "Example: ./data-sum-xx.sh  /lustre/data 2020 0928  2020 1001 TIO 1 1"
  echo "         ./data-sum-xx.sh  /lustre/data 2020 0928  2020 1001 HA 0 0"
  exit 1
fi

datapre=$1
syear=$2
smonthday=$3
eyear=$4
emonthday=$5
datatype=$6
report=$7
mail=$8

pver=0.1.1
num="00000000"
size="0000000.0000"
obstime="0000.000000"
obsday=0000
site=fso
device=lustre
homepre=/home/chd/data-info
suminfo=$homepre/$syear$smonthday-$eyear$emonthday-$datatype@fso.sum

if [ ! -d "$homepre" ];then
    mkdir -m 777 -p $homepre
fi	


sdate=$syear$smonthday
edate=$eyear$emonthday
checkdays=$((($(date +%s -d $edate) - $(date +%s -d $sdate))/86400));
today=`date  +%Y%m%d`
today0=`date  +%Y%m%d`
ctime=`date  +%H:%M:%S`
i=0
t0=`date +%s`
tmpdate=$sdate
echo " "
echo " "
echo "                      $datatype Data Summary $syear$smonthday to $eyear$emonthday @fso                                  "
echo "                      $datatype Data Summary $syear$smonthday to $eyear$emonthday @fso                                  ">$suminfo
echo "Date       Nums.                 Size(GiB)                  StartTime                                           EndTime                                     Obs. Time(hrs)" >>$suminfo
echo "**********************************************************************************************************************************************************************************">> $suminfo
while [ $i -le $checkdays ]
do
    echo
    checkdate=`date +%Y%m%d -d "+$i days $sdate"`
    checkyear=${checkdate:0:4}
    checkmonthday=${checkdate:4:4}
    #if [ ! -f $homepre/$checkyear/$datatype-$checkyear-$checkmonthday.sum ];then
	  today0=`date  +%Y%m%d`
    ctime=`date  +%H:%M:%S` 
	  echo "$today0 $ctime : Start $checkdate $datatype  Data Summerizing @fso"
    #sleep 1
    /home/chd/data-sum-daily.sh $datapre $checkyear $checkmonthday $datatype 0 &
    waiting "$!" "$datatype Date Summerizing on $checkdate @$device" "Summerizing $datatype Data on $checkdate @$device"
    today0=`date  +%Y%m%d`
    ctime=`date  +%H:%M:%S` 
    tput ed
    tput rc
    echo "$today0 $ctime : Task of $datatype Date Summerizing on $checkdate @$site Has been Done..."
    echo "                  : $i day(s) Processed..."
    if [ $report -eq "1" ];then 
        cat $homepre/$checkyear/$datatype-$checkyear-$checkmonthday.sum >>  $suminfo
    fi
    let i++
done
if [ $report -eq "1" ];then
    targetdir=$homepre/$syear
    cd $targetdir
    snum=`cat $datatype*.sum|awk '{sum += $2} END {print sum}'`
    ssize=`cat $datatype*.sum|awk '{sum += $3} END {print sum}'`
    sobstime=`cat $datatype*.sum|awk '{sum += $8} END {print sum}'`
    sobsday=`cat $datatype*.sum|awk 'i=$1;BEGIN{if (i > 0.5) print i;}'|wc -l`
    #sobstime=`echo $stime|awk '{print($1/3600)}'`
    if [ "$eyear" != "$syear" ];then
        targetdir=$homepre/$eyear
        cd $targetdir
        enum=`cat $datatype*.sum|awk '{sum += $2} END {print sum}'`
        esize=`cat $datatype*.sum|awk '{sum += $3} END {print sum}'`
        eobstime=`cat $datatype*.sum|awk '{sum += $8} END {print sum}'`
        eobsday=`cat $datatype*.sum|awk 'i=$1;BEGIN{if (i > 0.5) print i;}'|wc -l`
        #eobstime=`echo $etime|awk '{print($1/3600)}'`
    else
        enum="00000000"
        esize="0000000.0000"
        eobstime="0000.000000"
        eobsday="0000"
    fi
    num=`echo $snum $enum|awk '{print($1+$2)}'`
    size=`echo $ssize $esize|awk '{print($1+$2)}'`
    obstime=`echo $sobstime $eobstime|awk '{print($1+$2)}'`
    obsday=`echo $sobsday $eobsday|awk '{print($1+$2)}'`
    num=`printf "%08d" $num`
    size=`printf "%012.4f" $size`
    obstime=`printf "%011.6f" $obstime`
    obsday=`printf "%04d" $obsday`
    echo "******************************************************************************************************************************************************************************">> $suminfo
    echo "Start         End           Nums.               Size(GiB)               Total Obs. Time(hrs)     Total Obs. Day(s)      Total Cal. Day(s)" >>$suminfo
    echo "$syear$smonthday      $eyear$emonthday      $num            $size            $obstime              $obsday                 $checkdays" >>$suminfo
fi
today0=`date  +%Y%m%d`
ctime=`date  +%H:%M:%S`
if [ $mail -eq "1" ];then 
    echo "$today0 $ctime : Send Summary  for $year$monthday $datatype @$device to Users..."
    mail -s "Summary of $datatype Data from $syear$smonthday to $eyear$emonthday @fso" nvst_obs@ynao.ac.cn < $suminfo
    mail -s "Summary of $datatype Data from $syear$smonthday to $eyear$emonthday @fso" chd@ynao.ac.cn < $suminfo
fi
today0=`date  +%Y%m%d`
ctime=`date  +%H:%M:%S`
t1=`date +%s`
dt=`echo $t0 $t1|awk '{print($2-$1)}'`
echo "$today0 $ctime : $i days $datatype Data  Summerized..."
echo "             From : $sdate"
echo "               To : $edate"
echo "             Used : $dt secs."
