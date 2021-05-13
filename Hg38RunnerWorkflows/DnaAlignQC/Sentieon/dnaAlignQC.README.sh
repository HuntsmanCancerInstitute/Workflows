#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# 11 May 2021
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard BWA mem alignment to Hg38/GRCh38 followed by quality filtering, deduping, indel realignment, 
#    base score recalibration, haplotype calling, and various QC calculations.
# Run the USeq AggregateQCStats app on a directory containing multiple alignment runs to combine all the QC 
#    results into several relevant QC reports.
# This uses the fast Sentieon apps where appropriate.  Uses modules loaded on redwood.chpc.utah.edu


# 1) Install and load sentieon, samtools, and snakemake as modules
module use /uufs/chpc.utah.edu/common/PE/proj_UCGD/modulefiles/$UUFSCELL &> /dev/null
module load sentieon/202010.02 &> /dev/null
module load snakemake/5.6.0 &> /dev/null
module load samtools/1.10 &> /dev/null

# 2) Define the file path to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner

# 3) Check the file paths to the Hg38 references and target bed files below

# 4) Create a folder named as you would like the analysis name to appear, this along with the genome build will 
#    be prepended onto all files, no spaces, change into it. 

# 5) Soft link or move your two paired sequence files into the job dir, be sure their name suffix is fastq.gz 

# 6) Copy over the two workflow docs: xxx.README.sh and xxx.sm into the job directory.

# 7) Add a file named sam2USeq.config.txt that contains a single line of params for the sam2USeq tool, e.g. -c 15, 
#    or -c 20 to define the minimum read coverage for the normal or tumor samples respectively.
#    echo -n "-c 20" > sam2USeq.config.txt

# 8) Launch the xxx.README.sh via sbatch or run it on your local server.  
#    If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.

# 9) Define a temporary directory physically on the node in which to copy over all the resources and job files.  This will be deleted and then recreated.
tempDir=/scratch/local/$USER/$SLURM_JOB_ID

# Read threads, ram, fastq
name=${PWD##*/}
unset OMP_NUM_THREADS
allThreads=`nproc`
allRam=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)
shopt -s nullglob; fq=(*fastq.gz)
fq1=`realpath ${fq[0]}`
fq2=`realpath ${fq[1]}`
jobDir=$(pwd)

# Print params
echo Params:
echo -n name"    : "; echo $name
echo -n jobDir"  : "; echo $jobDir
echo -n tempDir" : "; echo $tempDir
echo -n threads" : "; echo $allThreads
echo -n ram"     : "; echo $allRam
echo -n host"    : "; echo $(hostname)
echo -n fq1"     : "; echo $fq1
echo -n fq2"     : "; echo $fq2
echo -n s2u conf": "; cat sam2USeq.config.txt
echo

# Define paths to the reference files
regionsForReadCoverage=$dataBundle/Bed/AvatarMergedNimIdtBeds/hg38NimIdtCCDSShared.bed.gz
regionsForOnTarget=$dataBundle/Bed/hg38StdChromLengths.bed.gz
indexFastaTruncated=$dataBundle/Indexes/B38IndexForBwa-0.7.17/hs38DH
dbsnp=$dataBundle/Vcfs/dbsnp_146.hg38.vcf.gz
gSnp=$dataBundle/Vcfs/1000G_phase1.snps.high_confidence.hg38.vcf.gz
gIndel=$dataBundle/Vcfs/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz

# Look for required files
ls $fq1 $fq2 sam2USeq.config.txt dnaAlignQC.README.sh dnaAlignQC.sm $regionsForReadCoverage $regionsForOnTarget $dbsnp $gSnp $gIndel $indexFastaTruncated* &> /dev/null

# Pull base names for the ref files
nameReadCoverage=$(basename $regionsForReadCoverage)
nameOnTarget=$(basename $regionsForOnTarget)
nameSnp=$(basename $dbsnp)
nameGSnp=$(basename $gSnp)
nameGIndel=$(basename $gIndel)
nameIndex=$(basename $indexFastaTruncated)
nameFastq1=$(basename $fq1)
nameFastq2=$(basename $fq2)

# Print params
echo; echo Basenames:
echo -n "nameFastq1        : "; echo $nameFastq1
echo -n "nameFastq2        : "; echo $nameFastq2
echo -n "nameReadCoverage  : "; echo $nameReadCoverage
echo -n "nameOnTarget      : "; echo $nameOnTarget
echo -n "nameSnp           : "; echo $nameSnp
echo -n "nameGSnp          : "; echo $nameGSnp
echo -n "nameGIndel        : "; echo $nameGIndel
echo -n "nameIndex         : "; echo $nameIndex

