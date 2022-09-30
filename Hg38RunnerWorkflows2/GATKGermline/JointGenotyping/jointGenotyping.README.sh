#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e

# 4 Jan 2022
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard GATK GenotypeGVCFs analysis followed by normalizing the vcf with vt and splitting it into individual vcf files with light filtering.

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place it in your path
which singularity &> /dev/null || module load singularity

# 2) Set the path to the TNRunner dataBundle in the snakemake config yaml file. It can be downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578
dataBundle=$(grep dataBundle *.yaml | grep -v ^# | cut -d ' ' -f2)

# 3) Check and if needed, modify the parameters specific to this workflow in the snakemake config yaml file.

# 4) If needed build the singularity container, and define the path to the xxx.sif file, do after each update, e.g. singularity pull docker://hcibioinformatics/public:GATK_SM_1
container=$dataBundle/Containers/public_GATK_SM_1.sif

# 5) If running this on AWS EC2 via the JobRunner, build the resource archive, and upload it to S3
# cd /uufs/chpc.utah.edu/common/PE/hci-bioinformatics1
# zip -r dnaAlignQC_3Nov2021.zip TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.* TNRunner/Containers/public_SM_BWA_1.sif \
#   TNRunner/Bed/AvatarMergedNimIdtBeds/hg38NimIdtMergedPad150bp.bed.gz* TNRunner/Bed/AvatarMergedNimIdtBeds/hg38NimIdtCCDSShared.bed.gz*


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Create a folder named ToGenotype in the analysis folder.

# 3) Move or Soft link all the xxx.g.vcf.gz files into the ToGenotype folder from running the GATK Haplotype caller.

# 4) Copy over the workflow docs: xxx.sing, xxx.README.sh, xxx.sm, and the xxx.yaml snakemake config file into the job directory.

# 5) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.


#### No need to modify anything below ####
jobDir=$(realpath .)

# make a temp dir
tmpDir=/scratch/local/$USER/$SLURM_JOB_ID/JointGenotypingTmp
rm -rf $tmpDir; mkdir -p $tmpDir &> /dev/null || true
if [ ! -d $tmpDir ]; then
    tmpDir=$jobDir"/JointGenotypingTmp"; rm -rf $tmpDir; mkdir $tmpDir
fi

SINGULARITYENV_dataBundle=$dataBundle SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_tmpDir=$tmpDir \
singularity exec --containall --bind $dataBundle,$tmpDir $container bash $jobDir/*.sing



