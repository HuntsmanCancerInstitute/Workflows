#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw 
#SBATCH -N 1
#SBATCH -t 72:00:00

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#Job params
jobName=${PWD##*/}
firstReadFastq=`ls *_R1_*`
secondReadFastq=`ls *_R2_*`

readCovBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/HCINix/MM10Ref/Bed/S0276129_SureSelectMouseExomeV1/GRCm38/S0276129_CoveredCCDS_GRCm38.bed.gz
onTargetBed=/uufs/chpc.utah.edu/common/HIPAA/u0028003/HCINix/MM10Ref/Bed/S0276129_SureSelectMouseExomeV1/GRCm38/S0276129_CoveredPad100bp_GRCm38.bed.gz

email=david.nix@hci.utah.edu

#Set machine params
threads=`nproc --all`
memory=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)G
random=$RANDOM
echo "Threads: "$threads "  Memory: " $memory "  Host: " `hostname`; echo
echo "Name: "$jobName

~/BioApps/SnakeMake/3.13.3/snakemake -p -T --cores $threads --snakefile *.sm  \
--config fR=$firstReadFastq sR=$secondReadFastq name=$jobName rcBed=$readCovBed otBed=$onTargetBed threads=$threads memory=$memory \
email=$email --stat $jobName"_"$random"_runStats.json"

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mv -f *_runStats.json Json/
mkdir Run
mv -f *sh Run/
mv -f *sm Run/
cp -f slurm* Run/
rm -rf .snakemake 



