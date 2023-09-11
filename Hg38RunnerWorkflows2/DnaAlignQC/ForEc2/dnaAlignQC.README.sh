#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e

# 15 May Jan 2022
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard BWA mem alt aware alignment to Hg38/GRCh38 followed by quality filtering, deduplication, and read depth QC.
# The output alignment cram file has been filtered and only contains uniquely aligned primary alignments.
# Don't use this for structural variant and repeat/ segment duplication analysis without disabling those settings.
# For use on AWS EC2, see ~/TNRunner/Workflows/DnaAlignQC for CHPC Slurm

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place it in your path
which singularity &> /dev/null || module load singularity

# 2) Set the path to the TNRunner dataBundle in the snakemake config yaml file. It can be downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578
dataBundle=$(grep dataBundle *.yaml | grep -v ^# | cut -d ' ' -f2)

# 3) Check and if needed, modify the parameters specific to this workflow in the snakemake config yaml file.

# 4) If needed build the singularity container, and define the path to the xxx.sif file, do after each update, e.g. singularity pull docker://hcibioinformatics/public:SM_BWA_1
container=$dataBundle/Containers/public_SM_BWA_1.sif

# 5) If running this on AWS EC2 via the JobRunner, build the resource archive, and upload it to S3
# cd /uufs/chpc.utah.edu/common/PE/hci-bioinformatics1
# zip -r dnaAlignQC_15May2023.zip TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.* \
# TNRunner/Containers/public_SM_BWA_1.sif \
# TNRunner/Bed/AvatarNimIdtTwstBeds/mergedNimV1IdtV1-2TwistV2Pad175bp8March2023.bed.gz* \
# TNRunner/Bed/AvatarNimIdtTwstBeds/sharedNimV1IdtV1-2TwistV2CCDS8March2023.bed.gz*
# aws s3 cp dnaAlignQC_15May2023.zip s3://hcibioinfo-jobrunner/ResourceBundles/dnaAlignQC_15May2023.zip && \
# rm -f dnaAlignQC_15May2023.zip

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. 

# 2) Soft link or move your paired fastq.gz files into the job dir, their names should end in xxxq.gz . Alternatively provide a cram file and it will be converted to paired fastq.

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, xxx.sm, and the tnRunner.yaml config file into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on your local server.  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

# Launch the container
jobDir=$(realpath .)
SINGULARITYENV_dataBundle=$dataBundle SINGULARITYENV_jobDir=$jobDir \
singularity exec --containall --bind $dataBundle,$jobDir $container \
bash $jobDir/*.sing

