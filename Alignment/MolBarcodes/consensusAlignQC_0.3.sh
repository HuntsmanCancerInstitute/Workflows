#!/bin/bash
#SBATCH --account=hci-kp 
#SBATCH --partition=hci-kp 
#SBATCH -N 1
#SBATCH -C "c20"
#SBATCH -t 300:00:00


set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Job params
jobName=`ls *_R1.fastq.gz | awk -F'_R1.fastq.gz' '{print $1}'`
firstReadFastq=`ls *_R1.fastq.gz`
secondReadFastq=`ls *_R3.fastq.gz`
barcodeReadFastq=`ls *_R2.fastq.gz`
email=david.nix@hci.utah.edu

#HS settings
#readCoverageBed=/uufs/chpc.utah.edu/common/home/u0028003/Anno/B37/HunterKeith/HSV1_GBM_IDT_Probes_B37.bed
#onTargetBed=/uufs/chpc.utah.edu/common/home/u0028003/Anno/B37/HunterKeith/HSV1_GBM_IDT_Probes_B37Pad25bps.bed

#Exome settings
readCoverageBed=/uufs/chpc.utah.edu/common/home/u0028003/Anno/B37/HunterKeith/b37_xgen_exome_targets.bed
onTargetBed=/uufs/chpc.utah.edu/common/home/u0028003/Anno/B37/HunterKeith/b37_xgen_exome_probes_pad25.bed

#Set machine params
threads=`nproc`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)G
echo "Threads: "$threads "  Memory: " $memory "  Host: " `hostname`; echo

# Print out a workflow
~/BioApps/SnakeMake/snakemake  --dag --snakefile *.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq bR=$barcodeReadFastq \
rCB=$readCoverageBed oTB=$onTargetBed \
name=$jobName threads=$threads memory=$memory email=$email \
| dot -Tsvg > $jobName"_dag.svg"

# Launch the actual job
~/BioApps/SnakeMake/snakemake -p -T --cores $threads --snakefile consensusAlignQC_*.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq bR=$barcodeReadFastq \
rCB=$readCoverageBed oTB=$onTargetBed \
name=$jobName threads=$threads memory=$memory email=$email 

rm -rf .snakemake snap*

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

