#!/bin/bash

#set directories
dir_fastq="/home/jjeon/R/RNAseq_Zhiyuan/" # change once we upload data to GEO
root_intermediate="./intermediate_results/"
path_to_index="./kallisto/transcripts_GRCh38.idx"

#set run parameters
threads_per_run=12
bootstraps=100

#create directory to output results
mkdir kallisto
mkdir intermediate_results

# move to kallisto directory to set up index used for allignment
cd kallisto
curl -O http://ftp.ensembl.org/pub/release-107/fasta/homo_sapiens/cdna/Homo_sapiens.GRCh38.cdna.all.fa.gz
#lets check the reference transctiptome  against known [3064e49e2fd475a9510006925e596dd4a90238565e52ed410e387ac82d812daa]
sha256sum Homo_sapiens.GRCh38.cdna.all.fa.gz

#lets create a quantification index
kallisto index -i transcripts_GRCh38.idx Homo_sapiens.GRCh38.cdna.all.fa.gz

#return to working directory
cd ..

#BEAS2B-CIT

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_CIT-1_S18 \
${dir_fastq}B_CIT-1_S18_L001_R1_001.fastq.gz \
${dir_fastq}B_CIT-1_S18_L001_R2_001.fastq.gz \
${dir_fastq}B_CIT-1_S18_L002_R1_001.fastq.gz \
${dir_fastq}B_CIT-1_S18_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_CIT-2_S19 \
${dir_fastq}B_CIT-2_S19_L001_R1_001.fastq.gz \
${dir_fastq}B_CIT-2_S19_L001_R2_001.fastq.gz \
${dir_fastq}B_CIT-2_S19_L002_R1_001.fastq.gz \
${dir_fastq}B_CIT-2_S19_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_CIT-3_S20 \
${dir_fastq}B_CIT-3_S20_L001_R1_001.fastq.gz \
${dir_fastq}B_CIT-3_S20_L001_R2_001.fastq.gz \
${dir_fastq}B_CIT-3_S20_L002_R1_001.fastq.gz \
${dir_fastq}B_CIT-3_S20_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_CIT-6_S21 \
${dir_fastq}B_CIT-6_S21_L001_R1_001.fastq.gz \
${dir_fastq}B_CIT-6_S21_L001_R2_001.fastq.gz \
${dir_fastq}B_CIT-6_S21_L002_R1_001.fastq.gz \
${dir_fastq}B_CIT-6_S21_L002_R2_001.fastq.gz


#BEAS2B-D10
kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_D10-1_S22 \
${dir_fastq}B_D10-1_S22_L001_R1_001.fastq.gz \
${dir_fastq}B_D10-1_S22_L001_R2_001.fastq.gz \
${dir_fastq}B_D10-1_S22_L002_R1_001.fastq.gz \
${dir_fastq}B_D10-1_S22_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_D10-2_S23 \
${dir_fastq}B_D10-2_S23_L001_R1_001.fastq.gz \
${dir_fastq}B_D10-2_S23_L001_R2_001.fastq.gz \
${dir_fastq}B_D10-2_S23_L002_R1_001.fastq.gz \
${dir_fastq}B_D10-2_S23_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_D10-3_S24 \
${dir_fastq}B_D10-3_S24_L001_R1_001.fastq.gz \
${dir_fastq}B_D10-3_S24_L001_R2_001.fastq.gz \
${dir_fastq}B_D10-3_S24_L002_R1_001.fastq.gz \
${dir_fastq}B_D10-3_S24_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_D10-4_S25 \
${dir_fastq}B_D10-4_S25_L001_R1_001.fastq.gz \
${dir_fastq}B_D10-4_S25_L001_R2_001.fastq.gz \
${dir_fastq}B_D10-4_S25_L002_R1_001.fastq.gz \
${dir_fastq}B_D10-4_S25_L002_R2_001.fastq.gz


