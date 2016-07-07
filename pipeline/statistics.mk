# filter read report
%.coverage.tsv: %.samstats
	cat $< | grep '^COV' | cut -f 3- > $@

# read coverage plot
%.coverage.pdf: %.coverage.tsv $(PYTHON) $(MATPLOTLIB)
	$(PYTHON) ./src/scripts/coverage_stats.py $< -o $@
