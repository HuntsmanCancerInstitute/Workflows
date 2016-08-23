#!/bin/bash
#SBATCH --account=hci-kp 
#SBATCH --partition=hci-kp 
#SBATCH -N 1
#SBATCH -C "c24"
#SBATCH -t 30:00:00
#SBATCH --job-name=bwaCon

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Job params
jobName=`ls *_R1.fastq.gz | awk -F'_R1.fastq.gz' '{print $1}'`
firstReadFastq=`ls *_R1.fastq.gz`
secondReadFastq=`ls *_R3.fastq.gz`
barcodeReadFastq=`ls *_R2.fastq.gz`
email=david.nix@hci.utah.edu

# For ReadCov calc, smallest
readCoverageBed=/uufs/chpc.utah.edu/common/home/u0028003/Lu/KeithTNExomes/Bed/b37_xgen_exome_targets.bed.gz
# For OnTarget calc, largest
onTargetBed=/uufs/chpc.utah.edu/common/home/u0028003/Lu/KeithTNExomes/Bed/b37_xgen_exome_probes_pad25.bed.gz
# For analysis, just right, not used with alignment and QC, just for snv/indel variant calling
analysisBed=/uufs/chpc.utah.edu/common/home/u0028003/Lu/KeithTNExomes/Bed/b37_xgen_exome_targets_pad25.bed.gz


#Set machine params
threads=`nproc`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)G
random=$RANDOM
echo "Threads: "$threads "  Memory: " $memory "  Host: " `hostname`; echo

# Launch the actual job
snakemake -p -T --cores $threads --snakefile bwaQCConsensus_0.1.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq bR=$barcodeReadFastq \
rCB=$readCoverageBed oTB=$onTargetBed aB=$analysisBed \
name=$jobName threads=$threads memory=$memory email=$email 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

