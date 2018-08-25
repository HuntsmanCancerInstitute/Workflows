#!/bin/bash
#SBATCH --account=hci-rw 
#SBATCH --partition=hci-rw 
#SBATCH -N 1
#SBATCH -C "c28"
#SBATCH -t 30:00:00
#SBATCH --job-name=MYNAME
#SBATCH --mail-user=name@utah.edu



### User Job parameters
# use sed or otherwise to put in custom names and IDs below
jobName=MYNAME
coreID=MYID
# Bed files - make sure these are different files
readCoverageBed=panel_merged.bed
onTargetBed=panel_merged_ext25.bed

# snakemake file - adjust depending on which snakemake file you're executing
smfile=alignQC_1.4.sm 




### Start job
echo "---------- Starting job $jobName -------- "
echo -e "Start: $((($(date +'%s') - $start)/60)) min"
module use /uufs/chpc.utah.edu/common/home/hcibcore/Modules/modulefiles
module use /uufs/chpc.utah.edu/common/HIPAA/hci-bioinformatics1/Modules/modulefiles
module load snakemake
snakemake=`which snakemake`
firstReadFastq=`ls *_1.txt.gz`
secondReadFastq=`ls *_2.txt.gz`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 8)G
start=$(date +'%s')

echo "Fastq files: $firstReadFastq $secondReadFastq"
echo "Bed files: $readCoverageBed $onTargetBed"


### Print out a workflow
$snakemake \
--dag --latency-wait 15 --snakefile $smfile \
--config fR=$firstReadFastq sR=$secondReadFastq \
rcBed=$readCoverageBed otBed=$onTargetBed \
name=$jobName id=$coreID threads=$NCPU memory=$memory \
| dot -Tsvg > ${jobName}_dag.svg



### Launch the actual job
$snakemake \
-p -T --latency-wait 15 --cores $NCPU --snakefile $smfile \
--config fR=$firstReadFastq sR=$secondReadFastq \
rcBed=$readCoverageBed otBed=$onTargetBed \
name=$jobName id=$coreID threads=$NCPU memory=$memory 


### Finish
echo "\n---------- Complete! -------- "
echo -e "$((($(date +'%s') - $start)/60)) min total"

