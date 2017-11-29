#!/bin/bash
#SBATCH --account=hci-kp 
#SBATCH --partition=hci-kp 
#SBATCH -N 1
#SBATCH -C "c24"
#SBATCH -t 90:00:00
#SBATCH --job-name=UniFoundation_0.1

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#machine specifications
allThreads=`nproc`
allRam=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)
echo "Threads: "$allThreads "  Memory: " $allRam "  Host: " `hostname`; echo

name=`ls *.xml | awk -F'.xml' '{print $1}'`

~/BioApps/SnakeMake/snakemake -p -T \
--cores $threads \
--snakefile uniFoundation_0.1.sm \
--configfile uniAppRes_0.1.yaml \
--config \
allThreads=$allThreads \
allRam=$allRam \
controlBam=/uufs/chpc.utah.edu/common/home/u0028003/HCINix/NA12878/B37/HG001.NA12878DJ.UCSCKnwnEnsPad150bp.bwa.bam \
regionsForOnTarget=/uufs/chpc.utah.edu/common/home/u0028003/Anno/B37/FoundationMed/t7D2BaitSetB37EnsGeneExonsPad25bp.bed \
regionsForReadCoverage=/uufs/chpc.utah.edu/common/home/u0028003/Anno/B37/FoundationMed/t7D2BaitSetB37EnsGeneExonsPad25bp.bed \
minTumorAlignmentDepth=100 \
minNormalAlignmentDepth=10 \
minTumorAF=0.015 \
maxNormalAF=1 \
minTNRatio=1.2 \
minTNDiff=0.015 \
useqSamAlignmentExtractor="-q 20 -a 0.65 -d -f" \
useqSam2USeq="-v H_sapiens_Feb_2009 -x 2000 -r -c 100" \
sampleBam=$name"_DNA.bam" \
sampleXml=$name".xml" \
name=$name

rm -rf snappy* 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

