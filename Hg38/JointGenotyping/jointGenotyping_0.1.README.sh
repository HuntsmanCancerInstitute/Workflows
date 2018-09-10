#!/bin/bash
#SBATCH --account=hci-rw
#SBATCH --partition=hci-rw
#SBATCH -N 1
#SBATCH -t 48:00:00

set -e; start=$(date +'%s'); rm -f DONE FAILED COMPLETE; touch STARTED

# 10 September 2018
# David.Nix@Hci.Utah.Edu
# Huntsman Cancer Institute

# This is a standard GATK GenotypeGVCFs analysis followed by normalizing the vcf with vt and splitting it into individual vcf files with light filtering.


#### Do just once ####

# 1) Install udocker in your home directory as yourself, not as root, https://github.com/indigo-dc/udocker/releases . Define the location of the udocker executable.
udocker=/uufs/chpc.utah.edu/common/HIPAA/u0028003/BioApps/UDocker/udocker-1.1.1/udocker
#udocker=/home/u0028003/BioApps/UDocker/udocker-1.1.1/udocker

# 2) Define a root mount file path that contains the vcf files to analyze, your working job directories, and reference files. These need to be in sub direcatories of the mount path. UDocker can only see files that reside within this path.
mount=/scratch/mammoth/serial/u0028003/
#mount=/Repository/AnalysisData/Nix/

# 3) Modify the jointGenotyping_*.udocker file setting the paths to the required resources. These must be on the mount path.
## emacs jointGenotyping_*.udocker 
## regionsForAnalysis - bgzipped bed file of regions to use in calling genotypes, use chrXXXX naming for Hg38. See bgzip and tabix from https://github.com/samtools/htslib .
## indexFasta - the indexed fasta file used for alignment including xxx.fa.fai and xxx.dict files, see https://github.com/lh3/bwa/tree/master/bwakit

# 4) Build the udocker container, do just once after each update.
## $udocker rm SnakeMakeBioApps_2   # might not exit and throw error
## $udocker pull hcibioinformatics/public:SnakeMakeBioApps_2
## $udocker create --name=SnakeMakeBioApps_2  hcibioinformatics/public:SnakeMakeBioApps_2


#### Do for every run ####

# 1) Create an analysis folder named as you would like the name to appear, this along with the genome build will be prepended onto all files, no spaces, change into it. This must reside somewhere in the mount path.
## cd $mount/JointGenotyping/; mkdir LungPatients_12Aug2018; cd LungPatients_12Aug2018

# 2) Create a ToGenotype folder in the analysis folder.
## mkdir ToGenotype

# 2) Move or Soft link all the xxx.g.vcf.gz files into the ToGenotype folder from running the GATK Haplotype caller.
## ln -s $mount/Batch391GVcfs/*g.vcf.gz ToGenotype/

# 3) Copy over the jointGenotyping_xxx.udocker, jointGenotyping_xxx.README.sh, and jointGenotyping_xxx.sm workflow docs
## cp $mount/JointGenotyping/WorkflowDocs/jointGenotyping_* .

# 4) If needed, modify the filtering params in the local copy of the jointGenotyping_xxx.udocker file, e.g. genomeBuild, USeq params
## emacs jointGenotyping_xxx.udocker

# 5) Launch the jointGenotyping_xxx.README.sh via sbatch or run it on your local server.
## sbatch jointGenotyping_xxx.README.sh

# 6) If the run fails, fix the issue and restart.  Snakemake should pick up where it left off. 



#### No need to modify anything below ####
echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params and fetch real path for linked fastq
name=${PWD##*/}
jobDir=`readlink -f .`

$udocker run --env=name=$name --env=jobDir=$jobDir \
--volume=$mount:$mount SnakeMakeBioApps_2 < jointGenotyping_*.udocker

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

# Final cleanup
mkdir -p RunScripts
mv jointGenotyping_* RunScripts/
mv *_SnakemakeRun.log Logs/
mv *_SnakemakeRunStats.log Logs/
rm -rf .snakemake 
mv slurm* Logs/
rm -f DONE FAILED STARTED; touch COMPLETE

