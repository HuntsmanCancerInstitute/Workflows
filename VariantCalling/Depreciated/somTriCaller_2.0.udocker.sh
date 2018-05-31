set -e

# 24 May 2018
# David.Nix@Hci.Utah.Edu

# Print params
echo -n tumor"  : "; echo $tumor
echo -n normal" : "; echo $normal
echo -n jobDir" : "; echo $jobDir
echo -n name"   : "; echo $name; echo

# Set vars, sourcing /root/.bashrc doesn't work in udocker
export PATH="/BioApps/Miniconda3/bin:$PATH"
export ALL_THREADS=$(nproc)
export ALL_RAM=$(expr `free -g | grep -oP '\d+' | head -n 1` - 2)
echo "Threads: "$ALL_THREADS"  Memory: "$ALL_RAM"  Host: "`hostname`; echo

cd $jobDir

#set params
s=/scratch/mammoth/serial/u0028003
genomeBuild=Hg38

/BioApps/Miniconda3/bin/snakemake -p -T \
--cores $ALL_THREADS \
--snakefile somTriCaller_*.sm \
--configfile /BioApps/apps.yml \
--config \
allThreads=$ALL_THREADS \
allRam=$ALL_RAM \
regionsForAnalysis=$s/SnakeMakeDevResources/Bed/sortedHg38RegionsToCall.bed.gz \
indexFasta=$s/SnakeMakeDevResources/Indexes/B38_NS_GRCm38_Index/hs38DH.fa \
dbsnp=$s/SnakeMakeDevResources/Vcfs/dbsnp_132_b37.leftAligned.vcf.gz \
mpileup=$s/SnakeMakeDevResources/MpileupBkg/BkGrdMouseHumanMixes/b38Mm10AvatarBkg.mpileup.gz \
tumorBam=$tumor \
normalBam=$normal \
genomeBuild=$genomeBuild \
name=$name \
minTumorAlignmentDepth=10 \
minNormalAlignmentDepth=8 \
minTumorAF=0.015 \
maxNormalAF=1 \
minTNRatio=1.2 \
minTNDiff=0.015 &> $name"_"$genomeBuild"_SnakemakeRun.log"

echo; echo "Clean up and logging ....."
rm -rf Run; mkdir Run && cp somTriCaller_* Run/ && cp *SnakemakeRun.log Run/ &&
cp slurm* Run/ && zip -qr Run.zip Run && mv Run.zip $name"_"$genomeBuild/ && rm -rf Run .snakemake

echo; echo UDocker Done
