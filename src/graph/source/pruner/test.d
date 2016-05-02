module pruner.app;

import std.stdio;
import pruner.formats;
import pruner.graph;

auto maxFlowOpt(Read[] reads, edge_t maxReadsPerPos)
{
    import std.algorithm;
    import std.range;
    import std.array;
    import std.typecons;

    auto positions = reads.map!`a.start`
                          .chain(reads.map!`a.end`)
                          .array
                          .sort()
                          .release
                          .uniq
                          .array;

    auto readIntervalCapacity = 1;
    auto superSource = -1;
    auto superSink = positions[$-1] + 1;

    DGraph g;

    edge_t backboneCapacity, sourceSinkCapacity;
    void update(edge_t minReadsPerPos, edge_t maxReadsPerPos)
    {
        backboneCapacity = maxReadsPerPos - minReadsPerPos;
        sourceSinkCapacity = maxReadsPerPos;

        // update backbone
        g.updateEdge(superSource, positions[0], sourceSinkCapacity);
        g.updateEdge(positions[$-1], superSink, sourceSinkCapacity);

        // pairwise iteration
        foreach (p0, p1; zip(positions, positions.save.dropOne))
            g.updateEdge(p0, p1, backboneCapacity);
    }

    // add intervals
    foreach (ref read; reads)
        g.addEdge(read.start, read.end, readIntervalCapacity, &read);

    uint l = 1, r = maxReadsPerPos;
    alias FlowTuple = typeof(g.maxFlow(0, 0));

    FlowTuple lastValidFlow;
    uint lastValidK;

    // fake binary search
    while (l <= r)
    {
        auto m = (l + r) / 2;
        update(m, maxReadsPerPos);
        auto lastFlow = g.maxFlow(superSource, superSink);
        // 0 = can't satisfy -> go to left
        if(lastFlow.max == 0)
            r = m - 1;
        else
        {
            // TODO: this case might be a bit more complex?
            l = m + 1;
            if (lastFlow.max == maxReadsPerPos)
            {
                lastValidFlow = lastFlow;
                lastValidK = m;
            }
        }
    }
    return tuple!("k", "flow")(lastValidK, lastValidFlow.flow);
}

const(Read)*[] prune(Flow)(Flow f)
{
    import std.array;
    // remove edges
    const(Read)*[] pruned;
    foreach (k, v; f.flow.byPair)
    {
        if (v == 0)
        {
            TailEdge* e = f.g.getEdgeByCid(k);
            if(e.edge != null)
            {
                pruned ~= (*e).edge;
            }
        }
    }
    return pruned;
}

unittest
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10)];
    foreach (i, ref read; reads)
        read.id = i;

    auto opt = maxFlowOpt(reads, 3);
    assert(opt.k == 2);
    const(Read)*[] pruned = opt.flow.prune;
    assert(pruned.length == 2);
    auto expectedPrun = [4, 2];
    // 1-3 and 2-6
    foreach (i, prun; pruned)
        assert(*prun == reads[expectedPrun[i]]);

    //assert(maxFlowOpt(reads, 3).max == 3);
    //assert(maxFlowOpt(reads, 6, 1) == 6);
    //auto reads2 = [Read(1, 3), Read(2, 6), Read(4, 10)];
    //assert(maxFlowOpt(reads2, 3, 1) == 3);
    //assert(maxFlowOpt([], 3, 1) == 1);
}
