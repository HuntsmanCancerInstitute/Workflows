#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw 
#SBATCH -N 1
#SBATCH -t 72:00:00

############### Example Slurm Cluster Scheduler Bash Script for Executing the Consensus Alignment Workflow ##############
# See https://github.com/HuntsmanCancerInstitute/Workflows/tree/master/Alignment/MolBarcodes for the latest version

# Configured for the latest IDT dual sample index with paired 3mer UMIs


set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Job params
jobName=`ls *"_R1_"*".gz" | awk -F'_R1_001.fastq.gz' '{print $1}'`
firstReadFastq=`ls *"_R1_"*".gz"`
secondReadFastq=`ls *"_R2_"*".gz"`
email=david.nix@hci.utah.edu

#HS settings
readCoverageBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Scratch/Anno/B37/Bed/HunterKeith/HSV1_GBM_IDT_Probes_B37.bed
onTargetBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Scratch/Anno/B37/Bed/HunterKeith/HSV1_GBM_IDT_Probes_B37Pad25bps.bed

#Set machine params
threads=`nproc`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)G
echo "Threads: "$threads "  Memory: " $memory "  Host: " `hostname`; echo

# Print out a workflow
~/BioApps/SnakeMake/3.13.3/snakemake  --dag --snakefile *.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq\
rCB=$readCoverageBed oTB=$onTargetBed \
name=$jobName threads=$threads memory=$memory email=$email \
| dot -Tsvg > $jobName"_dag.svg"

# Launch the actual job
~/BioApps/SnakeMake/3.13.3/snakemake -p -T --cores $threads --snakefile consensusAlignQC_*.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq \
rCB=$readCoverageBed oTB=$onTargetBed \
name=$jobName threads=$threads memory=$memory email=$email 

rm -rf .snakemake snap*

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

