#!/usr/bin/env python3
# encoding: utf-8

import sys
import argparse
from Bio import SeqIO

parser = argparse.ArgumentParser(description="Cut sequences")
parser.add_argument('inFile', nargs=1, type=argparse.FileType('r'), help='Input file')
parser.add_argument('-o', '--outFile', dest='outFile', type=argparse.FileType('w'),
                    default=sys.stdout, help='Output file (default: stdout)')
parser.add_argument('-s', '--start', dest='start', type=int, default=0, help='Start position file')
parser.add_argument('-e', '--end', dest='end', type=int, default=-1, help='End position file')
args = parser.parse_args()

ge = SeqIO.read(args.inFile[0], format="fasta")

ge.seq = ge.seq[args.start:args.end]
SeqIO.write(ge, args.outFile, format="fasta")
