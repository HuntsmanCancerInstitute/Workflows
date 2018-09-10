#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE; touch STARTED

# 10 September 2018
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This fires a variety of apps that annotate a vcf with functional effect info using SnpEff, dbNSFP, ClinVar, and the VCFSpliceScanner.  It also generates a filtered vcf based on these annotations.



#### Do just once ####

# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.1/udocker

# 2) Define a root mount file path that contains the vcf files to analyze, your working job directories, and reference files. These need to be in sub direcatories of the mount path. UDocker can only see files that reside within this path.
mount=/scratch/mammoth/serial/u0028003/

# 3) Modify the annotator_*.udocker file setting the paths to the required resources. These must be on the mount path. 

# 4) Build the udocker container, do just once after each update.
## $udocker rm SnakeMakeBioApps_2 && $udocker pull hcibioinformatics/public:SnakeMakeBioApps_2 && $udocker create --name=SnakeMakeBioApps_2  hcibioinformatics/public:SnakeMakeBioApps_2 && echo "UDocker Container Built"



#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the mount path.

# 2) Copy or soft link your gzipped vcf file to annotate into the job directory naming them anything ending in .vcf.gz

# 3) Copy over the Annotator workflow docs: xxx.udocker, xxx.README.sh, and xxx.sm into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params and fetch real path for linked fastq
name=${PWD##*/}
jobDir=`readlink -f .`

$udocker run --env=name=$name --env=jobDir=$jobDir \
--volume=$mount:$mount SnakeMakeBioApps_2 < annotator_*.udocker

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv annotator_* RunScripts/
mv *Hg38_AnnotatorRun* Logs/
mv snpEff_* Logs/
rm -rf .snakemake 
mv -f slurm* Logs/
rm -f FAILED STARTED; touch COMPLETE

