#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 11 Dec 2018
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This fires a GATK CNV workflow generating copy ratio and heterozygous allele frequency segment calls. See https://gatkforums.broadinstitute.org/dsde/discussion/11682 and https://gatkforums.broadinstitute.org/dsde/discussion/11683 

# Major issue! The CR segs identified in the tumor are often present in the matched normal. The USeq GatkCalledSegmentAnnotator enables filtering for these types of false positives.


#### Do just once ####

# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.3/udocker

# 2) Define two mount file paths to expose in udocker. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/gnomexFlex.jsp?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/mammoth/serial/u0028003

# 3) Modify the xxx.udocker file setting the paths to the required resources. These must be within the mounts.

# 4) Build the udocker container, do just once after each update.
#    $udocker rm GatkPlus_1 && $udocker pull hcibioinformatics/public:GatkPlus_1 && $udocker create --name=GatkPlus_1 hcibioinformatics/public:GatkPlus_1  && echo "UDocker Container Built"



#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link your:
#    a) Tumor and normal bam files and their associated indexes into the job dir naming them tumor.bam/.bai, normal.bam/.bai
#    b) Germline variant xxx.vcf.gz file with its associated index
#    c) Gender matched panel of normals hdf5 file (see ~/TNRunner/CNV/Bkg/, xxxFemalePoN.hdf5 or /CNV/Bkg/xxxMalePoN.hdf5) 

# 3) Copy over the workflow docs: xxx.udocker, xxx.README.sh, and xxx.sm into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params and fetch real path for linked fastq
name=${PWD##*/}
jobDir=`readlink -f .`
tumorBam=`readlink -f tumor.bam`
normalBam=`readlink -f normal.bam`
vcf=`readlink -f *vcf.gz`
bkg=`readlink -f *PoN.hdf5`

$udocker run --env=name=$name --env=jobDir=$jobDir \
--volume=$dataBundle:$dataBundle --volume=$myData:$myData \
--env=tumorBam=$tumorBam --env=normalBam=$normalBam --env=vcf=$vcf \
--env=bkg=$bkg GatkPlus_1 < *.udocker

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv -f cnv_* RunScripts/
mv -f *.log Logs/
rm -rf .snakemake 
mv -f slurm* Logs/
rm -f FAILED STARTED DONE
touch COMPLETE

