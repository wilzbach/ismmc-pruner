#!/usr/bin/env python
# encoding: utf-8


def maxFlowApprox(reads, maxReadsPerPos, minReadsPerPos):
    """  TO BE DONE  """
    positions = sorted(set([x for sublist in reads for x in sublist]))
    positionsDict = {}
    currentMaxFlow = 0
    currentStart = -1
    readsIter = iter(sorted(reads))
    for p in positions:
        currentMaxFlow += 1
    return 0
