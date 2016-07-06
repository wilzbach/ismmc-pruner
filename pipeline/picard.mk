PICARD=progs/picard

# we can't assume that ant is available, hence download the binary for now

build/picard-$(PICARD_VERSION): $(ANT) | build
	mkdir -p $@
	curl -L https://github.com/broadinstitute/picard/archive/$(PICARD_VERSION).tar.gz \
		| tar -zxf - -C $@ --strip-components=1

build/picard-$(PICARD_VERSION)/dist/picard.jar: build/picard-$(PICARD_VERSION) build/htsjdk-$(HTSJDK_VERSION)/build.xml
	sed 's/name="htsjdk-classes" value="htsjdk/name="htsjdk-classes" value="$${htsjdk}/' -i $</build.xml
	$(ANT) -f $< -Dbasedir="$<" -Dhtsjdk=../htsjdk-$(HTSJDK_VERSION)

progs/picard.jar: build/picard-$(PICARD_VERSION)/dist/picard.jar progs
	cp $< $@

progs/picard: | progs/picard.jar
	echo "#!/bin/bash" > $@
	echo 'DIR="$$( cd "$$( dirname "$${BASH_SOURCE[0]}" )" && pwd )"' >> $@
	echo 'java $$JVM_OPTS -jar "$$DIR"/picard.jar "$$@"' >> $@
	chmod +x $@

# same level: foo.fa and foo.dict
%.dict: %.fa | $(PICARD)
	$(PICARD) CreateSequenceDictionary REFERENCE=$< OUTPUT=$@
