#!/bin/bash

if [[ $# -lt 2 ]]
then
	echo "Usage $0 simulation_output_folder output_id_file [stop_id]"
	exit
fi

rm $2

last_id=-1

if [[ $# -eq 3 ]]
then
	last_id=$3
fi
it=0
for i in $1/[0-9]*
do
	id=$(basename $i)
	mod=$(($it % 100))
	if [ $mod -eq 0 ]
	then
		echo "Iteration $it"
	fi
	if [ $id -eq $last_id ]
	then
		echo "Stopping the analysis in the folder $id"
		exit
	fi
	n_gtrees=$(ls -l $i/g_tree* | wc -l)
	n_raxtrees=$(ls -l $i/RAxML_best* | wc -l)
	if [[ $n_gtrees -ne $n_raxtrees ]]
	then
		echo $id >> $2
	fi
	it=$(($it+1))
done
