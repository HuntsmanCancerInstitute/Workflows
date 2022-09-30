#!/bin/bash

# 27 Aug 2022
# David.Nix@hci.utah.edu
# Huntsman Cancer Institute

# Runs a snakemake workflow to process Tempus datasets for translational genomics
# Execute this on redwood and in the /scratch/general/pe-nfs1/u0028003/Avatar directory

set -e; start=$(date +'%s')
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# load snakemake
module load snakemake/6.4.1

# make a work dir and change into it
snakemake -p --cores all --snakefile avatarAutoProcessing.sm 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"



