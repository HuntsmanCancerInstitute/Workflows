#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e

# MSI Calling Workflow 
# 20 Jan 2022
# David.Nix@hci.utah.edu
# Aaron.Atkinson@Hci.Utah.Edu
# Huntsman Cancer Institute

# MSI status calculator with Mantis https://github.com/OSU-SRLab/MANTIS

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place it in your path
which singularity &> /dev/null || module load singularity

# 2) Set the path to the TNRunner dataBundle in the snakemake config yaml file. It can be downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578
dataBundle=$(grep dataBundle *.yaml | grep -v ^# | cut -d ' ' -f2)

# 3) Check and if needed, modify the parameters specific to this workflow in the snakemake config yaml file.

# 4) If needed build the singularity container, and define the path to the xxx.sif file, do after each update, e.g. singularity pull docker://hcibioinformatics/public:MSI_SM_1
container=$dataBundle/Containers/public_MSI_SM_1.sif

# 5) If running this on AWS EC2 via the JobRunner, build the resource archive, and upload it to S3
# cd /uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/
# zip -r msi_20Jan2022.zip  \
#   TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.fasta \
#   TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.dict \
#   TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.fasta.fai \
#   TNRunner/Containers/public_MSI_SM_1.sif \
#   TNRunner/Bed/Msi/MSI6.sorted.bed
#   aws s3 cp msi_20Jan2022.zip s3://hcibioinfo-jobrunner/ResourceBundles/ && rm -f msi_20Jan2022.zip

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. 

# 2) Soft link bam and bai files naming them tumor.bam, tumor.bai, normal.bam, and normal.bai into the analysis folder. Cram files and crai indexes also work, name them tumor.cram, tumor.crai, normal.cram, and normal.crai.

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, xxx.sm, and the xxx.yaml snakemake config file into the job directory.

# 4) Launch the xxx.README.sh via slurm's sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.


#### No need to modify anything below ####

# Read out params
jobDir=`readlink -f .`

SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $dataBundle,$jobDir $container \
bash $jobDir/*.sing

# Final cleanup
mkdir -p RunScripts
mv -f msi.*  RunScripts/ &> /dev/null || true
mv -f *.yaml RunScripts/ &> /dev/null || true
cp slurm* Logs/ &> /dev/null || true
mv -f *snakemake.stats.json Logs/ &> /dev/null || true
rm -rf .snakemake STARTED RESTART* QUEUED slurm* TmpBams
