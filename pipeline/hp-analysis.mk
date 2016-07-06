################################################################################
# WhatsHap Analysis
################################################################################

%.hp.normal.vcf %.hp.normal.log: %.gvcf %.samsorted.bam | $(WHATSHAP)
	$(WHATSHAP) phase $^ -o $*.hp.normal.vcf 2> $*.hp.normal.log

%.hp.pruned.vcf %.hp.pruned.log: %.gvcf %.pruned.bam.filtered.bam %.pruned.bam.filtered.bam.bai | $(WHATSHAP)
	$(WHATSHAP) phase $< $(word 2,$^) -o $@ 2>  $*.hp.pruned.log

%.hp.compare: %.hp.normal.log %.hp.pruned.log
	@echo "===normal===="
	@grep "No. of" $<
	@echo "===pruned===="
	@grep "No. of" $(word 2, $^)
