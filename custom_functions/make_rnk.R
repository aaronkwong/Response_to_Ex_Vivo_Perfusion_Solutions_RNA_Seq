#create a rank file for GSEA from my typical limma analysis
#the output path should be a path which is the path as well as the name of the file to be created
#example input: "make_rnk(output,"D:/Google Drive/Masters/Project #3/Triple Time point/GSEA Analysis/R vs cit2/reperf_vs_cit2.rnk")

#v5 change: sometimes p-values will not be order in ascending when not produced by limma. Added a line to make_rnk_simple to 
# rank pvalues to prevent errors if the remove infitines function is called. This fix needs to be applied to other functions.

#clean referes to whether the proper column names have been attached and whether the rownames have been gsubed to remove _at
make_rnk<-function(x,output_path,clean){
	if(clean==FALSE){
		colnames(x)<-c("p.value","fdr","log2ratio.paired","fold.paired")
		rownames(x)<-gsub("_at","",rownames(x))
	}
	p.val<-x[,"p.value"]
	scores<-(log(x[,"p.value"])*sign(x[,"fold.paired"]))*-1
	scores<-data.frame(scores)
	row.names(scores)<-rownames(x)
	colnames(scores)<-"scores"
	write.table(scores, file =output_path,row.names=TRUE,sep="\t",col.names=F,quote=F)
	return(scores)
}

#this function is almost identical to the one above, except that it has a col names for easier identification in execel. the col names messes up the file when
#it is used for gsea
make_rnk_for_excel<-function(x,output_path){
	p.val<-x[,"p.value"]
	scores<-(log(x[,"p.value"])*sign(x[,"fold.paired"]))*-1
	scores<-data.frame(scores)
	row.names(scores)<-rownames(x)
	colnames(scores)<-"scores"
	write.table(scores, file =output_path,row.names=TRUE,sep="\t",col.names=T,quote=F)
	return(scores)
}

#this function makes a rank file from a dataframe that contains only two columns. The first column p values and the second a folc change (or logFC)
#where the sign indicates either up or downregulation. 
# x a dataframe
# output_path a path to the object rnk file that should be written
# clean a logical indicating whether the column names of x have are already "p.value","fold.direction". If FALSE, column names are overwritten to force them to be "p.value","fold.direction"
make_rnk_simple<-function(x,output_path,clean){
	if(clean==FALSE){
		colnames(x)<-c("p.value","fold.direction")
	}
	#make sure table x is in increasing order of pvalues
	x<-x[order(x[,"p.value"]),]
	#xtract p values and calculate score
	p.val<-x[,"p.value"]
	scores<-(log(x[,"p.value"])*sign(x[,"fold.direction"]))*-1
	#scores could contain "Inf" values if any of the pvalues were too small. We need to replace these values
	if (Inf %in% abs(scores)){
		cat(paste0("At least one 'Inf' or '-Inf' was detected in the scores list of data used to create outputfile ",output_path,". Replacing values Inf and -Inf values...\n" ))
		scores<-remove_infinities(scores)
	}
	print(object.size(scores))
	scores<-data.frame(cbind(rownames(x),scores))
	colnames(scores)<-c("genes","scores")
	write.table(scores, file =output_path,row.names=FALSE,sep="\t",col.names=TRUE,quote=F,fileEncoding = "UTF-8")
}

#replace "Inf" and "-Inf" values when p-values are computed to be zero
remove_infinities<-function(vector_of_scores){
	index_replace<-which.max(which(abs(vector_of_scores)==Inf))
	if (!(length(index_replace)==0)){
		#make the last Inf value the following (non-Inf) value +1. Make sure to multiply by sign of the Inf value
		vector_of_scores[index_replace]<-(abs(vector_of_scores[index_replace+1])+1)*sign(vector_of_scores[index_replace])
		return(remove_infinities(vector_of_scores))
	}else{
		return(vector_of_scores)
	}
}

#replace "Inf" and "-Inf" values when p-values are computed to be basically zero
remove_infinities_by_adding_fc<-function(x,vector_of_scores){
	#find index of all scores that are either Inf or -Inf
	index_replace<-which(abs(vector_of_scores)==Inf)
	#find the max and min score which are not Inf or -Inf respectively
	max_score<-max(vector_of_scores[-index_replace])
	min_score<-min(vector_of_scores[-index_replace])
	#create a vector same length as abs(Inf) values with Inf values replaced by max and -Inf values replaces by min
	new_values<-vector_of_scores[index_replace]
	new_values[new_values==Inf]<-max_score
	new_values[new_values==-Inf]<-min_score
	#add fold change to these max and min values (this basically takes all the genes with very small p values and ranks them by FC instead of p value)
	vector_of_scores[index_replace]<-new_values + x[,"fold.direction"][index_replace]
	return(vector_of_scores)
}

#this function makes a rank file from a dataframe that contains only two columns. The first column p values and the second a folc change (or logFC)
#where the sign indicates either up or downregulation. 
# x a dataframe
# output_path a path to the object rnk file that should be written
# clean a logical indicating whether the column names of x have are already "p.value","fold.direction". If FALSE, column names are overwritten to force them to be "p.value","fold.direction"
make_rnk_simple_by_variant<-function(x,output_path,clean){
	if(clean==FALSE){
		colnames(x)<-c("p.value","fold.direction")
	}
	#make sure table x is in increasing order of pvalues
	x<-x[order(x[,"p.value"]),]
	#xtract p values and calculate score
	p.val<-x[,"p.value"]
	scores<-((1-x[,"p.value"])*sign(x[,"fold.direction"]))
	#scores could contain "Inf" values if any of the pvalues were too small. We need to replace these values
	if (1 %in% abs(scores)){
		cat(paste0("At least one p value of 0 was detected in the scores list of data used to create outputfile ",output_path,". Replacing values ...\n" ))
		scores[abs(scores)==1]<-scores[abs(scores)==1]+x[,"fold.direction"][abs(scores)==1]
	}
	print(object.size(scores))
	scores<-data.frame(cbind(rownames(x),scores))
	colnames(scores)<-c("genes","scores")
	write.table(scores, file =output_path,row.names=FALSE,sep="\t",col.names=TRUE,quote=F,fileEncoding = "UTF-8")
}

make_rnk_simple_by_fold_change<-function(x,output_path,clean){
	if(clean==FALSE){
		colnames(x)<-c("p.value","fold.direction")
	}
	#make sure table x is in increasing order of pvalues
	x<-x[order(x[,"fold.direction"]),]
	scores<-x[,"fold.direction"]
	scores<-data.frame(cbind(rownames(x),scores))
	colnames(scores)<-c("genes","scores")
	write.table(scores, file =output_path,row.names=FALSE,sep="\t",col.names=TRUE,quote=F,fileEncoding = "UTF-8")
}