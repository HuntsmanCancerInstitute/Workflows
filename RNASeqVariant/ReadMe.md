# RNASeq expression and variant pipeline

This is a [pysano](https://healthcare.utah.edu/huntsmancancerinstitute/research/shared-resources/center-managed/bioinformatics/pysano/) 
`cmd.txt` template for running a RNASeq expression and variant detection pipeline. It 
could be converted to a slurm script as necessary by replacing paths and adding headers.

It will run 

- STAR alignment with genomic and transcriptome bam output against Ensembl GRCh38

- featureCounts gene counting

- RSEM transcript counting

- Picard MarkDuplicates

- GATK split N alignments

- GATK base recalibration

- GATK indel realignment

- GATK base recalibration

- GATK HaplotypeCaller in VCF mode for individual SNP detection

- GATK HaplotypeCaller in gVCF mode for joint genotyping 

### Guide

Customize the job information at the top of the template for each sample job. Run each 
sample through the pipeline. It assumes paired-end RNASeq reads; adjust accordingly.

After running all samples through the pipeline, merge the individual VCF and gVCF files 
together. Generate a _master_ list of possible variant positions from the merged VCF file 
to use in a final GATK genotype call on the merged gVCF file. Use the final joint genotype 
VCF file for further analysis.

Differential expression can be performed using standard DESeq2 analysis.


