#!/bin/bash
#SBATCH --account=hci-kp 
#SBATCH --partition=hci-kp 
#SBATCH -N 1
#SBATCH -C "c20"
#SBATCH -t 30:00:00
#SBATCH --job-name=1B

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Job params
#jobName=`ls *R1.fastq.gz | awk -F'_R1.fastq.gz' '{print $1}'`
#firstReadFastq=`ls *R1.fastq.gz`
#secondReadFastq=`ls *R3.fastq.gz`

jobName=`ls *_1.txt.gz | awk -F'_1.txt.gz' '{print $1}'`                                                                                                                        
firstReadFastq=`ls *_1.txt.gz`                                                                                                                                                     
secondReadFastq=`ls *_2.txt.gz`

readCovBed=/uufs/chpc.utah.edu/common/home/u0028003/Lu/Deb/Bed/SeqCap_EZ_Exome_v2_TiledRegions.bed
onTargetBed=/uufs/chpc.utah.edu/common/home/u0028003/Lu/Deb/Bed/mSeqCap_EZ_Exome_v2_TiledRegionsPad150.bed

email=david.nix@hci.utah.edu

#Set machine params
threads=`nproc`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)G
random=$RANDOM
echo "Threads: "$threads "  Memory: " $memory "  Host: " `hostname`; echo
echo "Name: "$jobName


# Print out a workflow, can execute many times to get status of job
~/BioApps/SnakeMake/snakemake  --dag --snakefile *.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq name=$jobName rcBed=$readCovBed otBed=$onTargetBed threads=$threads memory=$memory \
email=$email | dot -Tsvg > $jobName"_"$random"_dag.svg"

# Launch the actual job
~/BioApps/SnakeMake/snakemake -p -T --cores $threads --snakefile *.sm  \
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



