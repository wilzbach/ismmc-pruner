#!/usr/bin/env python
# -*- coding: utf-8 -*-

import numpy as np
import matplotlib.pyplot as plt
import argparse
import sys
from scipy.stats import norm

parser = argparse.ArgumentParser(description="Plot depth")
parser.add_argument('inFile', nargs=1, type=argparse.FileType('r'), help='Input file')
parser.add_argument('-o', '--outFile', dest='outFile', type=argparse.FileType('wb'),
                    default=sys.stdout, help='Output file (default: stdout)')
args = parser.parse_args()

m = np.loadtxt(args.inFile[0], np.int, usecols=range(1, 3))
pos, reads = m.T

plt.hist(reads, bins=range(0, 200, 1), normed=True, alpha=0.6, color='g')

# Fit a normal distribution to the data:
mu, std = norm.fit(reads)
print(np.mean(reads))
print(mu, std)

# Plot the PDF.
xmin, xmax = plt.xlim()
x = np.linspace(xmin, xmax, 100)
p = norm.pdf(x, mu, std)
print(x)
print(p)
plt.plot(x, p, linewidth=2)

plt.savefig(args.outFile, bbox_inches='tight', format="pdf")
plt.close()
