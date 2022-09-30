#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 1 Sept 2021
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard GATK GenotypeGVCFs analysis followed by normalizing the vcf with vt and splitting it into individual vcf files with light filtering.

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity/3.6.4

# 2) Define file paths to "mount" in the container. 
## The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578 . 
## The second is the path to your data.
## The third is to a temporary dir for fast local node processing. WARNING, this will be deleted.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/general/pe-nfs1/u0028003
tmpDir=/scratch/local/$USER/$SLURM_JOB_ID/JointGenotypingTmp

# 3) Modify the workflow xxx.sing file setting the paths to the required resources.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
## singularity pull docker://hcibioinformatics/public:GATK_SM_1
container=$dataBundle/Containers/public_GATK_SM_1.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Create a folder named ToGenotype in the analysis folder.

# 2) Move or Soft link all the xxx.g.vcf.gz files into the ToGenotype folder from running the GATK Haplotype caller.

# 3) Copy over the JointGenotyping workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the analysis folder.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

echo -e "\n---------- Rsyncing ToGenotype -------- $((($(date +'%s') - $start)/60)) min"

# Delete and make the tmp directory
rm -rf $tmpDir &> /dev/null || true; mkdir -p $tmpDir || true

# Copy Vcfs to tmp to speed up processing
rsync -rLq ToGenotype/ $tmpDir/ToGenotype/ && echo 'Rsync COMPLETE' || echo 'Rsync FAILED'

jobDir=$(realpath .)

echo -e "\n---------- Launching Container -------- $((($(date +'%s') - $start)/60)) min"

SINGULARITYENV_tmpDir=$tmpDir SINGULARITYENV_dataBundle=$dataBundle SINGULARITYENV_jobDir=$jobDir \
singularity exec --containall --bind $dataBundle,$myData,$tmpDir $container bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv jointGeno* RunScripts/
mv -f slurm* *snakemake.stats.json Logs/ &> /dev/null || true
rm -rf .snakemake STARTED RESTART* QUEUED 


