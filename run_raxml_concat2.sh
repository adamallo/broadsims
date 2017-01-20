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

method="concat"
cd $dir/$id

if [[ -d $method ]]
then
	echo "Folder already present"
	exit
fi

##untar concat.phy
tar -xvzf seqs.tar.gz seqs/concat.phy

mkdir $method
cd $method
outfile=${method}2
/usr/bin/time -p -o time2.stat raxmlHPC-SSE3 -g ../data/constraintTree.trees -s ../seqs/concat.phy -m GTRGAMMA -p 2222 -N 20 -n $outfile 1>${method}2.out 2>${method}2.err
mv RAxML_bestTree.$outfile ${method}2.tree

#Deleting the just extracted concat.phy
rm -rf ../seqs/*
rmdir ../seqs

#Reorganization
mkdir raxml_files2
mv RAxML* raxml_files2
tar -czf raxml_files2.tar.gz raxml_files2
rm -rf raxml_files2
