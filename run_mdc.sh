#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

module load python/2.7.8
module load java/jdk/1.8.0_31

H=/home/dmallo/broadsims/new/sim_broadsims/
BIN=/home/dmallo/broadsims/new/scripts/

PHYLONET="java -jar /home/dmallo/bin/PhyloNet_3.6.1.jar"
nDigits=5
#nDigits=6

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
	id=`echo $(printf "%0${nDigits}d" $1)`
else
	id=`echo $(printf "%0${nDigits}d" $SGE_TASK_ID)`
fi

echo working on $id

##Astrid
method="mdc"
mkdir -p $H/$id/$method
cd $H/$id/$method

#if [[ ! -f mdc.nex ]]
#then
	python $BIN/newicktonexusphylonet.py -i ../data/gtrees_estimated.trees -o mdc.nex
#fi

#if [[ ! -f ${method}.tree ]]
#then
	rm -rf ${method}.time
	/usr/bin/time -a -o ${method}.time $PHYLONET mdc.nex 1> ${method}.out 2>${method}.err
	tail -n +2 mdc_temp.tree | head -n 1 > mdc.tree
#fi
