#!/bin/bash

# 18 May 2022
# David.Nix@hci.utah.edu
# Huntsman Cancer Institute

# Runs a snakemake workflow to process Caris datasets for translational genomics
# Execute this on redwood and in the /scratch/general/pe-nfs1/u0028003/Caris directory

set -e; start=$(date +'%s')
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# load snakemake
module load snakemake/6.4.1

# make a work dir and change into it
#wd="CarisRun_"$(date +'%m_%d_%Y'); mkdir $wd; cd $wd

snakemake -p --cores all --snakefile carisAutoProcessing.sm 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"



