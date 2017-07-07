#!/opt/local/bin/python

### Imports ###
import dendropy
from dendropy import TreeList,Tree
import sys
import argparse
from os import walk
import glob
from collections import defaultdict
import re

### Main ###

### Argparse
parser = argparse.ArgumentParser(description="Converts a newick tree file in a Nexus file",prog="newicktonexusphylonet.py")
parser.add_argument("-i",required=True,type=str,help="Input newick tree name")
parser.add_argument("-o",required=True,type=str,help="Output file name")
args = parser.parse_args()

###Main
itrees=TreeList.get(path=args.i,schema="newick",rooting="default-rooted",preserve_underscores=True)
itrees.write(path=args.o,schema="nexus",unquoted_underscores=True,suppress_rooting=True)
namespace=itrees.taxon_namespace
labels=namespace.labels()
regex=re.compile("(.+)_.+_.+")
speciesmap=defaultdict(list)

for label in labels:
	match=regex.match(label).group(1)
	speciesmap[match].append(label)

textlisttrees="("+",".join(str(x) for x in xrange(1,len(itrees)+1))+")"
textspeciesmap="<"+";".join([ species+":"+",".join(speciesmap[species]) for species in speciesmap ])+">"
with open(args.o,"a") as f:
	f.write("BEGIN PHYLONET;\ninfer_ST_MDC " + textlisttrees + " -a " + textspeciesmap + " mdc_temp.tree;\nEND;")
print("Done!")
