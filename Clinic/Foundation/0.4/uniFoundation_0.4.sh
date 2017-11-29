#!/bin/bash
#SBATCH --account=hci-aa 
#SBATCH --partition=hci-aa 
#SBATCH -N 1
#SBATCH -t 72:00:00

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#machine specifications
allThreads=`nproc`
allRam=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)
echo "Threads: "$allThreads "  Memory: " $allRam "  Host: " `hostname`; echo

name=${PWD##*/}

# copy over contents to scratch
launchDir=`pwd`
tempDir=/scratch/local/Nix_DeleteMe
rm -rf $tempDir
mkdir $tempDir
rsync -rPtL $launchDir/ $tempDir/
cd $tempDir

~/BioApps/SnakeMake/3.13.3/snakemake -p -T \
--cores $allThreads \
--snakefile uniFoundation_0.4.sm \
--configfile uniAppRes_0.4.yaml \
--config \
allThreads=$allThreads \
allRam=$allRam \
controlBam=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Anno/B37/Bams/HG001.NA12878DJ.UCSCKnwnEnsPad150bp.bwa.bam  \
regionsForOnTarget=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Foundation/Bed/t7D2BaitSetB37EnsGeneExonsPad25bp.bed \
regionsForReadCoverage=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Foundation/Bed/t7D2BaitSetB37EnsGeneExonsPad25bp.bed \
regionsForAnalysis=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Foundation/Bed/t7D2BaitSetB37EnsGeneExonsPad25bp.bed \
mpileup=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Foundation/MpileupBkgFound50Bams/b37Foundation50.mpileup.gz \
indexFasta=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Anno/B37/Ref/human_g1k_v37_decoy_phiXAdaptr.fasta \
dbsnp=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Anno/B37/Vcf/dbsnp_132_b37.leftAligned.vcf \
cosmic=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Anno/B37/Vcf/b37_cosmic_v54_120711.vcf \
goldIndels=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Anno/B37/Vcf/Mills_and_1000G_gold_standard.indels.b37.vcf \
oneKIndels=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Anno/B37/Vcf/1000G_phase1.indels.b37.vcf \
dbNSFP=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Anno/DbNSFP/B37/dbNSFP3.5a_hg19.txt.gz \
ucscTrans=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Anno/B37/Genes/b37EnsTranscripts12June2017.ucsc.gz \
clinvar=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Anno/Clinvar/B37/norm_clinvar.vcf.gz \
mpileup=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/Nix/Foundation/MpileupBkgFound50Bams/b37Foundation50.mpileup.gz \
minTumorAlignmentDepth=100 \
minNormalAlignmentDepth=10 \
minTumorAF=0.01 \
maxNormalAF=1 \
minTNRatio=1.2 \
minTNDiff=0.01 \
genomeBuild=B37 \
useqSamAlignmentExtractor="-q 20 -a 0.65 -d -f" \
useqSam2USeq="-v B37 -x 2000 -r -c 100" \
sampleBam=$name"_DNA.bam" \
sampleXml=$name".xml" \
name=$name &> $name"_Snakemake.log"

# clean up
rm -rf .snakemake 

# move the data back to the launchDir
rsync -rPtL $tempDir/ $launchDir/

# delete the temp dir and original starting data
cd $launchDir
rm -rf $tempDir
rm -rf $name"_DNA.bam" $name"_DNA.bam.bai" $name".xml"
gzip *log; mv *log.gz Log/
mv uni* Log/

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total" >> slurm*
