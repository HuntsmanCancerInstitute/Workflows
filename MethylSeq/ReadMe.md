# Bisulfite-treated DNA MethylSeq

These are a [pysano](https://healthcare.utah.edu/huntsmancancerinstitute/research/shared-resources/center-managed/bioinformatics/pysano/) 
`cmd.txt` templates for running jobs on the HCI nodes at CHPC. These 
could be converted to a slurm script for direct execution on CHPC as necessary by 
replacing paths and adding headers. 

Carefully check the header lines at the top of the templates, and make adjustments as 
necessary (email, etc). 

Contact the Core if you have any issues.

There are two workflows here: Novoalign/USeq and Bismark.

### Novoalign and USeq workflow

[Novoalign](http://www.novocraft.com/products/novoalign/) currently gives a better 
alignment rate than Bismark/Bowtie2, at the expense of speed. With moderate-sized sequencing 
projects, you may still time out (10 days) on a single node.

Therefore, split your Fastq reads into a few million reads apiece, and align each job 
independently on separate nodes (You will thank me later). Split the file manually, or run 
[this script](https://github.com/tjparnell/HCI-Scripts/blob/master/Fastq/split_fastq.pl), 
which maintains compression and executes with multiple threads.

Run the `novoalign_part_cmd.txt` alignment on each part. When finished, merge the 
resulting bam files into a single bam file with samtools and index.

Once you have a single file, you can run the `useq_bisulfite_cmd.txt` job with the 
sample bam file.

You will need to run additional USeq applications for calling differentially methylated 
regions. See the [USeq documentation](http://useq.sourceforge.net/usageBisSeq.html). 

*NOTE* The `cmd.txt` template files are organism specific. Add or remove the comment marks 
as necessary to match your organism genome version. Contact the Core if the genome 
version you need doesn't exist.

### Bismark workflow

An example Bismark alignment and initial processing steps are provided in the 
`bismark_cmd.txt` template file.

This will use the GNomEx sample identifier (e.g. 1234X1) from the Fastq file name as 
the base name for the output files. 

Note the organism parameter at the top and adjust accordingly.

