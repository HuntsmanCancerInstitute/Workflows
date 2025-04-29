#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 28 April 2025
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This workflow converts a Tempus json files, including v3.3.0, to vcf, Crossmaps it to Hg38, and merges it with a recalled somatic variant vcf.


#### Do just once ####

# 1) Install Apptainer (https://apptainer.org/) or load via a module, place in your path
# module load apptainer

# 2) Define file path to the data bundle to "mount" in the container.
# dataBundle=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner
dataBundle=/scratch/u0028003/Tempus/TNRunner

# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the apptainer container, and define the path to the xxx.sif file, do just once after each update.
#singularity pull docker://hcibioinformatics/public:fibsSmCmUsTxVt_1
#container=/uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner/Containers/public_Tempus_3.3.sif
container=/scratch/u0028003/Tempus/public_fibsSmCmUsTxVt_1.sif

# 5) For running on AWS, create the dataBundle on redwood
# cd /uufs/chpc.utah.edu/common/PE/hci-bioinformatics1
# zip -r tempusVcf_28Apr2025.zip \
#   TNRunner/Indexes/B38IndexForBwa-0.7.17/hs38DH.fa \
#   TNRunner/Indexes/B38IndexForBwa-0.7.17/hs38DH.fa.fai \
#   TNRunner/Indexes/B38IndexForBwa-0.7.17/hs38DH.dict \
#   TNRunner/Indexes/B37/human_g1k_v37_decoy_phiXAdaptr.fasta \
#   TNRunner/Indexes/B37/human_g1k_v37_decoy_phiXAdaptr.fasta.fai \
#   TNRunner/Indexes/B37/human_g1k_v37_decoy_phiXAdaptr.dict \
#   TNRunner/Indexes/GRCh37_to_GRCh38.chain.gz \
#   TNRunner/Bed/Tempus/gencode.v19.annotation.genes.bed.gz* \
#   TNRunner/AnnotatorData/Hgnc/hgncGeneSymbolsAliases27March2025.txt.gz* \
#   && echo OK || echo FAIL


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the myData mount path.

# 2) Soft link or copy one or more Tempus TL-xxx.json files and their associated Tempus soma and germ vcf.gz files into a directory in the job directory called ClinicalReport/ 

# 3) Soft link or copy your recalled somatic variant xxx.vcf.gz files into the job directory, not the ClinicalReport/ .

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, and xxx.sm into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off. If needed delete the .snakemake folder.


#### No need to modify anything below ####

echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params 
name=${PWD##*/}
jobDir=$(realpath .)

APPTAINERENV_name=$name APPTAINERENV_jobDir=$jobDir APPTAINERENV_dataBundle=$dataBundle \
apptainer exec  --bind $dataBundle,$jobDir $container bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"


# Final cleanup
mkdir -p RunScripts
mv tempusVcf* RunScripts/
mv -f slurm* Logs/ || true
rm -rf .snakemake 
rm -f FAILED STARTED DONE RESTARTED RUNME
touch COMPLETE 


