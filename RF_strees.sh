#!/bin/bash
module load gcc/5.2.0
module load R/3.2.2_1

SCRATCH=/state/partition1/dmallo
SCRIPT_DIR=/home/dmallo/broadsims/new/scripts
H=/home/dmallo/broadsims/new/sim_broadsims
nDigits=5

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

methods=("astral" "greedy" "mpest" "mrl" "njst" "star" "steac")

Rscript $SCRIPT_DIR/RF_strees.R $H/$id ${methods[@]}

