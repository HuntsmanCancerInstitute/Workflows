#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw 
#SBATCH -N 1
#SBATCH -t 72:00:00

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Job params
jobName=`ls *R1_001.fastq.gz | awk -F'_R1_001.fastq.gz' '{print $1}'`
firstReadFastq=`ls *R1_001.fastq.gz`
secondReadFastq=`ls *R2_001.fastq.gz`

#readCovBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Mam/Tempus/b37RefSeq_ExonsNoUTRs_1713Gene_xOTempus.bed.gz
#onTargetBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/PENix/Anno/B37/Genes/b37KnownEnsExonsPad150.bed
#readCovBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/HCINix/Avatar/SeqCapEZExomeV3B37SharedPrimaryCaptureTargets.bed
#onTargetBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/HCINix/Avatar/v3NimbExomeMergedTargetsPad150bp_B37.bed
readCovBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Scratch/Anno/B37/Bed/HunterKeith/HSV1_GBM_IDT_Probes_B37.bed
onTargetBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/Scratch/Anno/B37/Bed/HunterKeith/HSV1_GBM_IDT_Probes_B37Pad25bps.bed

email=david.nix@hci.utah.edu

#Set machine params
threads=`nproc`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)G
random=$RANDOM
echo "Threads: "$threads "  Memory: " $memory "  Host: " `hostname`; echo
echo "Name: "$jobName


# Print out a workflow, can execute many times to get status of job
~/BioApps/SnakeMake/3.13.3/snakemake  --dag --snakefile *.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq name=$jobName rcBed=$readCovBed otBed=$onTargetBed threads=$threads memory=$memory \
email=$email | dot -Tsvg > $jobName"_"$random"_dag.svg"

# Launch the actual job
~/BioApps/SnakeMake/3.13.3/snakemake -p -T --cores $threads --snakefile *.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq name=$jobName rcBed=$readCovBed otBed=$onTargetBed threads=$threads memory=$memory \
email=$email --stat $jobName"_"$random"_runStats.json"

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mv -f *_runStats.json Json/
mkdir Run
mv -f *sh Run/
mv -f *sm Run/
mv -f *svg Run/
cp -f slurm* Run/
rm -rf .snakemake *.fastq.gz



