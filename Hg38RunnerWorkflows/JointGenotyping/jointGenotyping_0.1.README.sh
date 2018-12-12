#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f DONE FAILED COMPLETE QUEUED; touch STARTED

# 14 September 2018
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard GATK GenotypeGVCFs analysis followed by normalizing the vcf with vt and splitting it into individual vcf files with light filtering.


#### Do just once ####

# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.1/udocker

# 2) Define two mount file paths to expose in udocker. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/gnomexFlex.jsp?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/mammoth/serial/u0028003

# 3) Modify the JointGenotyping workflow xxx.udocker file setting the paths to the required resources. These must be within the mounts.

# 4) Build the udocker container, do just once after each update.
## $udocker rm SnakeMakeBioApps_3 && $udocker pull hcibioinformatics/public:SnakeMakeBioApps_3 && $udocker create --name=SnakeMakeBioApps_3  hcibioinformatics/public:SnakeMakeBioApps_3 && echo "UDocker Container Built"


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Create a folder named ToGenotype in the analysis folder.

# 2) Move or Soft link all the xxx.g.vcf.gz files into the ToGenotype folder from running the GATK Haplotype caller.

# 3) Copy over the JointGenotyping workflow docs: xxx.udocker, xxx.README.sh, and xxx.sm into the analysis folder.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params and fetch real path for linked fastq
name=${PWD##*/}
jobDir=`readlink -f .`

$udocker run --env=name=$name --env=jobDir=$jobDir \
--volume=$dataBundle:$dataBundle --volume=$myData:$myData \
SnakeMakeBioApps_3 < jointGenotyping_*.udocker

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv jointGenotyping_* RunScripts/
mv *.log Logs/
rm -rf .snakemake 
mv slurm* Logs/
rm -f DONE FAILED STARTED; touch COMPLETE

