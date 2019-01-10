#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 7 January 2019
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This workflow aligns IDT's dual sample index and dual 3mer inline UMIs with BWA mem b37, 
# calls consensus on the clustered family members, filters, base score recalibrates, and realigns indels.
# It also collects a variety of QC metrics. Run the USeq AggregateQCStats app on a directory containing multiple 
# alignment runs to combine all the QC results into several relevant QC reports.


#### Do just once ####
# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.3/udocker

# 2) Define two mount file paths to expose in udocker. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/gnomexFlex.jsp?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/mammoth/serial/u0028003

# 3) Modify the xxx.udocker workflow file setting the paths to the required resources. These must be within the mounts.

# 4) Build the udocker container, do just once after each update.
## $udocker rm SnakeMakeBioApps_3 && $udocker pull hcibioinformatics/public:SnakeMakeBioApps_3 && $udocker create --name=SnakeMakeBioApps_3  hcibioinformatics/public:SnakeMakeBioApps_3 && echo "UDocker Container Built"


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link your paired fastq.gz files into the job dir naming them 1.fastq.gz and 2.fastq.gz . 

# 3) Copy over the workflow docs: xxx.udocker, xxx.README.sh, and xxx.sm into the job directory.

# 4) Add a file named sam2USeq.config.txt that contains a single line of params for the sam2USeq tool, e.g. -c 10, or -c 20 to define the minimum read coverage.

# 5) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params and fetch real path for linked fastq
name=${PWD##*/}
fastqReadOne=`readlink -f 1.fastq.gz`
fastqReadTwo=`readlink -f 2.fastq.gz`
jobDir=`readlink -f .`

$udocker run \
--env=fastqReadOne=$fastqReadOne --env=fastqReadTwo=$fastqReadTwo --env=name=$name --env=jobDir=$jobDir \
--volume=$dataBundle:$dataBundle --volume=$myData:$myData \
SnakeMakeBioApps_3 < *.udocker

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv consensus* RunScripts/
mv *.log  Logs/
rm -rf .snakemake FAILED STARTED; touch COMPLETE
mv slurm* Logs/
