#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

# 17 July 2024
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard BWA mem alt aware alignment followed by quality filtering, and deduplication.
# The output alignment cram file has been filtered and only contains uniquely aligned primary alignments.
# The read coverage statistics are only valid for WGS, ChiPSeq, and WES.  They will be incorrect for small panel captures.  These require custom target bed files.
# UMIs if present are ignored.

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place it in your path
module load singularity

# 2) Set the path to the data bundles defined in the snakemake config yaml file. They are needed here to enable singularity access.
tnRunner=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
atlatl=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/atlatl

# 3) Check and if needed, modify the parameters specific to this workflow in the config yaml file.

# 4) If needed build the singularity container, and define the path to the xxx.sif file, do after each update, e.g. singularity pull docker://hcibioinformatics/public:SM_BWA_2
container=$tnRunner/Containers/public_SM_BWA_2.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. 

# 2) Soft link or copy your paired fastq.gz files into the job dir, their names should end in xxxq.gz and contain _R1_ and _R2_ . Multiple R1s and R2s will be combine. These WILL BE DELETED upon completion.

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, xxx.sm, and species_seqPlatform_adapter matched xxx.DnaAlignQC.yaml config file into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.


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
SINGULARITYENV_jobDir=$tempDir/$name SINGULARITYENV_fastqRead1=$fastqRead1 SINGULARITYENV_fastqRead2=$fastqRead2 \
  singularity exec --containall --bind $atlatl,$tnRunner,$tempDir/$name $container \
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
  mv -f dnaAlignQC* RUNME *yaml RunScripts/ 
  rm -rf .snakemake STARTED RESTARTED QUEUED FAILED *cram* *q.gz
else
  echo -e "\n---------- FAILED! -------- $((($(date +'%s') - $start)/60)) min total"
  rm -rf STARTED RESTARTED QUEUED
  touch FAILED
fi