#BEAS2B-STEEN
kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_S-1_S26 \
${dir_fastq}B_S-1_S26_L001_R1_001.fastq.gz \
${dir_fastq}B_S-1_S26_L001_R2_001.fastq.gz \
${dir_fastq}B_S-1_S26_L002_R1_001.fastq.gz \
${dir_fastq}B_S-1_S26_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_S-2_S27 \
${dir_fastq}B_S-2_S27_L001_R1_001.fastq.gz \
${dir_fastq}B_S-2_S27_L001_R2_001.fastq.gz \
${dir_fastq}B_S-2_S27_L002_R1_001.fastq.gz \
${dir_fastq}B_S-2_S27_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_S-3_S28 \
${dir_fastq}B_S-3_S28_L001_R1_001.fastq.gz \
${dir_fastq}B_S-3_S28_L001_R2_001.fastq.gz \
${dir_fastq}B_S-3_S28_L002_R1_001.fastq.gz \
${dir_fastq}B_S-3_S28_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_S-4_S29 \
${dir_fastq}B_S-4_S29_L001_R1_001.fastq.gz \
${dir_fastq}B_S-4_S29_L001_R2_001.fastq.gz \
${dir_fastq}B_S-4_S29_L002_R1_001.fastq.gz \
${dir_fastq}B_S-4_S29_L002_R2_001.fastq.gz


#BEAS2B-STEEN-GLU
kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_S4-1_S30 \
${dir_fastq}B_S4-1_S30_L001_R1_001.fastq.gz \
${dir_fastq}B_S4-1_S30_L001_R2_001.fastq.gz \
${dir_fastq}B_S4-1_S30_L002_R1_001.fastq.gz \
${dir_fastq}B_S4-1_S30_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_S4-2_S31 \
${dir_fastq}B_S4-2_S31_L001_R1_001.fastq.gz \
${dir_fastq}B_S4-2_S31_L001_R2_001.fastq.gz \
${dir_fastq}B_S4-2_S31_L002_R1_001.fastq.gz \
${dir_fastq}B_S4-2_S31_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_S4-3_S32 \
${dir_fastq}B_S4-3_S32_L001_R1_001.fastq.gz \
${dir_fastq}B_S4-3_S32_L001_R2_001.fastq.gz \
${dir_fastq}B_S4-3_S32_L002_R1_001.fastq.gz \
${dir_fastq}B_S4-3_S32_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}B_S4-4_S33 \
${dir_fastq}B_S4-4_S33_L001_R1_001.fastq.gz \
${dir_fastq}B_S4-4_S33_L001_R2_001.fastq.gz \
${dir_fastq}B_S4-4_S33_L002_R1_001.fastq.gz \
${dir_fastq}B_S4-4_S33_L002_R2_001.fastq.gz


#HPMEC-CIT
kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_CIT-1_S34 \
${dir_fastq}H_CIT-1_S34_L001_R1_001.fastq.gz \
${dir_fastq}H_CIT-1_S34_L001_R2_001.fastq.gz \
${dir_fastq}H_CIT-1_S34_L002_R1_001.fastq.gz \
${dir_fastq}H_CIT-1_S34_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_CIT-2_S35 \
${dir_fastq}H_CIT-2_S35_L001_R1_001.fastq.gz \
${dir_fastq}H_CIT-2_S35_L001_R2_001.fastq.gz \
${dir_fastq}H_CIT-2_S35_L002_R1_001.fastq.gz \
${dir_fastq}H_CIT-2_S35_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_CIT-3_S36 \
${dir_fastq}H_CIT-3_S36_L001_R1_001.fastq.gz \
${dir_fastq}H_CIT-3_S36_L001_R2_001.fastq.gz \
${dir_fastq}H_CIT-3_S36_L002_R1_001.fastq.gz \
${dir_fastq}H_CIT-3_S36_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_CIT-4_S37 \
${dir_fastq}H_CIT-4_S37_L001_R1_001.fastq.gz \
${dir_fastq}H_CIT-4_S37_L001_R2_001.fastq.gz \
${dir_fastq}H_CIT-4_S37_L002_R1_001.fastq.gz \
${dir_fastq}H_CIT-4_S37_L002_R2_001.fastq.gz



