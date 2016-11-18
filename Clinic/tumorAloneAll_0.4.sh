#!/bin/bash
#SBATCH --account=arupbio-kp 
#SBATCH --partition=arup-kp 
#SBATCH -N 1
#SBATCH -C "c24"
#SBATCH -t 30:00:00
#SBATCH --job-name=Horizon

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Name of the job and fastq's, required
jobName=Horizon
firstReadFastq=`ls *_R1*.fastq.gz`
secondReadFastq=`ls *_R3*.fastq.gz`
barcodeReadFastq=`ls *_R2*.fastq.gz`

#Make a directory for the run logs
mkdir -p $jobName/RunLogs

# Print out a workflow, can execute many times to get status of job
snakemake --dag --snakefile *.sm --configfile *.yaml \
--config fR=$firstReadFastq sR=$secondReadFastq bR=$barcodeReadFastq bN=$jobName \
| dot -Tsvg > $jobName/RunLogs/$jobName"_"$RANDOM"_dag.svg"

# Launch the actual job
snakemake -p -T --cores 24 --snakefile *.sm --configfile *.yaml \
--config fR=$firstReadFastq sR=$secondReadFastq bR=$barcodeReadFastq bN=$jobName \
--stat $jobName/RunLogs/$jobName"_runStats.json"

# Final cleanup
rm -f *~
cp slurm* $jobName/RunLogs/ 
mv *.sm $jobName/RunLogs/ 
mv *.yaml $jobName/RunLogs/ 
mv *.sh $jobName/RunLogs/
mv $jobName/RunLogs/ $jobName/log/

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

