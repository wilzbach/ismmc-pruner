ANT=build/ant-$(ANT_VERSION)/bin/ant

build/ant-$(ANT_VERSION): | build
	mkdir -p $@
	curl -L http://mirror2.shellbot.com/apache//ant/binaries/apache-ant-$(ANT_VERSION)-bin.tar.gz | tar -zxf - -C $@ --strip-components=1

$(ANT): build/ant-$(ANT_VERSION)
