#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 10 Sept 2021
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This fires a variety of apps that annotate a vcf with functional effect info using SnpEff 5.0e, ExAC AFs, ClinVar, and the VCFSpliceScanner.  It also generates a filtered vcf based on these annotations.


#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place in your path
module load singularity/3.6.4

# 2) Define file paths to "mount" in the container. The first is to the TNRunner data bundle downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578 . The second is the path to your data.
dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
myData=/scratch/general/pe-nfs1/u0028003

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:SnpEff_SM_1
container=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner/Containers/public_SnpEff_SM_1.sif

# 5) Create a file called annotatedVcfParser.config.txt and provide params for the USeq AnnotatedVcfParser application, e.g. '-d 20 -m 0.1 -q 0.1 -p 0.01 -g D5S,D3S -n 4.4 -a HIGH -l -c Pathogenic,Likely_pathogenic,Conflicting_interpretations_of_pathogenicity,Drug_response -t 0.51 -e Benign,Likely_benign -o -b 0.1 -z 3 -u RYR1' for strict germline or '-d 20 -f' for somatic.

# 6) Create a file called vcfCallFrequency.config.txt and provide params for the USeq VCFCallFrequency application, e.g. '-v Hg38/Somatic/Avatar/Vcf -b Hg38/Somatic/Avatar/Bed -m 0.1'


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Copy or soft link your gzipped vcf file to annotate into the job directory naming it anything ending in .vcf.gz

# 3) Copy over the Annotator workflow docs: xxx.sing, xxx.README.sh, and xxx.sm as well as the annotatedVcfParser.config.txt and vcfCallFrequency.config.txt into the job directory.

# 4) Launch the xxx.README.sh via slurm's sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# look for required files
echo -e "\nLooking for required files..."
ls vcfCallFrequency.config.txt annotatedVcfParser.config.txt *vcf.gz

# Read out params
jobDir=`readlink -f .`

SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $dataBundle,$myData $container \
bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv annotat* *config.txt RunScripts/ || true
mv -f slurm* *snakemake.stats.json Logs/ || true
rm -rf .snakemake FAILED STARTED DONE RESTARTED
touch COMPLETE 


