MVN=build/mvn-$(MVN_VERSION)/bin/mvn

build/mvn-$(MVN_VERSION): | build
	mkdir -p $@
	curl -L http://mirror.softaculous.com/apache/maven/maven-3/$(MVN_VERSION)/binaries/apache-maven-$(MVN_VERSION)-bin.tar.gz | tar -zxf - -C $@ --strip-components=1

$(MVN): build/mvn-$(MVN_VERSION)
