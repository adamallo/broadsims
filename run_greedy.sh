#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

module load python/2.7.8

H=/home/dmallo/broadsims/new/sim_broadsims
nDigits=5

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
	id=`echo $(printf "%0${nDigits}d" $1)`
else
	id=`echo $(printf "%0${nDigits}d" $SGE_TASK_ID)`
fi

method=greedy
echo working on $id
mkdir -p $H/$id/$method
cd $H/$id/$method

$method.tree && echo output already exists. 
$method.tree && exit 1

if [[ ! -d ../data/constraintTree.trees ]]
then
	cd ..
	tar xvzf raxml_gtrees.tar.gz raxml_gtrees/constraintTree.trees
	mv raxml_gtrees/constraintTree.trees data
	rm -rf raxml_gtrees
	cd $method
fi

/usr/bin/time -a -o $method.time python $H/../scripts/constrained_greedy.py -i ../data/gtrees_estimated.trees -c ../data/constraintTree.trees -o $method.supertree
python $H/../scripts/collapse.py -i $method.supertree -o $method.tree
