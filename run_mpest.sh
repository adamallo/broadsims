#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

module load python/2.7.8
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
method="mpest"
for j in `seq $i $(( $i + $n -1 ))`
do
{
	id=$(printf "%0${nDigits}d" $j)
	echo working on $id
	seed=$(expr $RANDOM$RANDOM % 10000000)
	nruns=20 #Like raxml
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
	mkdir -p $H/$id/$method
	echo -e "../data/gtrees_estimated.trees\n0\n$seed\n$nruns\n$nloci $ntaxa\n${smap}0" > "$H/$id/$method/control.file"
	cd $H/$id/$method

#test -s $method.tre && echo output already exists. 
#test -s $method.tre && exit 1

	/usr/bin/time -a -o $method.time mpest control.file 1>$method.out 2>$method.err
	mv $H/$id/data/gtrees_estimated.trees.tre $H/$id/$method/$method.trees.nex
	
	#Choos the best tree
	besttreeline=$(grep -n "tree mpest" $method.trees.nex | sed -e "s/ .*\[/ /g" -e "s/\].*//g" -e "s/://g"| awk 'BEGIN{OFS=","}{print $2,$1}' | shuf | sort -s -k1,1 -n --field-separator="," | head -n 1 | awk 'BEGIN{FS=","}{print($2)}')	
	cat $method.trees.nex | perl -0777 -pe "s/tree mpest.*$//gsm" > $method.tree.nex
	sed "${besttreeline}q;d" $method.trees.nex >> $method.tree.nex
	echo "end;" >> $method.tree.nex
	python -c '
import os
import sys
import dendropy
 
src_fpath = os.path.expanduser(os.path.expandvars("'$method.tree.nex'"))
if not os.path.exists(src_fpath):
    sys.stderr.write("Not found: %s" % src_fpath) 
    sys.exit(1)     
 
dest_fpath = os.path.expanduser("'$method.tree'")
trees = dendropy.TreeList.get_from_path(src_fpath, "nexus")
trees[-1].write_to_path(dest_fpath, "newick",suppress_rooting=True)'
	
} &
done
wait
