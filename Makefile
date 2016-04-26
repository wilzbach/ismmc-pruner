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
# step 4: align & map
chr_reads_aligned_raw=data/chr1.reads.ali.raw.bam
chr_reads_aligned_sorted=data/chr1.reads.ali.sorted.bam
# 4b) some statistics
chr_reads_stats=data/chr1.reads.stats
chr_reads_coverage_tsv=data/chr1.reads.coverage.tsv
chr_reads_coverage_pdf=data/chr1.reads.coverage.pdf
# step 5: call variants
chr_reads_variants=data/chr1.reads.vcf
cutoff=1000000
#cutoff=248956422
#todo set to 5000
read_size=5000
#TODO: update
# bash only supports integers
# TODO increase to 30
num_reads=$$(( $(cutoff) * 15 / $(read_size)))

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
progs:
	mkdir -p progs

################################################################################
# PROGS
# -----
#
# Because having portable progs is nice
################################################################################

BWA=progs/bwa
BWA_VERSION=0.7.13

SAMTOOLS=progs/samtools
SAMTOOLS_VERSION=1.3

GATK=progs/gatk
GATK_VERSION=3.5

PICARD=progs/gatk
PICARD_VERSION=2.2.2

MASON_VARIATOR=progs/mason_variator
SEQAN_VERSION=2.1.1

WGSIM=progs/wgsim

PBSIM=progs/pbsim
PBSIM_VERSION=1.0.3

progs/bwa-$(BWA_VERSION): | progs
	curl -L http://downloads.sourceforge.net/project/bio-bwa/bwa-$(BWA_VERSION).tar.bz2 \
	| bzip2 -d | tar xf - -C progs

progs/bwa: | progs/bwa-$(BWA_VERSION)
	cd progs/bwa-$(BWA_VERSION) && make
	ln -s ./bwa-$(BWA_VERSION)/bwa $@

progs/samtools-$(SAMTOOLS_VERSION): | progs
	curl -L https://github.com/samtools/samtools/releases/download/$(SAMTOOLS_VERSION)\
	/samtools-$(SAMTOOLS_VERSION).tar.bz2 \
	| bzip2 -d | tar xf - -C progs

progs/samtools: | progs/samtools-$(SAMTOOLS_VERSION)
	cd progs/samtools-$(SAMTOOLS_VERSION) && \
		sed -e 's|#!/usr/bin/env python|#!/usr/bin/env python2|' -i misc/varfilter.py
	cd progs/samtools-$(SAMTOOLS_VERSION) && ./configure
	cd progs/samtools-$(SAMTOOLS_VERSION) && make -j $(NPROCS)
	ln -s ./samtools-$(SAMTOOLS_VERSION)/samtools $@

progs/gatk-protected-$(GATK_VERSION): | progs
	curl -L https://github.com/broadgsa/gatk-protected/archive/$(GATK_VERSION).tar.gz | tar -zxf - -C progs

progs/gatk: | progs/gatk-protected-$(GATK_VERSION)
	cd progs/gatk-protected-$(GATK_VERSION) && mvn install
	echo "#!/bin/sh" > $@
	echo 'DIR="$$( cd "$$( dirname "$${BASH_SOURCE[0]}" )" && pwd )"' >> $@
	echo 'exec /usr/bin/java $$JVM_OPTS -jar "$$DIR/gatk-protected-$(GATK_VERSION)/target/GenomeAnalysisTK.jar" "$$@"' >> $@
	chmod +x $@

progs/picard-tools-$(PICARD_VERSION): | progs
	wget https://github.com/broadinstitute/picard/releases/download/$(PICARD_VERSION)/picard-tools-$(PICARD_VERSION).zip -O $@.zip
	unzip -d progs $@.zip
	rm $@.zip

progs/picard: | progs/picard-tools-$(PICARD_VERSION)
	echo "#!/bin/sh" > $@
	echo 'DIR="$$( cd "$$( dirname "$${BASH_SOURCE[0]}" )" && pwd )"' >> $@
	echo 'java $$JVM_OPTS -jar "$$DIR"/picard-tools-$(PICARD_VERSION)/picard.jar "$$@"' >> $@
	chmod +x $@

progs/seqan-seqan-v$(SEQAN_VERSION): | progs
	curl -L https://github.com/seqan/seqan/archive/seqan-v$(SEQAN_VERSION).tar.gz | gunzip - | tar -xf - -C progs

progs/seqan-seqan-v$(SEQAN_VERSION)/build: | progs/seqan-seqan-v$(SEQAN_VERSION)
	mkdir -p progs/seqan-seqan-v$(SEQAN_VERSION)/build
	cmake \
		-DCMAKE_BUILD_TYPE=Release \
		-B$@ \
		-Hprogs/seqan-seqan-v$(SEQAN_VERSION)

progs/mason_variator: | progs/seqan-seqan-v$(SEQAN_VERSION)/build
	cd progs/seqan-seqan-v$(SEQAN_VERSION)/build && make -j $(NPROCS) mason_variator
	cp progs/seqan-seqan-v$(SEQAN_VERSION)/build/bin/mason_variator $@

progs/mason_simulator: | progs/seqan-seqan-v$(SEQAN_VERSION)/build
	cd progs/seqan-seqan-v$(SEQAN_VERSION)/build && make -j $(NPROCS) mason_simulator
	cp progs/seqan-seqan-v$(SEQAN_VERSION)/build/bin/mason_variator $@

