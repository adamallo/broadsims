library(phangorn)
args <- commandArgs(TRUE)
if (length(args)!=1 || !file.info(args[1])$isdir){
        print("Usage Rscript RF.r inputdir outputdir")
        quit()
}

setwd(args[1])

rep=as.numeric(basename(getwd()))

trees=read.tree("data/gtrees_estimated.trees")
comb_matrix=RF.dist(trees,normalize=TRUE)
meanRF=mean(comb_matrix)
SDRF=sd(comb_matrix)
tlengths=vector(mode="numeric",length=length(trees))
thights=vector(mode="numeric",length=length(trees))
tminbranches=vector(mode="numeric",length=length(trees))
tmeanbranches=vector(mode="numeric",length=length(trees))
for (n in 1:length(trees)) {
	tree=trees[[n]]
	tlengths[n]=sum(tree$edge.length)
	thights[n]=max(node.depth.edgelength(tree))
	tminbranches[n]=min(tree$edge.length)
	tmeanbranches[n]=mean(tree$edge.length)
}
out=c(rep,meanRF,SDRF,mean(tlengths),sd(tlengths),mean(thights),sd(thights),mean(tminbranches),sd(tminbranches),mean(tmeanbranches),sd(tmeanbranches))
names(out)=c("rep","meanRF","sdRF","meanLength","sdLength","meanHight","sdHight","meanbmin","sdbmin","meanbranch","sdmeanbranch")
write.table(file="data/measurables.csv",t(out),quote = FALSE,row.names = FALSE,col.names=TRUE,sep=",")
