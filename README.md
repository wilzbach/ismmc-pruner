[![Circle CI](https://circleci.com/gh/wilzbach/read-prunner.svg?style=svg)](https://circleci.com/gh/wilzbach/read-prunner)

* curl
* gzip

Requirements
------------

* bwa
* GATK
* picard
* samtools
* ...

On Arch Linux this can be conveniently installed using

```
pacaur -S bwa gatk-git picard-tools samtools
```

Steps
-----


Variations in chr1
------------------

248m nts

snps:                45974
small indels:        237
structural variants: 90

BWA runtime: 53 min


GATK

23034



Small (1m)
---------

178 SNPs -> found 78

Runtimes
---------

bamtools: 38.35s 
pySam: 60.76s

small

bamtools: 0.23
seqan: 2.4s


TODO
----

HCMappingQualityFilter -> failing reads (2%)

Other
-----

- [BAM Reader performance test](https://github.com/wilzbach/bam-perf-test)
