################################################################################
# WhatsHap Analysis
################################################################################
%.hp.normal.vcf %.hp.normal.log: %.gvcf %.samsorted.bam $$(@D)/ref.fa $$(@D)/ref.fa.fai | $(WHATSHAP)
	$(WHATSHAP) phase --reference $(word 3, $^) --max-coverage $(READ_COVERAGE) $< $(word 2,$^) -o $*.hp.normal.vcf 2> $*.hp.normal.log

%.hp.pruned.vcf %.hp.pruned.log: %.gvcf %.pruned.filtered.bam %.pruned.filtered.bam.bai $$(@D)/ref.fa $$(@D)/ref.fa.fai | $(WHATSHAP)
	$(WHATSHAP) phase --reference $(word 4, $^) --max-coverage $(READ_COVERAGE) $< $(word 2,$^) -o $*.hp.pruned.vcf 2>  $*.hp.pruned.log

%.hp.compare: %.hp.normal.log %.hp.pruned.log
	@echo "===normal===="
	@grep "No. of" $<
	@echo "===pruned===="
	@grep "No. of" $(word 2, $^)

################################################################################
# Pruned WhatsHap Analysis
################################################################################

%.gt.compare: %.pgvcf %.gvcf
