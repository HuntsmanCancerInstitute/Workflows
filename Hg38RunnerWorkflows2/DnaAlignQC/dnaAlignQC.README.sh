#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

# 6 July 2023
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard BWA mem alt aware alignment to Hg38/GRCh38 followed by quality filtering, deduplication, and read depth QC.
# The output alignment cram file has been filtered and only contains uniquely aligned primary alignments.
# Don't use this for structural variant and repeat/ segment duplication analysis without disabling those settings.



#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place it in your path
which singularity &> /dev/null || module load singularity

# 2) Set the path to the TNRunner dataBundle in the snakemake config yaml file. It can be downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578
dataBundle=$(grep dataBundle *.yaml | grep -v ^# | cut -d ' ' -f2)

# 3) Check and if needed, modify the parameters specific to this workflow in the snakemake config yaml file.

# 4) If needed build the singularity container, and define the path to the xxx.sif file, do after each update, e.g. singularity pull docker://hcibioinformatics/public:SM_BWA_1
container=$dataBundle/Containers/public_SM_BWA_1.sif

# 5) If running this on AWS EC2 via the JobRunner, build the resource archive, and upload it to S3
# cd /uufs/chpc.utah.edu/common/PE/hci-bioinformatics1
# zip -r dnaAlignQC_3Nov2021.zip TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.* TNRunner/Containers/public_SM_BWA_1.sif \
#   TNRunner/Bed/AvatarMergedNimIdtBeds/hg38NimIdtMergedPad150bp.bed.gz* TNRunner/Bed/AvatarMergedNimIdtBeds/hg38NimIdtCCDSShared.bed.gz*


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. 

# 2) Soft link or move your paired fastq.gz files into the job dir, their names should end in xxxq.gz . Alternatively provide a cram file and it will be converted to paired fastq.

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, xxx.sm, and the tnRunner.yaml config file into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####
set -e
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
set +e
cd $tempDir/$name
SINGULARITYENV_dataBundle=$dataBundle SINGULARITYENV_jobDir=$tempDir/$name \
  singularity exec --containall --bind $dataBundle,$tempDir/$name $container bash $tempDir/$name/*.sing || true

echo -e "\n---------- Files In Temp -------- $((($(date +'%s') - $start)/60)) min"
ls -1 $tempDir/$name

# Copy back job files regardless of success or failure, disable exit on error, exclude the cram and fastq files
echo -e "\n---------- Copying back results -------- $((($(date +'%s') - $start)/60)) min"
rm -f $tempDir/$name/*cram* &> /dev/null
sleep 2s
rsync -rtL --exclude '*q.gz' $tempDir/$name/ $jobDir/ && echo CopyBackOK || { echo CopyBackFAILED; rm -f COMPLETE; }

echo -e "\n---------- Files In JobDir -------- $((($(date +'%s') - $start)/60)) min"
ls -1 $jobDir; cd $jobDir; rm -rf $tempDir &> /dev/null 

# OK?
if [ -f COMPLETE ];
then
  echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"
  mv -f slurm* Logs/ 
  rm -f dnaAlignQC.* QUEUED
else
  echo -e "\n---------- FAILED! -------- $((($(date +'%s') - $start)/60)) min total"
  touch FAILED
fi


