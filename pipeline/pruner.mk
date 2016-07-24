PRUNER_BUILDDIR=build/pruner
PRUNER_TESTDIR=build/pruner_test
DISABLE_LOGGING=-version=StdLoggerDisableLogging

PRUNERFLAGS_IMPORT = $(foreach dir,$(PRUNER_SOURCE_DIR), -I$(dir))
PRUNER_SOURCES = $(call rwildcard,$(PRUNER_SOURCE_DIR)/pruner/,*.d)
PRUNER_OBJECTS = $(patsubst $(PRUNER_SOURCE_DIR)/%.d, $(PRUNER_BUILDDIR)/%.o, $(PRUNER_SOURCES))

build/pruner_test: | build
	mkdir -p $@

# create object files
$(PRUNER_BUILDDIR)/pruner.o : $(PRUNER_SOURCES) | $(DCC)
	$(DCC) -c -debug -g -w -vcolumns $(DISABLE_LOGGING) -of$@ $^

# binary
progs/pruner: $(PRUNER_BUILDDIR)/pruner.o | $(DCC)
	$(DCC) -g -of$@ $^

# create object files for unittest
$(PRUNER_TESTDIR)/bin: $(PRUNER_SOURCES) | $(DCC) $(PRUNER_TESTDIR) debug
	$(DCC) -unittest $^ -of$@ -g -vcolumns

################################################################################
# Faster binary with LDC
################################################################################

LDC_FLAGS=-release -O3 -boundscheck=off

progs/pruner.ldc: $(PRUNER_SOURCES) | $(LDC)
	$(LDC) $(LDC_FLAGS) -d$(DISABLE_LOGGING) -of$@ -od$(PRUNER_BUILDDIR)/ldc/ $^

################################################################################
# Prune reads
# -----------
#
# TODO: Can be combined in one step, once this is working & well tested
#
# I) We transform the BAM filter in a chr,start,stop,id format
# II) We run the pruner - it outputs the pruned ids
# III) We filter the BAM file based on the pruned ids
#  - expects that the ordered ids are sorted
################################################################################

%.pruned.plain: %.samsorted.bam | progs/pruner_in
	$| $< > $@

%.pruned.ids: %.pruned.plain progs/pruner.ldc
	@echo $(MAX_COVERAGE)
	cat $< | $(word 2, $^) --max-coverage $(MAX_COVERAGE) > $@
	#cat $< | $(word 2, $^) -p random -m 2 > $@

%.pruned.filtered.bam: %.samsorted.bam %.pruned.ids | progs/pruner_out
	cat $(word 2, $^) | $| $< $@ > /dev/null
