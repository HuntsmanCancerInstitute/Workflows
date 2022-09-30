#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED STARTED

# 13 May 2022
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This fires the SampleConcordance app from USeq to calculate sample concordance based on homozygous variants found present in bam files.  Use this with RNASeq and DNASeq datasets.


#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/general/pe-nfs1/u0028003

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:SM_BWA_1
container=$dataBundle/Containers/public_SM_BWA_1.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside in the mount paths.

# 2) Create a directory named 'BamPileupFiles' and soft link or move all of your single sample/alignment bgzipped bam pileup files and their tbi indexes into it.  See the USeq BamPileup app. 

# 3) Soft link or copy over a txt file describing the clinically reported gender for the samples. The file name should start with the word "gender" and contain a line with the word "Gender" followd by the word "Female", "Male", "M" or "F". Case insensitive. xxx.gz/ xxx.zip OK 

# 4) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the job directory.

# 5) Launch the xxx.README.sh via slurm's sbatch or run it on your local server.  

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params
jobDir=`readlink -f .`

SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $dataBundle,$myData $container \
bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv -f sampleConcordance*  RunScripts/
mv -f  *.yaml RunScripts/ &> /dev/null || true
cp slurm* Logs/ &> /dev/null || true
mv -f *snakemake.stats.json Logs/ &> /dev/null || true
rm -rf .snakemake STARTED RESTART* QUEUED slurm*
touch COMPLETE 

