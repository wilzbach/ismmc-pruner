SHELL=/bin/bash
chromosomeURL="ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA_000001405.15_GRCh38/GCA_000001405.15_GRCh38_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/chr1.fna.gz"

chr=perm/chr1.fa
# step 1: prepare reference
chr_ref_base=data/chr1.cut
chr_ref=$(chr_ref_base).fa
chr_ref_index_bwa=$(chr_ref).bwt
chr_ref_index_fai=$(chr_ref).fai
chr_ref_index_dict=$(chr_ref_base).dict
# step 2: mutate reference into haplotypes
chr_mut=data/chr1.mut.fa
chr_mut_vcf=data/chr1.mut.vcf
# step 3: sample reads
# the merged sam file is only needed for coverage analysis
chr_reads=data/chr1.reads.bam
chr_reads_h1=data/chr1.reads.h1.fq
chr_reads_h2=data/chr1.reads.h2.fq
chr_reads_sorted=data/chr1.reads.sorted.stats
chr_reads_stats=data/chr1.reads.stats
chr_reads_coverage_tsv=data/chr1.reads.coverage.tsv
chr_reads_coverage_pdf=data/chr1.reads.coverage.pdf
# step 4: align & map
chr_reads_aligned=data/chr1.reads.ali.bam
chr_reads_variants=data/chr1.reads.vcf
cutoff=1000000
#todo set to 5000
read_size=100
#TODO: update
# bash only supports integers
num_reads=$$(( $(cutoff) * 1 / $(read_size)))

################################################################################
# Pretasks
################################################################################

NPROCS:=1
OS:=$(shell uname -s)
unneeded_var =
ifeq ($(OS),Linux)
	NPROCS:=$(shell grep -c ^processor /proc/cpuinfo)
endif
ifeq ($(OS),Darwin) # Assume Mac OS X
	NPROCS:=$(shell system_profiler | awk '/Number Of CPUs/{print $4}{next;}')
endif

perm: 
	mkdir -p perm
data: 
	mkdir -p data

################################################################################
# Step 1 - create reference & index it
# ------------------------------------
#
# - bwa -> bwt files
# - mason_variator needs fai
# - GATK needs fai and dict
################################################################################

# TODO add data and perm

$(chr):  
	curl $(chromosomeURL) | gunzip > $@

# create reference "genome"
$(chr_ref): $(chr)
	./src/cut.py $(chr) -e $(cutoff)  > $@

# index reference
$(chr_ref_index_bwa): $(chr_ref)
	bwa index $<

# GATK needs more indexing
$(chr_ref_index_fai): $(chr_ref)
	samtools faidx $<

$(chr_ref_index_dict): $(chr_ref)
		picard CreateSequenceDictionary REFERENCE=$< OUTPUT=$@

################################################################################
# Step 2 - mutate references into haplotypes
# ------------------------------------------
#
# mutate (SNPs, Indels, SVs) with two haplotypes
################################################################################

$(chr_mut) $(chr_mut_vcf): $(chr_ref) $(chr_ref_index_fai)
	mason_variator -ir $< -of $(chr_mut) -ov $(chr_mut_vcf) \
		--out-breakpoints data/chr1.mut.tsv --num-haplotypes 2

################################################################################
# Step 3 - simulate reads
# ----------------------
#
# Reads are read from fragments
################################################################################

# simulate paired-end reads
$(chr_reads) $(chr_reads_h1) $(chr_reads_h2): $(chr_ref) $(chr_mut)
	mason_simulator -ir $(chr_ref) -iv $(chr_mut_vcf) \
    	-o $(chr_reads_h1) -or $(chr_reads_h2) -oa $(chr_reads) \
    	--num-threads $(NPROCS) --read-name-prefix sim  \
		--seq-technology 454 \
		--num-fragments $(num_reads) \
		--454-read-length-min 4000 \
		--454-read-length-max 6000 \
		--454-read-length-mean 5000 \
		--454-read-length-stddev 400 \
		--fragment-min-size 5000 \
		--fragment-max-size 20000 \
		--fragment-mean-size 15000 \
		--fragment-size-std-dev 1500

$(chr_reads_sorted): $(chr_reads)
	samtools sort $< > $@

# reads statistics
$(chr_reads_stats): $(chr_reads_sorted)
	samtools stats $< > $@

# filter read report
$(chr_reads_coverage_tsv): $(chr_reads_stats)
	cat $< | grep '^COV' | cut -f 3- > $@

# read coverage plot
$(chr_reads_coverage_pdf): $(chr_reads_coverage_tsv)
	./src/coverage_stats.py $< -o $@

################################################################################
# Step 4 - Align reads to reference
# ---------------------------------
#
# mem is recommended for longer reads (faster, more accurate)
################################################################################

# align reads
$(chr_reads_aligned): $(chr_ref) $(chr_reads) $(chr_ref_index_bwa)
	bwa mem -t $(NPROCS) $(chr_ref) $(chr_reads_h1) $(chr_reads_h2) > $@

################################################################################
# Step 5 - Map variant from read to reference
################################################################################

# map variants
$(chr_reads_variants): $(chr_ref) $(chr_reads_aligned) $(chr_ref_index_dict) $(chr_ref_index_fai)
	gatk -nt $(NPROCS) -R $(chr_ref) -T HaplotypeCaller -I $(chr_reads_aligned) -o $@

################################################################################
# Step 6 - Prune reads
################################################################################

################################################################################
# Step 7 - Find haplotypes (pruned, normal)
################################################################################


################################################################################
# Step 8 - Analysis
################################################################################


# normal pipeline + coverage plots
all: $(chr_reads_coverage_pdf) $(chr_reads_variants)
