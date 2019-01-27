#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH
#$ -l h_vmem=30G
#$ -l mem_free=30G

H=/home/dmallo/broadsims/new/sim_broadsims
export BIN=/home/dmallo/broadsims/new/scripts/
SCRATCH=/state/partition1/dmallo

module load python/2.7.8
module load java/jdk/1.8.0_31

nDigits=5
seed=2222
MAX_ATTEMPTS=10

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
	id=`echo $(printf "%0${nDigits}d" $((10#$1)))` ##The 10# should avoid octal interpertation
	shift
else
	id=`echo $(printf "%0${nDigits}d" $SGE_TASK_ID)`
fi

if [[ "$#" -ne 1 ]]
then
	exit 1
fi


nloci=$1
method=starbeast2_relaxed_$nloci
echo working on $id
mkdir -p $H/$id/$method
cd $H/$id/$method

analysis_name=${id}_$nloci
run_name=$(printf "%s.%010d" $analysis_name $seed)

touch ${run_name}.incomplete

#Generate input.xml
if [[ ! -f ${run_name}.xml ]]
then
	$BIN/generate_xmls_starbeast.sh $run_name $nloci $seed -e -r
fi

#Generates the first script for the execution of BEAST
n_chain=0
chain_name=$(printf "%s.%03x" $run_name $n_chain)
touch ${run_name}.incomplete
echo -e "#$/bin/bash\npython $BIN/run_beast.py $analysis_name $seed 0" > ${chain_name}.sh
chmod +x ${chain_name}.sh

##If the ESSs of the relevant parameters were not enough (flagged by the run_name.incomplete file), we keep going
##If there was an irreparable error, we stop
while [[ -f ${run_name}.incomplete ]] && [[ ! -f ${run_name}.error ]]
do
	chain_name=$(printf "%s.%03x" $run_name $n_chain)
	touch ${chain_name}.incomplete

	if [[ -f ${chain_name}.sh ]]
	then
		n_attempt=0
		while [[ $n_attempt -lt $MAX_ATTEMPTS ]] && [[ -f ${chain_name}.incomplete ]]
		do
			log_name=$(printf "chain_%s_A.%03d.log" $chain_name $n_attempt)
			./${chain_name}.sh > $log_name 2>&1 ##it removes ${chain_name}.incomplete if OK
			n_attempt=$(($n_attempt+1))
		done
	fi

	if [[ -f ${chain_name}.incomplete ]]
	then
		touch ${run_name}.error
	fi
	n_chain=$(($n_chain+1))
done

#/usr/bin/time -a -o $method.time beast2.4 -beagle_SSE -seed 2222 -overwrite input.xml 1> $method.out 2> $method.err

##Generate a newick version of the MCC tree
python -c '
import os
import sys
import dendropy

src_fpath = os.path.expanduser(os.path.expandvars("'"${run_name}_MCC.tree"'"))
if not os.path.exists(src_fpath):
    sys.stderr.write("Not found: %s" % src_fpath)
    sys.exit(1)

dest_fpath = os.path.expanduser("'"${method}.tree"'")
trees = dendropy.TreeList.get_from_path(src_fpath, "nexus")
trees[-1].write_to_path(dest_fpath, "newick",suppress_rooting=True)'

##Summarize the time spent by all chains in a time -a like output
tail -n+2 ${run_name}.csv | perl -lane '$e+=$F[0];$s+=$F[1];END{print "${e}user ${s}system"}' > ${method}.time

