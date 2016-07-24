SHELL=pipeline/time.sh

################################################################################
# Dynamic variables
################################################################################

CHR_CUTOFF=5000000 # use -1 for entire chromosome
READ_SIZE=50000
READ_COVERAGE=30
SNP_RATE=0.01

FOLDERS=build data debug perm progs

################################################################################
# Build tools (as binaries)
################################################################################

include pipeline/platform.mk

DMD_VERSION=2.071.0
DCC=/usr/bin/dmd
include pipeline/dmd.mk

LDC_VERSION=1.0.0
include pipeline/ldc.mk

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
# Python (from source)
################################################################################

PYTHON_VERSION=3.5.2
BIOPYTHON_VERSION=1.67
NUMPY_VERSION=1.11.1
MATPLOTLIB_VERSION=1.5.1
SCIPY_VERSION=0.17.1

include pipeline/python.mk

################################################################################
# Progams (from source)
# --------------------
#
# Having portable, versioned and modifiable progs is nice
#
# - avoid breakage (fixed versions)
# - independent from host system (nice for clusters with old distributions)
# - compile once, run everywhere (static linking is used wherever possible)
# - compile from source code and thus allow easy modification & patching
# - sometimes binaries aren't even publicly available (e.g. GATK)
################################################################################

.SECONDEXPANSION:

BWA_VERSION=0.7.13
include pipeline/bwa.mk

SAMTOOLS_VERSION=1.3
include pipeline/samtools.mk

SAMBAMBA_VERSION=0.6.3
include pipeline/sambamba.mk

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

WHATSHAP_VERSION=0.12
include pipeline/whatshap.mk

################################################################################
# Pipeline: build dependencies
################################################################################

PRUNER_SOURCE_DIR=src/graph

include pipeline/pruner_in_out.mk
include pipeline/rwildcard.mk
include pipeline/pruner.mk

################################################################################
# Pipeline: analysis
################################################################################

include pipeline/reference.mk
include pipeline/statistics.mk
include pipeline/hp-analysis.mk

################################################################################
# Pipeline: data
################################################################################

perm/grch38_%.fa: | perm
	curl "ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA_000001405.22_GRCh38.p7/GCA_000001405.22_GRCh38.p7_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/$*.fna.gz" | \
		gunzip > $@

CHROMOSOMES=$(addprefix data/, $(addprefix grch38_,chr1 chr2 chr3))

include pipeline/folders.mk

################################################################################
# Global targets
################################################################################

# run the entire pipeline
all: $(addsuffix /mut.hp.compare, $(CHROMOSOMES))

test: $(PRUNER_TESTDIR)/bin
	$<

################################################################################
# Development settings
################################################################################

# Save intermediate files during development (remove for production)
.SECONDARY:

# disable builtin rules
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
