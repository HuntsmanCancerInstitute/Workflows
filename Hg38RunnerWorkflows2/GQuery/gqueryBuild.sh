#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 120:00:00

# 25 Feb 2025
# David.Nix@hci.utah.edu
# Huntsman Cancer Institute

# Runs a snakemake workflow to generate the GQuery index based off the files in the HCI Patient Molecular Repository on AWS
# Execute this on redwood 

set -e; start=$(date +'%s')
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# load snakemake
module load snakemake/8.16.0

snakemake -p --cores all --snakefile gqueryBuild.sm 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"



