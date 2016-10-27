#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

module load R/3.2.2_1


H=/home/dmallo/broadsims/new/sim_broadsims
nDigits=5

if [ $# -lt 1 ]
then
	echo "USAGE: $0 [id] step"
	exit
fi

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
	#id=`echo $(printf "%0.$nDigits" $1)`
	i=$1
	n=$2
else
	i=$SGE_TASK_ID
	#id=`echo $(printf "%0.$nDigits" $SGE_TASK_ID)`
	n=$1
fi

echo starting in $i, executing the script in $n folders
#method=njst
methods=("njst" "star" "steac")
for j in `seq $i $(( $i + $n -1 ))`
do
{
	id=$(printf "%0${nDigits}d" $j)
	echo working on $id
	cat $H/$id/data/gtrees_estimated.trees |sed -e "s/:[^),]*//g" -e "s/)[0-9.]*//g" -e "s/[(,);]/ /g" -e 's/ /\'$'\n''/g' |sort|uniq|tail -n+2|sed "s/\(.*\)\_.*\_.*$/& s\1/" >$H/$id/data/species.map
	for method in "${methods[@]}"
	do
		mkdir -p $H/$id/$method
		cd $H/$id/$method

#test -s $method.tre && echo output already exists. 
#test -s $method.tre && exit 1

		/usr/bin/time -a -o $method.time Rscript $H/../scripts/steac_star_njst.r $method ../data/gtrees_estimated.trees ../data/species.map "0_0_0" ${method}.tree 1>$method.out 2>$method.err
	done
} &
done
wait