progs/wgsim-master: | progs
	curl -L https://github.com/lh3/wgsim/archive/master.tar.gz | tar -zxf - -C progs

progs/wgsim: | progs/wgsim-master
	gcc -g -O2 -Wall -o $@ progs/wgsim-master/wgsim.c -lz -lm

progs/pbsim-$(PBSIM_VERSION): | progs
	curl -L https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/pbsim/pbsim-$(PBSIM_VERSION).tar.gz | tar -zxf - -C progs

progs/pbsim: | progs/pbsim-$(PBSIM_VERSION)
	cd progs/pbsim-$(PBSIM_VERSION) && ./configure
	cd progs/pbsim-$(PBSIM_VERSION) && make -j $(NPROCS)
	ln -s ./pbsim-$(PBSIM_VERSION)/src/pbsim $@

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
$(chr_ref): $(chr) | data
	./src/cut.py $(chr) -e $(cutoff)  > $@

# index reference
$(chr_ref_index_bwa): $(chr_ref) | $(BWA)
	$(BWA) index $<

# GATK needs more indexing
$(chr_ref_index_fai): $(chr_ref) | $(SAMTOOLS)
	$(SAMTOOLS) faidx $<

$(chr_ref_index_dict): $(chr_ref) | $(PICARD)
	$(PICARD) CreateSequenceDictionary REFERENCE=$< OUTPUT=$@

################################################################################
# Step 2 - mutate references into haplotypes
# ------------------------------------------
#
# mutate (SNPs, Indels, SVs) with two haplotypes
################################################################################

$(chr_mut) $(chr_mut_vcf): $(chr_ref) $(chr_ref_index_fai) | $(MASON_VARIATOR)
	$(MASON_VARIATOR) -ir $< -of $(chr_mut) -ov $(chr_mut_vcf) \
		--out-breakpoints data/chr1.mut.tsv --num-haplotypes 2

################################################################################
# Step 3 - simulate reads
# ----------------------
#
# Reads are read from fragments
################################################################################

# simulate paired-end reads
#$(chr_reads) $(chr_reads_h1) $(chr_reads_h2): $(chr_ref) $(chr_mut)
simulate_with_mason: $(chr_ref) $(chr_mut) | $(MASON_SIMULATOR)
	$(MASON_SIMULATOR) -ir $(chr_ref) -iv $(chr_mut_vcf) \
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

#simulate_with_wgsim: $(chr_ref) $(chr_mut)
$(chr_reads) $(chr_reads_h1) $(chr_reads_h2): $(chr_ref) $(chr_mut) | $(WGSIM)
	$(WGSIM) -1 $(read_size) -2 $(read_size) -N $(num_reads) -R 0.0 -e 0.0 -r 0.0 \
		$(chr_mut) $(chr_reads_h1) $(chr_reads_h2) > $(chr_reads)

#$(chr_reads) $(chr_reads_h1) $(chr_reads_h2): $(chr_ref) $(chr_mut)
simulate_with_pbsim: $(chr_ref) $(chr_mut) | $(PBSIM)
	$(PBSIM) --depth 20 $(chr_mut) --model_qc ~/hel/thesis/tools/pbsim-1.0.3/data/model_qc_clr --prefix sd
	rm sd_000{1,2}.ref
	#rm sd_000{1,2}.maf
	mv sd_0001.fastq $(chr_reads_h1)
	mv sd_0002.fastq $(chr_reads_h2)

################################################################################
# Step 4 - Align reads to reference
# ---------------------------------
#
# mem is recommended for longer reads (faster, more accurate)
#
# gatk required us to have read groups and indexed file bam file
################################################################################

# align reads
$(chr_reads_aligned_raw): $(chr_ref) $(chr_reads) $(chr_ref_index_bwa) | $(BWA)
	$(BWA) mem -t $(NPROCS) $(chr_ref) $(chr_reads_h1) $(chr_reads_h2) \
		-R "@RG\tID:$(chr_ref)\tPG:bwa\tSM:$(chr_ref)" > $@

# TODO join

# each threads uses at least 800 MB (-m flag) - dont start too many!
$(chr_reads_aligned_sorted): $(chr_reads_aligned_raw) | $(SAMTOOLS)
	$(SAMTOOLS) sort --threads 4 -o $@ $<
	$(SAMTOOLS) index $@

# reads statistics
$(chr_reads_stats): $(chr_reads_aligned_sorted) | $(SAMTOOLS)
	$(SAMTOOLS) stats $< > $@

# filter read report
$(chr_reads_coverage_tsv): $(chr_reads_stats)
	cat $< | grep '^COV' | cut -f 3- > $@

# read coverage plot
$(chr_reads_coverage_pdf): $(chr_reads_coverage_tsv)
	./src/coverage_stats.py $< -o $@

################################################################################
# Step 5 - Map variant from read to reference
################################################################################

# map variants
$(chr_reads_variants): $(chr_ref) $(chr_reads_aligned_sorted) $(chr_ref_index_dict) $(chr_ref_index_fai) | $(GATK)
	$(GATK) -R $(chr_ref) -T HaplotypeCaller -I $(chr_reads_aligned_sorted) -o $@

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
