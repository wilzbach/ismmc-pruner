BWA=progs/bwa

build/bwa-$(BWA_VERSION): | build
	curl -L http://downloads.sourceforge.net/project/bio-bwa/bwa-$(BWA_VERSION).tar.bz2 \
	| bzip2 -d | tar xf - -C $|

progs/bwa: build/bwa-$(BWA_VERSION) | progs
	cd $< && make -j $(NPROCS)
	cp $</bwa $@

# sub-level: foo.fa.bwt
%.bwt: % $(BWA)
	$(BWA) index $<

# aligns data/chr/mut.simread1.fq + data/chr/mut.simread2.fq to reference data/chr/ref.fa
#  - mem is recommended for longer reads (faster, more accurate)
%.ali: $$(@D)/ref.fa %.simread1.fq %.simread2.fq $$(@D)/ref.fa.bwt | $(SAMTOOLS)
	$(BWA) mem -t $(NPROCS) $< $(word 2, $^) $(word 3, $^) \
		-R "@RG\tID:$(@D)\tPG:bwa\tSM:$(@D)" > $@
