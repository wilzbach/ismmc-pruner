MASON_VARIATOR=progs/mason_variator

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
build/seqan-seqan-v$(SEQAN_VERSION)/build: build/seqan-seqan-v$(SEQAN_VERSION) | $(CMAKE)
	sed -e 's/find_package (OpenMP)/$(subst $(newline),\n,${SEQAN_PATCH})/' -i $</apps/mason2/CMakeLists.txt
	mkdir -p $</build
	CMAKE_EXE_LINKER_FLAGS="-static" $(CMAKE) \
		-DCMAKE_BUILD_TYPE=Release \
		-DSEQAN_NO_NATIVE=1 \
		-static \
		-B$@ \
		-H$<

progs/mason_variator: build/seqan-seqan-v$(SEQAN_VERSION)/build | progs
	cd $< && make -j $(NPROCS) mason_variator
	cp $</bin/mason_variator $@

progs/mason_simulator: | build/seqan-seqan-v$(SEQAN_VERSION)/build | progs
	cd $< && make -j $(NPROCS) mason_simulator
	cp $</bin/mason_simulator $@

################################################################################
# Mutate references into haplotypes
# ---------------------------------
#
# mutate (SNPs, Indels, SVs)
################################################################################

%/mut.fa: $$*/ref.fa $$*/ref.fa.fai | $(MASON_VARIATOR)
	$(MASON_VARIATOR) -ir $< -of $@ -ov $(*D).mut.vcf \
		--out-breakpoints $@.tsv --num-haplotypes 2
