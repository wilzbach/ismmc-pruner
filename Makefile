################################################################################
# Compiler variables
################################################################################

SHELL=/bin/bash

################################################################################
# Dynamic variables
################################################################################

chromosomeURL="ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA_000001405.22_GRCh38.p7/GCA_000001405.22_GRCh38.p7_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/chr1.fna.gz"

cutoff=248956422
read_size=5000
#TODO: update
# bash only supports integers
# TODO increase to 30
num_reads=$$(( $(cutoff) * 15 / $(read_size)))

################################################################################
# File variables
################################################################################

chr=perm/chr1.fa
chr_ref=data/chr1
mut_suffix=.mut

PRUNER_SOURCE_DIR=src/graph
PRUNER_BUILDDIR=build/pruner
PRUNER_TESTDIR=build/pruner_test
chr_mut=$(chr_ref)$(mut_suffix)

################################################################################
# Pretasks
# ---------
# Setup folder and platform-specific variables
################################################################################

include pipeline/getprocs.mk

FOLDERS=build data debug perm progs

$(FOLDERS):
	mkdir -p $@

PLATFORM:=$(shell uname -m)

################################################################################
# PROGS
# -----
# Because having portable, versioned and modifiable progs is nice
#
# - avoid breakage (fixed versions)
# - independent from host system (nice for clusters with old distributions)
# - compile once, run everywhere (static linking is used wherever possible)
# - compile from source code and thus allow easy modification & patching
# - sometimes binaries aren't even publicly available (e.g. GATK)
################################################################################

BWA_VERSION=0.7.13
include pipeline/bwa.mk

SAMTOOLS_VERSION=1.3
include pipeline/samtools.mk

GATK_VERSION=3.5
include pipeline/gatk.mk

# required by picard (versions should be the same)
HTSJDK_VERSION=2.2.2
include pipeline/htsjdk.mk

PICARD_VERSION=2.2.2
include pipeline/picard.mk

SEQAN_VERSION=2.1.1
include pipeline/seqan.mk

WGSIM_VERSION=a12da3375ff3b51a5594d4b6fa35591173ecc229
include pipeline/wgsim.mk

PBSIM_VERSION=1.0.3
include pipeline/pbsim.mk

################################################################################
# Build tools
# -----------
#
# We don't want to fiddle with them, download as binaries
################################################################################

DMD_VERSION=2.071.0
DCFLAGS = -w
DCC=/usr/bin/dmd
include pipeline/dmd.mk

# needed for SeqAn
CMAKE_VERSION=3.5.2
include pipeline/cmake.mk

# needed for GATK
MVN_VERSION=3.3.9
include pipeline/mvn.mk

# needed for Picard
ANT_VERSION=1.9.7
include pipeline/ant.mk

# needed for newer HTSJDK versions
GRADLE_VERSION=2.14
include pipeline/gradle.mk

################################################################################
# Python
################################################################################

PYTHON_VERSION=3.5.2
BIOPYTHON_VERSION=1.67
NUMPY_VERSION=1.11.1
MATPLOTLIB_VERSION=1.5.1

include pipeline/python.mk

################################################################################
# Pruner in & out
################################################################################

LIBHTS=build/samtools-$(SAMTOOLS_VERSION)/htslib-$(SAMTOOLS_VERSION)/libhts.a

# order of libraries matters
progs/pruner_in: src/bam/in.c | build/samtools-$(SAMTOOLS_VERSION) $(LIBHTS) build/bam progs
	gcc -I$(word 1,$|)/htslib-$(SAMTOOLS_VERSION) -Ibuild \
		-L $(word 1,$|)/htslib-$(SAMTOOLS_VERSION) $< -l:libhts.a -lz -pthread -o $@

progs/pruner_out: src/bam/out.c | build/samtools-$(SAMTOOLS_VERSION) $(LIBHTS) build/bam progs
	gcc -I$(word 1,$|)/htslib-$(SAMTOOLS_VERSION) -Ibuild \
		-L $(word 1,$|)/htslib-$(SAMTOOLS_VERSION) $< -l:libhts.a -lz -pthread -o $@

################################################################################
# D part: compile
################################################################################

include pipeline/rwildcard.mk

PRUNERFLAGS_IMPORT = $(foreach dir,$(PRUNER_SOURCE_DIR), -I$(dir))
PRUNER_SOURCES = $(call rwildcard,$(PRUNER_SOURCE_DIR)/pruner/,*.d)
PRUNER_OBJECTS = $(patsubst $(PRUNER_SOURCE_DIR)/%.d, $(PRUNER_BUILDDIR)/%.o, $(PRUNER_SOURCES))

build/pruner_test: | build
	mkdir -p $@

# create object files
$(PRUNER_BUILDDIR)/pruner.o : $(PRUNER_SOURCES) | $(DCC)
	$(DCC) -c -debug -g -w -vcolumns -profile -of$@ $^

progs/pruner: $(PRUNER_BUILDDIR)/pruner.o | $(DCC)
	$(DCC) -g -of$@ $^

################################################################################
# D part: test (one-step)
################################################################################

# create object files for unittest
$(PRUNER_TESTDIR)/bin: $(PRUNER_SOURCES) | $(DCC) $(PRUNER_TESTDIR) debug
	$(DCC) -unittest $^ -of$@ -g -vcolumns

test: $(PRUNER_TESTDIR)/bin
	$<

################################################################################
# WhatsHap
# Version 0.10 is broken :/
################################################################################

WHATSHAP_VERSION=0.9
WHATSHAP=$(PYTHON_SITE_PACKAGES)/whatshap
$(WHATSHAP): | $(PIP)
	$(PIP) install --upgrade --ignore-installed whatshap==$(WHATSHAP_VERSION)

################################################################################
# Step 0) Pattern rules for suffixes
# - Indexes are created on demand
# - intermediate files will be removed on exit
################################################################################

# aligns foo.bar.read1.fq + foo.bar.read2.fq to reference foo.fa
#  - the first dot determines the name of the reference
#  - mem is recommended for longer reads (faster, more accurate)
#  - gatk required us to have read groups and indexed file bam file
#  TODO: $(word 1,$(subst ., ,data/chr1.mut))
%.ali: $(chr_ref).fa.bwt %.read1.fq %.read2.fq | $(SAMTOOLS)
	$(BWA) mem -t $(NPROCS) $(subst .bwt,,$<) $(word 2, $^) $(word 3, $^) \
		-R "@RG\tID:$(chr_ref)\tPG:bwa\tSM:$(chr_ref)" > $@

# Map variant from read to reference
# - Sample dot pattern applies
%.gvcf: $(chr_ref).fa.fai $(chr_ref).dict %.samsorted.bam | $(GATK)
	$(GATK) -R $(subst .fai,,$<) -T HaplotypeCaller -I $(word 3,$^) -o $@

################################################################################
# Step 1 - create reference & index it
# ------------------------------------
#
# - bwa -> bwt files
# - mason_variator needs fai
# - GATK needs fai and dict
################################################################################

# TODO add data and perm

$(chr): | perm
	curl $(chromosomeURL) | gunzip > $@

# create reference "genome"
$(chr_ref).fa: $(chr) | data $(BIOPYTHON)
	$(PYTHON) src/cut.py $(chr) -e $(cutoff)  > $@

################################################################################
# Step 2 - mutate references into haplotypes
# ------------------------------------------
#
# mutate (SNPs, Indels, SVs) with two haplotypes
################################################################################

$(chr_mut).fa $(chr_mut).ref.vcf: $(chr_ref).fa $(chr_ref).fa.fai | $(MASON_VARIATOR)
	$(MASON_VARIATOR) -ir $< -of $(chr_mut).fa -ov $(chr_mut).ref.vcf \
		--out-breakpoints data/chr1.mut.tsv --num-haplotypes 2

################################################################################
# Step 3 - simulate reads
# ----------------------
#
# Reads are read from fragments
################################################################################

$(chr_mut).read1.fq $(chr_mut).read2.fq: $(chr_mut).fa | $(WGSIM)
	$(WGSIM) -1 $(read_size) -2 $(read_size) -N $(num_reads) -R 0.0 -e 0.0 -r 0.0 \
		$< $@ $(chr_mut).read2.fq

################################################################################
# Step 6 - Prune reads
# TODO: Can be combined in one step, once this is working & well tested
#
# I) We transform the BAM filter in a chr,start,stop,id format
# II) We run the pruner - it outputs the pruned ids
# III) We filter the BAM file based on the pruned ids
#
# III) expects that the ordered ids are sorted
################################################################################

data/pruning.bam.plain: $(chr_mut).samsorted.bam | progs/pruner_in
	$| $< > $@

data/pruning.bam.ids: data/pruning.bam.plain progs/pruner
	cat $< | $(word 2, $^) --max-coverage 3 > $@

data/pruning.bam.filtered: $(chr_mut).samsorted.bam data/pruning.bam.ids | progs/pruner_out
	cat $(word 2, $^) | $| $< $@ > /dev/null

################################################################################
# Step 7 - Find haplotypes (pruned, normal)
# TODO: run whatshap properly in a local installation
################################################################################

data/haplotypes.normal.vcf data/haplotypes.normal.log: hp.normal.im
hp.normal.im: $(chr_mut).gvcf $(chr_mut).samsorted.bam | $(WHATSHAP)
	$(WHATSHAP) $^ -o data/haplotypes.normal.vcf 2> data/haplotypes.normal.log

data/haplotypes.pruned.vcf data/haplotypes.pruned.log: hp.pruned.im
hp.pruned.im: $(chr_mut).gvcf data/pruning.bam.filtered.bai | $(WHATSHAP)
	$(WHATSHAP) $< $(subst .bai,,$(word 2,$^)) -o data/haplotypes.pruned.vcf 2>  data/haplotypes.pruned.log

.INTERMEDIATE: hp.normal.im hp.pruned.im

################################################################################
# Step 8 - Analysis
################################################################################

data/haplotypes.compare: data/haplotypes.normal.log data/haplotypes.pruned.log
	@echo "===normal===="
	@grep "No. of" $<
	@echo "===pruned===="
	@grep "No. of" $(word 2, $^)

# normal pipeline + coverage plots
all: data/haplotypes.compare
#all: $(chr_reads_coverage_pdf) $(chr_reads_variants)

################################################################################
# TODO: statistics
################################################################################

# filter read report
$(chr_reads).coverage.tsv: $(chr_reads).samstats
	cat $< | grep '^COV' | cut -f 3- > $@

# read coverage plot
$(chr_reads).coverage.pdf: $(chr_reads).coverage.tsv
	./src/coverage_stats.py $< -o $@
