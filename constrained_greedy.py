### Imports ###
import dendropy
from dendropy import TreeList,Tree,TreeArray,SplitDistribution,Bipartition
from dendropy.utility import constants
import sys
import argparse
import glob
import random
import types

### My functions ###
def constrained_consensus(self,constrainTree=None,
	min_freq=constants.GREATER_THAN_HALF,is_bipartitions_updated=False,
	summarize_splits=True, **kwargs):
	"""
	Returns a consensus tree of all trees in ``self``, with minumum frequency
	of bipartition to be added to the consensus tree given by ``min_freq``.
	It only takes into account bipartitions compatible with the bipartitions
	in constrainTree, i.e., constrainTree is used as a tree backbone.
	"""

	##Consolidating namespaces
	constrainTree.migrate_taxon_namespace(self.taxon_namespace)
	ta=self._get_tree_array(kwargs)

	return ta.constrained_consensus_tree(constrainTree=constrainTree,min_freq=min_freq,summarize_splits=summarize_splits,is_bipartitions_updated=False,**kwargs)

def constrained_consensus_tree_array(self,
	constrainTree,
	min_freq=constants.GREATER_THAN_HALF,
	is_rooted=None,
	summarize_splits=True,
	is_bipartitions_updated=False,
	**split_summarization_kwargs):
	
	if not is_bipartitions_updated:
		constrainTree.encode_bipartitions(suppress_storage=True)

	for lbitmask in self._tree_leafset_bitmasks:
		if lbitmask != constrainTree.seed_node.edge.bipartition.leafset_bitmask:
			raise NotImplementedError
			##I am not sure if this works properly. Trees with two sets of different missing data
			##fail when assessing if they are compatible
	
	tree = self._split_distribution.constrained_consensus_tree(
		constrainTree=constrainTree,
		min_freq=min_freq,
		is_rooted=self.is_rooted_trees,
		summarize_splits=summarize_splits,
		is_bipartitions_updated=False,
		is_bipartitions_constrain_updated=False,
		**split_summarization_kwargs)
	
	return tree

def constrained_consensus_tree_splits(self,
			constrainTree=None,
			min_freq=constants.GREATER_THAN_HALF,
			is_rooted=None,
			summarize_splits=True,
			fill_bitmask=None,
			is_bipartitions_constrain_updated=False,
			**split_summarization_kwargs
			):
	"""
	Returns a consensus tree from splits in ``self``.
	
	Parameters
	----------
	constrainTree : Tree to constrain the consensus method
	
	min_freq : real
		The minimum frequency of a split in this distribution for it to be
		added to the tree.
	
	is_rooted : bool
		Should tree be rooted or not? If *all* trees counted for splits are
		explicitly rooted or unrooted, then this will default to |True| or
		|False|, respectively. Otherwise it defaults to |None|.
	
	fill_bitmask : int
		 Leafset bitmask of the constraint Tree 
	
	\*\*split_summarization_kwargs : keyword arguments
		These will be passed directly to the underlying
		`SplitDistributionSummarizer` object. See
		:meth:`SplitDistributionSummarizer.configure` for options.
	
	Returns
	-------
	t : consensus tree
	
	"""
	
	assert constrainTree.taxon_namespace is self.taxon_namespace

	if is_rooted is None:
		if constrainTree.is_rooted & self.is_all_counted_trees_rooted():
			is_rooted = True
		elif constrainTree.is_unrooted & self.is_all_counted_trees_strictly_unrooted():
			is_rooted = False
 
	constraintSplits = SplitDistribution(taxon_namespace=constrainTree.taxon_namespace)
	constraintSplits.count_splits_on_tree(
					tree=constrainTree,
					is_bipartitions_updated=is_bipartitions_constrain_updated,
					default_edge_length_value=None)
	fill_bitmask=constrainTree.seed_node.edge.bipartition._leafset_bitmask	
	
	split_frequencies = self._get_split_frequencies()
	to_try_to_add = []
	_almost_one = lambda x: abs(x - 1.0) <= 0.0000001
	for s in split_frequencies:
		freq = split_frequencies[s]
		if (min_freq is None) or (freq >= min_freq) or (_almost_one(min_freq) and _almost_one(freq)):
			to_try_to_add.append((freq, s))

	to_try_to_add.sort(reverse=True)
	
	##We initiate the list with the constraintSplits
	splits_for_tree = [i for i in constraintSplits]
	splits_for_tree.extend([i[1] for i in to_try_to_add])

	con_tree = Tree.from_split_bitmasks(
			split_bitmasks=splits_for_tree,
			taxon_namespace=self.taxon_namespace,
			is_rooted=is_rooted)

	if summarize_splits:
		self.summarize_splits_on_tree(
			tree=con_tree,
			is_bipartitions_updated=False,
			**split_summarization_kwargs
			)
	return con_tree

##Extending the original Dendropy Classes
TreeList.constrained_consensus=constrained_consensus
TreeArray.constrained_consensus_tree=constrained_consensus_tree_array
SplitDistribution.constrained_consensus_tree=constrained_consensus_tree_splits

### Main ###

### Argparse
parser = argparse.ArgumentParser(description="Implementation of a constrained greedy consensus",prog="constrained_greedy.py")
parser.add_argument("-i",type=str,help="Newick input gene trees",metavar="input")
parser.add_argument("-c",type=str,help="Tree to constrain the search ala RAxML's -g",metavar="constrain")
parser.add_argument("-o",type=str,help="Output file name",metavar="output")
#parser.add_argument("-s",type=int,help="Random number generator seed",metavar="seed")
args = parser.parse_args()

###Random number machinery initialization
#if args.s:
#	seed=args.s
#else:
#	seed=random.randint(0,sys.maxint)

#random.seed(seed)
#print("Seed: %d" % seed)

###Input trees
gene_trees=TreeList.get(path=args.i,schema="newick",rooting="force-unrooted")
constrainTree=Tree.get(path=args.c,schema="newick")
consensus=gene_trees.constrained_consensus(constrainTree=constrainTree,summarize_splits=False,min_freq=0)

#Write gene trees
consensus.write(path=args.o,schema="newick",suppress_rooting=True)
print("Done!")
