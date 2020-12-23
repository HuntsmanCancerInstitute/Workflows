#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 8 April 2020
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard BWA mem alignment to Hg38/GRCh38 followed by quality filtering, deduping, base score recalibration, haplotype calling, and various QC calculations.
# Run the USeq AggregateQCStats app on a directory containing multiple alignment runs to combine all the QC results into several relevant QC reports.


#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity/3.6.4

# 2) Define a temporary directory physically on the node in which to copy over all the resources and job files.  This will be deleted and then recreated.
tempDir=/scratch/local/TempDeleteMe_u0028003

# 3) Define the file path to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/gnomexFlex.jsp?analysisNumber=A5578 and the required reference resources
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
## Tempus xT and xE
regionsForReadCoverage=$dataBundle/Bed/Tempus/TempusXT648Hg38/refGeneTempusXT648_CCDS.bed.gz
regionsForOnTarget=$dataBundle/Bed/AllExonHg38Bed8April2020/hg38AllGeneExonsPad175bp.bed.gz

# 4) Modify the workflow xxx.sing file setting the paths to the required resources.

# 5) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:SnakeMakeBioApps_5
container=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/SingularityBuilds/public_SnakeMakeBioApps_5.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. 

# 2) Soft link your paired fastq.gz files into the job dir naming them 1.fastq.gz and 2.fastq.gz 

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the job directory.

# 4) Add a file named sam2USeq.config.txt that contains a single line of params for the sam2USeq tool, e.g. -c 10, or -c 20 to define the minimum read coverage for the normal or tumor samples respectively.

# 5) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

echo -e "\n---------- Copying Resources to Temp Dir -------- $((($(date +'%s') - $start)/60)) min"

# Read out params
name=${PWD##*/}
jobDir=`readlink -f .`

# Check that required files are present
echo "Checking for required files"
ls 1.fastq.gz 2.fastq.gz sam2USeq.config.txt dnaAlignQC.README.sh dnaAlignQC.sing dnaAlignQC.sm > /dev/null
echo

# Create new working temp dir
rm -rf $tempDir
mkdir -p $tempDir/$name $tempDir/Ref

# Echo real fastq names
echo "fastqOne     : "$(realpath 1.fastq.gz)
echo "fastqTwo     : "$(realpath 2.fastq.gz)

# Copy over job files
rsync -rtL --exclude 'slurm-*' $jobDir/ $tempDir/$name/

# Copy over reference files
indexFastaTruncated=$dataBundle/Indexes/B38IndexForBwa-0.7.17/hs38DH
dbsnp=$dataBundle/Vcfs/dbsnp_146.hg38.vcf.gz
gSnp=$dataBundle/Vcfs/1000G_phase1.snps.high_confidence.hg38.vcf.gz
gIndel=$dataBundle/Vcfs/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
rsync -rtL $regionsForReadCoverage* $regionsForOnTarget* $indexFastaTruncated* $dbsnp* $gSnp* $gIndel* $tempDir/Ref/

# Disable set -e, abort on error, will use files to check for completion
set +e

# Launch workflow
echo -e "\n---------- Launching Workflow -------- $((($(date +'%s') - $start)/60)) min"
SINGULARITYENV_name=$name \
SINGULARITYENV_tempDir=$tempDir \
SINGULARITYENV_regionsForReadCoverage=${regionsForReadCoverage##*/} \
SINGULARITYENV_regionsForOnTarget=${regionsForOnTarget##*/} \
SINGULARITYENV_regionsForReadCoverage=${regionsForReadCoverage##*/} \
SINGULARITYENV_indexFastaTruncated=${indexFastaTruncated##*/} \
SINGULARITYENV_dbsnp=${dbsnp##*/} \
SINGULARITYENV_gSnp=${gSnp##*/} \
SINGULARITYENV_gIndel=${gIndel##*/} \
singularity exec --containall --bind $tempDir $container \
bash $tempDir/$name/*.sing && touch COMPLETE

# Copy back job files regardless of success or failure
echo -e "\n---------- Copying back results -------- $((($(date +'%s') - $start)/60)) min"
rsync -rtL --exclude '*.fastq.gz' $tempDir/$name/ $jobDir/

# Delete temp dir regardless of job outcome
rm -rf $tempDir

if [ -f COMPLETE ];
then
  mkdir -p RunScripts
  mv dnaAlignQC* sam2USeq.config.txt RunScripts/
  mv -f *.log  Logs/ || true
  rm -rf .snakemake
  rm -f FAILED STARTED DONE RESTART QUEUED
  echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"
  mv -f slurm* Logs/ || true
else
  echo -e "\n---------- FAILED! -------- $((($(date +'%s') - $start)/60)) min total"
  touch FAILED
  rm -f STARTED DONE RESTART QUEUED
fi
