#this script performs differential gene expression and data normalization with DeSeq2. Normalized values are used to generate PCA plots. Differential gene expression for contrasts are used to perfrom pathway analysis using GSEA.

library(renv)
renv::activate()

suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(rhdf5))
suppressPackageStartupMessages(library(tximport))
suppressPackageStartupMessages(library(DESeq2))
suppressPackageStartupMessages(library("vsn"))
suppressPackageStartupMessages(library("pheatmap"))
suppressPackageStartupMessages(library("RColorBrewer"))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(biomaRt))

# load custom files
source("./custom_functions/make_rnk.R")
source("./custom_functions/GSEA_Pipeline.R")
source("./custom_functions/gdpath.R")

#create output directories
dir.create("./results")
dir.create("./results/rnk_results")
dir.create("./results/pathway_analysis")


cat("reading in sample info...\n")
# read the file with sample information
samples <- read.table("./raw_data/samples_info.txt", header=TRUE)
#clean up samples condition column
samples$condition<-gsub("-","_",samples$condition)
samples$condition<-factor(samples$condition)
#clean up sample info
samples$cell_type<-rep("BEAS2B",nrow(samples))
samples$cell_type[grepl("H_",samples$condition)]<-"HPMEC"
samples$treatment<-gsub("B_","",samples$condition)
samples$treatment<-gsub("H_","",samples$treatment)
samples$treatment<-factor(samples$treatment)
samples$cell_type<-factor(samples$cell_type)

cat("reading in transcript abundances...\n")
#pull in raw transcript counts from each sample
files <- file.path(paste0("./intermediate_results/",samples$assay, "/abundance.h5"))
names(files) <- paste0(samples$assay)
txi.kallisto <- tximport(files, type = "kallisto", txOut = TRUE)

cat("summarizing gene level abundances...\n")
# create tx2gene file
# use biomart to map transcript id to gene symbol
ensembl <- useEnsembl(biomart = "genes", dataset = "hsapiens_gene_ensembl",version=107)
# produce tx2 format table with columns 1 the transcript_id and the second column HGNC ID
tx2_gene_annotations<-getBM(filters= "ensembl_transcript_id_version", attributes= c("ensembl_transcript_id_version","hgnc_symbol"),values = rownames(txi.kallisto$abundance), mart= ensembl)

# remove any annotations which do not map to a gene symbol
tx2_gene_annotations<-tx2_gene_annotations[tx2_gene_annotations$hgnc_symbol!="",]

# import and quantify gene level abundance
txi <- tximport(files, type="kallisto", tx2gene=tx2_gene_annotations)

#pull in count data and annotations (txi) and put into dds object
dds <- DESeqDataSetFromTximport(txi,colData = samples,design = ~ condition)

#prefilter lowly expressed genes
keep <- rowSums(counts(dds)) >= 10
dds <- dds[keep,]

#run DE
cat("saving DESeq2 object...\n")
dds <- DESeq(dds)
saveRDS(dds,"./results/dds_object.rds")


#lets also create transformed matrix of normalized values. Here we use two normalizationa algos. Regularized log transform is prefered (rld)
#variance stabilization
cat("performing vsd and rld normalization...\n")
vsd <- vst(dds, blind=FALSE)
saveRDS(vsd,"./results/vsd_object.rds")
vsd_B<-vsd[,vsd$cell_type=="BEAS2B"]
vsd_H<-vsd[,vsd$cell_type=="HPMEC"]

# regulariazed transform
rld <- rlog(dds, blind=FALSE)
saveRDS(rld,"./results/rld_object.rds")
rld_B<-rld[,rld$cell_type=="BEAS2B"]
rld_H<-rld[,rld$cell_type=="HPMEC"]


cat("creating PCA plots...\n")
#QC plots to asses sd pre normalization
png("./results/vsd_meanSDPlot_pre_normalization.png",height=400,width=600)
meanSdPlot(assay(vsd))
dev.off()
png("./results/rld_meanSDPlot_pre_normalization.png",height=400,width=600)
meanSdPlot(assay(rld))
dev.off()

#lets make some QC plots to compare vst and rlog
ntd <- normTransform(dds)

#QC plots to asses sd post normalization
png("./results/vsd_meanSDPlot_post_normalization.png",height=400,width=600)
meanSdPlot(assay(vsd))
dev.off()
png("./results/rld_meanSDPlot_post_normalization.png",height=400,width=600)
meanSdPlot(assay(rld))
dev.off()


#PCA plots for all cell together
png("./results/All_Cells_PCA.png",height=400,width=600)
pcaData <- plotPCA(vsd, intgroup=c("treatment", "cell_type"), returnData=TRUE)
percentVar <- round(100 * attr(pcaData, "percentVar"))
print(
ggplot(pcaData, aes(PC1, PC2, color=treatment, shape=cell_type)) +
	geom_point(size=3) +
	xlab(paste0("PC1: ",percentVar[1],"% variance")) +
	ylab(paste0("PC2: ",percentVar[2],"% variance")) + 
	coord_fixed()
)
dev.off()

#PCA plots for only BEAS2B
png("./results/BEAS2B_PCA.png",height=400,width=600)
pcaData <- plotPCA(vsd_B, intgroup=c("treatment", "cell_type"), returnData=TRUE)
percentVar <- round(100 * attr(pcaData, "percentVar"))
print(
	ggplot(pcaData, aes(PC1, PC2, color=treatment, shape=cell_type)) +
	geom_point(size=3) +
	xlab(paste0("PC1: ",percentVar[1],"% variance")) +
	ylab(paste0("PC2: ",percentVar[2],"% variance")) + 
	coord_fixed()
)
dev.off()

#PCA plots for only HPMEC
png("./results/HPMEC_PCA.png",height=400,width=600)
pcaData <- plotPCA(vsd_H, intgroup=c("treatment", "cell_type"), returnData=TRUE)
percentVar <- round(100 * attr(pcaData, "percentVar"))
print(
ggplot(pcaData, aes(PC1, PC2, color=treatment, shape=cell_type)) +
	geom_point(size=3) +
	xlab(paste0("PC1: ",percentVar[1],"% variance")) +
	ylab(paste0("PC2: ",percentVar[2],"% variance")) + 
	coord_fixed()
)
dev.off()


#sample to sample heatmap
png("./results/All_Cells_heatmap.png",height=400,width=600)
sampleDists <- dist(t(assay(vsd)))
sampleDistMatrix <- as.matrix(sampleDists)
rownames(sampleDistMatrix) <- paste(vsd$condition, vsd$type, sep="-")
colnames(sampleDistMatrix) <- NULL
colors <- colorRampPalette( rev(brewer.pal(9, "Blues")) )(255)
pheatmap(sampleDistMatrix,
         clustering_distance_rows=sampleDists,
         clustering_distance_cols=sampleDists,
         col=colors)
dev.off()

