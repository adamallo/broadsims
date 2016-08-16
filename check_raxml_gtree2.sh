#!/bin/bash
dir=/home/dmallo/broadsims/new/sim_broadsims/
while read id
do 
	besttreefiles=($(ls $dir/$id/RAxML_best* | sed "s/.*\/\(.*\)/\1/"))
	treefiles=($(ls $dir/$id/g_tree*.trees | sed "s/.*\/\(.*\)/\1/"))
	n_files=${#treefiles[@]}
	n_finished=${#besttreefiles[@]}
	#echo "DEBUG: $n_files $n_finished"
	reps=""
	if [ $n_files -ne $n_finished ]
	then 
		for (( nfile=0 ; nfile<$n_files ; ++nfile ))
		do 
			nrep=$(echo ${treefiles[$nfile]} | sed "s/g_trees\(.*\).trees/\1/")
			if [[ ! "${besttreefiles[@]}" =~ "RAxML_bestTree.${nrep}" ]]
			then
					reps="$reps$nrep,"
			fi
		done
		echo "$id $reps"
	fi
done < to_repeat.txt
