module pruner.app;

import std.stdio;
import pruner.formats;
import pruner.graph;

auto maxFlowOpt(Read[] reads, uint maxReadsPerPos, uint minReadsPerPos)
{
    import std.algorithm;
    import std.range;

    auto positions = reads.map!`a.start`
                          .chain(reads.map!`a.end`)
                          .array
                          .sort()
                          .release
                          .uniq
                          .array;
    auto backboneCapacity = maxReadsPerPos - minReadsPerPos;
    auto sourceSinkCapacity = maxReadsPerPos;
    auto readIntervalCapacity = 1;
    auto superSource = -1;
    auto superSink = positions[$-1] + 1;

    DGraph g;

    // add backbone
    g.addEdge(superSource, positions[0], sourceSinkCapacity);
    g.addEdge(positions[$-1], superSink, sourceSinkCapacity);
    foreach (p0, p1; zip(positions, positions.save.dropOne))
        g.addEdge(p0, p1, backboneCapacity);

    // add intervals
    foreach (read; reads)
        g.addEdge(read.start, read.end, readIntervalCapacity);

    auto m = g.maxFlow(superSource, superSink);
    return m;
}

unittest
{
    import std.stdio;
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10)];
    assert(maxFlowOpt(reads, 3, 1) == 3);
    assert(maxFlowOpt(reads, 6, 1) == 6);
    auto reads2 = [Read(1, 3), Read(2, 6), Read(4, 10)];
    assert(maxFlowOpt(reads2, 3, 1) == 3);
    //assert(maxFlowOpt([], 3, 1) == 1);
}
