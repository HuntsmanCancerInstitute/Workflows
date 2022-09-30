#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 4 Jan 2022
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is uses Manta2 + Strelka2 to call germline variants. In a systematic benchmarking comparison, Manta2/Strelka2 out performs GATK Haplotyping/JointGenotyping for calling germline variants: https://www.nature.com/articles/s41598-019-45835-3

# WARNING, only jointly call <= 10 sample sets at a time. 

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity

# 2) Define file paths to "mount" in the container. 
## The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578 . 
## The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/general/pe-nfs1/u0028003

# 3) Modify the workflow xxx.sing file setting the paths to the required resources.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
## singularity pull docker://hcibioinformatics/public:ILLUM_SM_1
container=$dataBundle/Containers/public_ILLUM_SM_1.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Create a folder named ToGenotype in the analysis folder.

# 3) Move or Soft link all the xxx.cram files into the ToGenotype folder from running the DnaAlignQC workflow.

# 4) Copy over the StrelkaGermline workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the analysis folder.

# 5) Launch the xxx.README.sh via sbatch or run it on your local server, e.g. "bash ./*README.sh"  

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

jobDir=$(realpath .)

echo -e "\n---------- Launching Container -------- $((($(date +'%s') - $start)/60)) min"

SINGULARITYENV_dataBundle=$dataBundle SINGULARITYENV_jobDir=$jobDir \
singularity exec --containall --bind $dataBundle,$myData,$tmpDir $container bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv -f illuminaGermline*  RunScripts/
#mv -f  *.yaml RunScripts/ &> /dev/null || true
cp slurm* Logs/ &> /dev/null || true
mv -f *snakemake.stats.json Logs/ &> /dev/null || true
rm -rf .snakemake STARTED RESTART* QUEUED slurm*

