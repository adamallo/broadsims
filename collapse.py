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
	mrca_node.clear_child_nodes()
	taxon=Taxon(specie)
	mrca_node.taxon=taxon
	newNamespace.add_taxon(taxon)

tree.taxon_namespace=newNamespace
tree.write(path=args.o,schema="newick",suppress_rooting=True)
#
#
#if args.gt != 0:
#        print "Scaling branch lengths to time with generation time %d\n" % args.gt
#        for tree in trees:
#                for edge in tree.preorder_edge_iter():
#                        #print "DEBUG: %s" % edge.length
#                        if edge.length != None:
#                                edge.length=edge.length/args.gt
#
#if args.od != 0:
#        print "Adding outgroup with branch length %d\n" % args.od
#        namespace=trees.taxon_namespace
#        outgroup= Taxon("outgroup")
#        namespace.add_taxon(outgroup)
#        ntree=0
#        labels=namespace.labels()
#        labels.remove("outgroup")
#        for tree in trees:
#                outgroup_node=Node(taxon=outgroup,edge_length=args.od)
#                new_root_node=Node()
#                tree.seed_node.edge_length=args.od-tree.seed_node.distance_from_tip()
#                new_root_node.add_child(tree.seed_node)
#                new_root_node.add_child(outgroup_node)
#                tree.seed_node=new_root_node

