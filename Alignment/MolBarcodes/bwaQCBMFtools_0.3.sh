#!/bin/bash
#SBATCH --account=hci-kp 
#SBATCH --partition=hci-kp 
#SBATCH -N 1
#SBATCH -C "c24"
#SBATCH -t 30:00:00
#SBATCH --job-name=bwaBMFtools

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Job params
jobName=`ls *_R1*fastq.gz | awk -F'_R1.fastq.gz' '{print $1}'`
firstReadFastq=`ls *_R1*fastq.gz`
secondReadFastq=`ls *_R3*fastq.gz`
barcodeReadFastq=`ls *_R2*fastq.gz`
email=david.nix@hci.utah.edu

# For ReadCov calc, smallest
readCoverageBed=/uufs/chpc.utah.edu/common/home/u0028003/Lu/KeithG/13894R/CtDNA/HSV1_GBM_IDT_Probes_B37.bed
# For OnTarget calc, largest
onTargetBed=/uufs/chpc.utah.edu/common/home/u0028003/Lu/KeithG/13894R/CtDNA/HSV1_GBM_IDT_Probes_B37Pad25bps.bed

#Set machine params
random=$RANDOM
threads=`nproc`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)G
echo "Threads: "$threads "  Memory: " $memory "  Host: " `hostname`; echo
ls $firstReadFastq $secondReadFastq $barcodeReadFastq 
echo $jobName

# Print out a workflow, can execute many times to get status of job
~/BioApps/SnakeMake/snakemake  --dag --snakefile *.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq bR=$barcodeReadFastq \
rCB=$readCoverageBed oTB=$onTargetBed \
name=$jobName threads=$threads memory=$memory email=$email | \
dot -Tsvg > $jobName"_"$random"_dag.svg"

# Launch the actual job
~/BioApps/SnakeMake/snakemake -p -T --cores $threads --snakefile bwaQCBMFtools_0.3.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq bR=$barcodeReadFastq \
rCB=$readCoverageBed oTB=$onTargetBed \
name=$jobName threads=$threads memory=$memory email=$email 

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

