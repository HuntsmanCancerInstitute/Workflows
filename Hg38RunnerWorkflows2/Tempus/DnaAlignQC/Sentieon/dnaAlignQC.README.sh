#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# 17 Aug 2020
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard BWA mem alignment to Hg38/GRCh38 followed by quality filtering, deduping, indel realignment, 
#    base score recalibration, haplotype calling, and various QC calculations.
# Run the USeq AggregateQCStats app on a directory containing multiple alignment runs to combine all the QC 
#    results into several relevant QC reports.
# This uses the fast Sentieon apps where appropriate.  Uses modules loaded on redwood.chpc.utah.edu


# 1) Install and load sentieon, samtools, and snakemake as modules
module use /uufs/chpc.utah.edu/common/PE/proj_UCGD/modulefiles/$UUFSCELL &> /dev/null
module load sentieon/201911.00 &> /dev/null
module load snakemake/5.6.0 &> /dev/null
module load samtools/1.10 &> /dev/null

# 2) Define the file path to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner

# 3) Check the file paths to the Hg38 references and target bed files in the snakemake launch script below

# 4) Create a folder named as you would like the analysis name to appear, this along with the genome build will 
#    be prepended onto all files, no spaces, change into it. 

# 5) Soft link or move your two paired sequence fastq.gz files into the job dir 

# 6) Copy over the two workflow docs: xxx.README.sh and xxx.sm into the job directory.

# 7) Add a file named sam2USeq.config.txt that contains a single line of params for the sam2USeq tool, e.g. -c 15, 
#    or -c 20 to define the minimum read coverage for the normal or tumor samples respectively.
echo -n "-c 20" > sam2USeq.config.txt

# 8) Launch the xxx.README.sh via sbatch or run it on your local server.  
#    If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.




# Read threads, ram, fastq
name=${PWD##*/}
unset OMP_NUM_THREADS
allThreads=`nproc`
allRam=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)
shopt -s nullglob; fq=(*.gz)
fq1=`realpath ${fq[0]}`
fq2=`realpath ${fq[1]}`

# Print params
echo
echo -n name"         : "; echo $name
echo -n threads"      : "; echo $allThreads
echo -n ram"          : "; echo $allRam
echo -n host"         : "; echo $(hostname)
echo -n fq1"          : "; echo $fq1
echo -n fq2"          : "; echo $fq2
echo -n s2u conf"     : "; cat sam2USeq.config.txt
echo; echo

# Look for required files
ls $fq1 $fq2 sam2USeq.config.txt &> /dev/null

# Launch snakemake
snakemake --printshellcmds --cores $allThreads --snakefile *.sm --config \
regionsForReadCoverage=$dataBundle/Bed/AllExonHg38Bed8April2020/hg38AllGeneExonsPad175bp.bed.gz \
regionsForOnTarget=$dataBundle/Bed/AllExonHg38Bed8April2020/hg38AllGeneExonsPad175bp.bed.gz \
indexFasta=$dataBundle/Indexes/B38IndexForBwa-0.7.17/hs38DH.fa \
dbsnp=$dataBundle/Vcfs/dbsnp_146.hg38.vcf.gz \
gSnp=$dataBundle/Vcfs/1000G_phase1.snps.high_confidence.hg38.vcf.gz \
gIndel=$dataBundle/Vcfs/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
useq=$dataBundle/BioApps/USeq/Apps \
ucsc=$dataBundle/BioApps/UCSC/ \
useqSamAlignmentExtractor="-q 20 -a 0.65 -d -f -u" \
useqSam2USeq="-v Hg38 -x 5000 -r -w sam2USeq.config.txt" \
name=$name \
fastqReadOne=$fq1 \
fastqReadTwo=$fq2 \
allThreads=$allThreads \
allRam=$allRam

# Cleanup
mkdir -p RunScripts
mv dnaAlignQC* RunScripts/
mv sam2USeq.config.txt RunScripts/
rm -rf .snakemake 
rm -f FAILED STARTED DONE RESTART
touch COMPLETE 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"
mv -f slurm* Logs/ || true

# Notes
## regionsForOnTarget - bgzipped bed file of regions to use in calculating on target capture rates, use chrXXXX naming. See bgzip and tabix from https://github.com/samtools/htslib .
## regionsForReadCoverage - bgzipped bed file of regions to use in calculating unique observation read coverage uniformity metrics, ditto. Typically the prior +/- 150bp
## indexFasta - the BWA mem fasta file with all the associated index files including xxx.fa.fai and xxx.dict files, see https://github.com/lh3/bwa/tree/master/bwakit
## gIndels - a bgzipped and tabix indexed vcf file of trusted indels from the 1000 Genomes project Hg38GATKBundle, see https://software.broadinstitute.org/gatk/download/bundle
## gSnps - ditto, 1000G high confidence snps from the Hg38 GATKBundle
## dbsnp - ditto, dbSNP variants from the Hg38 GATKBundle
## useq - launch each app to see cmd line options

# Replace first and last lines above with the following to get dag svg graph
	# /BioApps/Miniconda3/bin/snakemake --dag \
	# allRam=$allRam | dot -Tsvg > $name"_dag.svg"
