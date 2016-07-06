# newer versions use gradle
build/htsjdk-$(HTSJDK_VERSION): | build
	mkdir -p $@
	curl -L https://github.com/samtools/htsjdk/archive/$(HTSJDK_VERSION).tar.gz \
		| tar -zxf - -C $@ --strip-components=1

build/htsjdk-$(HTSJDK_VERSION)/build.xml: build/htsjdk-$(HTSJDK_VERSION)

build/htsjdk-$(HTSJDK_VERSION)/dist/htsjdk-$(HTSJDK_VERSION).jar: build/htsjdk-$(HTSJDK_VERSION) $(ANT)
	$(ANT) -f $< -Dbasedir="$<"
