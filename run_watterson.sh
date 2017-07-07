#!/bin/bash

H=/home/dmallo/broadsims/new/sim_broadsims
nDigits=5
SCRATCH=/state/partition1/dmallo

if [ "$SGE_TASK_ID" == "" ] || [ "$SGE_TASK_ID" == "undefined" ]
then
        if [ $# -ne 1 ]
        then
                echo -e "USAGE: $0 [id]\nUse the id if you are not using a job array. Otherwise the id will be obtained from the jobid\n"
                exit
        fi
        id=$1
        shift
else
        id=$SGE_TASK_ID
        id=$(printf "%0${nDigits}d" $id)
fi

mkdir -p $SCRATCH/$id
tar xvzf $H/$id/seqs.tar.gz -C $SCRATCH/$id --strip-components=1 seqs/*.phy
module load R/3.2.2_1
module load gcc/5.2.0

Rscript $H/../scripts/watterson.R $SCRATCH/$id $H/$id
rm -rf $SCRATCH/$id
