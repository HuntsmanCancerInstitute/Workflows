#!/bin/bash
#SBATCH --account=hci-kp 
#SBATCH --partition=hci-kp 
#SBATCH -N 1
#SBATCH -C "c20"
#SBATCH -t 30:00:00
#SBATCH --job-name=bisulfiteAlign_0.1

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Job params
jobName=`ls *_R1_*.fastq.gz | awk -F'_' '{print $1}'`
firstReadFastq=`ls *_R1_*.fastq.gz`
secondReadFastq=`ls *_R2_*.fastq.gz`
email=david.nix@hci.utah.edu

#Set machine params
threads=`nproc`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)G
random=$RANDOM
echo "Threads: "$threads "  Memory: " $memory "  Host: " `hostname`; echo

# Print out a workflow, can execute many times to get status of job
snakemake --dag --snakefile *.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq name=$jobName threads=$threads memory=$memory \
email=$email | dot -Tsvg > $jobName"_"$random"_dag.svg"

# Launch the actual job
snakemake -p -T --cores $threads --snakefile *.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq name=$jobName threads=$threads memory=$memory \
email=$email --stat $jobName"_"$random"_runStats.json"

# Cleanup
mv -f *.json Log/
mv -f *.svg Log/
mv -f *.sh Log/
mv -f *.sm Log/
mv -f slurm* Log/

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

