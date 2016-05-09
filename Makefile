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
chr_ref=data/chr1
mut_suffix=.mut

PRUNER_BUILDDIR = build/pruner
PRUNER_SOURCE_DIR=src/graph/source
PRUNER_SOURCES = $(wildcard $(PRUNER_SOURCE_DIR)/pruner/*.d)
PRUNER_OBJECTS = $(patsubst $(PRUNER_SOURCE_DIR)/%.d, $(PRUNER_BUILDDIR)/%.o, $(PRUNER_SOURCES))
PRUNERFLAGS_IMPORT = $(foreach dir,$(PRUNER_SOURCE_DIR), -I$(dir))

chr_mut=$(chr_ref)$(mut_suffix)

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

PYTHON_EXEC=python3
PYTHON=build/python/bin/python3
PIP=build/python/bin/pip3
PYTHON_VERSION:=$(shell python3 --version | cut -f 2 -d ' ' | cut -f 1,2 -d .)
PYTHON_FOLDER=build/python
VIRTUALENV=/usr/bin/virtualenv

# in cause no virtualenv is installed
ifeq ($(wildcard $(VIRTUALENV)),)
	VIRTUALENV=$(HOME)/.local/lib/python$(PYTHON_VERSION)/site-packages/virtualenv.py
endif

$(VIRTUALENV):
	pip install --user --upgrade virtualenv

$(PYTHON_FOLDER): | $(VIRTUALENV) build
	virtualenv -p $(PYTHON_EXEC) build/python

BIOPYTHON=$(PYTHON_FOLDER)/lib/python$(PYTHON_VERSION)/site-packages/Bio

$(BIOPYTHON): | $(PYTHON_FOLDER) $(NUMPY)
	@echo $(BIOPYTHON)
	$(PIP) install --ignore-installed biopython

$(NUMPY): | $(PYTHON_FOLDER)
	$(PIP) install --ignore-installed numpy

$(MATPLOTLIB): | $(PYTHON_FOLDER)
	$(PIP) install --ignore-installed matplotlib

WHATSHAP=$(PYTHON_FOLDER)/bin/whatshap
$(WHATSHAP): | $(PYTHON_FOLDER)
	$(PIP) install --upgrade --ignore-installed whatshap

################################################################################
# Build "build tools"
################################################################################

CMAKE_VERSION=3.5.2

# we need cmake3
ifeq "$$(cmake -version | head -n 1 | cut -f 3 -d ' ' | cut -f 1 -d .)" "3"
CMAKE=cmake
else
CMAKE=build/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM)/bin/cmake
endif

CMAKE=build/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM)/bin/cmake

# cmake version in space
_cmake_version_sp= $(subst ., ,$(CMAKE_VERSION))

PLATFORM:=$(shell uname -m)

build/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM): | build
	curl -L http://www.cmake.org/files/v$(word 1, $(_cmake_version_sp)).$(word 2, $(_cmake_version_sp))/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM).tar.gz | gunzip - | tar -xf - -C $|

$(CMAKE): | build/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM)

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

build/samtools-$(SAMTOOLS_VERSION)/htslib-$(SAMTOOLS_VERSION)/libhts.a: | build/samtools-$(SAMTOOLS_VERSION)
	cd $</htslib-$(SAMTOOLS_VERSION) && make -j $(NPROCS) libhts.a

build/bam: build/samtools-$(SAMTOOLS_VERSION) | build
	ln -s ./samtools-$(SAMTOOLS_VERSION) $|/bam

build/gatk-protected-$(GATK_VERSION): | build
	curl -L https://github.com/broadgsa/gatk-protected/archive/$(GATK_VERSION).tar.gz | tar -zxf - -C $|

progs/gatk.jar: | build/gatk-protected-$(GATK_VERSION) progs
	sed 's/<module>external-example<\/module>//' -i $(word 1,$|)/public/pom.xml
	cd $(word 1,$|) && mvn compile -Dmaven.test.skip=true -P\!queue
	cp $(word 1,$|)/target/GenomeAnalysisTK.jar $@

progs/gatk: | progs/gatk.jar
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
# Step 0) Pattern rules for suffixes
# - Indexes are created on demand
# - intermediate files will be removed on exit
################################################################################

# sub-level: foo.fa.bwt
%.bwt: % | $(BWA)
	$(BWA) index $<

# sub-level: foo.fa.fai
%.fai: % | $(SAMTOOLS)
	$(SAMTOOLS) faidx $<

# sub-level: foo.fa.idx
%.bai: % | $(SAMTOOLS)
	$(SAMTOOLS) index $<

# same level: foo.fa and foo.dict
%.dict: %.fa | $(PICARD)
	$(PICARD) CreateSequenceDictionary REFERENCE=$< OUTPUT=$@

# aligns foo.bar.read1.fq + foo.bar.read2.fq to reference foo.fa
#  - the first dot determines the name of the reference
#  - mem is recommended for longer reads (faster, more accurate)
#  - gatk required us to have read groups and indexed file bam file
#  TODO: $(word 1,$(subst ., ,data/chr1.mut))
%.ali: $(chr_ref).fa.bwt %.read1.fq %.read2.fq | $(SAMTOOLS)
	$(BWA) mem -t $(NPROCS) $(subst .bwt,,$<) $(word 2, $^) $(word 3, $^) \
		-R "@RG\tID:$(chr_ref)\tPG:bwa\tSM:$(chr_ref)" > $@

# each threads uses at least 800 MB (-m flag) - dont start too many!
%.samsorted.bam: %.ali | $(SAMTOOLS)
	$(SAMTOOLS) sort --threads 4 -o $@ $<
	$(SAMTOOLS) index $@

# Map variant from read to reference
# - Sample dot pattern applies
%.gvcf: $(chr_ref).fa.fai $(chr_ref).dict %.samsorted.bam | $(GATK)
	$(GATK) -R $(subst .fai,,$<) -T HaplotypeCaller -I $(word 3,$^) -o $@

# reads statistics
%.samstats: % | $(SAMTOOLS)
	$(SAMTOOLS) stats $< > $@

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
	cat $< | $(word 2, $^) > $@

data/pruning.bam.filtered: $(chr_mut).samsorted.bam data/pruning.bam.ids | progs/pruner_out
	cat $(word 2, $^) | $| $< $@ > /dev/null

################################################################################
# Step 7 - Find haplotypes (pruned, normal)
################################################################################

data/haplotypes.normal.vcf data/haplotypes.normal.log: hp.normal.im
hp.normal.im: $(chr_mut).gvcf $(chr_mut).samsorted.bam | $(WHATSHAP)
	$(PYTHON) $(WHATSHAP) $^ -o data/haplotypes.normal.vcf 2> data/haplotypes.normal.log

data/haplotypes.pruned.vcf data/haplotypes.pruned.log: hp.pruned.im
hp.pruned.im: $(chr_mut).gvcf data/pruning.bam.filtered.bai | $(WHATSHAP)
	$(PYTHON) $(WHATSHAP) $< $(subst .bai,,$(word 2,$^)) -o data/haplotypes.pruned.vcf 2>  data/haplotypes.pruned.log

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
