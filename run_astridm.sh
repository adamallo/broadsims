#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

module load python/2.7.8
H=/home/dmallo/broadsims/new/sim_broadsims/
#H=/home/dmallo/njstM/data/sim1/
BIN=/home/dmallo/broadsims/new/scripts/

ASTRID="python /home/dmallo/astridm/ASTRID"
nDigits=5
#nDigits=6

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
	id=`echo $(printf "%0${nDigits}d" $1)`
else
	id=`echo $(printf "%0${nDigits}d" $SGE_TASK_ID)`
fi

echo working on $id

ifile=$H/$id/data/gtrees_estimated.trees
data=$H/$id/data/

if [[ ! -f $data/astrid.mapping ]]
then
	cat $ifile |sed -e "s/:[^),]*//g" -e "s/)[0-9.]*//g" -e "s/[(,);]/ /g" -e 's/ /\'$'\n''/g' |sort|uniq|tail -n+2|sed "s/\(.*\)\_.*\_.*$/& \1/" > $data/astrid.mapping
fi

if [[ ! -f $data/gtrees_estimated_basaltrifurcation.trees ]]
then
	python $BIN/strictunroot.py -i $ifile -o $data/gtrees_estimated_basaltrifurcation.trees
fi

##Astrid
method="astrid"
mkdir -p $H/$id/$method
cd $H/$id/$method

if [[ ! -f astrid.tree ]]
then
	if [[ ! -f $data/gtrees_estimated_basaltrifurcation_sp.trees ]]
	then
		sed "s/_[0-9]*_[0-9]*//g" $data/gtrees_estimated_basaltrifurcation.trees > $data/gtrees_estimated_basaltrifurcation_sp.trees
	fi
	/usr/bin/time -a -o ${method}.time $ASTRID -i $data/gtrees_estimated_basaltrifurcation_sp.trees -c ${method}.cache -o ${method}.tree 1> ${method}.out 2>${method}.err
fi

##Astridmu
method="astridmu"
mkdir -p $H/$id/$method
cd $H/$id/$method

if [[ ! -f astridmu.tree ]]
then
	/usr/bin/time -a -o ${method}.time $ASTRID -i $data/gtrees_estimated_basaltrifurcation.trees --map $data/astrid.mapping -c ${method}.cache --bygene -o ${method}.tree 1> ${method}.out 2>${method}.err
fi
