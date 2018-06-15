#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 72:00:00

# 31 May 2018
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This workflow utilizes a public docker image to execute a snakemake somatic variant workflow.  Specifically, three tumor normal somatic short variant analyis applications (GATK-Mutect2, Illumina-Manta/Strelk2, and Lofreq) are launched, lightly filtered, and combine into a composite vcf file.  The vcf record's ID column lists the callers that reported each variant.  To create a universal variant QUAL score independent of a particular callers algorithm, each variant's allele frequency is converted into a z-score by comparing it to the  non-reference allele frequencies in a panel of normals at that position.  This bkz score also effectively down weights variants in error prone regions of the genome controling for localized platform specific artifacts.

#Download the workflow files from : https://github.com/HuntsmanCancerInstitute/Workflows/tree/master/VariantCalling



####### USAGE #######


#### Do just once ####

# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.1/udocker

# 2) Define a root mount file path that contains the bam files to analyze, your working job directories, and reference files. These need to be in sub direcatories of the mount path. UDocker can only see files that reside within this path.
mount=/scratch/mammoth/serial/u0028003/

# 3) Modify the somTriCaller_*.udocker.sh file setting the paths to the required resources. These must be on the mount path.
## emacs $mount/SomTriCallerWorkflowDocs/somTriCaller_*.udocker.sh 
## regionsForAnalysis - a sorted, bgzipped, and tabix indexed bed file of regions to report variants. See https://github.com/samtools/htslib
## indexFasta - the same fasta file used in sample alignment. Also needed are the index xxx.fa.fai and xxx.dict files.
## dbsnp - vt normalize and decompose_blocksub the dbsnp file, bgzip, and tabix index. See https://genome.sph.umich.edu/wiki/Vt and https://github.com/samtools/htslib
## mpileup - a multi sample background mpileup file of 10-25 normal bam files. See http://bioserver.hci.utah.edu/USeq/Documentation/cmdLnMenus.html#VCFBackgroundChecker

# 4) Build the udocker container for reuse, do just once after each update.
## $udocker pull hcibioinformatics/public:SnakeMakeBioApps_1
## $udocker create --name=SnakeMakeBioApps_1  hcibioinformatics/public:SnakeMakeBioApps_1


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the mount path.
## cd $mount/SomaticAnalysis/; mkdir Patient_123_SomTriCaller; cd Patient_123_SomTriCaller

# 2) Soft link bam and bai files naming them tumor.bam, tumor.bai, normal.bam, and normal.bai. The actual files must reside in the mount path for the container to be able to see them.
## ln -s $mount/Bams/p123Tumor.bam tumor.bam; ln -s $mount/Bams/p123Tumor.bai tumor.bai; ln -s $mount/Bams/p123Normal.bam normal.bam; ln -s $mount/Bams/p123Normal.bai normal.bai;

# 3) Copy over the somTriCaller_xxx.udocker.sh, somTriCaller_xxx.slurm.sh, and somTriCaller_xxx.sm workflow docs
## cp $mount/SomTriCallerWorkflowDocs/* .

# 4) If needed, modify the filtering params in the local copy of the somTriCaller_xxx.udocker.sh file, e.g. read depth, AF, AF ratio, etc.
## emacs somTriCaller_*.udocker.sh

# 5) Launch the somTriCaller_xxx.slurm.sh via sbatch.  For other cluster engines, use the somTriCaller_xxx.slurm.sh as a template.
## sbatch somTriCaller_*.slurm.sh

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
SnakeMakeBioApps_1 < somTriCaller_*.udocker.sh

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"
