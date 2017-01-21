use warnings;
use strict;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

#Config
#######
my $chaintype="MCMC";
my $chainlength="20000000";
my $logperiod="10000";##For all written logs
my $logscreenperiod="50000";##STDOUT
my $storeperiod="50000";##Backup state to resume afterwards if necessary
my $ploidy=1;
my $outname="outname";
my $input_dir="";
my $outfile="";
my $help;
my $nloci=0;
my $seed=20;

my $usage="Usage: $0 [options] -i input_dir -o output_file -n outputlog_name\n\nThis script generates a StarBeast2 XMl file out of alignment files present in a folder. Those must be in Phylip format. This script has not been tested for missing data (all gene trees are expected to have the same taxa). Quick description of the model: Yule Species Tree with birth rate prior U(-inf,10000).Multispecies coalescent model with one strict rate (prior lognormal 1,1)per gene tree (ploidy 1) and analytical integration of population sizes. Population sizes prior Gamma with shape 3 and mean 1/X.GTR+G substitution model with 4 discretized rates, (G prior Exp(1)), (GTR rates prior, Gamma(0.05,10) except AG Gamma(0.05,20).\n\nOptions\n---------\n--logperiod: period for all written logs.\n--logscreenperiod: period for screen log.\n--storeperiod: period for the storage of the MCMC state\n-s/--seed: seed for the pseudo-random number generator\n--maxloci: only consider a random sample of this specified number of loci without replacement\n\n";

######
#Main
###################

##Getopt
######################################################
(! GetOptions(
	'i=s' => \$input_dir,
	'output_file|o=s' => \$outfile,
	'outputlog_name|n=s' => \$outname,
	'logperiod=i' => \$logperiod,
	'logscreenperiod=i' => \$logscreenperiod,
	'storeperiod=i' => \$storeperiod,
	'maxloci=i' => \$nloci,
	'seed|s=i' => \$seed,
	'help|h' => \$help,
)) or (($input_dir eq "") || ($outfile eq "") || $help) and die $usage;

srand($seed);

open(my $XML,">$outfile") or die "The file $outfile can't be opened for writting\n";

##Header
print($XML '<?xml version="1.0" encoding="UTF-8" standalone="no"?><beast beautitemplate=\'StarBeast2\' beautistatus=\'noAutoSetClockRate\' namespace="beast.core:beast.evolution.alignment:beast.evolution.tree.coalescent:beast.core.util:beast.evolution.nuc:beast.evolution.operators:beast.evolution.sitemodel:beast.evolution.substitutionmodel:beast.evolution.likelihood" required="starbeast2 v0.13.1" version="2.4">');

##Distribution counters
#######################
our $nUniform=0;
our $nExponential=0;
our $nLogNormal=0;
our $nNormal=0;
our $nBeta=0;
our $nGamma=0;
our $nLaplaceDistribution=0;
our $nInverseGamma=0;
our $nOneOnX=0;
our $iSeq=0;

##Loop variables
################
my %species;
my @loci;
my $sp_regex=qr/^(.*)_[0-9]+_[0-9]+$/;
my $taxon;
my $sequence;
my $nseqs;
my $alLength;
my $header;
my @alignment;
my $filename;
my $sp;

##XML DATA
###########

