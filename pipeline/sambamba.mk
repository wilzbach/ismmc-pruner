SAMBAMBA=progs/sambamba

# build from source doesn't work atm
#build/sambamba-$(SAMBAMBA_VERSION): $(LDC) | build
	#git clone --recursive https://github.com/lomereiter/sambamba.git $@

#$(SAMBAMBA): build/sambamba-$(SAMBAMBA_VERSION)
	#(cd $< && git checkout v$(SAMBAMBA_VERSION) && git submodule update && \
	#PATH=$(LDC_BIN_PATH):$$PATH LIBRARY_PATH=$(LDC_LIBRARY_PATH) make sambamba-ldmd2-64)

$(SAMBAMBA): | progs
	curl -L https://github.com/lomereiter/sambamba/releases/download/v$(SAMBAMBA_VERSION)/sambamba_v$(SAMBAMBA_VERSION)_linux.tar.bz2 | \
		bzip2 -d | tar xf - -C $| --transform "s|sambamba_v$(SAMBAMBA_VERSION)|sambamba|"

# binary index for bam files
%.bai: % $(SAMBAMBA)
	$(SAMBAMBA) index $<

%.samsorted.bam: %.ali.sam $(SAMBAMBA)
	$(SAMBAMBA) view -S --format bam -l 0 $< > $@.tmp
	$(SAMBAMBA) sort --nthreads $(NPROCS) -o $@ $@.tmp
	rm $@.tmp
	$(SAMBAMBA) index $@

%.depth: % $(SAMBAMBA)
	$(SAMBAMBA) depth $< > $@
