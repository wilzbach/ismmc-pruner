SHELL=/bin/bash
################################################################################
# A simple & flexible bioinformatics pipeline
# ==========================================
#
# Ideas
# -----
#
# - automatic dependency injection with Makefile rules, e.g. the dependency
#   BWA is only downloaded & compiled if needed
# - fully automated installation of required tools from their source
# - if possible, wildcard patterns instead of rules (e.g. <file>.bwt runs bwt)
# - make will generate a dependency chain for our data and regenerate outdated files
# - be able to run the newest, latest software on any machine
# - use versioning for all dependencies to all reproducibility
# - use make -j8 (will automatically parallelize wherever possible)
#
# Building from source
# --------------------
#
# - we must be able to run the newest software on old clusters, hence everything
#   needs to be built from scratch
# - some software licenses don't allow binary releases (GATK)
# - we need to be able to inspect & modify the source code
# - we want to _understand_ every bit of out pipeline
# - if something doesn't build, it's outdated anyhows
#
# Dependencies
# ------------
#
# Dependencies are automatically generated, e.g.
#
# - bwa -> bwt files
# - mason_variator needs fai
# - GATK needs fai and dict

# Directory structure:
# -------------------
#
# - build: all required build tools and source code of required programs
# - data: all experimental results
# - debug: temporary folder that is used to print some debug information for tests
# - perm: permanent data that shouldn't be deleted
# - progs: all required executables of the pipeline
# - src: this pipeline's source code
#
# Popular make targets:
# --------------------
#
# - all: runs the entire pipeline
# - test: runs D unittests
#
# Pick out any intermediate file in the pipeline and run `make <file>` to generate
# it
#
# Notes:
# ------
#
# - due to limitations in the Makefile the working directory must be the directory
#   of this Makefile
# - the folder names are coded statically on purpose
################################################################################

################################################################################
# Dynamic variables
################################################################################

#cutoff=248956422
cutoff=1000000
read_size=5000
#TODO: update
# bash only supports integers
# TODO increase to 30
num_reads=$$(( $(cutoff) * 15 / $(read_size)))

FOLDERS=build data debug perm progs

################################################################################
# Build tools
# -----------
#
# We don't want to fiddle with them, download as binaries
################################################################################

include pipeline/platform.mk

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
# ------
#
# We need Python sources to be able to build binary extensions
################################################################################

PYTHON_VERSION=3.5.2
BIOPYTHON_VERSION=1.67
NUMPY_VERSION=1.11.1
MATPLOTLIB_VERSION=1.5.1

include pipeline/python.mk

################################################################################
# PROGS
# -----
#
# Because having portable, versioned and modifiable progs is nice
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
# Pipeline build dependencies
################################################################################

PRUNER_SOURCE_DIR=src/graph

include pipeline/pruner_in_out.mk
include pipeline/rwildcard.mk
include pipeline/pruner.mk

################################################################################
# Pipeline analysis
################################################################################

include pipeline/reference.mk
include pipeline/statistics.mk
include pipeline/hp-analysis.mk

################################################################################
# Setup data
################################################################################

perm/chr1.fa: | perm
	curl "ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA_000001405.22_GRCh38.p7/GCA_000001405.22_GRCh38.p7_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/chr1.fna.gz" | \
		gunzip > $@

perm/chr2.fa: | perm
	curl "ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA_000001405.22_GRCh38.p7/GCA_000001405.22_GRCh38.p7_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/chr2.fna.gz" | \
		gunzip > $@

CHROMOSOMES=chr1 chr2
CHROMOSOMES_DIRS=$(addprefix data/,$(CHROMOSOMES))

FOLDERS += $(CHROMOSOMES_DIRS)
include pipeline/folders.mk

################################################################################
# Global targets
################################################################################

# run the entire pipeline
all: $(addsuffix /mut.hp.compare, $(CHROMOSOMES_DIRS))

test: $(PRUNER_TESTDIR)/bin
	$<

################################################################################
# Save intermediate files during development
#%.simread1.fq %.simread2.fq %.bwt %.fai %.fa %.samsorted.bam %.gvcf %.dict %.ali %.log %.bai %.plain %.ids
################################################################################

.SECONDARY:
