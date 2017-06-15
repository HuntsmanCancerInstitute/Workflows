#!/bin/bash
#SBATCH --account=hci-kp 
#SBATCH --partition=hci-kp 
#SBATCH -N 1
#SBATCH -C "c20"
#SBATCH -t 90:00:00
#SBATCH --job-name=TRF

set -e; start=$(date +'%s')
echo -e "---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

#machine specifications
allThreads=`nproc`
halfThreads=$(($allThreads/2))
allRam=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)
halfRam=$(($allRam/2))
random=$RANDOM
echo "Threads: "$allThreads "  Memory: " $allRam "  Host: " `hostname`; echo

name=`ls *.xml | awk -F'.xml' '{print $1}'`

snakemake -p -T --cores $threads --snakefile *.sm --configfile *.yaml --config allThreads=$allThreads halfThreads=$halfThreads allRam=$allRam"G" halfRam=$halfRam"G" sampleBam=$name"_DNA.bam" sampleXml=$name".xml" name=$name

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

