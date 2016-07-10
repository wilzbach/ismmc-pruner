# maps data/chr1/ref.fa to perm/chr1.fa

# create reference "genome"
%/ref.fa: perm/$$(*F).fa src/scripts/cut.py | $$(@D)/ $(BIOPYTHON)
	$(PYTHON) src/scripts/cut.py $< -e $(CHR_CUTOFF)  > $@
