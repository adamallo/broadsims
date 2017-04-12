library(phangorn)
args <- commandArgs(TRUE)
if (length(args)!=2 || !file.info(args[1])$isdir || !file.info(args[2])$isdir ){
        print("Usage Rscript RF.r inputdir outputdir")
        quit()
}

##Actually, some things are gathered from the outputdir

setwd(args[2]) ##We are in the output!

rep=as.numeric(basename(getwd()))

truetrees=list.files(path="true_trees",pattern="g_trees.*.trees")
final_data=data.frame(rep=numeric(0),gid=numeric(0),rf=numeric(0))
options(stringsAsFactors=FALSE)
for (t in 1:length(truetrees))
{
        truetreefile=truetrees[t]
	truetree=read.tree(paste0("true_trees/",truetreefile))
	labels_original=sort(truetree$tip.label)
	gid=gsub(pattern="g_trees([0-9]*)\\.trees",replacement='\\1',x=basename(truetreefile))
	ptreefile=paste0(args[1],"/","RAxML_bestTree.",gid)
	if(file.exists(ptreefile)) {
                dist=tryCatch({
                        ptree=read.tree(ptreefile)
                        labels2=sort(ptree$tip.label)
                        todel=setdiff(labels_original,labels2) ##The gene tree may be smaller if all individuals of one species have been dropped from all replicates
                        if (length(todel)!=0){
                                print(paste0("The file ",ptreefile," does not have the same set of labels as the species tree. Different labels: ",paste(todel,collapse=" ")))
                                temp_truetree=drop.tip(truetree,tip=todel) #Prunes tips and internal branches
                                RF.dist(temp_truetree,ptree,check.labels=TRUE,normalize=TRUE)
                        } else {
                                RF.dist(truetree,ptree,check.labels=TRUE,normalize=TRUE)
                        }
                },warning=function(war){
                        print(paste0("The file ",ptreefile," generated a NA"))
                        return(NA)
                },error=function(err){
                        print(paste0("The file ",ptreefile," generated a NA"))
                        return(NA)
                })
                #dist=RF.dist(truetree,tree,check.labels = TRUE)/((truetree$Nnode+1)*2-6) ##truetree$Nnode= Number of internal nodes. This tree is rooted, so internal nodes+1 = n_leaves. 2*(n-3) = number of internal branches/bipartitions in an unrooted tree * 2.
                final_data=rbind(final_data,data.frame(rep=rep,gid=gid,rf=dist))
	} else {
		print(paste0("The file ",ptreefile,"was not present"))
		final_data=rbind(final_data,data.frame(rep=rep,gid=gid,rf=NA))
	}
}
##Still have to finish this
final_data$rep=as.numeric(final_data$rep)
final_data$rf=as.numeric(final_data$rf)
write.table(final_data,file="data/gtrees_rf.csv",sep=",",quote=FALSE,row.names=FALSE,col.names=TRUE)
write.table(data.frame(mean=mean(final_data$rf,na.rm = TRUE),sd=sd(final_data$rf,na.rm = TRUE)),file="data/gtrees_rfsummary.csv",sep=",",quote=FALSE,row.names=FALSE,col.names=TRUE)
