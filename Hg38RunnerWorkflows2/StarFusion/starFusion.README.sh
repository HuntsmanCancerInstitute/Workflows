#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

# 9 Nov 2022
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This fires the standard STAR-Fusion toolkit

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578 
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
# singularity pull docker://hcibioinformatics/public:StarFusion_1
container=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner/Containers/public_StarFusion_1.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link your two gzipped fastq RNASeq files into the job directory.

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the job directory.

# 4) Launch the xxx.README.sh via slurm's sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.


#### No need to modify anything below ####
set -e
start=$(date +'%s')
name=${PWD##*/}
jobDir=$(realpath .)

# Define a temporary directory physically on the node in which to copy over all the job files.  This will be deleted and then recreated.
tempDir=/scratch/local/$USER/$SLURM_JOB_ID
rm -rf $tempDir &> /dev/null || true; mkdir -p $tempDir/$name || true

echo -e "\n---------- Copying job files to tempDir -------- $((($(date +'%s') - $start)/60)) min"
rsync -rtL --exclude 'slurm-*' $jobDir/ $tempDir/$name/ && echo CopyOverOK || echo CopyOverFAILED

# Execute the sing file in the container from the tempDir, always return true, even if it fails so one can copy all back
echo -e "\n---------- Launching container -------- $((($(date +'%s') - $start)/60)) min"
cd $tempDir/$name

SINGULARITYENV_jobDir=$tempDir/$name/  SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $dataBundle,$jobDir $container bash $tempDir/$name/*.sing || true

echo -e "\n---------- Files In Temp -------- $((($(date +'%s') - $start)/60)) min"
ls -la $tempDir/$name

# Copy back job files regardless of success or failure, disable exit on error
echo -e "\n---------- Copying back results -------- $((($(date +'%s') - $start)/60)) min"
set +e
rm -rf $tempDir/$name/*cram &> /dev/null
rsync -rtL --exclude '*q.gz' $tempDir/$name/ $jobDir/ && echo CopyBackOK || { echo CopyBackFAILED; rm -f COMPLETE; }

echo -e "\n---------- Files In JobDir -------- $((($(date +'%s') - $start)/60)) min"
ls -la $jobDir; cd $jobDir; rm -rf $tempDir &> /dev/null 

# OK?
if [ -f COMPLETE ];
then
  echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"
  mv -f slurm* Logs/ 
  rm -f starFusion.* QUEUED
else
  echo -e "\n---------- FAILED! -------- $((($(date +'%s') - $start)/60)) min total"
  touch FAILED
fi

