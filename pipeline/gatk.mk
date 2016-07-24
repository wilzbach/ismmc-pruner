GATK=progs/gatk

build/gatk-protected-$(GATK_VERSION): | build
	curl -L https://github.com/broadgsa/gatk-protected/archive/$(GATK_VERSION).tar.gz | tar -zxf - -C $|

# We need to remove the weird oracle.jrockit import (not available on OpenJDK)
# Moreover the external-example doesn't build with OpenJDK
progs/gatk.jar: build/gatk-protected-$(GATK_VERSION) $(MVN) | progs
	sed 's/^import oracle.jrockit/\/\/import oracle.jrockit/' \
		-i $</public/gatk-tools-public/src/main/java/org/broadinstitute/gatk/tools/walkers/varianteval/VariantEval.java
	sed 's/<module>external-example<\/module>//' -i $</public/pom.xml

	# disable annoying call-home "feature"
	COMMAND="patch -Np1 -i ../../pipeline/gatk_disable_home.patch -d $<"; \
	if [[ ! "$$COMMAND -R --dry-run" ]] ; then \
		"$$COMMAND" ; \
	fi

	$(MVN) -f $< verify -P\!queue
	cp $</target/GenomeAnalysisTK.jar $@

progs/gatk: | progs/gatk.jar
	echo "#!/bin/bash" > $@
	echo 'DIR="$$( cd "$$( dirname "$${BASH_SOURCE[0]}" )" && pwd )"' >> $@
	echo 'exec /usr/bin/java $$JVM_OPTS -jar "$$DIR/gatk.jar" "$$@"' >> $@
	chmod +x $@

# call haplotyper with any reference
%.gvcf: $$(@D)/ref.fa %.samsorted.bam $$(@D)/ref.dict $$(@D)/ref.fa.fai | $(GATK)
	$(GATK) -R $< -T HaplotypeCaller -I $(word 2,$^) -o $@

%.pgvcf: $$(@D)/ref.fa %.pruned.filtered.bam %.pruned.filtered.bam.bai $$(@D)/ref.dict $$(@D)/ref.fa.fai | $(GATK)
	$(GATK) -R $< -T HaplotypeCaller -I $(word 2,$^) -o $@
