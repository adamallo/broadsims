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

mkdir $H/$id/gtrees_times
mkdir $SCRATCH/
mkdir $SCRATCH/$id

echo "gid,time" > $H/$id/gtrees_times/gtimes.csv
sum=0
tar xvzf $H/$id/raxml_gtrees.tar.gz -C $SCRATCH/$id --strip-components=1 raxml_gtrees/*.time
if [[ $? -ne 0 ]]
then
	tar xvzf $H/$id/raxml_gtrees.tar.gz -C $SCRATCH/$id --strip-components=1 raxml_gtrees/*info*
	for i in $SCRATCH/$id/RAxML_info*
	do
		gid=$(basename $i | sed "s/RAxML_info\.//g")
		if [[ -s $i ]]
		then
			time=$(sed -n "s/Overall execution time: \(.*\) secs .*/\\1/pg" $i)
			echo "$gid,$time" >> $H/$id/gtrees_times/gtimes.csv
			sum=$(perl -e "print($sum+$time)")
		else
			echo "Missing $gid $i"
		fi
	done

else
	for i in $SCRATCH/$id/*time
	do
		gid=$(basename $i | sed "s/.g_tree.time//g")
		if [[ -s $i ]]
		then
			time=$(tail -n 2 $i| awk 'BEGIN{FS=" "}{a=a+$2}END{print a}')
			echo "$gid,$time" >> $H/$id/gtrees_times/gtimes.csv
			sum=$(perl -e "print($sum+$time)")
		else
			echo "Missing $gid $i"
		fi
	done
fi

rm -rf $SCRATCH/$id

echo $sum > $H/$id/gtrees_times/totalgtime.txt
