#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

H=/home/dmallo/broadsims/new/sim_broadsims
BIN=/home/dmallo/broadsims/new/scripts/
SCRATCH=/state/partition1/dmallo

module load python/2.7.8

nloci=50
nDigits=5

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
	id=`echo $(printf "%0${nDigits}d" $((10#$1)))` ##The 10# should avoid octal interpertation
else
	id=`echo $(printf "%0${nDigits}d" $SGE_TASK_ID)`
fi

method=starbeast2
echo working on $id
mkdir -p $H/$id/$method
cd $H/$id/$method

#Generate input.xml
if [[ ! -f input.xml ]]
then
	$BIN/generate_xmls_starbeast.sh $id
fi

/usr/bin/time -a -o $method.time beast2.4 -beagle_SSE -seed 2222 -overwrite input.xml 1> $method.out 2> $method.err

##This may not work
##Treeannotator
treeannotator -b 10 species.trees ${method}.tree.nex

##From nexus to newick
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

