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

echo "rep,time,stime,method" > $H/$id/data/times.csv
methods=("astral" "greedy" "mpest" "mrpmatrix" "mrl" "njst" "star" "steac")
#methods=("astral" "greedy" "mpest" "mrl" "njst" "star" "steac" "revpomo" "starbeast2" "astrid")
gtreetime=$(cat $H/$id/gtrees_times/totalgtime.txt)

for m in ${methods[@]}
do
	if [[ -s $H/$id/$m/${m}.time ]]
	then
		lines=$(wc -l $H/$id/$m/${m}.time | awk '{print $1}')
		if [[ $lines -gt 2 ]]
		then
			echo "Multiple entries in id $id method $m time. Choosing the last two, dangerous"
			time=$(tail -n 2 $H/$id/$m/${m}.time | awk 'BEGIN{FS=" "}{if (NR==1){sub("user","",$1); sub("system","",$2);print $1+$2}}')
		elif [[ $lines -lt 2 ]]
		then
			echo "Less than two lines in id $id method $m time. This will generate an NA"
			time="NA"
		else
			time=$(awk 'BEGIN{FS=" "}{if (NR==1){sub("user","",$1); sub("system","",$2);print $1+$2}}' $H/$id/$m/${m}.time)
		fi
	else
		echo "Missing time file in id $id method $m. This will generate an NA"
		time="NA"
	fi
	totaltime=$(perl -e "print($gtreetime+$time)")
	echo "$id,$totaltime,$time,$m" >> $H/$id/data/times.csv
		
done
