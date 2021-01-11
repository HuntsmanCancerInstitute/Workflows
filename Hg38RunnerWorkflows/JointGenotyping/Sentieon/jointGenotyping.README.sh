#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 72:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 14 Dec 2020
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard GATK GenotypeGVCFs analysis via Sentieon, normalizing the vcf with vt and splitting it into individual vcf files with light filtering.


#### Do just once ####

# 1) Install and load sentieon and snakemake in your path, as modules
module use /uufs/chpc.utah.edu/common/PE/proj_UCGD/modulefiles/$UUFSCELL &> /dev/null
module load sentieon/201911.00 &> /dev/null
module load snakemake/5.6.0 &> /dev/null

# 2) Define file path to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578 .
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner

# 3) Modify the snakemake file setting to the required resources below. These must be within the mounts.


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Create a folder named ToGenotype in the analysis folder.

# 3) Move or Soft link all the xxx.g.vcf.gz files into the ToGenotype folder from running the GATK/Sentieon Haplotype caller.

# 4) Copy over the JointGenotyping workflow docs: xxx.README.sh, and xxx.sm into the analysis folder.

# 5) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 6) If the run fails, look at the individual rule Log files, fix the issue and restart.  Snakemake should pick up where it left off.



echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params 
name=${PWD##*/}
unset OMP_NUM_THREADS
allThreads=`nproc`
allRam=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)

# Print params
echo
echo -n jobDir"     : "; pwd
echo -n name"       : "; echo $name
echo -n dataBundle" : "; echo $dataBundle
echo -n threads"    : "; echo $allThreads
echo -n ram"        : "; echo $allRam
echo -n host"       : "; echo $(hostname)
echo; echo

# Launch snakemake
snakemake --printshellcmds --cores $allThreads --snakefile *.sm --config \
genomeBuild=Hg38 \
regionsForAnalysis=$dataBundle/Bed/AllExonHg38Bed8April2020/hg38AllGeneExonsPad175bp.bed \
indexFasta=$dataBundle/Indexes/B38IndexForBwa-0.7.17/hs38DH.fa \
queryDataDir=$dataBundle/GQuery/Data \
queryVcfFileFilter=Hg38/Germline/Avatar/Vcf \
queryBedFileFilter=Hg38/Germline/Avatar/Bed \
useqJointGenotypeVCFParser="-q 20 -d 10 -a 0.05 -g 20" \
name=$name \
allThreads=$allThreads \
allRam=$allRam \
bioApps=$dataBundle/BioApps

# Notes
## regionsForAnalysis - bgzipped bed file of regions to use in calling genotypes, use chrXXXX naming for Hg38. See bgzip and tabix from https://github.com/samtools/htslib .
## indexFasta - the indexed fasta file used for alignment including xxx.fa.fai and xxx.dict files, see https://github.com/lh3/bwa/tree/master/bwakit
## query Data dir - is that created by the QueryIndexer App for use by the VCFCallFrequency USeq tool.
## queryFileFilter - relative file path in the QueryData dir that determines what vcf and bed files to use in calculating each vcfCallFrequency.
## useq - launch the JointGenotypeVCFParser USeq app to see cmd line options

# Replace first and last lines above with the following to get dag svg graph
	# /BioApps/Miniconda3/bin/snakemake --dag \
	# allRam=$allRam | dot -Tsvg > $name"_dag.svg"


echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv jointGenotyping* RunScripts/
mv -f slurm* Logs/ || true
rm -rf .snakemake 
rm -f FAILED STARTED DONE RESTART
touch COMPLETE 


