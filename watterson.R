library(pegas)
args <- commandArgs(TRUE)

if (length(args)!=2 || !file.info(args[1])$isdir || !file.info(args[2])$isdir ){
        print("Usage Rscript RF.r inputdir outputdir")
        quit()
}

##Actually, some things are gathered from the outputdir

setwd(args[2]) ##We are in the output!

rep=as.numeric(basename(getwd()))

seqs=list.files(path=args[1],pattern="*_TRUE.phy$")
final_data=data.frame(rep=vector(mode = "numeric", length=length(seqs)),gid=vector(mode = "numeric", length=length(seqs)),theta=vector(mode = "numeric", length=length(seqs)))
for (n in 1:length(seqs)){
	seqfile=paste(args[1],seqs[n],sep="/")
	msa=read.dna(seqfile)
	theta=as.numeric(theta.s(msa))
	gid=as.numeric(gsub(pattern="([0-9]*)_TRUE\\.phy",replacement='\\1',x=basename(seqfile)))
	final_data[n,]=c(rep,gid,theta)
}

concat=read.dna(paste(args[1],"concat.phy",sep="/"))
thetaconcat=theta.s(concat)
write.table(final_data,file="data/watterson.csv",sep=",",quote=FALSE,row.names=FALSE,col.names=TRUE)
write.table(data.frame(mean=mean(final_data$theta,na.rm = TRUE),sd=sd(final_data$theta,na.rm = TRUE),concat=thetaconcat),file="data/watterson_summary.csv",sep=",",quote=FALSE,row.names=FALSE,col.names=TRUE)
