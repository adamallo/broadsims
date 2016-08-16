#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

if [[ $# -eq 1 ]]
then
        if [[ -f $1 ]]
        then
                input_file=$1
        else
		echo "The file $1 is not readable"
		exit
	fi
else
	echo "Usage: $0 inputfile"
	exit
fi

nrep=$(echo $input_file | sed 's/_TRUE.phy//')
echo "Running $input_file"
rm -f RAxML_info.$nrep
rm -f RAxML_log.${nrep}.*
rm -f RAxML_parsimonyTree.${nrep}.*
rm -f RAxML_result.${nrep}.*
#/usr/bin/time -p -o ${nrep}.g_tree.time raxmlHPC-SSE3 -s $input_file -m GTRGAMMA -p 2222 -N 20 -n $nrep
/usr/bin/time -p -o ${nrep}.g_tree.time raxmlHPC-SSE3 -s $input_file -m GTRCAT -p 1234 -N 20 -n $nrep
