#!/usr/bin/env python
# encoding: utf-8

import sys
import argparse
import flow
from analyze import findMinMaxCov
import pygraphviz as pgv

parser = argparse.ArgumentParser(description="Awesome parser")
parser.add_argument('-i', '--inFile', dest='inFile', help='Input file')
parser.add_argument('-m', '--maxReads', type=int, default=3, help='Max reads per position')
parser.add_argument('-n', '--minReads', type=int, default=1, help='Max reads per position')
args = parser.parse_args()

if args.inFile is None:
    sys.exit("No input file.")


def drawNet(maxFlow, toFile):
    networkFile = toFile
    A = pgv.AGraph(directed=True)
    #A.graph_attr["rotate"] = 90
    A.graph_attr["rankdir"] = "LR"
    #A.graph_attr["splines"] = "ortho"
    for s, vs in maxFlow.items():
        for e, w in vs.items():
            style = "dashed" if e - s == 1 else "solid"
            if w > 0:
                A.add_edge(s, e, style=style, xlabel=w, penwidth="2")
            else:
                A.add_edge(s, e, style=style, color="grey", xlabel="0")
    A.layout("dot")
    with open(networkFile, "wb") as f:
        f.write(A.draw(format="png"))

with open(args.inFile) as file:
    # VERY SLOW input reading from dummy file - just for testing
    text = file.read()
    reads = [tuple(int(y) for y in x.split(",")) for x in text.split("\n") if len(x) > 0]

    maxFlow, pruned, net = flow.maxFlowOpt(reads, args.maxReads, args.minReads)
    if len(maxFlow) == 0:
        print("not enough covering reads")
    else:
        print("pruned", pruned)
        print("edges", maxFlow)
        min_cov, max_cov = findMinMaxCov(maxFlow)
        print("min: %d, max: %d" % (min_cov, max_cov))
        drawNet(net, "network.png")

    # TODO: implement tailored Ford-Fulkerson

    # TO BE DONE
    # approxFlow = flow.maxFlowApprox(reads, args.maxReads, args.minReads)
    # print(approxFlow)
