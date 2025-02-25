#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

# 14 May 2024
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This runs a primary CellRanger analysis

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity

# 2) Define file paths to "mount" in the container. The first is to the data bundle mirrored on BSR servers. The second is needed for cram conversion and sample concordance.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/atlatl

# 3) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:CellRanger_1
container=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner/Containers/public_CellRanger_1.sif


#### Do for every run ####

# 1) Create a folder for each sample named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) SOFT LINK your gzipped fastq files for a particular sample into the job directory. These WILL BE DELETED upon completion.

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, xxx.sm, and species_libraryPrep matched xxx.cellRanger.yaml into the job directory.

# 4) Add a 'sampleNames: xxx,yyy,zzz' entry in the yaml with one or more parsed sample names for CellRanger to merge, e.g. 'sampleNames: 20758X2_230503_A00421_0548_AH7M32DRX3,20758X2_230731_A00421_0576_BHGMFWDRX3' .  Alternatively, add this to a RUNME txt file and it will be parsed and added to the yaml.

# 5) Launch the xxx.README.sh via slurm's sbatch or run it on your local server.  

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.


#### No need to modify anything below ####
set -e
rm -f FAILED COMPLETE QUEUED; touch STARTED
start=$(date +'%s')
jobDir=$(realpath .)
name=${PWD##*/}

# Define a temporary directory physically on the node in which to copy over all the job files.  This will be deleted and then recreated.
tempDir=/scratch/local/$USER/$SLURM_JOB_ID
rm -rf $tempDir &> /dev/null || true; mkdir -p $tempDir/$name || true

echo -e "\n---------- Copying job files to tempDir -------- $((($(date +'%s') - $start)/60)) min"
rsync -rtL --exclude 'slurm-*' $jobDir/ $tempDir/$name/ && echo CopyOverOK || echo CopyOverFAILED

# Execute the sing file in the container from the tempDir, always return true, even if it fails so one can copy all back
echo -e "\n---------- Launching container -------- $((($(date +'%s') - $start)/60)) min"
cd $tempDir/$name
set +e
SINGULARITYENV_jobDir=$tempDir/$name SINGULARITYENV_dataBundle=$dataBundle \
  singularity exec --containall --bind $dataBundle,$tempDir/$name $container \
  bash $tempDir/$name/*.sing

echo -e "\n---------- Files In Temp -------- $((($(date +'%s') - $start)/60)) min"
ls -1 $tempDir/$name

# Copy back job files regardless of success or failure, disable exit on error, exclude the fastqs, and crams
echo -e "\n---------- Copying back results -------- $((($(date +'%s') - $start)/60)) min"
sleep 2s
rm -rf $tempDir/$name/*.cram $tempDir/$name/*.crai &> /dev/null || true
rsync -rtL --exclude '*q.gz' $tempDir/$name/ $jobDir/ && echo CopyBackOK || { echo CopyBackFAILED; rm -f COMPLETE; }

echo -e "\n---------- Files In JobDir -------- $((($(date +'%s') - $start)/60)) min"
ls -1 $jobDir; cd $jobDir; rm -rf $tempDir &> /dev/null || true

# OK?
if [ -f COMPLETE ];
then
  echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"
  mkdir -p RunScripts
  mv -f slurm* *stats.json Logs/ 
  mv -f *cellRanger.* RUNME RunScripts/ 
  rm -rf .snakemake STARTED RESTARTED QUEUED FAILED 
  # Delete the fastqs?
  rm -f *q.gz
else
  echo -e "\n---------- FAILED! -------- $((($(date +'%s') - $start)/60)) min total"
  rm -rf STARTED RESTARTED QUEUED
  touch FAILED
fi

