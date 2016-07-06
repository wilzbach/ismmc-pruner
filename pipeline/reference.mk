# maps data/chr1/ref.fa to perm/chr1.fa

# create reference "genome"
%/ref.fa: perm/$$(*F).fa | $$(@D) $(BIOPYTHON)
	$(PYTHON) src/cut.py $< -e $(cutoff)  > $@
