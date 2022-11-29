#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 24:00:00

set -e; start=$(date +'%s'); rm -f FAILED COMPLETE QUEUED; touch STARTED

# 28 Nov 2022
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This fires a GATK CNV workflow generating copy ratio and heterozygous allele frequency segment calls. See https://gatkforums.broadinstitute.org/dsde/discussion/11682 and https://gatkforums.broadinstitute.org/dsde/discussion/11683 

#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place it in your path
which singularity &> /dev/null || module load singularity

# 2) Set the path to the TNRunner dataBundle in the snakemake config yaml file. It can be downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578
dataBundle=$(grep dataBundle *.yaml | grep -v ^# | cut -d ' ' -f2)

# 3) Check and if needed, modify the parameters specific to this workflow in the snakemake config yaml file.

# 4) If needed build the singularity container, and define the path to the xxx.sif file, do after each update, e.g. singularity pull docker://hcibioinformatics/public:GATK_SM_2
container=$dataBundle/Containers/public_GATK_SM_2.sif

# 5) If running this on AWS EC2 via the JobRunner, build the resource archive, and upload it to S3
#cd /uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/
#zip -r somaticCopyNumber_18Jan2022.zip  \
#   TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.fasta \
#   TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.dict \
#   TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.fasta.fai \
#   TNRunner/Containers/public_GATK_SM_1.sif \
#   TNRunner/CNV/AVATAR/Somatic/NIM/mergedSeqCap_EZ_Exome_v3_hg38_capture_primary_targets_pad150bp.preprocessed.interval_list \
#   TNRunner/CNV/AVATAR/Somatic/IDT/hg38IdtProbesPad150bp.processed.interval_list \
#   TNRunner/Bed/hg38StdChromLengths.bed.gz \
#   TNRunner/AnnotatorData/UCSC/8Aug2018/hg38RefSeq8Aug2018_Merged.ucsc.gz 
#   aws s3 cp somaticCopyNumber_18Jan2022.zip s3://hcibioinfo-jobrunner/ResourceBundles/

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. 

# 2) Soft link your:
#    a) Tumor and normal bam (or cram) files and their associated indexes into the job dir naming them tumor.bam/.bai(or .cram/.crai), normal.bam/.bai(or .cram/.crai)
#    b) Tumor passing region bed file, see the QC folder in the DnaAlignQC results directory
#    c) Germline variant xxx.vcf.gz file with its associated index
#    d) Gender and capture matched PoN xxx.hdf5 and xxx.interval_list files (see /uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/TNRunner/CopyRatioBkgs) 

# 3) Copy over the workflow docs: xxx.sing, xxx.README.sh, xxx.sm, and the xxx.yaml snakemake config file into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on the local server, e.g. bash ./*README.sh  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off.



#### No need to modify anything below ####

# Read out params
jobDir=`readlink -f .`

SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $jobDir,$dataBundle $container \
bash $jobDir/*.sing

# Final cleanup
mkdir -p RunScripts
mv -f copyAnalysis*  RunScripts/ &> /dev/null || true
mv -f *.yaml RunScripts/ &> /dev/null || true
cp slurm* Logs/ &> /dev/null || true
mv -f *snakemake.stats.json Logs/ &> /dev/null || true
rm -rf .snakemake STARTED RESTART* QUEUED slurm*
