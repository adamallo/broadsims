#!/bin/bash

raxml_sh=$(pwd)
raxml_sh="${raxml_sh}/rerun_raxml_gtree_perep.sh"
usage="$0 check_file"

if [[ ! -f $1 ]]
then
	echo $usage
	exit
fi

input_file=$(readlink -e $1)

cd /home/dmallo/broadsims/new/sim_broadsims
mkdir ../repOlogs
mkdir ../repElogs

while read folder ids
do
	cd $folder
	itids=$(echo $ids | sed "s/,/ /g")
	for id in $itids
	do
		job=$(qsub -q compute-1-x.q,compute-0-x.q,compute-2-x.q -j y -e ../../repElogs/ -o ../../repOlogs/ $raxml_sh ${id}_TRUE.phy | sed "s/.*job\ \(.*\)\ (.*/\1/")
		echo $folder,$id,$job
	done
	cd ..

done < $input_file
