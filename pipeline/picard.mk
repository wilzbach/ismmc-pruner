PICARD=progs/picard

# we can't assume that ant is available, hence download the binary for now

build/picard-$(PICARD_VERSION): $(ANT) | build
	mkdir -p $@
	curl -L https://github.com/broadinstitute/picard/archive/$(PICARD_VERSION).tar.gz \
		| tar -zxf - -C $@ --strip-components=1

build/picard-$(PICARD_VERSION)/picard.jar: build/picard-$(PICARD_VERSION)
	$(ANT) -f $< -Dbasedir="$<" clone-htsjdk
	$(ANT) -f $< -Dbasedir="$<"

progs/picard.jar: build/picard-$(PICARD_VERSION)/picard.jar progs
	cp $</picard.jar $@

progs/picard: | progs/picard.jar
	echo "#!/bin/bash" > $@
	echo 'DIR="$$( cd "$$( dirname "$${BASH_SOURCE[0]}" )" && pwd )"' >> $@
	echo 'java $$JVM_OPTS -jar "$$DIR"/picard.jar "$$@"' >> $@
	chmod +x $@

# same level: foo.fa and foo.dict
%.dict: %.fa | $(PICARD)
	$(PICARD) CreateSequenceDictionary REFERENCE=$< OUTPUT=$@
