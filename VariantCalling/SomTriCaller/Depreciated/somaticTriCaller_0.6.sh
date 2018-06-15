#!/bin/bash
#SBATCH --account=hci-kp 
#SBATCH --partition=hci-kp 
#SBATCH -N 1
#SBATCH -C "c24"
#SBATCH -t 240:00:00

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Job params
jobName=`basename $(pwd)`
tumorBam=0.01_0.bam
normalBam=norm_0.bam

#Hotspot settings
#regionsForAnalysis=/uufs/chpc.utah.edu/common/home/u0028003/Anno/B37/HunterKeith/HSV1_GBM_IDT_Probes_B37Pad25bps.bed
#mpileup=/uufs/chpc.utah.edu/common/home/u0028003/Lu/Underhill/BkgrdNormals/GBMHS/30BamGBMHS.mpileup.gz
#minTumorAlignmentDepth=100                                                                                                                                               
#minNormalAlignmentDepth=50

#Exome settings
regionsForAnalysis=/uufs/chpc.utah.edu/common/home/u0028003/Anno/B37/HunterKeith/b37_xgen_exome_targets_pad25.bed
mpileup=/uufs/chpc.utah.edu/common/home/u0028003/Lu/Underhill/BkgrdNormals/Exome/20BamXgenExome.mpileup.gz
minTumorAlignmentDepth=20
minNormalAlignmentDepth=20

#General filter settings
minTumorAF=0.001
maxNormalAF=0.5
minTNRatio=1.2
minTNDiff=0.001
minZScore=4

email=david.nix@hci.utah.edu

#Set machine params
threads=`nproc`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)G
echo "Threads: "$threads "  Memory: " $memory "  Host: " `hostname`; echo

# Print out a workflow
~/BioApps/SnakeMake/snakemake  --dag --snakefile *.sm  \
--config name=$jobName rA=$regionsForAnalysis tBam=$tumorBam nBam=$normalBam  threads=$threads memory=$memory \
email=$email mpileup=$mpileup mtad=$minTumorAlignmentDepth mnad=$minNormalAlignmentDepth mtaf=$minTumorAF \
mnaf=$maxNormalAF mr=$minTNRatio md=$minTNDiff zscore=$minZScore \
| dot -Tsvg > $jobName"_dag.svg"

# Launch it
~/BioApps/SnakeMake/snakemake -p -T --cores $threads --snakefile *.sm \
--config name=$jobName rA=$regionsForAnalysis tBam=$tumorBam nBam=$normalBam  threads=$threads memory=$memory \
email=$email mpileup=$mpileup mtad=$minTumorAlignmentDepth mnad=$minNormalAlignmentDepth mtaf=$minTumorAF \
mnaf=$maxNormalAF mr=$minTNRatio md=$minTNDiff zscore=$minZScore

# Cleanup
mkdir -p Raw Txt Filt Log;
gzip *.log
mv -f *.log.gz Log/
mv -f *.raw.* Raw/
mv -f *.txt.gz Txt/
mv -f *.filt.* Filt/
mv -f Filt/*_Consensus* .
rm -rf snappy* .snakemake

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"





