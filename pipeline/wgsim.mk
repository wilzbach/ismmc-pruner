WGSIM=progs/wgsim

build/wgsim-$(WGSIM_VERSION): | build
	curl -L https://github.com/lh3/wgsim/archive/$(WGSIM_VERSION).tar.gz | tar -zxf - -C $|

progs/wgsim: build/wgsim-$(WGSIM_VERSION)
	gcc -g -O2 -Wall -o $@ $</wgsim.c -lz -lm

# simulate reads
# reads are sampled in pairs thus we need to divide by 2
%.simread1.fq : %.fa src/scripts/count.py | $(WGSIM) $(BIOPYTHON) $(PYTHON)
	chrLength=$$($(PYTHON) src/scripts/count.py -e $(CHR_CUTOFF) $< ); \
	echo $$chrLength; \
	numReads=$$(python -c "print(int($$chrLength * $(READ_COVERAGE) / $(READ_SIZE) / 2))"); \
	echo $$numReads; \
	$(WGSIM) -S 42 -1 $(READ_SIZE) -2 $(READ_SIZE) -N $$numReads -R 0.0 -e 0.0 -r 0.0 -d 500 \
		$< $@ $(subst 1.fq,2.fq,$@)

%.simread2.fq: %.simread1.fq
	@echo -n ""
