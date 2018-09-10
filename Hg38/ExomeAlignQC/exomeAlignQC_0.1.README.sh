#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE; touch STARTED

# 10 September 2018
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard BWA mem alignment to Hg38/GRCh38 followed by quality filtering, deduping, base score recalibration, and various QC calculations.
# Run the USeq AggregateQCStats app on a directory containing multiple alignment runs to combine all the QC results into several relevant QC reports.


#### Do just once ####

# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.1/udocker

# 2) Define a root mount file path that contains the fastq files to analyze, your working job directories, and reference files. These need to be in sub direcatories of the mount path. UDocker can only see files that reside within this path.
mount=/scratch/mammoth/serial/u0028003/

# 3) Modify the hg38ExomeAlignQC_*.udocker file setting the paths to the required resources. These must be on the mount path.
## emacs hg38ExomeAlignQC_xxx.udocker 
## regionsForOnTarget - bgzipped bed file of regions to use in calculating on target capture rates, use chrXXXX naming. See bgzip and tabix from https://github.com/samtools/htslib .
## regionsForReadCoverage - bgzipped bed file of regions to use in calculating unique observation read coverage uniformity metrics, ditto.
## indexFasta - the BWA mem fasta file with all the associated index files including xxx.fa.fai and xxx.dict files, see https://github.com/lh3/bwa/tree/master/bwakit
## gIndels - a bgzipped and tabix indexed vcf file of trusted indels from the 1000 Genomes project Hg38GATKBundle, see https://software.broadinstitute.org/gatk/download/bundle
## gSnps - ditto, 1000G high confidence snps from the Hg38 GATKBundle
## dbsnp - ditto, dbSNP variants from the Hg38 GATKBundle

# 4) Build the udocker container, do just once after each update.
## $udocker rm SnakeMakeBioApps_2   # might not exit and throw erro
## $udocker pull hcibioinformatics/public:SnakeMakeBioApps_2
## $udocker create --name=SnakeMakeBioApps_2  hcibioinformatics/public:SnakeMakeBioApps_2


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the mount path.
## cd $mount/Alignments/; mkdir Patient_123_Germline; cd Patient_123_Germline

# 2) Soft link your paired fastq.gz files into the dir naming them 1.fastq.gz and 2.fastq.gz . The actual files must reside in the mount path for the container to be able to see them.
## ln -s $mount/Fastq/p123_1.fastq.gz 1.fastq.gz; ln -s $mount/Fastq/p123_2.fastq.gz 2.fastq.gz

# 3) Copy over the hg38ExomeAlignQC_xxx.udocker, hg38ExomeAlignQC_xxx.README.sh, and hg38ExomeAlignQC_xxx.sm workflow docs
## cp $mount/Hg38ExomeAlignQCWorkflowDocs/hg38ExomeAlignQC_* .

# 4) If needed, modify the filtering params in the local copy of the hg38ExomeAlignQC_xxx.udocker file, e.g. Minimum Mapping Quality, USeqSam2USeq min read count (differs for germline and somatic). Create a sam2USeq.config.txt param file?
## emacs hg38ExomeAlignQC_xxx.udocker

# 5) Launch the hg38ExomeAlignQC_xxx.README.sh via sbatch or run it on your local server.  For other cluster engines, use the hg38ExomeAlignQC_xxx.README.sh as a template.
## sbatch hg38ExomeAlignQC_xxx.README.sh

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off. 



#### No need to modify anything below ####
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params and fetch real path for linked fastq
name=${PWD##*/}
fastqReadOne=`readlink -f 1.fastq.gz`
fastqReadTwo=`readlink -f 2.fastq.gz`
jobDir=`readlink -f .`

$udocker run \
--env=fastqReadOne=$fastqReadOne --env=fastqReadTwo=$fastqReadTwo --env=name=$name --env=jobDir=$jobDir \
--volume=$mount:$mount \
SnakeMakeBioApps_2 < exomeAlignQC_*.udocker

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv exomeAlignQC* RunScripts/
mv *_ExomeAlignQCRun.log  *_ExomeAlignRunStats.log Logs/
rm -rf .snakemake 
mv slurm* Logs/
rm -f FAILED STARTED; touch COMPLETE
