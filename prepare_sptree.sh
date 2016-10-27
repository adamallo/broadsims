#!/bin/bash

HOME=/home/dmallo/broadsims/new/sim_broadsims
ROOTING_APP=/home/dmallo/bin/smirarab_src/mirphyl/utils/reroot.py
cd $HOME

export PYTHONPATH=/home/dmallo/smirarab_dendropy/DendroPy ##Loading an outdated DendroPy version that works with the rooting script

for i in *  #complete
do
	if [[ $i = "00001" || $i = "00002" || $i = "00003" ]]
	then
		echo "Skipping the first folder\n"
	elif [[ -d $i ]]
	then
		cd $i
		echo $(pwd)
		cat RAxML_bestTree* > gtrees_estimated.trees.temp
		python $ROOTING_APP gtrees_estimated.trees.temp 0_0_0 gtrees_estimated.trees
		#each method will have its folder. They will make them on their own
		mkdir data
		mv gtrees_estimated.trees.temp.rooted gtrees_estimated.trees
		mv gtrees_estimated.trees data
		mkdir true_trees
		mv g_trees* true_trees
		mkdir seqs
		mv *.phy* seqs
		mv control.txt seqs
		mv LOG.txt seqs
		mkdir raxml_gtrees
		mv RAxML* raxml_gtrees
		mv *g_tree.time raxml_gtrees
		mv constraintTree.trees raxml_gtrees
		mv s_tree.trees true_trees
		rm -f gtrees_estimated.trees.temp
		tar -cvzf seqs.tar.gz seqs
		tar -cvzf raxml_gtrees.tar.gz raxml_gtrees
		#tar -cvzf true_trees.tar.gz true_trees
		#Be 100% sure this works until deleting anything!
		rm -rf seqs
		rm -rf raxml_gtrees
		#rm -rf true_trees
		#for each method we will have a method.tree output with the estimated species tree
		cd ..
	fi
done
