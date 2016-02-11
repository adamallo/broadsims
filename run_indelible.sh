#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

if [[ $# -eq 1 ]] 
then
	if [[ -d $1 ]] && [[ -n "$SGE_TASK_ID" ]]
	then
		dir=$1
		id=$(printf "%05d" $SGE_TASK_ID)
	elif [[ -d $1 ]]
	then
		echo "Error, folder_id not specified without using a job array. Usage: script simphy_dir [folder_id]"
		exit
	else
		echo "Error, $1 is not a valid directory. Usage: script simphy_dir [folder_id]"
		exit
	fi

elif [[ $# -eq 2 ]]
then
	if [[ -d $1 ]] && [[ -d $1/$2 ]]
	then
		dir=$1
		id=$2
	elif [[ -d $1 ]]
	then
		echo "Error, $2 is not a valid subdirectory of $1. Usage: script simphy_dir [folder_id]"
		exit
	else
		echo "Error, $1 is not a valid directory. Usage: script simphy_dir [folder_id]"
                exit	
	fi
	
else
	echo "Error. Usage: script simphy_dir [folder_id]"
	exit
fi

cd $dir/$id
indelible
