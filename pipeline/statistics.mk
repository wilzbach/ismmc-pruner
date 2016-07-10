# filter read report
%.coverage.tsv: %.samstats
	cat $< | grep '^COV' | cut -f 3- > $@

# read coverage plot
%.coverage.pdf: %.coverage.tsv src/scripts/coverage_stats.py $(PYTHON) $(MATPLOTLIB)
	$(PYTHON) $(word 2, $^) $< -o $@

%.depth.pdf: %.depth src/scripts/depth_stats.py $(PYTHON) $(MATPLOTLIB) $(SCIPY)
	$(PYTHON) $(word 2, $^) $< -o $@

%.odepth.pdf: %.depth src/scripts/depth_own.py $(PYTHON) $(MATPLOTLIB) $(SCIPY)
	$(PYTHON) $(word 2, $^) $< -o $@

.PHONY: %.statspdf

%.statspdf: %.depth.pdf %.coverage.pdf
	@echo -n ""