my @tempfiles= <$input_dir/*>;
my @files;
if ($nloci != 0 and $nloci < scalar(@tempfiles))
{
	print("Sampling $nloci out of ",scalar @tempfiles,"\n");
	for (my $i=0; $i<$nloci;++$i)
	{
		push(@files,splice(@tempfiles,rand(@tempfiles),1));
	}
	print("List of selected loci: ",join(",",@files),"\n");
}
else
{
	@files=@tempfiles;
	$nloci=scalar @files;
}

foreach my $file (@files)
{
	$filename= ($file=~s/^.*\/(.*)\.[^.]+$/$1/r);
	push(@loci,$filename);
	print ($XML "\n<data id=\"$filename\" name=\"alignment\">\n");
	open(my $FILE,$file) or die "Error opening the file $file";
	@alignment=<$FILE>;
	close($FILE);
	$header=shift(@alignment);
	($nseqs,$alLength)=split(" ",$header);
	
	for (my $n=0; $n<$nseqs; ++$n)
	{
		no warnings 'uninitialized'; ##++ operator on undefined values always use them as 0

		($taxon,$sequence)=split(" ",$alignment[$n]);
		$sp= ($taxon =~ s/$sp_regex/$1/r);

		##Sp/taxa hash for later
		unless (exists $species{$sp})
		{
			$species{$sp}={$taxon => 1}; #New anonymous hash
		}
		else
		{
			$species{$sp}{$taxon}++; ##This is replicating %taxa but split by species. I do need the secondary array in order to make it more efficient to "push unique values into the array".
		}
		
		print ($XML "\t<sequence id=\"${taxon}_$iSeq\" taxon=\"$taxon\" totalcount=\"4\" value=\"$sequence\"/>\n"); ##Missing data candidate. Untested
		$iSeq+=1;
	}
	print($XML "</data>\n\n");	
}

my $distributions= << 'HEREDOC';
<map name="Uniform" >beast.math.distributions.Uniform</map>
<map name="Exponential" >beast.math.distributions.Exponential</map>
<map name="LogNormal" >beast.math.distributions.LogNormalDistributionModel</map>
<map name="Normal" >beast.math.distributions.Normal</map>
<map name="Beta" >beast.math.distributions.Beta</map>
<map name="Gamma" >beast.math.distributions.Gamma</map>
<map name="LaplaceDistribution" >beast.math.distributions.LaplaceDistribution</map>
<map name="prior" >beast.math.distributions.Prior</map>
<map name="InverseGamma" >beast.math.distributions.InverseGamma</map>
<map name="OneOnX" >beast.math.distributions.OneOnX</map>
HEREDOC

print($XML "$distributions\n\n"); ##Distribution aliases

##XML CONFIGURATION 
####################

##Note: there is a bit of overload splitting prints to make the code more readable.

print($XML "<run id=\"mcmc\" spec=\"$chaintype\" chainLength=\"$chainlength\" storeEvery=\"$storeperiod\">\n");

	print($XML "\t<state id=\"state\" storeEvery=\"$storeperiod\">\n");##All components of the chain state (parameters and trees)

		#The species tree, statenode specified by the package StarBeast2
		print($XML "\t\t<stateNode id=\"Tree.t:Species\" spec=\"starbeast2.SpeciesTree\">\n");
		
			print($XML "\t\t\t<taxonset id=\"taxonsuperset\" spec=\"TaxonSet\">\n"); ##Species tree taxonSet
			foreach my $sp (keys %species)
			{
				print ($XML "\t\t\t\t<taxon id=\"$sp\" spec=\"TaxonSet\">\n"); ##Species TaxonSet
				foreach my $taxon (keys %{$species{$sp}})
				{
					print($XML "\t\t\t\t\t<taxon id=\"$taxon\" spec=\"Taxon\"/>\n"); ##Leaf taxon 
				}
				print($XML "\t\t\t\t</taxon>\n");
			}
			print($XML "\t\t\t</taxonset>\n");

		print($XML "\t\t</stateNode>\n");
		
		##Other Species tree parameters
		print($XML "\t\t<parameter id=\"speciationRate.t:Species\" lower=\"0.0\" name=\"stateNode\">1.0</parameter>\n");
		print($XML "\t\t<parameter id=\"popMean.Species\" lower=\"0.0\" name=\"stateNode\">1.0</parameter>\n");

		##Loop for each gene tree with its alignment taxon set
		foreach my $locus (@loci)
		{
			#Gene tree
			print($XML "\t\t<tree id=\"Tree.t:$locus\" name=\"stateNode\">\n");
				print($XML "\t\t\t<taxonset id=\"TaxonSet.$locus\" spec=\"TaxonSet\">\n");#Taxa
					print($XML "\t\t\t\t<alignment idref=\"$locus\"/>\n");#Alignment
				print($XML "\t\t\t</taxonset>\n");
			print($XML "\t\t</tree>\n");

			#ClockRate
			print($XML "\t\t<parameter id=\"clockRate.c:$locus\" lower=\"0.0\" name=\"stateNode\">1.0</parameter>\n");
			
			#Substitution process parameteres
			print($XML "\t\t<parameter id=\"gammaShape.s:$locus\" name=\"stateNode\">1.0</parameter>\n"); #Site heterogeneity
			print($XML "\t\t<parameter id=\"freqParameter.s:$locus\" dimension=\"4\" lower=\"0.0\" upper=\"1.0\" name=\"stateNode\">0.25</parameter>\n"); #Frequencies
			print($XML "\t\t<parameter id=\"rateAC.s:$locus\" lower=\"0.001\" name=\"stateNode\">1.0</parameter>\n"); #Relative rates
			print($XML "\t\t<parameter id=\"rateAG.s:$locus\" lower=\"0.001\" name=\"stateNode\">1.0</parameter>\n");
			print($XML "\t\t<parameter id=\"rateAT.s:$locus\" lower=\"0.001\" name=\"stateNode\">1.0</parameter>\n");
			print($XML "\t\t<parameter id=\"rateCG.s:$locus\" lower=\"0.001\" name=\"stateNode\">1.0</parameter>\n");
			print($XML "\t\t<parameter id=\"rateGT.s:$locus\" lower=\"0.001\" name=\"stateNode\">1.0</parameter>\n");	
		}

	print($XML "\t</state>\n");
	
	#StarBeast initialization	
	print($XML "\t<init id=\"SBI\" spec=\"starbeast2.StarBeastInitializer\" birthRate=\"\@speciationRate.t:Species\" estimate=\"false\" speciesTree=\"\@Tree.t:Species\">\n");
	foreach my $locus (@loci)
	{
		print($XML "\t\t<geneTree idref=\"Tree.t:$locus\"/>\n");
	}
		##StarBeast analytical population size integration
		print($XML "\t\t<populationModel id=\"popModelBridge.Species\" spec=\"starbeast2.PassthroughModel\">\n");
			print($XML "\t\t\t<childModel id=\"constantPopIOModel.Species\" spec=\"starbeast2.DummyModel\"/>\n");
		print($XML "\t\t</populationModel>\n");
	print($XML "\t</init>\n");

	#Posterior
	print($XML "\t<distribution id=\"posterior\" spec=\"util.CompoundDistribution\">\n");
		#SpeciesCoalescent likelihood
		print($XML "\t\t<distribution id=\"speciescoalescent\" spec=\"starbeast2.MultispeciesCoalescent\" populationMean=\"\@popMean.Species\">\n");#MSC prior
			print($XML "\t\t\t<parameter id=\"popShape.Species\" estimate=\"false\" lower=\"0.0\" name=\"populationShape\">3.0</parameter>\n"); #Prior for the distribution of population sizes. I think this is the conjugate prior for the analytical population size integration
			foreach my $locus (@loci)
			{
				#Gene trees
				print($XML "\t\t\t<distribution id=\"geneTree.t:$locus\" spec=\"starbeast2.GeneTree\" ploidy=\"$ploidy\" populationModel=\"\@popModelBridge.Species\" speciesTree=\"\@Tree.t:Species\" tree=\"\@Tree.t:$locus\"/>\n");

			}
		print ($XML "\t\t</distribution>\n");
		
		#Prior
		print($XML "\t\t<distribution id=\"prior\" spec=\"util.CompoundDistribution\">\n");
			#Stree-related
			print($XML "\t\t\t<distribution id=\"YuleModel.t:Species\" spec=\"beast.evolution.speciation.YuleModel\" birthDiffRate=\"\@speciationRate.t:Species\" tree=\"\@Tree.t:Species\"/>\n"); #Species tree Yule process
			print($XML pushUniform(3,"speciationRatePrior.t:Species","\@speciationRate.t:Species",undef,"10000.0")); #Birth rate
			print($XML pushOneOnX(3,"popMeanPrior.Species","\@popMean.Species"));#Mean population size
	
			#Gene-tree related
			foreach my $locus (@loci)
			{
				#Clock
				print($XML pushLogNormal(3,"clockRatePrior.c:$locus","\@clockRate.c:$locus","1.0","1.0"));
				
				#SiteHeter
				print($XML pushExponential(3,"GammaShapePrior.s:$locus","\@gammaShape.s:$locus","1.0"));
	
				#RelativeRates
				print($XML pushGamma(3,"RateACPrior.s:$locus","\@rateAC.s:$locus","0.05","10"));
				print($XML pushGamma(3,"RateAGPrior.s:$locus","\@rateAG.s:$locus","0.05","20"));
				print($XML pushGamma(3,"RateATPrior.s:$locus","\@rateAT.s:$locus","0.05","10"));
				print($XML pushGamma(3,"RateCGPrior.s:$locus","\@rateCG.s:$locus","0.05","10"));
				print($XML pushGamma(3,"RateGTPrior.s:$locus","\@rateGT.s:$locus","0.05","10"));

			}
		print($XML "\t\t</distribution>\n");
		
		#Gene-tree Likelihood for all gene trees
		print($XML "\t\t<distribution id=\"likelihood\" spec=\"util.CompoundDistribution\">\n");
		foreach my $locus (@loci)
		{
			#Likelihood of each gene tree
			print($XML "\t\t\t<distribution id=\"treeLikelihood.$locus\" spec=\"TreeLikelihood\" data=\"\@$locus\" tree=\"\@Tree.t:$locus\">\n");
				#Site Model
				print($XML "\t\t\t\t<siteModel id=\"SiteModel.s:$locus\" spec=\"SiteModel\" gammaCategoryCount=\"4\" shape=\"\@gammaShape.s:$locus\">\n");
					print($XML "\t\t\t\t\t<parameter id=\"mutationRate.s:$locus\" estimate=\"false\" name=\"mutationRate\">1.0</parameter>\n"); #Mutation rate fixed, since we do not have dates. The independent gene tree rates are estimated at the clock level.
					print($XML "\t\t\t\t\t<parameter id=\"proportionInvariant.s:$locus\" estimate=\"false\" lower=\"0.0\" name=\"proportionInvariant\" upper=\"1.0\">0.0</parameter>\n"); #No invariants
					print($XML "\t\t\t\t\t<substModel id=\"gtr.s:$locus\" spec=\"GTR\" rateAC=\"\@rateAC.s:$locus\" rateAG=\"\@rateAG.s:$locus\" rateAT=\"\@rateAT.s:$locus\" rateCG=\"\@rateCG.s:$locus\" rateGT=\"\@rateGT.s:$locus\">\n"); #Substitution model
						print($XML "\t\t\t\t\t\t<parameter id=\"rateCT.s:$locus\" estimate=\"false\" lower=\"0.001\" name=\"rateCT\">1.0</parameter>\n"); ##Lacking dummy parameter added here since we are estimating the relative rates relative to CT.
						print($XML "\t\t\t\t\t\t<frequencies id=\"estimatedFreqs.s:$locus\" spec=\"Frequencies\" frequencies=\"\@freqParameter.s:$locus\"/>\n"); #Frequencies

					print($XML "\t\t\t\t\t</substModel>\n");
                                               
				print($XML "\t\t\t\t</siteModel>\n");
				#Clock model
				print($XML "\t\t\t\t<branchRateModel id=\"StrictClock.c:$locus\" spec=\"beast.evolution.branchratemodel.StrictClockModel\" clock.rate=\"\@clockRate.c:$locus\"/>\n");
			print($XML "\t\t\t</distribution>\n");
		}
		print($XML "\t\t</distribution>\n");

	print($XML "\t</distribution>\n");
	
	#Operators
	##########

	#Coordinated operators
	
	print($XML "\t<operator id=\"Reheight.t:Species\" spec=\"starbeast2.NodeReheight2\" taxonset=\"\@taxonsuperset\" tree=\"\@Tree.t:Species\" weight=\"36.533505154639165\">\n");
	foreach my $locus (@loci)
	{
		print($XML "\t\t<geneTree idref=\"geneTree.t:$locus\"/>\n");
	}
	print($XML "\t</operator>\n");

	print($XML "\t<operator id=\"coordinatedUniform.t:Species\" spec=\"starbeast2.CoordinatedUniform\" speciesTree=\"\@Tree.t:Species\" weight=\"7.3067010309278375\">\n");
	foreach my $locus (@loci)
	{
		print($XML "\t\t<geneTree idref=\"Tree.t:$locus\"/>\n");
	}
	print($XML "\t</operator>\n");
	
	print($XML "\t<operator id=\"coordinatedExponential.t:Species\" spec=\"starbeast2.CoordinatedExponential\" speciesTree=\"\@Tree.t:Species\" weight=\"7.3067010309278375\">\n");
	foreach my $locus (@loci)
	{
		print($XML "\t\t<geneTree idref=\"Tree.t:$locus\"/>\n");
	}
	print($XML "\t</operator>\n");

	#Species tree operators
	print($XML "\t<operator id=\"TreeScaler.t:Species\" spec=\"ScaleOperator\" scaleFactor=\"0.95\" tree=\"\@Tree.t:Species\" weight=\"1.461340206185568\"/>\n");
	print($XML "\t<operator id=\"TreeRootScaler.t:Species\" spec=\"ScaleOperator\" rootOnly=\"true\" scaleFactor=\"0.7\" tree=\"\@Tree.t:Species\" weight=\"1.461340206185568\"/>\n");
	print($XML "\t<operator id=\"UniformOperator.t:Species\" spec=\"Uniform\" tree=\"\@Tree.t:Species\" weight=\"7.3067010309278375\"/>\n");
	print($XML "\t<operator id=\"SubtreeSlide.t:Species\" spec=\"SubtreeSlide\" size=\"0.002\" tree=\"\@Tree.t:Species\" weight=\"7.3067010309278375\"/>\n");
	print($XML "\t<operator id=\"Narrow.t:Species\" spec=\"Exchange\" tree=\"\@Tree.t:Species\" weight=\"7.3067010309278375\"/>\n");
	print($XML "\t<operator id=\"Wide.t:Species\" spec=\"Exchange\" isNarrow=\"false\" tree=\"\@Tree.t:Species\" weight=\"7.3067010309278375\"/>\n");
	print($XML "\t<operator id=\"WilsonBalding.t:Species\" spec=\"WilsonBalding\" tree=\"\@Tree.t:Species\" weight=\"7.3067010309278375\"/>\n");
	print($XML "\t<operator id=\"speciationRateScale.t:Species\" spec=\"ScaleOperator\" parameter=\"\@speciationRate.t:Species\" scaleFactor=\"0.5\" weight=\"0.48711340206185655\"/>\n");
	print($XML "\t<operator id=\"popMeanScale.Species\" spec=\"ScaleOperator\" parameter=\"\@popMean.Species\" scaleFactor=\"0.75\" weight=\"0.48711340206185655\"/>\n");
	
	#All trees
	print($XML "\t<operator id=\"updown.all.Species\" spec=\"UpDownOperator\" scaleFactor=\"0.75\" weight=\"2.922680412371136\">\n");#This may need to be reorganized
		print($XML "\t\t<up idref=\"speciationRate.t:Species\"/>\n");
		print($XML "\t\t<down idref=\"Tree.t:Species\"/>\n");
		print($XML "\t\t<down idref=\"popMean.Species\"/>\n");
		foreach my $locus (@loci)
		{
			print($XML "\t\t<up idref=\"clockRate.c:$locus\"/>\n");
			print($XML "\t\t<down idref=\"Tree.t:$locus\"/>\n");
		}
	print($XML "\t</operator>\n");
	
	#By gene tree
	foreach my $locus (@loci)
	{
		#Tree operators
		print($XML "\t<operator id=\"TreeScaler.t:$locus\" spec=\"ScaleOperator\" scaleFactor=\"0.95\" tree=\"\@Tree.t:$locus\" weight=\"3.0\"/>\n");
		print($XML "\t<operator id=\"TreeRootScaler.t:$locus\" spec=\"ScaleOperator\" rootOnly=\"true\" scaleFactor=\"0.7\" tree=\"\@Tree.t:$locus\" weight=\"3.0\"/>\n");
		print($XML "\t<operator id=\"UniformOperator.t:$locus\" spec=\"Uniform\" tree=\"\@Tree.t:$locus\" weight=\"15.0\"/>\n");
		print($XML "\t<operator id=\"SubtreeSlide.t:$locus\" spec=\"SubtreeSlide\" size=\"0.002\" tree=\"\@Tree.t:$locus\" weight=\"15.0\"/>\n");
		print($XML "\t<operator id=\"Narrow.t:$locus\" spec=\"Exchange\" tree=\"\@Tree.t:$locus\" weight=\"15.0\"/>\n");
		print($XML "\t<operator id=\"Wide.t:$locus\" spec=\"Exchange\" isNarrow=\"false\" tree=\"\@Tree.t:$locus\" weight=\"15.0\"/>\n");
		print($XML "\t<operator id=\"WilsonBalding.t:$locus\" spec=\"WilsonBalding\" tree=\"\@Tree.t:$locus\" weight=\"15.0\"/>\n");
		print($XML "\t<operator id=\"clockRateScaler.c:$locus\" spec=\"ScaleOperator\" parameter=\"\@clockRate.c:$locus\" scaleFactor=\"0.5\" weight=\"3.0\"/>\n");
		print($XML "\t<operator id=\"clockUpDownOperator.c:$locus\" spec=\"UpDownOperator\" scaleFactor=\"0.95\" weight=\"3.0\">\n");
			print($XML "\t\t<up idref=\"clockRate.c:$locus\"/>\n");
			print($XML "\t\t<down idref=\"Tree.t:$locus\"/>\n");
		print($XML "\t</operator>\n");
		
		#Substitution operators	
    		print($XML "\t<operator id=\"gammaShapeScaler.s:$locus\" spec=\"ScaleOperator\" parameter=\"\@gammaShape.s:$locus\" scaleFactor=\"0.75\" weight=\"1.0\"/>\n");
		print($XML "\t<operator id=\"RateACScaler.s:$locus\" spec=\"ScaleOperator\" parameter=\"\@rateAC.s:$locus\" scaleFactor=\"0.75\" weight=\"1.0\"/>\n");
		print($XML "\t<operator id=\"RateAGScaler.s:$locus\" spec=\"ScaleOperator\" parameter=\"\@rateAG.s:$locus\" scaleFactor=\"0.75\" weight=\"1.0\"/>\n");
		print($XML "\t<operator id=\"RateATScaler.s:$locus\" spec=\"ScaleOperator\" parameter=\"\@rateAT.s:$locus\" scaleFactor=\"0.75\" weight=\"1.0\"/>\n");
		print($XML "\t<operator id=\"RateCGScaler.s:$locus\" spec=\"ScaleOperator\" parameter=\"\@rateCG.s:$locus\" scaleFactor=\"0.75\" weight=\"1.0\"/>\n");
		print($XML "\t<operator id=\"RateGTScaler.s:$locus\" spec=\"ScaleOperator\" parameter=\"\@rateGT.s:$locus\" scaleFactor=\"0.75\" weight=\"1.0\"/>\n");
		print($XML "\t<operator id=\"FrequenciesExchanger.s:$locus\" spec=\"DeltaExchangeOperator\" delta=\"0.08\" weight=\"1.5\">\n");
			print($XML "\t\t<parameter idref=\"freqParameter.s:$locus\"/>\n");
		print($XML "\t</operator>\n");
	}
	
	#Screen logger
	print($XML "\t<logger id=\"screenlog\" logEvery=\"$logscreenperiod\" model=\"\@posterior\">\n");
        	print($XML "\t\t<log idref=\"posterior\"/>\n");
		print($XML "\t\t<log id=\"ESS.0\" spec=\"util.ESS\" arg=\"\@posterior\"/>\n");
		print($XML "\t\t<log idref=\"likelihood\"/>\n");
		print($XML "\t\t<log idref=\"prior\"/>\n");
    	print($XML "\t</logger>\n");

	#File Param Logger
	print($XML "\t<logger id=\"tracelog\" fileName=\"$outname.log\" logEvery=\"$logperiod\" model=\"\@posterior\" sort=\"smart\">\n");
		print($XML "\t\t<log idref=\"posterior\"/>\n");
		print($XML "\t\t<log idref=\"likelihood\"/>\n");
		print($XML "\t\t<log idref=\"prior\"/>\n");
		print($XML "\t\t<log idref=\"speciescoalescent\"/>\n");
		print($XML "\t\t<log idref=\"speciationRate.t:Species\"/>\n");
		print($XML "\t\t<log idref=\"YuleModel.t:Species\"/>\n");
		print($XML "\t\t<log id=\"TreeHeight.Species\" spec=\"beast.evolution.tree.TreeHeightLogger\" tree=\"\@Tree.t:Species\"/>\n");
		print($XML "\t\t<log id=\"TreeLength.Species\" spec=\"starbeast2.TreeLengthLogger\" tree=\"\@Tree.t:Species\"/>\n");
		print($XML "\t\t<log idref=\"popMean.Species\"/>\n");
		for my $locus (@loci)
		{
			print($XML "\t\t<log idref=\"treeLikelihood.$locus\"/>\n");
			print($XML "\t\t<log id=\"TreeHeight.t:$locus\" spec=\"beast.evolution.tree.TreeHeightLogger\" tree=\"\@Tree.t:$locus\"/>\n");
			print($XML "\t\t<log idref=\"gammaShape.s:$locus\"/>\n");
			print($XML "\t\t<log idref=\"rateAC.s:$locus\"/>\n");
			print($XML "\t\t<log idref=\"rateAG.s:$locus\"/>\n");
			print($XML "\t\t<log idref=\"rateAT.s:$locus\"/>\n");
			print($XML "\t\t<log idref=\"rateCG.s:$locus\"/>\n");
			print($XML "\t\t<log idref=\"rateGT.s:$locus\"/>\n");
			print($XML "\t\t<log idref=\"freqParameter.s:$locus\"/>\n");
		}
	print($XML "\t</logger>\n");
 
	#Species tree logger
	print($XML "\t<logger id=\"speciesTreeLogger\" fileName=\"species.trees\" logEvery=\"$logperiod\" mode=\"tree\">\n");
		print($XML "\t\t<log id=\"SpeciesTreeLoggerX\" spec=\"starbeast2.SpeciesTreeLogger\" speciesTree=\"\@Tree.t:Species\"/>\n");
    	print($XML "\t</logger>\n");

	#Gene tree loggers
	for my $locus (@loci)
	{
		print($XML "\t<logger id=\"treelog.t:$locus\" fileName=\"\$(tree).trees\" logEvery=\"$logperiod\" mode=\"tree\">\n");
        		print($XML "\t\t<log id=\"TreeWithMetaDataLogger.t:$locus\" spec=\"beast.evolution.tree.TreeWithMetaDataLogger\" tree=\"\@Tree.t:$locus\"/>\n");
		print($XML "\t</logger>\n");
	}
	

print($XML "</run>\n");
print($XML "</beast>\n");

close($XML);
exit();

#FUNCTIONS
##########

sub pushUniform
{
	(my $nTabs,my $id, my $x, my $lower, my $upper)=@_;
	my $sep="\t" x $nTabs;
	my $limits="";
	defined $lower and $limits.="lower=\"$lower\" ";
	defined $upper and $limits.="upper=\"$upper\" ";
	my $out="$sep<prior id=\"$id\" name=\"distribution\" x=\"$x\">";
	$out.="\n$sep\t<Uniform id=\"Uniform.$nUniform\" name=\"distr\" $limits/>";
	$out.="\n$sep</prior>\n";
	$nUniform+=1;
	return $out;	
}

sub pushExponential
{
	(my $nTabs,my $id, my $x,my $mean)=@_;
	my $sep="\t" x $nTabs;	
	my $out="$sep<prior id=\"$id\" name=\"distribution\" x=\"$x\">";
	$out.="\n$sep\t<Exponential id=\"Exponential.$nExponential\" name=\"distr\">";
	$out.="\n$sep\t\t<parameter id=\"Exponential.$nExponential.M\" estimate=\"false\" lower=\"0.0\" name=\"mean\">$mean</parameter>";
	$out.="\n$sep\t</Exponential>";
	$out.="\n$sep</prior>\n";
	$nExponential+=1;
	return $out;
}

sub pushLogNormal
{
	(my $nTabs,my $id, my $x,my $mean, my $sd)=@_;
	my $sep="\t" x $nTabs;	
	my $out="$sep<prior id=\"$id\" name=\"distribution\" x=\"$x\">";
	$out.="\n$sep\t<LogNormal id=\"LogNormalDistributionModel.$nLogNormal\" meanInRealSpace=\"true\" name=\"distr\">";
	$out.="\n$sep\t\t<parameter id=\"LogNormalDistributionModel.$nLogNormal.M\" estimate=\"false\" lower=\"0.0\" name=\"M\">$mean</parameter>";	
	$out.="\n$sep\t\t<parameter id=\"LogNormalDistributionModel.$nLogNormal.S\" estimate=\"false\" lower=\"0.0\" name=\"S\">$sd</parameter>";
	$out.="\n$sep\t</LogNormal>";
	$out.="\n$sep</prior>\n";
	$nLogNormal+=1;
	return $out;
}

sub pushNormal
{
}

sub pushBeta
{
}

sub pushGamma
{
	(my $nTabs,my $id, my $x,my $alpha, my $beta)=@_;
	my $sep="\t" x $nTabs;	
	my $out="$sep<prior id=\"$id\" name=\"distribution\" x=\"$x\">";
	$out.="\n$sep\t<Gamma id=\"Gamma.$nGamma\" name=\"distr\">";
	$out.="\n$sep\t\t<parameter id=\"Gamma.$nGamma.alpha\" estimate=\"false\" name=\"alpha\">$alpha</parameter>";	
	$out.="\n$sep\t\t<parameter id=\"Gamma.$nGamma.beta\" estimate=\"false\" name=\"beta\">$beta</parameter>";
	$out.="\n$sep\t</Gamma>";
	$out.="\n$sep</prior>\n";
	$nGamma+=1;
	return $out;

}

sub pushLaplace
{
}

sub pushInverseGamma
{
}

sub pushOneOnX
{
	(my $nTabs,my $id, my $x)=@_;
	my $sep="\t" x $nTabs;
	my $out="$sep<prior id=\"$id\" name=\"distribution\" x=\"$x\">";
	$out.="\n$sep\t<OneOnX id=\"OneOnX.$nOneOnX\" name=\"distr\"/>";
	$out.="\n$sep</prior>\n";
	$nOneOnX+=1;
	return $out;
}
