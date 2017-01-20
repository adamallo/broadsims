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

method=astral
echo working on $id
mkdir -p $H/$id/$method
cd $H/$id/$method

$method.tree && echo output already exists. 
$method.tree && exit 1

leaves=($(cat $H/$id/data/gtrees_estimated.trees |sed -e "s/:[^),]*//g" -e "s/)[0-9.]*//g" -e "s/[(,);]/ /g" -e 's/ /\'$'\n''/g' |sort|uniq|tail -n+2))
species=($(echo ${leaves[*]}| tr ' ' '\n' |sed "s/\(.*\)\_.*\_.*$/\1/" | sort | uniq))
ntaxa=${#species[@]}
nloci=$(cat $H/$id/data/gtrees_estimated.trees | wc -l)
smap=""
for sp in ${species[@]}
do
        individuals=($(echo ${leaves[*]} | tr ' ' '\n' | sed -n "/^${sp}_.*_.*/p"))
        nind=${#individuals[*]}
        smap=$(echo "$smap$sp $nind ${individuals[*]}\n")
done
echo -e $smap > ${method}.mapping

/usr/bin/time -a -o $method.time astral.sh -t 0 -s 2222 -a ${method}.mapping -i ../data/gtrees_estimated.trees -o $method.tree 1> $method.out 2>$method.err
