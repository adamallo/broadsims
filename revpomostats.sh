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

cd $H/$id/revpomo

rep=$id

echo "rep,etheta,etlength,etlengthsubs,etintlenght,etintlengthsubs" > ../data/sumrevpomo.csv

if [[ -f "revpomo.iqtree" ]]
then

	theta=$(cat revpomo.iqtree | sed -n "s/Watterson Theta:\s*\([^ ]\+\).*/\1/p")
	tlength=$(cat revpomo.iqtree | sed -n "s/ - measured in number of mutations and frequency shifts per site:\s*\([^ ]\+\).*/\1/p")
	tlengthsubs=$(cat revpomo.iqtree | sed -n "s/ - measured in number of substitutions per site (divided by N^2):\s*\([^ ]\+\).*/\1/p")
	tintlength=$(cat revpomo.iqtree | sed -n "s/- measured in mutations and frequency shifts per site:\s*\([^( ]*\).*/\1/p")
	tintlengthsubs=$(cat revpomo.iqtree | sed -n "s/- measured in substitutions per site:\s*\([^( ]*\).*/\1/p")
	echo "$rep,$theta,$tlength,$tlengthsubs,$tintlength,$tintlengthsubs" >> ../data/sumrevpomo.csv
else
	echo "$rep,NA,NA,NA,NA,NA" >> ../data/sumrevpomo.csv
fi
