################################################################################
# Compiler variables
################################################################################

SHELL=/bin/bash
DCFLAGS = -w
DCC=/usr/bin/dmd

################################################################################
# Dynamic variables
################################################################################

chromosomeURL="ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA_000001405.15_GRCh38/GCA_000001405.15_GRCh38_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/chr1.fna.gz"

cutoff=1000000
#cutoff=248956422
read_size=5000
#TODO: update
# bash only supports integers
# TODO increase to 30
num_reads=$$(( $(cutoff) * 15 / $(read_size)))

################################################################################
# File variables
################################################################################

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

PRUNER_BUILDDIR = build/pruner
PRUNER_SOURCE_DIR=src/graph/source
PRUNER_SOURCES = $(wildcard $(PRUNER_SOURCE_DIR)/pruner/*.d)
PRUNER_OBJECTS = $(patsubst $(PRUNER_SOURCE_DIR)/%.d, $(PRUNER_BUILDDIR)/%.o, $(PRUNER_SOURCES))
PRUNERFLAGS_IMPORT = $(foreach dir,$(PRUNER_SOURCE_DIR), -I$(dir))

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

build:
	mkdir -p $@
perm:
	mkdir -p $@
data:
	mkdir -p $@
progs:
	mkdir -p $@

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

PICARD=progs/picard
PICARD_VERSION=2.2.2

MASON_VARIATOR=progs/mason_variator
SEQAN_VERSION=2.1.1

CMAKE_VERSION=3.5.2

# we need cmake3
ifeq "$$(cmake -version | head -n 1 | cut -f 3 -d ' ' | cut -f 1 -d .)" "3"
CMAKE=cmake
else
CMAKE=build/cmake-$(CMAKE_VERSION)/bin/cmake
endif

WGSIM=progs/wgsim

PBSIM=progs/pbsim
PBSIM_VERSION=1.0.3

DMD_VERSION=2.071.0

ifeq ($(wildcard $(DCC)),)
	DCC=build/dmd2/linux/bin64/dmd
endif

build/dmd2: | build
	curl -fSL --retry 3 "http://downloads.dlang.org/releases/2.x/$(DMD_VERSION)/dmd.$(DMD_VERSION).linux.tar.xz" | tar -Jxf - -C $|

build/dmd2/linux/bin64/dmd: build/dmd2

################################################################################
# Python stuff
################################################################################

PYTHON=python3
PIP=pip
PYTHON_VERSION:=$(python3 --version | cut -f 2 -d ' ' | cut -f 1,2 -d .)
PYTHON_FOLDER=build/python
#export PYTHONPATH

$(PYTHON_FOLDER): | build
	mkdir -p $@

BIOPYTHON=$(PYTHON_FOLDER)/Bio
$(BIOPYTHON): | $(PYTHON_FOLDER)
	$(PIP) install --ignore-installed --target="$|" biopython

WHATSHAP=$(PYTHON_FOLDER)/whatshap
$(WHATSHAP): | $(PYTHON_FOLDER)
	$(PIP) install --ignore-installed --target="$|" whatshap

# cmake version in space
_cmake_version_sp= $(subst ., ,$(CMAKE_VERSION))

build/cmake-$(CMAKE_VERSION): | build
	curl -L http://www.cmake.org/files/v$(word 1, $(_cmake_version_sp)).$(word 2, $(_cmake_version_sp))/cmake-$(CMAKE_VERSION).tar.gz | gunzip - | tar -xf - -C $|

################################################################################
# Build "build tools"
################################################################################

$(CMAKE): | build/cmake-$(CMAKE_VERSION)
	cd $| && ./configure && make -j $(NPROCS)

################################################################################
# Bio tools
################################################################################

build/bwa-$(BWA_VERSION): | build
	curl -L http://downloads.sourceforge.net/project/bio-bwa/bwa-$(BWA_VERSION).tar.bz2 \
	| bzip2 -d | tar xf - -C $|

progs/bwa: | build/bwa-$(BWA_VERSION) progs
	cd $(word 1,$|) && make -j $(NPROCS)
	cp $(word 1,$|)/bwa $@

# symlink is needed for include directories
build/samtools-$(SAMTOOLS_VERSION): | build
	curl -L https://github.com/samtools/samtools/releases/download/$(SAMTOOLS_VERSION)\
	/samtools-$(SAMTOOLS_VERSION).tar.bz2 \
	| bzip2 -d | tar xf - -C $|

progs/samtools: | build/samtools-$(SAMTOOLS_VERSION) progs
	cd $(word 1,$|) && \
		sed -e 's|#!/usr/bin/env python|#!/usr/bin/env python2|' -i misc/varfilter.py
	cd $(word 1,$|) && ./configure
	cd $(word 1,$|) && make -j $(NPROCS)
	cp $(word 1, $|)/samtools $@

build/samtools-$(SAMTOOLS_VERSION)/htslib-$(SAMTOOLS_VERSION)/libhts.a: build/samtools-$(SAMTOOLS_VERSION)
	cd $</htslib-$(SAMTOOLS_VERSION) && make -j $(NPROCS) libhts.a

build/bam: build/samtools-$(SAMTOOLS_VERSION) | build
	ln -s ./samtools-$(SAMTOOLS_VERSION) $|/bam

build/gatk-protected-$(GATK_VERSION): | build
	curl -L https://github.com/broadgsa/gatk-protected/archive/$(GATK_VERSION).tar.gz | tar -zxf - -C $|

progs/gatk.jar: | build/gatk-protected-$(GATK_VERSION) progs
	sed 's/<module>external-example<\/module>//' -i $(word 1,$|)/public/pom.xml
	cd $(word 1,$|) && mvn install -Dmaven.test.skip=true -P\!queue
	cp $(word 1,$|)/target/GenomeAnalysisTK.jar $@

progs/gatk: progs/gatk.jar | build/gatk-protected-$(GATK_VERSION)
	echo "#!/bin/bash" > $@
	echo 'DIR="$$( cd "$$( dirname "$${BASH_SOURCE[0]}" )" && pwd )"' >> $@
	echo 'exec /usr/bin/java $$JVM_OPTS -jar "$$DIR/gatk.jar" "$$@"' >> $@
	chmod +x $@

build/picard-tools-$(PICARD_VERSION): | build
	wget https://github.com/broadinstitute/picard/releases/download/$(PICARD_VERSION)/picard-tools-$(PICARD_VERSION).zip -O $@.zip
	unzip -d $| $@.zip
	rm $@.zip

progs/picard.jar: | build/picard-tools-$(PICARD_VERSION) progs
	cp $(word 1,$|)/picard.jar $@

progs/picard: progs/picard.jar | build/picard-tools-$(PICARD_VERSION)
	echo "#!/bin/bash" > $@
	echo 'DIR="$$( cd "$$( dirname "$${BASH_SOURCE[0]}" )" && pwd )"' >> $@
	echo 'java $$JVM_OPTS -jar "$$DIR"/picard.jar "$$@"' >> $@
	chmod +x $@

build/seqan-seqan-v$(SEQAN_VERSION): | build
	curl -L https://github.com/seqan/seqan/archive/seqan-v$(SEQAN_VERSION).tar.gz | gunzip - | tar -xf - -C $|

# workaround to have multiline strings in a makefile
define newline


endef

define SEQAN_PATCH
SET(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
SET(BUILD_SHARED_LIBRARIES OFF)
SET(CMAKE_EXE_LINKER_FLAGS "-static")
endef

# Note: we make static build to increase portability
build/seqan-seqan-v$(SEQAN_VERSION)/build: | build/seqan-seqan-v$(SEQAN_VERSION) $(CMAKE)
	sed -e 's/find_package (OpenMP)/$(subst $(newline),\n,${SEQAN_PATCH})/' -i $(word 1, $|)/apps/mason2/CMakeLists.txt
	mkdir -p $(word 1,$|)/build
	CMAKE_EXE_LINKER_FLAGS="-static" $(CMAKE) \
		-DCMAKE_BUILD_TYPE=Release \
		-DSEQAN_NO_NATIVE=1 \
		-static \
		-B$@ \
		-H$(word 1,$|)

progs/mason_variator: | build/seqan-seqan-v$(SEQAN_VERSION)/build progs
	cd $(word 1,$|) && make -j $(NPROCS) mason_variator
	cp $(word 1,$|)/bin/mason_variator $@

progs/mason_simulator: | build/seqan-seqan-v$(SEQAN_VERSION)/build progs
	cd $(word 1,$|) && make -j $(NPROCS) mason_simulator
	cp $(word 1,$|)/bin/mason_simulator $@

build/wgsim-master: | build
	curl -L https://github.com/lh3/wgsim/archive/master.tar.gz | tar -zxf - -C $|

progs/wgsim: | build/wgsim-master
	gcc -g -O2 -Wall -o $@ build/wgsim-master/wgsim.c -lz -lm

build/pbsim-$(PBSIM_VERSION): | build
	curl -L https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/pbsim/pbsim-$(PBSIM_VERSION).tar.gz | tar -zxf - -C $|

progs/pbsim: | build/pbsim-$(PBSIM_VERSION)
	cd $| && ./configure
	cd $| && make -j $(NPROCS)
	cp ./pbsim-$(PBSIM_VERSION)/src/pbsim $@

# order matters
progs/pruner_in: src/bam/in.c | build/samtools-$(SAMTOOLS_VERSION) build/samtools-$(SAMTOOLS_VERSION)/htslib-$(SAMTOOLS_VERSION)/libhts.a build/bam progs
	gcc -I$(word 1,$|)/htslib-$(SAMTOOLS_VERSION) -Ibuild \
		-L $(word 1,$|)/htslib-$(SAMTOOLS_VERSION) $< -l:libhts.a -lz -pthread -o $@

progs/pruner_out: src/bam/out.c | build/samtools-$(SAMTOOLS_VERSION) build/samtools-$(SAMTOOLS_VERSION)/htslib-$(SAMTOOLS_VERSION)/libhts.a build/bam progs
	gcc -I$(word 1,$|)/htslib-$(SAMTOOLS_VERSION) -Ibuild \
		-L $(word 1,$|)/htslib-$(SAMTOOLS_VERSION) $< -l:libhts.a -lz -pthread -o $@

# create object files
$(PRUNER_BUILDDIR)/%.o : $(PRUNER_SOURCE_DIR)/%.d | $(DCC)
	$(DCC) $(DCFLAGS) $(DCFLAGS_LINK) $(PRUNERFLAGS_IMPORT) -c $< -of$@

progs/pruner: $(PRUNER_OBJECTS) | $(DCC)
	$(DCC) $^ -of$@

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
$(chr_ref): $(chr) | data $(BIOPYTHON)
	PYTHONPATH="$$(pwd)/build/python:$$PYTHONPATH" $(PYTHON) src/cut.py $(chr) -e $(cutoff)  > $@

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
# TODO: Can be combined in one step, once this is working & well tested
#
# I) We transform the BAM filter in a chr,start,stop,id format
# II) We run the pruner - it outputs the pruned ids
# III) We filter the BAM file based on the pruned ids
#
# III) expects that the ordered ids are sorted
################################################################################

data/pruning.bam.plain: $(chr_reads_aligned_sorted) | progs/pruner_in
	$| $< > $@

data/pruning.bam.ids: data/pruning.bam.plain progs/pruner
	cat $< | $(word 2, $^) > $@

data/pruning.bam.filtered: $(chr_reads_aligned_sorted) data/pruning.bam.ids | progs/pruner_out
	cat $(word 2, $^) | $| $< $@ > /dev/null

################################################################################
# Step 7 - Find haplotypes (pruned, normal)
################################################################################

data/haplotypes.normal.vcf data/haplotypes.normal.log: hp.normal.im
.INTERMEDIATE: hp.normal.im
hp.normal.im: $(chr_reads_variants) $(chr_reads_aligned_sorted) | $(WHATSHAP)
	whatshap $^ -o data/haplotypes.normal.vcf 2> data/haplotypes.normal.log

data/haplotypes.pruned.vcf data/haplotypes.pruned.log: hp.pruned.im
.INTERMEDIATE: hp.pruned.im
hp.pruned.im: $(chr_reads_variants) data/pruning.bam.filtered | $(WHATSHAP)
	whatshap $^ -o data/haplotypes.pruned.vcf 2>  data/haplotypes.pruned.log

data/haplotypes.pruned.log:

################################################################################
# Step 8 - Analysis
################################################################################

data/haplotypes.compare: data/haplotypes.normal.log data/haplotypes.pruned.log
	@echo "===normal===="
	@grep "No. of" $<
	@echo "===pruned===="
	@grep "No. of" $(word 2, $^)


# normal pipeline + coverage plots
all: $(chr_reads_coverage_pdf) $(chr_reads_variants)
