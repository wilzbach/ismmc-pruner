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

cov = np.loadtxt(args.inFile[0], np.int)

plt.plot(cov[:, 0], cov[:, 1])

# calculate mean coverage
s = np.sum(cov[:, 1])
mean = np.sum([p[0] * p[1] / s for p in cov])
ts = np.arange(0, np.max(cov), 10)
mean_ts = [mean for t in ts]

plt.plot(mean_ts, ts, color='green')
plt.xlabel('Coverage')
plt.ylabel('Number of reads')

plt.savefig(args.outFile, bbox_inches='tight', format="pdf")
plt.close()
