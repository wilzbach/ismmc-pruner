# filter read report
%.coverage.tsv: %.samstats
	cat $< | grep '^COV' | cut -f 3- > $@

# read coverage plot
%.coverage.pdf: %.coverage.tsv $(PYTHON) $(MATPLOTLIB)
	$(PYTHON) ./src/scripts/coverage_stats.py $< -o $@

%.depth.pdf: %.depth $(PYTHON) $(MATPLOTLIB)
	$(PYTHON) ./src/scripts/depth_stats.py $< -o $@

.PHONY: %.statspdf

%.statspdf: %.depth.pdf %.coverage.pdf
	@echo -n ""
