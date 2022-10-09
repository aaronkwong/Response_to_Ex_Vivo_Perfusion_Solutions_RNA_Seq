#!/bin/bash 

# analysis is meant to be run in the unzipped repository
R_version="/opt/R/4.2.1/bin/Rscript"
script_dir="./R"


#perform kallisto pseudoalignment, assuming kallisto is installed
source "./kallisto/kallisto_pseudo_alignment.sh"

# setup R virtual enviornmment for reproducibility
${R_version} "${script_dir}/setup_renv.R"

# Perform quantification, gene level aggregation and exploratory plots
${R_version} "${script_dir}/deseq2_preprocessing_and_exploratory_analysis.R"

# run differential gene expression and GSEA pathway analysis
${R_version} "${script_dir}/differential_gene_expression_and_pathway_analysis.R"



