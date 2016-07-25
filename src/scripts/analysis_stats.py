#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pandas as pd
import matplotlib.pyplot as plt
import argparse
import sys

parser = argparse.ArgumentParser(description="Plot depth")
parser.add_argument('inFile', nargs=1, type=argparse.FileType('r'), help='Input file')
parser.add_argument('-o', '--outFile', dest='outFile',
                    default=sys.stdout, help='Output file (default: stdout)')
args = parser.parse_args()

#coverage,time_ismmc,num_reads,time_whatshap,nr_variants
m = pd.read_csv(args.inFile[0])

for t in ['time_ismmc', 'time_whatshap']:
    for i, el in enumerate(m[t]):
        time = el.split('m')
        m.ix[i, t] = int(time[0]) * 60 + float(time[1][0:len(time[1]) - 1])

# remove last rows
mr = m[m['coverage'] > 0]
mlast = m[m['coverage'] < 0]

plt.plot(mr['coverage'], mr['time_whatshap'])
# plt.plot(mr['coverage'].max(), mlast['time_whatshap'], color='red', marker='o')
plt.xlabel('Coverage')
plt.ylabel('WhatsHap runtime in s')
plt.savefig(args.outFile + ".runtime.pdf", bbox_inches='tight', format="pdf")
plt.close()

plt.plot(mr['coverage'], mr['num_reads'])
plt.plot(mr['coverage'].max(), mlast['num_reads'], color='red', marker='o')
plt.xlabel('Coverage')
plt.ylabel('Num of reads')
plt.savefig(args.outFile + ".reads.pdf", bbox_inches='tight', format="pdf")
plt.close()

plt.plot(m['num_reads'], m['time_whatshap'])
plt.plot(mlast['num_reads'], mlast['time_whatshap'], color='red', marker='o')
plt.ylabel('Num of reads')
plt.ylabel('WhatsHap runtime in s')
plt.savefig(args.outFile + ".reads.rt.pdf", bbox_inches='tight', format="pdf")
plt.close()
