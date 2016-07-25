#!/bin/bash

#PREFIX="data/cov_30_50_000_500K/grch38_chr1"
#PREFIX="data/cov_30_50_000_5M/grch38_chr1"
PREFIX="data/cov_30_50_000_50M/grch38_chr1"

# Gotchas
# - tOpt = 2
# - ISMMC with k = 1 would prune everything

echo "coverage,time_ismmc,num_reads,time_whatshap,nr_variants,mec_score,nr_phased_blocks"
for x in $(seq 7 5 31) ; do
	export MAX_COVERAGE="$x";
	echo -n "${x},"

	rm -f ${PREFIX}/mut.pruned.ids
	TIME_ISSMC=$(make ${PREFIX}/mut.pruned.ids 2>&1 | grep real | tail -n 1 | cut -f2)
	echo -n "${TIME_ISSMC},"

	NUMBER_OF_READS=$(wc -l ${PREFIX}/mut.pruned.plain | cut -f1 -d' ')
	NUMBER_OF_PRUNED_READS=$(wc -l ${PREFIX}/mut.pruned.ids | cut -f1 -d' ')
	echo -n "$((${NUMBER_OF_READS} - ${NUMBER_OF_PRUNED_READS})),"

	rm -f ${PREFIX}/mut.pruned.filtered.bam
	rm -f ${PREFIX}/mut.hp.pruned.vcf
	TIME_WHATSHAP=$(make ${PREFIX}/mut.hp.pruned.vcf 2>&1 | grep real | tail -n 1 | cut -f2)
	echo -n "${TIME_WHATSHAP},"

	NR_PHASED_VARIANTS=$(cat ${PREFIX}/mut.hp.pruned.log | grep "No. of variants that were phased:" | cut -f 2 -d':' | tr -d ' ')
	echo -n "${NR_PHASED_VARIANTS},"

	MEC_SCORE=$(cat ${PREFIX}/mut.hp.pruned.log | grep "MEC score of phasing:" | cut -f 2 -d':' | tr -d ' ')
	echo -n "${MEC_SCORE},"

	NR_PHASED_BLOCKS=$(cat ${PREFIX}/mut.hp.pruned.log | grep "No. of phased blocks:" | cut -f 2 -d':' | tr -d ' ')
	echo "${NR_PHASED_BLOCKS},"

	mkdir -p tmp
	cat ${PREFIX}/mut.hp.pruned.vcf > tmp/5m_${x}.vcf
done

# print reference
echo -n "-1,0m0.0,"
NUMBER_OF_READS=$(wc -l ${PREFIX}/mut.pruned.plain | cut -f1 -d' ')
echo -n "${NUMBER_OF_READS},"
rm -f ${PREFIX}/mut.hp.normal.vcf
TIME_WHATSHAP=$(make ${PREFIX}/mut.hp.normal.vcf 2>&1 | grep real | tail -n 1 | cut -f2)
echo -n "${TIME_WHATSHAP},"
NR_PHASED_VARIANTS=$(cat ${PREFIX}/mut.hp.normal.log | grep "No. of variants that were phased:" | cut -f 2 -d':' | tr -d ' ')
echo "${NR_PHASED_VARIANTS}"

whatshap compare ${PREFIX}/mut.hp.pruned.vcf ${PREFIX}/mut.hp.normal.vcf
