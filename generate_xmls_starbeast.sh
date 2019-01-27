#!/bin/bash
module load perl/5.22.1

BIN=/home/dmallo/broadsims/new/scripts/
SCRATCH=/state/partition1/dmallo
usage="$0 name nloci seed\n"

if [[ "$#" -lt 3 ]]
then
	echo -e $usage
	exit 1
fi

name=$1
nloci=$2
seed=$3

shift 3

if [[ ! -d  ../seqs ]] && [[ -f ../seqs.tar.gz ]]
then
	mkdir -p $SCRATCH/$name
	tar xvzf ../seqs.tar.gz -C $SCRATCH/$name --strip-components=1 seqs/*TRUE.phy
	perl $BIN/makeXmlStarBeast2_clock.pl -i $SCRATCH/$name -o ${name}.xml -n $name --maxloci $nloci --seed $seed $@
	rm -rf $SCRATCH/$name
elif [[ -f ../seqs.tar.gz ]]
then
	perl $BIN/makeXmlStarBeast2_clock.pl -i ../seqs -o ${name}.xml -n $name --maxloci $nloci --seed $seed $@
else
	echo "ERROR: original sequences not found"
	exit 1
fi
