#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 25 August 2021
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard BWA mem alt aware alignment to Hg38/GRCh38 followed by quality filtering, deduplication, and read depth QC.
# The output alignment cram file has been filtered and only contains uniquely aligned primary alignments.  Don't use this for structural variant and repeat/ segment duplication analysis.

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity/3.6.4

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/general/pe-nfs1/u0028003

# 4) Modify the workflow xxx.sing file setting the paths to the required resources.

# 5) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:SM_BWA_1
container=$dataBundle/Containers/public_SM_BWA_1.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. 

# 2) Soft link your paired fastq.gz files into the job dir, these should end with xxxq.gz

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

jobDir=$(realpath .)

SINGULARITYENV_dataBundle=$dataBundle SINGULARITYENV_jobDir=$jobDir singularity exec --containall --bind $dataBundle,$myData $container bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"


# Final cleanup
mkdir -p RunScripts
mv -f dnaAlign* RunScripts/
mv -f slurm* Logs/ &> /dev/null || true
rm -rf .snakemake 
rm -f STARTED RESTART* QUEUED
