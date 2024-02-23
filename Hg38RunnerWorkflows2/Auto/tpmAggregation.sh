set -e

# Clear out anything made before
mkdir -p AggregateTPM
cd AggregateTPM
rm -rf TPM/ RSEM/ aggregateTPM* geneIds.txt  &> /dev/null || true

mkdir RSEM TPM
cp ../*Jobs/*/Avatar/*/Alignment/*TumorRNA/Quantitation/RSEM/*TumorRNA_Hg38.genes.results RSEM/

# parse the ensembl gene ids from one file
files=(RSEM/*)
firstFile=${files[0]}
echo $firstFile
java -jar -Xmx1G ~/USeqApps/PrintSelectColumns -i 0 -f $firstFile -n 1
mv RSEM/*.xls geneIds.txt

# parse TPM
java -jar -Xmx1G ~/USeqApps/PrintSelectColumns -i 5 -f RSEM/ -n 1
mv RSEM/*xls TPM/

# Rename the files to just the sample name
cd TPM/
for x in *xls
do
echo $x
name=$(echo $x | awk -F'_TumorRNA_Hg38.genes.PSC.xls' '{print $1}')
mv $x $name
done

# Save the names tab delimited and add on a return
ls -1 | tr '\n' '\t' > ../aggregateTPM.txt
echo >> ../aggregateTPM.txt

# merge files with paste
paste ../geneIds.txt * >> ../aggregateTPM.txt
cd ../
gzip aggregateTPM.txt

# Note, at this point the sample row is out of register due to the addition of the gene column.  This is deliberate to replicate export of the vst values from DeSeq2.

# run the NormalizedCountCBioFormater.java 
java -jar -Xmx20G ~/USeqApps/NormalizedCountCBioFormater \
   -e ~/TNRunner/AnnotatorData/TpmVstRNASeqParsing/ens106GeneId2Symbol.txt.gz \
   -n aggregateTPM.txt.gz

## Final file is aggregateTPM_ForCBio.txt.gz

rm -rf TPM/ RSEM/ aggregateTPM.txt.gz geneIds.txt
cd ../
