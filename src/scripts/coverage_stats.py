#!/usr/bin/env python
# -*- coding: utf-8 -*-

import numpy as np
import matplotlib.pyplot as plt
import argparse
import sys

parser = argparse.ArgumentParser(description="Plot coverage")
parser.add_argument('inFile', nargs=1, type=argparse.FileType('r'), help='Input file')
parser.add_argument('-o', '--outFile', dest='outFile', type=argparse.FileType('wb'),
                    default=sys.stdout, help='Output file (default: stdout)')
args = parser.parse_args()

covs = np.loadtxt(args.inFile[0], np.int)
cov, reads = covs.T

plt.plot(cov, reads)
plt.xlabel('Coverage')
plt.ylabel('Number of reads')

# calculate mean coverage
total_reads = np.sum(reads)
reads_weighted_cov = np.sum([p[0] * p[1] for p in covs])
mean = reads_weighted_cov / total_reads

# plot mean as line
mean_line_height = np.arange(0, np.max(reads), 10)
mean_line_x = [mean for t in mean_line_height]
plt.plot(mean_line_x, mean_line_height, color='green')

plt.savefig(args.outFile, bbox_inches='tight', format="pdf")
plt.close()
