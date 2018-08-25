# Alignment Workflows

These are best practice alignment pipelines developed by the HCI Bioinformatics 
Shared Resource for exome sequence alignment. They are intended to be run at the 
CHPC on the kingspeak or the redwood clusters. They use 
[snakemake](https://bitbucket.org/snakemake/snakemake) as a workflow manager. They can 
launched directly as a slurm job or through the HCI 
job management system.

For execution with the [pysano](https://healthcare.utah.edu/huntsmancancerinstitute/research/shared-resources/center-managed/bioinformatics/pysano/) 
system from the HCI local linux servers, use the `pysano_cmd_template.txt`.

For direct slurm execution on the CHPC clusters, use the `slurm_template.sh` and edit 
as appropriate.

Click on the `.svg` files to view the diagram of the workflow.

## Pipeline Versions

- `alignQC_1.3.sm`

    Original snakemake workflow. Trims adapters, aligns with BWA, mark duplicates with 
    SamBlaster, removes low quality and off-target alignments with USeq 
    SamAlignmentExtractor, realigns indels with GATK, recalibrate base quality with 
    GATK, runs USeq MergePairedAlignments and USeq Sam2USeq for quality metrics. 
    *NOTE:* This is compatible with the `kingspeak` cluster only.

- `alignQC_1.3_hci.sm`

    Same as `alignQC_1.3.sm` version but points to HCI resources on our group space. 
    These are the same resources used through pysano.
    *NOTE:* This is compatible with the `kingspeak` cluster only.

- `alignQC_1.4`

    Updated snakemake workflow with newer versions. Multi-threaded adapter trimming with Cutadapt, 
    BWA alignment, remove low quality alignments with USeq SamAlignmentExtractor, remove 
    duplicates with Picard, realigns indels with GATK, recalibrate base quality with 
    GATK, runs USeq MergePairedAlignments and USeq Sam2USeq for quality metrics, runs 
    Picard AlignmentSummaryMetrics, InsertSizeMetrics, and CollectHsMetrics.
    *NOTE:* This is compatible with the `redwood` cluster only.

- `alignQCgvcf_1.4`

    Same as `alignQC_1.4` but with addition of GATK HaplotypeCaller in GVCF mode.

- `alignQC_1.4a`

    Slightly streamlined version of 1.4 without USeq metrics.

- `alignQCgvcf_1.4a`

    Same as `alignQC_1.4a` but with addition of GATK HaplotypeCaller in GVCF mode.


## MolBarcodes

These are snakemake workflows for working with Unique Molecular Index (UMI) barcoded 
samples. 

- `consensusAlignQC_0.3`

    Snakemake alignment pipeline using the USeq consensus apps to collapse alignments 
    with the same UMI code, derive a consensus sequence between UMI duplicates, and 
    realign the consensus sequence. Requires three fastq files.

- `qiaseq_AlignQC`

    Snakemake alignment pipeline for the Qiaseq PCR-based library preparation. UMI codes 
    are extracted from the second fastq read. 



