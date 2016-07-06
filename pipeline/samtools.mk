SAMTOOLS=progs/samtools

# symlink is needed for include directories
build/samtools-$(SAMTOOLS_VERSION): | build
	curl -L https://github.com/samtools/samtools/releases/download/$(SAMTOOLS_VERSION)\
	/samtools-$(SAMTOOLS_VERSION).tar.bz2 \
	| bzip2 -d | tar xf - -C $|

progs/samtools: build/samtools-$(SAMTOOLS_VERSION) | progs
	cd $< && \
		sed -e 's|#!/usr/bin/env python|#!/usr/bin/env python2|' -i misc/varfilter.py
	cd $< && ./configure
	cd $< && make -j $(NPROCS)
	cp $</samtools $@

# static libhts.a
build/samtools-$(SAMTOOLS_VERSION)/htslib-$(SAMTOOLS_VERSION)/libhts.a: build/samtools-$(SAMTOOLS_VERSION)
	cd $</htslib-$(SAMTOOLS_VERSION) && make -j $(NPROCS) libhts.a

# allow includes without a version number
build/bam: build/samtools-$(SAMTOOLS_VERSION) | build
	ln -s ./samtools-$(SAMTOOLS_VERSION) $|/bam

# sub-level: foo.fa.fai
%.fai: % $(SAMTOOLS)
	$(SAMTOOLS) faidx $<

# sub-level: foo.fa.idx
%.bai: % $(SAMTOOLS)
	$(SAMTOOLS) index $<

# each threads uses at least 800 MB (-m flag) - dont start too many!
%.samsorted.bam: %.ali $(SAMTOOLS)
	$(SAMTOOLS) sort --threads 4 -o $@ $<
	$(SAMTOOLS) index $@

# reads statistics
%.samstats: % $(SAMTOOLS)
	$(SAMTOOLS) stats $< > $@