# Create new working temp dir on node
rm -rf $tempDir &> /dev/null || true
mkdir -p $tempDir/$name $tempDir/Ref || true

echo -e "\n---------- Copying job files to tempDir -------- $((($(date +'%s') - $start)/60)) min"
rsync -rtL --exclude 'slurm-*' --exclude '*fastq.gz' $jobDir/ $tempDir/$name/
rsync -rtL $fq1 $fq2 $tempDir/$name/

echo -e "\n---------- Copying reference files to tempDir -------- $((($(date +'%s') - $start)/60)) min"
rsync -rtL $regionsForReadCoverage* $regionsForOnTarget* $indexFastaTruncated* $dbsnp* $gSnp* $gIndel* $tempDir/Ref/

# Change into the tempDir
cd $tempDir/$name

# Disable set -e, abort on error, will use files to check for completion
set +e

echo -e "\n---------- Launching Snakemake -------- $((($(date +'%s') - $start)/60)) min"
snakemake --printshellcmds --cores $allThreads --snakefile dnaAlignQC.sm --config \
regionsForReadCoverage=$tempDir/Ref/$nameReadCoverage \
regionsForOnTarget=$tempDir/Ref/$nameOnTarget \
indexFasta=$tempDir/Ref/$nameIndex.fa \
dbsnp=$tempDir/Ref/$nameSnp \
gSnp=$tempDir/Ref/$nameGSnp \
gIndel=$tempDir/Ref/$nameGIndel \
useq=$dataBundle/BioApps/USeq/Apps \
ucsc=$dataBundle/BioApps/UCSC/ \
htslib=$dataBundle/BioApps/HTSlib/1.10.2/bin \
useqSamAlignmentExtractor="-q 20 -a 0.65 -d -f -u" \
useqSam2USeq="-v Hg38 -x 2500 -r -w sam2USeq.config.txt" \
name=$name \
fastqReadOne=$nameFastq1 \
fastqReadTwo=$nameFastq2 \
allThreads=$allThreads \
allRam=$allRam 

# Copy back job files regardless of success or failure
echo -e "\n---------- Copying back results -------- $((($(date +'%s') - $start)/60)) min"
## Do twice, sometimes this fails
rsync -rtL --exclude '*fastq.gz' $tempDir/$name/ $jobDir/ || \
rsync -rtL --exclude '*fastq.gz' $tempDir/$name/ $jobDir/ && echo CopyBackOK

# Change back to the JobDir, delete temp dir, wait for files to register
cd $jobDir
ls -1 
rm -rf $tempDir/$name/* $tempDir/Ref/* $tempDir &> /dev/null || true
sleep 10s

# OK?
if [ -f COMPLETE ];
then
  mkdir -p RunScripts
  mv dnaAlignQC* sam2USeq.config.txt RunScripts/
  rm -rf .snakemake
  rm -f FAILED STARTED DONE RESTART QUEUED
  echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"
  mv -f slurm* Logs/ || true
else
  echo -e "\n---------- FAILED! -------- $((($(date +'%s') - $start)/60)) min total"
  touch FAILED
  rm -f STARTED DONE RESTART QUEUED
fi

# Notes
## regionsForOnTarget - bgzipped bed file of regions, typically +/- 150bp padded, to use in calculating on target capture rates, use chrXXXX naming. See bgzip and tabix from https://github.com/samtools/htslib .
## regionsForReadCoverage - bgzipped bed file of regions to use in calculating unique observation read coverage uniformity metrics, typically just the regions that you really care about and don't have any repeat issues.
## indexFasta - the BWA mem fasta file with all the associated index files including xxx.fa.fai and xxx.dict files, see https://github.com/lh3/bwa/tree/master/bwakit
## gIndels - a bgzipped and tabix indexed vcf file of trusted indels from the 1000 Genomes project Hg38GATKBundle, see https://software.broadinstitute.org/gatk/download/bundle
## gSnps - ditto, 1000G high confidence snps from the Hg38 GATKBundle
## dbsnp - ditto, dbSNP variants from the Hg38 GATKBundle
## useq - launch each app to see cmd line options

# Replace first and last lines above with the following to get dag svg graph
	# /BioApps/Miniconda3/bin/snakemake --dag \
	# allRam=$allRam | dot -Tsvg > $name"_dag.svg"
