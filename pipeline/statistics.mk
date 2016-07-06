# filter read report
%.coverage.tsv: %.samstats
	cat $< | grep '^COV' | cut -f 3- > $@

# read coverage plot
%.coverage.pdf: %.coverage.tsv
	./src/coverage_stats.py $< -o $@
