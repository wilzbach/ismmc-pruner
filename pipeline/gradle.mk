GRADLE=build/gradle-$(GRADLE_VERSION)/bin/gradle

build/gradle-$(GRADLE_VERSION): | build
	wget https://services.gradle.org/distributions/gradle-$(GRADLE_VERSION)-bin.zip -O build/gradle.tmp.zip
	unzip -d $| build/gradle.tmp.zip
	rm build/gradle.tmp.zip

$(GRADLE): build/gradle-$(GRADLE_VERSION)
