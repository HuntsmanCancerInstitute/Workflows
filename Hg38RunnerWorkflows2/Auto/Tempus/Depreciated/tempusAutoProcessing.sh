#!/bin/bash

# 11 April 2023
# David.Nix@hci.utah.edu
# Huntsman Cancer Institute

# Runs a snakemake workflow to process Tempus datasets for translational genomics
# Execute this on redwood and in the /scratch/general/pe-nfs1/u0028003/Tempus directory

set -e; start=$(date +'%s')
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# load snakemake
module load snakemake

# make a work dir and change into it
#wd="TempusRun_"$(date +'%m_%d_%Y'); mkdir $wd; cd $wd
#--dry-run
snakemake -p --cores all --snakefile tempusAutoProcessing.sm 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"



