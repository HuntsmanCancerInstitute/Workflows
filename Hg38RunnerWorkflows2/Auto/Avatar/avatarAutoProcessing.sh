#!/bin/bash

# 2 Feb 2024
# David.Nix@hci.utah.edu
# Huntsman Cancer Institute

# Runs a snakemake workflow to process Avatar datasets for translational genomics
# Execute this on redwood and in the /scratch/general/pe-nfs1/u0028003/Avatar directory

# For each Avatar Batch, manually retrieve the clinical linkage file with ftp following instructions: https://ri-confluence.hci.utah.edu/display/BIOIN/SOP-+Avatar+Data+retrieval
# Place in the ResourceFiles dir
# Run the workflow, it will exit upon running the AvatarDataWrangler, follow the instructions to manually pull PHI, save the csv in the ResourceFiles dir

# If needed, login to Azure repo: https://orienavatar.com/account/login -> Avatar_MolecularData_hg38



set -e; start=$(date +'%s')
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# load snakemake and a current version of java
module load snakemake
module load openjdk/17.0.1

# make a work dir and change into it
snakemake -p --cores all --snakefile avatarAutoProcessing.sm 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"



