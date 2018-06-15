#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 24:00:00

# 14 June 2018
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This tumor-normal exome workflow uses Illumina's Manta and Strelka2 variant callers to identify short INDELs and SNVs. 
# A tuned set of filtering statistics is applied to produce lists with different FDR tiers. 
# Lastly a panel of normals is used to remove systematic false positives due to high localized background. 
# It works best with tumor samples sequenced to >= 100x depth and >= 20x for the normal.  

# Download the workflow files from : https://github.com/HuntsmanCancerInstitute/Workflows/tree/master/VariantCalling/SomaticExome/


#### Do just once ####

# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.1/udocker

# 2) Define a root mount file path that contains the bam files to analyze, your working job directories, and reference files. These need to be in sub direcatories of the mount path. UDocker can only see files that reside within this path.
mount=/scratch/mammoth/serial/u0028003/

# 3) Modify the somExoCaller_*.udocker file setting the paths to the required resources. These must be on the mount path.
## emacs $mount/SomExoCallerWorkflowDocs/somExoCaller_*.udocker 
## regionsForAnalysis - a sorted, bgzipped, and tabix indexed bed file of regions to report variants. See https://github.com/samtools/htslib
## indexFasta - the same fasta file used in sample alignment. Also needed are the index xxx.fa.fai and xxx.dict files.
## mpileup - a multi sample background mpileup file of 10-25 normal bam files. See http://bioserver.hci.utah.edu/USeq/Documentation/cmdLnMenus.html#VCFBackgroundChecker

# 4) Build the udocker container, do just once after each update.
## (if needed) $udocker rm SnakeMakeBioApps_1
## $udocker pull hcibioinformatics/public:SnakeMakeBioApps_1
## $udocker create --name=SnakeMakeBioApps_1  hcibioinformatics/public:SnakeMakeBioApps_1


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the mount path.
## cd $mount/SomaticAnalysis/; mkdir Patient_123_SomExoCaller; cd Patient_123_SomExoCaller

# 2) Soft link bam and bai files naming them tumor.bam, tumor.bai, normal.bam, and normal.bai. The actual files must reside in the mount path for the container to be able to see them.
## ln -s $mount/Bams/p123Tumor.bam tumor.bam; ln -s $mount/Bams/p123Tumor.bai tumor.bai; ln -s $mount/Bams/p123Normal.bam normal.bam; ln -s $mount/Bams/p123Normal.bai normal.bai;

# 3) Copy over the somExoCaller_xxx.udocker, somExoCaller_xxx.README.sh, and somExoCaller_xxx.sm workflow docs
## cp $mount/SomExoCallerWorkflowDocs/* .

# 4) If needed, modify the filtering params in the local copy of the somExoCaller_xxx.udocker file, e.g. read depth, AF, AF ratio, etc. Set the target FDR tier: 1 (9-15%FDR), 2 (4-6%FDR), 3 (1-2%FDR), 0 no filtering (30-60%FDR with base filters but no QSS/QSI). See http://bioserver.hci.utah.edu/USeq/Documentation/cmdLnMenus.html#StrelkaVCFParser
## emacs somExoCaller_*.udocker

# 5) Launch the somExoCaller_xxx.README.sh via sbatch or run it on your local server.  For other cluster engines, use the somExoCaller_xxx.README.sh as a template.
## sbatch somExoCaller_*.slurm.sh

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off. 








#### No need to modify anything below ####

set -e; start=$(date +'%s')
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params
name=${PWD##*/}
tumor=`readlink -f tumor.bam`
normal=`readlink -f normal.bam`
jobDir=`readlink -f .`

echo -e "\n---------- Launching Container -------- $((($(date +'%s') - $start)/60)) min"
$udocker run \
--env=tumor=$tumor --env=normal=$normal --env=name=$name --env=jobDir=$jobDir \
--volume=$mount:$mount \
SnakeMakeBioApps_1 < somExoCaller_*.udocker

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv somExoCaller* RunScripts/
mv *_SnakemakeRun.log Logs/
mv slurm* Logs/
rm -rf .snakemake

