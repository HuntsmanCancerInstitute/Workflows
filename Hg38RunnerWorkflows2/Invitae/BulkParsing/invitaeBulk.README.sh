#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 24 Oct 2023
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This workflow converts the Invitae bulk export csv files to patient specific json, vcf, and bed interrogated regions.
# It uses Crossmaps the vcf to Hg38, and builds PMR compatable dirs.


#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/gnomexFlex.jsp?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:Invitae_1
container=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner/Containers/public_Invitae_1.sif

#### Do for every run ####

# 1) Create a folder for this Invitae auto processing batch.

# 2) Add in the two patients and variants csv files from Invitae 

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.


#### No need to modify anything below ####

echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params 
jobDir=`readlink -f .`

SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $dataBundle $container \
bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv invitae* RunScripts/
mv -f slurm* Logs/ || true
rm -rf .snakemake 
rm -f FAILED STARTED DONE RESTARTED
touch COMPLETE 


