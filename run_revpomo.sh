#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

H=/home/dmallo/broadsims/new/sim_broadsims
PY3ENV_SOURCE=/home/dmallo/activate_python3env
nDigits=5
SCRATCH=/state/partition1/dmallo

module load python/2.7.8

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
	id=`echo $(printf "%0${nDigits}d" $1)`
else
	id=`echo $(printf "%0${nDigits}d" $SGE_TASK_ID)`
fi

method=revpomo
echo working on $id
mkdir -p $H/$id/$method
cd $H/$id/$method

$method.tree && echo output already exists. 
$method.tree && exit 1

if [[ ! -s counts.gz ]] || [[ ! -s popsize.txt ]]
then
	##Put the compressed data in the SCRATCH
	mkdir -p $SCRATCH/$id
	tar xvzf $H/$id/seqs.tar.gz -C $SCRATCH/$id --strip-components=1 seqs/concat.phy
	
	##Convert to fasta
	python $(which readseq_DM.py) -i phylip -o fasta $SCRATCH/$id/concat.phy $SCRATCH/$id/concat.fasta
	
	#Get the N size	
	popsize=3
	n_ind=$(cat $SCRATCH/$id/concat.fasta | sed -n "s/>[0-9]\+_[0-9]\+_\([0-9]\+\)/\\1/gp" | sort -nr | uniq | wc -l)
	if [[ $n_ind -gt 3 ]]
	then
		odd=$(( $n_ind % 2 ))
		if [[ $odd -ne 1 ]]
		then
			popsize=$(( $n_ind + 1 ))
		else
			popsize=$n_ind
		fi
		
	fi

	echo $popsize > popsize.txt

	#Translate species names
	sed -i "s/\([0-9]\+\)_\([0-9]\+\)_\([0-9]\+\)/\\1-\\2\\3/g" $SCRATCH/$id/concat.fasta
 
	#we need python3 with a specific environment
	module unload python/2.7.8
	source $PY3ENV_SOURCE
	
	#Convert to counts and save as data to keep (but not use in the analysis)
	FastaToCounts.py $SCRATCH/$id/concat.fasta $SCRATCH/$id/counts.gz
	
	#Copy counts to save
	cp $SCRATCH/$id/counts.gz counts.gz
fi
n_ind=$(cat popsize.txt)
st="CF$n_ind"
#perform analysis
/usr/bin/time -a -o $method.time iqtree -s counts.gz -st $st -m GTR+rP -seed 2222 -pre $method 1> $method.out 2>$method.err

mv $method.treefile $method.tree
rm -rf $SCRATCH/$id

