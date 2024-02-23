#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

# 2 Nov 2023
# David.Nix@hci.utah.edu
# Huntsman Cancer Institute

# Runs a snakemake workflow to process Invitae datasets for translational genomics
# Execute this on redwood

set -e; start=$(date +'%s')
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# load snakemake
module load snakemake/6.4.1

# make a work dir and change into it
jobDir=$(realpath .)
allThreads=$(nproc --all)
snakemake -p --cores all --config workingDir=$jobDir allThreads=$allThreads  --snakefile invitaeAutoProcessing.sm 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"



