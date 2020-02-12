#!/usr/bin/env nextflow
 
/* 
 * Proof of concept Nextflow based loh pipeline
 * 
 */ 

 
/*
 * Defines some parameters in order to specify 
 * input vcf, bam and their index files by using the command line options
 */
params.vcf = "/scratch/general/lustre/u0762203/loh/1220270/1220270_NormalDNA_Hg38_JointGenotyped.vcf.gz"
params.vcfIdx = "/scratch/general/lustre/u0762203/loh/1220270/1220270_NormalDNA_Hg38_JointGenotyped.vcf.gz.tbi"
params.bam = "/scratch/general/lustre/u0762203/loh/1220270/1220270_TumorDNA_Hg38_final.bam"
params.bamIdx = "/scratch/general/lustre/u0762203/loh/1220270/1220270_TumorDNA_Hg38_final.bai"
params.db = "/uufs/chpc.utah.edu/common/home/u0762203/db"
params.outdir = 'results'
vcf=file(params.vcf)
id=(vcf=~ /(\d+)_NormalDNA_Hg38_JointGenotyped/)[0][1]

log.info """
         LOH   P I P E L I N E    
         =============================
         normal : ${params.vcf}
         tumor: ${params.bam}
         """
         .stripIndent()

 
/*
 * Step 1. prepare tumor mpileup file 
 */ 
process tMpileup {
    input:
    file(params.bamIdx) 
 
    output:
    file("${id}.bam.mpileup.gz") into forAnot1
    file("${id}.bam.mpileup.gz.tbi") into forAnot3
 
    """
    /samtools-1.10/samtools mpileup -B -q 1 -d 1000000 -f ${params.db}/hg38.fa -l ${params.db}/mergedSeqCap_EZ_Exome_v3_hg38_capture_primary_targets_pad150bp.bed.gz ${params.bam} > ${id}.bam.mpileup
    /usr/bin/bgzip ${id}.bam.mpileup
    /usr/bin/tabix -s 1 -b 2 -e 2 ${id}.bam.mpileup.gz
    """
}
  
/*
 * Step 2. clean normal vcf
 */
process cleanVcf {
    input:
    file(params.vcfIdx)
     
    output:
    file("${id}.NormalDNA.clean.vcf") into forVt
    """
    /bin/gunzip -c ${params.vcf} > ${id}.g.vcf
    /nextflowWorkflow/accessoryScripts/cleanVcf.pl ${id}.g.vcf
    """
}
 
/*
 * Step 3. vt normalize and decompose normal vcf
 */
process vt {
    input:
    file("${id}.NormalDNA.clean.vcf") from forVt
     
    output:
     file("block.norm.${id}.NormalDNA.clean.vcf") into (forAnot2, calAf1) 
 
    """
    /vt/vt normalize ${id}.NormalDNA.clean.vcf -r ${params.db}/hg38.fa -o norm.${id}.NormalDNA.clean.vcf -n
   /vt/vt decompose_blocksub norm.${id}.NormalDNA.clean.vcf -o block.norm.${id}.NormalDNA.clean.vcf
    """
}
/*
 * Step 4. estimates the AF and DP of a normal vcf record from the paired tumor sample mpileup file
 */
process anot {
    input:
    file("${id}.bam.mpileup.gz") from forAnot1
    file("${id}.bam.mpileup.gz.tbi") from forAnot3
    file("block.norm.${id}.NormalDNA.clean.vcf") from forAnot2 
    output:
    file("${id}.TumorDNA_Hg38_final.vcf") into calAf2
 
    """
    java -jar /USeq_9.2.4/Apps/VCFMpileupAnnotator -v block.norm.${id}.NormalDNA.clean.vcf -q 13 -m ${id}.bam.mpileup.gz -o ${id}.TumorDNA_Hg38_final.vcf.gz
    gunzip ${id}.TumorDNA_Hg38_final.vcf.gz
    """
}

/*
 * Step 5.calculate average allele freq for tumor sample at the het sites
 */


process calcuAf {
    input:
    file("block.norm.${id}.NormalDNA.clean.vcf") from calAf1 
    file("${id}.TumorDNA_Hg38_final.vcf") from calAf2
     
    output:
    file("${id}.normal.het.baf.txt") into forR1
    file("${id}.tumor.ave.baf.txt") into forR2

    script:
    """
    /nextflowWorkflow/accessoryScripts/calcuAf.pl block.norm.${id}.NormalDNA.clean.vcf ${id}.TumorDNA_Hg38_final.vcf ${id}
    """
}

/*
 * Step 6.  LOH test to look for regions with LOH event
 */
process loh {
    publishDir params.outdir, mode:'copy' , pattern: '*loh.pdf'
    input:
    file("${id}.normal.het.baf.txt") from forR1
    file("${id}.tumor.ave.baf.txt") from forR2
    output:
    file("${id}.loh.bed") into toAnotRf
    file("${id}.loh.pdf") 
 
    """
     #path=`echo \$PWD`
    /nextflowWorkflow/accessoryScripts/loh.R ${id}.normal.het.baf.txt ${id}.tumor.ave.baf.txt ${id} 
    """
}

/*
 * Step 7.  annotate potential LOH region with genes and reformat the output for import (format may change soon due to cBio portal requirement) 
 */
process anotRf {
    publishDir params.outdir, mode:'copy'
    input:
    file("${id}.loh.bed") from toAnotRf
    output:
    file("${id}.header.genes.txt") 
    file("${id}.loh.import.txt") 
 
    """
    java -jar /USeq_9.2.4/Apps/AnnotateBedWithGenes -p 100 -g -b ${id}.loh.bed -r ${id}.targetWithGenes.txt.gz -u ${params.db}/hg38RefSeq8Aug2018_Merged.ucsc.gz
    gunzip ${id}.targetWithGenes.txt.gz
    /nextflowWorkflow/accessoryScripts/rf4lohImport.pl ${id}.targetWithGenes.txt
    """
}
