################################################################################
# WhatsHap Analysis
################################################################################

%.hp.normal.vcf %.hp.normal.log: %.gvcf %.samsorted.bam | $(WHATSHAP)
	$(WHATSHAP) phase --max-coverage $(READ_COVERAGE) $^ -o $*.hp.normal.vcf 2> $*.hp.normal.log

%.hp.pruned.vcf %.hp.pruned.log: %.gvcf %.pruned.filtered.bam %.pruned.filtered.bam.bai | $(WHATSHAP)
	$(WHATSHAP) phase $< $(word 2,$^) -o $*.hp.pruned.vcf 2>  $*.hp.pruned.log

%.hp.compare: %.hp.normal.log %.hp.pruned.log
	@echo "===normal===="
	@grep "No. of" $<
	@echo "===pruned===="
	@grep "No. of" $(word 2, $^)
