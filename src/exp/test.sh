#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BAM="/../../data_all/chr1.reads.ali.sorted.bam"

mkdir -p "$DIR"/build

(
cd "$DIR"/build
cmake ..
make
)

#for f in hts bamtools seqan ; do
	#echo "testing $f"
	#time "$DIR/build/$f/prun_$f" ${DIR}${BAM} "foo"
#done

time "$DIR/pysam" ${DIR}${BAM} "foo"
