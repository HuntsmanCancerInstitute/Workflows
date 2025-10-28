#!/bin/bash

# 1 Oct 2025
# David.Nix@hci.utah.edu
# Huntsman Cancer Institute

# Runs a snakemake workflow to process Ambry datasets for translational genomics
# Execute this on redwood 

set -e; start=$(date +'%s')
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# load snakemake and a current version of java
module load snakemake
module load openjdk/17.0.1

# Launch snakemake using 
snakemake -p \
--cores all \
--snakefile ambryAutoProcessing.sm 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"
