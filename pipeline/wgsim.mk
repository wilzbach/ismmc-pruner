WGSIM=progs/wgsim

build/wgsim-$(WGSIM_VERSION): | build
	curl -L https://github.com/lh3/wgsim/archive/$(WGSIM_VERSION).tar.gz | tar -zxf - -C $|

progs/wgsim: build/wgsim-$(WGSIM_VERSION)
	gcc -g -O2 -Wall -o $@ $</wgsim.c -lz -lm

# simulate reads
%.simread1.fq : %.fa %.fa.fai | $(WGSIM) $(PYTHON)
	chrLength=$$(head -n1 $(word 2, $^) | cut -f2 ); \
	numReads=$$(python -c "print($$chrLength * $(READ_COVERAGE) / $(READ_SIZE))"); \
	echo $$numReads; \
	$(WGSIM) -1 $(READ_SIZE) -2 $(READ_SIZE) -N $$numReads -R 0.0 -e 0.0 -r 0.0 \
		$< $@ $(subst 1.fq,2.fq,$@)

%.simread2.fq: %.simread1.fq
	@echo -n ""
