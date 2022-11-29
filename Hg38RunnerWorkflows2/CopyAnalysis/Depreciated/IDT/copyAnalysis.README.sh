#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 24:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 10 Dec 2021
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This fires a GATK CNV workflow generating copy ratio and heterozygous allele frequency segment calls. See https://gatkforums.broadinstitute.org/dsde/discussion/11682 and https://gatkforums.broadinstitute.org/dsde/discussion/11683 


#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/general/pe-nfs1/u0028003

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:GATK_SM_1
container=$dataBundle/Containers/public_GATK_SM_1.sif

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link your:
#    a) Tumor and normal bam (or cram) files and their associated indexes into the job dir naming them tumor.bam/.bai(or .cram/.crai), normal.bam/.bai(or .cram/.crai)
#    b) Germline variant xxx.vcf.gz file with its associated index
#    c) Gender and capture matched PoN hdf5 file (see ~/TNRunner/CNV/AVATAR/Somatic/IDT and NIM, xxxFemalePoN.hdf5 or xxxMalePoN.hdf5) 

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the job directory.

# 4) Look at and if needed modify the xxx.sing file 'intervals' to match the PoN.

# 5) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params
name=${PWD##*/}
jobDir=`readlink -f .`

SINGULARITYENV_name=$name SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $dataBundle,$myData $container \
bash $jobDir/*.sing


echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv -f copyAnalysis* RunScripts/
cp slurm* Logs/ &> /dev/null || true
mv -f *snakemake.stats.json Logs/ &> /dev/null || true
rm -rf .snakemake STARTED RESTART* QUEUED slurm*
touch COMPLETE 

