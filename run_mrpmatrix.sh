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

method=mrpmatrix
echo working on $id
mkdir -p $H/$id/$method
cd $H/$id/$method

mrp.matrix && echo output already exists. 
mrp.matrix && exit 1

/usr/bin/time -a -o $method.time mrpmatrix ../data/gtrees_estimated.trees mrp.matrix PHYLIP -randomize 1>$method.out 2>$method.err