#HPMEC-D10
kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_D10-1_S1 \
${dir_fastq}H_D10-1_S1_L001_R1_001.fastq.gz \
${dir_fastq}H_D10-1_S1_L001_R2_001.fastq.gz \
${dir_fastq}H_D10-1_S1_L002_R1_001.fastq.gz \
${dir_fastq}H_D10-1_S1_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_D10-2_S2 \
${dir_fastq}H_D10-2_S2_L001_R1_001.fastq.gz \
${dir_fastq}H_D10-2_S2_L001_R2_001.fastq.gz \
${dir_fastq}H_D10-2_S2_L002_R1_001.fastq.gz \
${dir_fastq}H_D10-2_S2_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_D10-3_S3 \
${dir_fastq}H_D10-3_S3_L001_R1_001.fastq.gz \
${dir_fastq}H_D10-3_S3_L001_R2_001.fastq.gz \
${dir_fastq}H_D10-3_S3_L002_R1_001.fastq.gz \
${dir_fastq}H_D10-3_S3_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_D10-4_S4 \
${dir_fastq}H_D10-4_S4_L001_R1_001.fastq.gz \
${dir_fastq}H_D10-4_S4_L001_R2_001.fastq.gz \
${dir_fastq}H_D10-4_S4_L002_R1_001.fastq.gz \
${dir_fastq}H_D10-4_S4_L002_R2_001.fastq.gz



#HPMEC-STEEN
kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_S-1_S5 \
${dir_fastq}H_S-1_S5_L001_R1_001.fastq.gz \
${dir_fastq}H_S-1_S5_L001_R2_001.fastq.gz \
${dir_fastq}H_S-1_S5_L002_R1_001.fastq.gz \
${dir_fastq}H_S-1_S5_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_S-2_S6 \
${dir_fastq}H_S-2_S6_L001_R1_001.fastq.gz \
${dir_fastq}H_S-2_S6_L001_R2_001.fastq.gz \
${dir_fastq}H_S-2_S6_L002_R1_001.fastq.gz \
${dir_fastq}H_S-2_S6_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_S-3_S7 \
${dir_fastq}H_S-3_S7_L001_R1_001.fastq.gz \
${dir_fastq}H_S-3_S7_L001_R2_001.fastq.gz \
${dir_fastq}H_S-3_S7_L002_R1_001.fastq.gz \
${dir_fastq}H_S-3_S7_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_S-4_S8 \
${dir_fastq}H_S-4_S8_L001_R1_001.fastq.gz \
${dir_fastq}H_S-4_S8_L001_R2_001.fastq.gz \
${dir_fastq}H_S-4_S8_L002_R1_001.fastq.gz \
${dir_fastq}H_S-4_S8_L002_R2_001.fastq.gz



#HPMEC-STEEN GLU
kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_S4-1_S9 \
${dir_fastq}H_S4-1_S9_L001_R1_001.fastq.gz \
${dir_fastq}H_S4-1_S9_L001_R2_001.fastq.gz \
${dir_fastq}H_S4-1_S9_L002_R1_001.fastq.gz \
${dir_fastq}H_S4-1_S9_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_S4-2_S10 \
${dir_fastq}H_S4-2_S10_L001_R1_001.fastq.gz \
${dir_fastq}H_S4-2_S10_L001_R2_001.fastq.gz \
${dir_fastq}H_S4-2_S10_L002_R1_001.fastq.gz \
${dir_fastq}H_S4-2_S10_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_S4-3_S11 \
${dir_fastq}H_S4-3_S11_L001_R1_001.fastq.gz \
${dir_fastq}H_S4-3_S11_L001_R2_001.fastq.gz \
${dir_fastq}H_S4-3_S11_L002_R1_001.fastq.gz \
${dir_fastq}H_S4-3_S11_L002_R2_001.fastq.gz

kallisto quant -i $path_to_index -t $threads_per_run -b $bootstraps -o ${root_intermediate}H_S4-4_S12 \
${dir_fastq}H_S4-4_S12_L001_R1_001.fastq.gz \
${dir_fastq}H_S4-4_S12_L001_R2_001.fastq.gz \
${dir_fastq}H_S4-4_S12_L002_R1_001.fastq.gz \
${dir_fastq}H_S4-4_S12_L002_R2_001.fastq.gz
