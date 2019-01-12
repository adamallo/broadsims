#!/bin/bash
module load perl/5.22.1

H=/home/dmallo/broadsims/new/sim_broadsims
BIN=/home/dmallo/broadsims/new/scripts/
SCRATCH=/state/partition1/dmallo
nloci=50
usage="$0 id\n The id option $1 is not valid"


id=$1

if [[ ! -d $H/$id ]]
then
	echo "$usage"
	exit 1
fi

mkdir $H/$id/starbeast2/

#if [[ ! -d  $H/$id/seqs ]]
#then
	mkdir $SCRATCH/
	mkdir $SCRATCH/$id
	tar xvzf $H/$id/seqs.tar.gz -C $SCRATCH/$id --strip-components=1 seqs/*TRUE.phy
	perl $BIN/makeXmlStarBeast2.pl -i $SCRATCH/$id -o $H/$id/starbeast2/input.xml -n ${id}_50 --maxloci 50
	rm -rf $SCRATCH/$id
#else
#	perl $BIN/makeXmlStarBeast2.pl -i $H/$id/seqs -o $H/$id/starbeast2/input.xml -n ${id}_50 --maxloci 50
#fi
