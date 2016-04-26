#!/usr/bin/env python
# encoding: utf-8

import networkx as nx
import utils
import copy


def maxFlowOpt(reads, maxReadsPerPos, minReadsPerPos):
    """
        reads:
        maxReadsPerPos: maximum coverage (aka k)
        minReadsPerPos: minimum coverage (aka t)
    """
    # flatten read start and end into one list
    positions = sorted(set([x for sublist in reads for x in sublist]))
    backboneCapacity = maxReadsPerPos - minReadsPerPos
    sourceSinkCapacity = maxReadsPerPos
    readIntervalCapacity = 1
    superSource = -1
    superSink = positions[-1] + 1
    g = nx.DiGraph()

    # we remove reads directly from the list
    reads = copy.copy(reads)

    # add backbone
    g.add_edge(superSource, positions[0], {'capacity': sourceSinkCapacity})
    g.add_edge(positions[-1], superSink, {'capacity': sourceSinkCapacity})
    for (p0, p1) in utils.pairwise(positions):
        g.add_edge(p0, p1, {'capacity': backboneCapacity})

    # add intervals
    for read in reads:
        g.add_edge(read[0], read[1], {'capacity': readIntervalCapacity})

    # TODO: implement flow algorithm
    val, mincostFlow = nx.maximum_flow(g, superSource, superSink)
    pruned = []

    # TODO: this is in O(n) -> we can do it in O(log n)
    for key, values in mincostFlow.items():
        for value, weight in values.items():
            if weight is 0:
                toRemove = (key, value)
                if toRemove in reads:
                    pruned.append((key, value))
                    reads.remove((key, value))

    return reads, pruned, mincostFlow
