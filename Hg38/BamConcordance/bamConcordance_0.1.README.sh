#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE; touch STARTED

# 10 September 2018
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This fires the BamConcordance app from USeq to calculate sample concordance based on homozygous variants found present in bam files.  Use this with RNASeq and DNASeq datasets.

#### Do just once ####

# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.1/udocker

# 2) Define a root mount file path that contains the fastq files to analyze, your working job directories, and reference files. These need to be in sub direcatories of the mount path. UDocker can only see files that reside within this path.
mount=/scratch/mammoth/serial/u0028003/

# 3) Modify the bamConcordance_*.udocker file setting the paths to the required resources. These must be on the mount path. See http://bioserver.hci.utah.edu/USeq/Documentation/cmdLnMenus.html#BamConcordance 

# 4) Build the udocker container, do just once after each update.
## $udocker rm SnakeMakeBioApps_2 && $udocker pull hcibioinformatics/public:SnakeMakeBioApps_2 && $udocker create --name=SnakeMakeBioApps_2  hcibioinformatics/public:SnakeMakeBioApps_2 && echo "UDocker Container Built"


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the mount path.

# 2) Soft link your bam and matched bai files into the job directory.

# 3) Copy over the bamConcordance_xxx.udocker, bamConcordance_xxx.README.sh, and bamConcordance_xxx.sm workflow docs

# 4) If needed, modify the filtering params in the local copy of the bamConcordance_xxx.udocker file

# 5) Launch the bamConcordance_xxx.README.sh via sbatch or run it on your local server.  

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off. 



#### No need to modify anything below ####
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params and fetch real path for linked fastq
name=${PWD##*/}
jobDir=`readlink -f .`

$udocker run \
--env=name=$name --env=jobDir=$jobDir \
--volume=$mount:$mount \
SnakeMakeBioApps_2 < bamConcordance_*.udocker

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv bamConcordance* RunScripts/
mv *Run.log  *RunStats.log Logs/
rm -rf .snakemake 
mv slurm* Logs/
rm -f FAILED STARTED DONE; touch COMPLETE 
