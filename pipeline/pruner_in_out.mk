LIBHTS=build/samtools-$(SAMTOOLS_VERSION)/htslib-$(SAMTOOLS_VERSION)/libhts.a

# order of libraries matters
progs/pruner_in: src/bam/in.c | build/samtools-$(SAMTOOLS_VERSION) $(LIBHTS) build/bam progs
	gcc -I$(word 1,$|)/htslib-$(SAMTOOLS_VERSION) -Ibuild \
		-L $(word 1,$|)/htslib-$(SAMTOOLS_VERSION) $< -l:libhts.a -lz -pthread -o $@

progs/pruner_out: src/bam/out.c | build/samtools-$(SAMTOOLS_VERSION) $(LIBHTS) build/bam progs
	gcc -I$(word 1,$|)/htslib-$(SAMTOOLS_VERSION) -Ibuild \
		-L $(word 1,$|)/htslib-$(SAMTOOLS_VERSION) $< -l:libhts.a -lz -pthread -o $@
