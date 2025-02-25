#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 96:00:00

set -e

# 6 Jan 2025
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This fires a variety of apps that annotate a vcf with functional effect info using SnpEff 5.0e, ExAC AFs, ClinVar, and the VCFSpliceScanner.  It also generates a filtered vcf based on these annotations.


#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module, place it in your path
which singularity &> /dev/null || module load singularity

# 2) Set the path to the TNRunner dataBundle in the snakemake config yaml file. It can be downloaded and uncompressed from https://hci-bio-app.hci.utah.edu/gnomex/?analysisNumber=A5578
dataBundle=$(grep dataBundle *.yaml | grep -v ^# | cut -d ' ' -f2)

# 3) Check and if needed, modify the parameters specific to this workflow in the snakemake config yaml file.

# 4) If needed build the singularity container, and define the path to the xxx.sif file, do after each update, e.g. singularity pull docker://hcibioinformatics/public:SnpEff_SM_2
container=$dataBundle/Containers/public_SnpEff_SM_2.sif

# 5) If running this on AWS EC2 via the JobRunner, build the resource archive, and upload it to S3
# cd /uufs/chpc.utah.edu/common/PE/hci-bioinformatics1/
# zip -r annotator_17Dec2021.zip  \
#    TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.fasta \
#    TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.dict \
#    TNRunner/GATKResourceBundleAug2021/Homo_sapiens_assembly38.fasta.fai \
#    TNRunner/Containers/public_SnpEff_SM_1.sif \
#    TNRunner/Bed/ACMG/hg38ACMGPlusPatho21Apr2021.bed.gz* \
#    TNRunner/AnnotatorData \
#    TNRunner/GQuery
# aws s3 cp annotator_17Dec2021.zip s3://hcibioinfo-jobrunner/ResourceBundles/

# 6) Create a file called annotatedVcfParser.config.txt and provide params for the USeq AnnotatedVcfParser application, e.g. '-d 20 -m 0.1 -q 0.1 -p 0.01 -g D5S,D3S -n 4.4 -a HIGH -l -c Pathogenic,Likely_pathogenic,Conflicting_interpretations_of_pathogenicity,Drug_response -t 0.51 -e Benign,Likely_benign -o -b 0.1 -z 3 -u RYR1' for strict germline or '-d 20 -f' for somatic.

# 7) Create a file called vcfCallFrequency.config.txt and provide params for the USeq VCFCallFrequency application, e.g. '-v Hg38/Somatic/Avatar/Vcf -b Hg38/Somatic/Avatar/Bed -m 0.1'

# 8) Create a file called oncoKB.config.txt containing two lines. The first is the OncoKB licensing key, see https://www.oncokb.org.  The second is the OncoTree tumor type abbreviation 'CODE', see https://oncotree.mskcc.org/?version=oncotree_latest_stable&field=NAME, use 'OTHER' if not known or a normal germline sample.
#    E.g. 
#    97c69z57-1674-467a-9150-v09d3a21655d
#    PRAD

#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. 

# 2) Copy or soft link your gzipped vcf file to annotate into the job directory naming it anything ending in .vcf.gz

# 3) Copy over the docs: xxx.sing, xxx.README.sh, xxx.sm, xxx.yaml, and three xxx.config.txt files into the job directory.

# 4) Launch the xxx.README.sh via sbatch or run it on the local server, e.g. bash ./*README.sh  

# 5) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off. If needed, try deleting the .snakemake dir first to clear any locked files.



#### No need to modify anything below ####
jobDir=$(realpath .)

SINGULARITYENV_jobDir=$jobDir SINGULARITYENV_dataBundle=$dataBundle \
singularity exec --containall --bind $jobDir,$dataBundle $container \
bash $jobDir/*.sing

# Final cleanup
mkdir -p RunScripts
rm -f oncoKB.config.txt 
mv -f annotator*  *config.txt RunScripts/ &> /dev/null || true
mv -f *.yaml RunScripts/ &> /dev/null || true
cp slurm* Logs/ &> /dev/null || true
mv -f *snakemake.stats.json Logs/ &> /dev/null || true
rm -rf .snakemake STARTED RESTART* QUEUED slurm*
touch COMPLETE

