#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw 
#SBATCH -N 1
#SBATCH -t 72:00:00

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#machine specifications
allThreads=`nproc`
allRam=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)
echo "Threads: "$allThreads "  Memory: " $allRam "  Host: " `hostname`; echo

name=`ls *_1.txt.gz | awk -F'_1.txt.gz' '{print $1}'`
firstRead=`ls *_1.txt.gz`
secondRead=`ls *_2.txt.gz`

~/BioApps/SnakeMake/3.13.3/snakemake -p -T \
--cores $allThreads \
--snakefile uniAlignQCB38_0.4.sm \
--configfile uniAppRes_0.4.yaml \
--config \
allThreads=$allThreads \
allRam=$allRam \
name=$name \
firstReadFastq=$firstRead \
secondReadFastq=$secondRead \
useqSamAlignmentExtractor="-q 20 -a 0.65 -d -f" \
useqSam2USeq="-v B38 -x 1000 -r -c 300" \
regionsForOnTarget=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Scratch/Anno/B38/Bed/ExomeCaptureDesignS07604715/S07604715_Padded100bp_Hg38.bed \
regionsForReadCoverage=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Scratch/Anno/B38/Bed/ExomeCaptureDesignS07604715/S07604715_Covered_Hg38.bed \
indexFasta=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Scratch/Anno/B38/Bwa/bwa-0.7.17/B38Index/hs38DH.fa \
goldIndels=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Scratch/Anno/B38/GATKBundleB38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
dbsnp=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Scratch/Anno/B38/GATKBundleB38/dbsnp_146.hg38.vcf.gz

# clean up
rm -rf .snakemake 


echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"


#/Repository/AnalysisData/Nix/SnakeMakeDevResources/Fastq/14238X1_4M_1.txt.gz 14238X1_4M_2.txt.gz

#/Repository/AnalysisData/Nix/SnakeMakeDevResources/Bed/S07604715_Padded100bp_Hg38.bed.gz S07604715_Covered_Hg38.bed.gz

#/Repository/AnalysisData/Nix/SnakeMakeDevResources/Vcfs/dbsnp_146.hg38.vcf.gz Mills_and_1000G_gold_standard.indels.hg38.vcf.gz

#/Repository/AnalysisData/Nix/SnakeMakeDevResources/Indexes/B38IndexForBwa-0.7.17/hs38DH.fa