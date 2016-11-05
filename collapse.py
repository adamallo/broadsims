import dendropy
from dendropy import TreeList,Tree,Taxon,Node
import sys
import argparse
import re

parser = argparse.ArgumentParser(description="Parses a Newick tree file and writes another with subtrees formed by the same species collapsed. It assumes that all samples for each species form a monophyletic group. Leave names are expected to follow the scheme species_\d+_\d+")
parser.add_argument("-i",type=str,default="infile.tree",required=True,help="Input Newick tree file")
parser.add_argument("-o",type=str,default="outtree.tree",required=False,help="Output Newick tree file")
args = parser.parse_args()

tree=Tree.get_from_path(args.i,schema="newick",rooting="force-unrooted")
namespace=tree.taxon_namespace
labels=namespace.labels()
regex=re.compile("(.+) .+ .+")
species=[match.group(1) for label in labels for match in [regex.match(label)] if match]
species_set=set(species)
species=list(species_set)
newNamespace=dendropy.datamodel.taxonmodel.TaxonNamespace()

for specie in species:
	regex=re.compile(specie + " .+ .+")
	leaves=[match.group(0) for label in labels for match in [regex.match(label)] if match]
	mrca_node=tree.mrca(taxon_labels=leaves)
	del mrca_node._child_nodes[:]
	taxon=Taxon(specie)
	mrca_node.taxon=taxon
	newNamespace.add_taxon(taxon)

tree.taxon_namespace=newNamespace
tree.write(path=args.o,schema="newick",suppress_rooting=True)

