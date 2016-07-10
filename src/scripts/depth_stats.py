#!/usr/bin/env python
# -*- coding: utf-8 -*-

import numpy as np
import matplotlib.pyplot as plt
import argparse
import sys

parser = argparse.ArgumentParser(description="Plot depth")
parser.add_argument('inFile', nargs=1, type=argparse.FileType('r'), help='Input file')
parser.add_argument('-o', '--outFile', dest='outFile', type=argparse.FileType('wb'),
                    default=sys.stdout, help='Output file (default: stdout)')
args = parser.parse_args()

m = np.loadtxt(args.inFile[0], np.int, usecols=range(1, 3))
pos, reads = m.T

avg_reads = np.sum(reads) / len(reads)

print("AVG coverage per reads: ", avg_reads)
print("Total reads", len(reads))

plt.plot(pos, reads)
plt.xlabel('Position')
plt.ylabel('Number of reads')

# plot mean as line
mean_line_x = np.arange(np.min(pos), np.max(pos), 10)
mean_line_y = [avg_reads for t in mean_line_x]
plt.plot(mean_line_x, mean_line_y, color='green')

plt.savefig(args.outFile, bbox_inches='tight', format="pdf")
plt.close()
