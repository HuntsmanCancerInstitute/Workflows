#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 24 July 2023
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This tumor-normal workflow uses GATK's Mutect2 caller to identify short INDELs and SNVs.
# See https://gatk.broadinstitute.org/hc/en-us/articles/360035531132--How-to-Call-somatic-mutations-using-GATK4-Mutect2
# Build notes: /Users/u0028003/Code/workingWithMutect2.sh for a faster way to build the PoN


#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
# singularity pull docker://hcibioinformatics/public:Gatk_Latest_Sm_1 
container=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner/Containers/public_Gatk_Latest_Sm_1.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link bam and bai files naming them tumor.bam, tumor.bai, normal.bam, and normal.bai into the analysis folder. Cram/crai files also work, name them tumor.cram, tumor.crai, normal.cram, and normal.crai.

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, xxx.sm, and xxx.yaml into the job directory.

# 4) Launch the xxx.README.sh via slurm's sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake will pick up where it left off.



#### No need to modify anything below ####

echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params
jobDir=`readlink -f .`

SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $dataBundle $container \
bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv -f mutect*  RunScripts/
mv -f  *.yaml RunScripts/ &> /dev/null || true
cp slurm* Logs/ &> /dev/null || true
mv -f *snakemake.stats.json Logs/ &> /dev/null || true
rm -rf .snakemake STARTED RESTART* QUEUED slurm*
touch COMPLETE 

