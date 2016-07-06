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
