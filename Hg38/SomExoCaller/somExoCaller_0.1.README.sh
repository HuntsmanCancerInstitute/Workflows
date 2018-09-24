#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; rm -f FAILED COMPLETE QUEUED; touch STARTED

# 14 September 2018
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This tumor-normal exome workflow uses Illumina's Manta and Strelka2 variant callers to identify short INDELs and SNVs. 
# A tuned set of filtering statistics is applied to produce lists with different FDR tiers. 
# Lastly a panel of normals is used to remove systematic false positives due to high localized background. 
# It works best with tumor samples sequenced to >= 100x depth and >= 20x for the normal.  

#### Do just once ####

# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.1/udocker

# 2) Define two mount file paths to expose in udocker. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/gnomexFlex.jsp?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/mammoth/serial/u0028003

# 3) Modify the SomExoCaller workflow xxx.udocker file setting the paths to the required resources. These must be within the mounts.

# 4) Build the udocker container, do just once after each update.
## $udocker rm SnakeMakeBioApps_3 && $udocker pull hcibioinformatics/public:SnakeMakeBioApps_3 && $udocker create --name=SnakeMakeBioApps_3  hcibioinformatics/public:SnakeMakeBioApps_3 && echo "UDocker Container Built"


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link bam and bai files naming them tumor.bam, tumor.bai, normal.bam, and normal.bai into the analysis folder. 

# 3) Soft link passing read coverage bed files for the tumor and normal samples naming them tumor.bed.gz and normal.bed.gz into the analysis folder. 

# 3) Copy over the SomExoCaller workflow docs: xxx.udocker, xxx.README.sh, and xxx.sm into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

start=$(date +'%s')
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params
name=${PWD##*/}
tumorBam=`readlink -f tumor.bam`
normalBam=`readlink -f normal.bam`
jobDir=`readlink -f .`
tumorBed=`readlink -f tumor.bed.gz`
normalBed=`readlink -f normal.bed.gz`


echo -e "\n---------- Launching Container -------- $((($(date +'%s') - $start)/60)) min"
$udocker run \
--env=tumorBam=$tumorBam --env=normalBam=$normalBam --env=name=$name --env=jobDir=$jobDir \
--env=tumorBed=$tumorBed --env=normalBed=$normalBed \
--volume=$dataBundle:$dataBundle --volume=$myData:$myData \
SnakeMakeBioApps_3 < somExoCaller_*.udocker

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv somExoCaller* RunScripts/
mv *_SnakemakeRun.log Logs/
mv slurm* Logs/
rm -rf .snakemake
rm -f FAILED STARTED; touch COMPLETE



