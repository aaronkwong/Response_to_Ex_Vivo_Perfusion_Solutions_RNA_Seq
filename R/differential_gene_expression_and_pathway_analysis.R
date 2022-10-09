library(renv)
renv::activate()

suppressPackageStartupMessages(library(DESeq2))


# load custom files
source("./custom_functions/make_rnk.R")
source("./custom_functions/GSEA_Pipeline.R")
source("./custom_functions/gdpath.R")

# create output directories
dir.create("./results/rnk_results")
dir.create("./results/pathway_analysis")

#read in preprocessed data
dds<-readRDS("./results/dds_object.rds")


#gmt
gmt_path<-"./gsea/Human_GOBP_AllPathways_no_GO_iea_August_03_2022_symbol.gmt"

# pick comparison you want
# the order is first versus second. For example, c("B_D10","B_CIT") is B_D10 vs B_CIT
comparisons_to_run<-list(
	#compare BEAS2B with CIT
	c("B_D10","B_CIT"),
	c("B_Steen","B_CIT"),
	c("B_Steen_Glu","B_CIT"),
	#compare HPMEC with CIT
	c("H_D10","H_CIT"),
	c("H_Steen","H_CIT"),
	c("H_Steen_Glu","H_CIT")
)


#extract results for each comparison of interest
comparison_names<-sapply(comparisons_to_run,FUN=paste0,collapse="_vs_")
list_of_de_results<-list()
for (i in 1:length(comparisons_to_run)){
	#pull DE tables
	res<- DESeq2::results(dds,contrast=c("condition",comparisons_to_run[[i]]))
	res_subset<-data.frame(res)[,c("pvalue","log2FoldChange")]
	write.table(data.frame(res),file=paste0("./results/rnk_results/",comparison_names[i],"_DE.tab"))
	# it seems some pvalues are na, report it
	print(paste0(length(which(is.na(res_subset)))," NA values were found. Removing them from rnk to prevent errors.",paste0(which(is.na(res_subset)),collapse=" ")))
	list_of_de_results[[i]]<-na.omit(res_subset)
}
names(list_of_de_results)<-comparison_names

#make rank files for each comparison and store location
list_of_rnk_files<-c()
x<-1
for (i in 1:length(list_of_de_results)){
	rnk_location<- paste0("./results/rnk_results/",names(list_of_de_results)[i],".rnk")
	print(rnk_location)
	#save rnk file to the rnk folder
	make_rnk_simple(x=list_of_de_results[[i]], output_path=rnk_location,clean=FALSE)
	#save the location of the rnk file to give to gsea later
	list_of_rnk_files[x]<-rnk_location
	x<-x+1
}
names(list_of_rnk_files)<-names(list_of_de_results)


#run gsea for each rnk file generated
#this script orders all analysis to be run in parallel. Check the output folder and make sure itt didnt error out. Takes approx 15 mins to run all analysis as long as RAM isnt an issue
#after sending out command to run GSEA, it just runs in the background. Only way to check progress is to look at output folders
for (i in 1:length(list_of_rnk_files)){
	print(paste0("comparison ",names(list_of_rnk_files)[i]," sent."))
	s.broad_GSEA_preranked(
		s.gsea_soft=paste0("./gsea/gsea-3.0.jar"),
		s.gsea_memory=4096,
		s.gsea_nperm=1000,
		s.gsea_rnk=list_of_rnk_files[[i]],
		s.gsea_gmt=gmt_path, 
		s.gsea_output_name=names(list_of_rnk_files)[i],
		s.gsea_output_location=paste0("./results/pathway_analysis"),
		s.timestamp=123456789,
		wait=FALSE
	)
	Sys.sleep(60)
}
