#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# Circulating Tumor - Normal Somatic Variant Calling Workflow
# Bash script for launching the Singularity Container
# 22 Oct 2019

# This workflow calls somatic variants found at low allele frequencies (< 1%) in high depth capture DNA datasets such as those derived from sequencing cell free DNA samples for circulating tumor analysis.
# It utilized Bcftools to generate nearly every possible observed variant, filters the calls with a USeq tool called SimpleSomaticCaller, and lastly z-scores the variants using a panel of high depth normals. See the USeq VCFBkz and BamPileup apps for details.
# Benchmarking with CLINVAR variant spike ins shows excellent sensitivity and specificity (e.g. > 95% TPR at 5% FDR for 0.5% spiked SNVs).
# It works best with plasma and buffy coat samples sequenced > 2000x depth where UMIs were used to reduce error rates and call consensus on PCR duplicate families.
  

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module then define the path to the executable
module load singularity/3.2.0
singExec=/uufs/chpc.utah.edu/sys/installdir/singularity3/3.2.0/bin/singularity

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/gnomexFlex.jsp?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/mammoth/serial/u0028003

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#$singExec pull docker://hcibioinformatics/public:CtSom_1
container=/uufs/chpc.utah.edu/common/HIPAA/u0028003/HCINix/SingularityBuilds/public_CtSom_1.sif


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link bam and bai files naming them tumor.bam, tumor.bai, normal.bam, and normal.bai into the analysis folder. 

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the job directory.

# 4) Launch the xxx.README.sh via slurm's sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params
name=${PWD##*/}
jobDir=`readlink -f .`

SINGULARITYENV_name=$name SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
$singExec exec --containall --bind $dataBundle,$myData $container \
bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv ctSom* RunScripts/
mv -f *.log  Logs/ || true
mv -f slurm* Logs/ || true
rm -rf .snakemake FAILED QUEUED STARTED DONE RESTART
touch COMPLETE 

