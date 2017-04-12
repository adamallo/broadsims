#!/bin/bash

H=/home/dmallo/broadsims/new/sim_broadsims
nDigits=5
SCRATCH=/state/partition1/dmallo

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
        if [ $# -ne 1 ]
        then
                echo -e "USAGE: $0 [id]\nUse the id if you are not using a job array. Otherwise the id will be obtained from the jobid\n"
                exit
        fi
        id=$1
        shift
else
        id=$SGE_TASK_ID
        id=$(printf "%0${nDigits}d" $id)
fi

echo "rep,time,stime,method" > $H/$id/data/times2.csv
if [[ -s $H/$id/concat/time2.stat ]]
then
	time=$(tail -n 2 $H/$id/concat/time2.stat| awk 'BEGIN{FS=" "}{a=a+$2}END{print a}')
	
else
	echo "Missing time file in id $id method $m. This will generate an NA"
	time="NA"
fi
#totaltime=$(perl -e "print($gtreetime+$time)")
totaltime=$time
echo "$id,$totaltime,$time,concat2" >> $H/$id/data/times2.csv
