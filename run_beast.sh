#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

H=/home/dmallo/broadsims/new/sim_broadsims
nDigits=5

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
	id=`echo $(printf "%0${nDigits}d" $1)`
else
	id=`echo $(printf "%0${nDigits}d" $SGE_TASK_ID)`
fi

method=starbeast2
echo working on $id
mkdir -p $H/$id/$method
cd $H/$id/$method

$method.tree && echo output already exists. 
$method.tree && exit 1

##Convert phy in fasta

##Generate xml
#>input.xml
/usr/bin/time -a -o $method.time beast2.4 -beagle_SSE -seed 2222 input.xml 1> $method.out 2> $method.err

##Treeannotator
