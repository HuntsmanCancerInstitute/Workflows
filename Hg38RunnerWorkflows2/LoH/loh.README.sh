#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 24:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 10 October 2022
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This launches a Loss of Heterozygosity analysis of germline variant allele fractions in the tumor sample.

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place it in your path
which singularity &> /dev/null || module load singularity

# 2) Set the path to the TNRunner dataBundle in the snakemake config yaml file. It can be downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578
dataBundle=$(grep dataBundle *.yaml | grep -v ^# | cut -d ' ' -f2)

# 3) Check and if needed, modify the parameters specific to this workflow in the snakemake config yaml file.

# 4) If needed build the singularity container, and define the path to the xxx.sif file, do after each update, e.g. singularity pull docker://hcibioinformatics/public:GATK_SM_2
container=$dataBundle/Containers/public_GATK_SM_2.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. 

# 2) Soft link your:
#    a) Tumor and Normal USeq BamPileup files and their associated tabix indexes into the job dir naming them tumor.bp.txt.gz, normal.bp.txt.gz, tumor.bp.txt.gz.tbi, and normal.bp.txt.gz.tbi 
#    b) High confident, filtered, and annotated germline variant xxx.vcf.gz file with its associated index, any name ending in vcf.gz works.
#    c) Seg pass bed file from running the TNRunner CopyRatio workflow xxx_GATKCopyRatio_Hg38.called.seg.pass.bed.gz

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, xxx.sm, and the xxx.yaml snakemake config file into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on the local server, e.g. bash ./*README.sh  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

# Read out params
jobDir=`readlink -f .`

SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $jobDir,$dataBundle $container \
bash $jobDir/*.sing

# Final cleanup
mkdir -p RunScripts
mv -f loh*  RunScripts/ &> /dev/null || true
mv -f *.yaml RunScripts/ &> /dev/null || true
cp slurm* Logs/ &> /dev/null || true
mv -f *snakemake.stats.json Logs/ &> /dev/null || true
rm -rf .snakemake STARTED RESTART* QUEUED slurm*
