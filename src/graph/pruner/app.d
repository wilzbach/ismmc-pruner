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

    uint[] positions = reads.map!`a.start`
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
        // maxFlow with k=maxReadsPerPos,t=m
        update(m, maxReadsPerPos);
        auto lastFlow = g.maxFlow(superSource, superSink);
        // 0 = can't satisfy -> go to left
        // iff max-flow is exactly k
        if(lastFlow.max != maxReadsPerPos)
        {
            assert(lastFlow.max < maxReadsPerPos);
            r = m - 1;
        }
        else
        {
            // TODO: this case might be a bit more complex?
            l = m + 1;
            lastValidFlow = lastFlow;
            lastValidK = m;
        }
    }

    //auto lastValidFlow = g.maxFlow(superSource, superSink);
    //auto lastValidK = lastValidFlow.max;
    return tuple!("tOpt", "flow")(lastValidK, lastValidFlow.flow);
}

/**
Searches for all reads in the flow that are zero and can be removed.
*/
const(Read)*[] prune(Flow)(Flow f)
{
    import std.array: byPair;
    // remove edges
    const(Read)*[] pruned;
    // iterates over all edges in the flow
    foreach (edge, flowValue; f.flow.byPair)
    {
        if (flowValue == 0)
        {
            TailEdge* e = f.g.getEdgeByCid(edge);
            if(e.read != null)
            {
                pruned ~= (*e).read;
            }
        }
    }
    return pruned;
}

// test with duplicates read
//unittest
//{
    //auto reads = [Read(0, 5), Read(0, 5), Read(0, 7),
                  //Read(6, 11), Read(6, 11),
                  //Read(10, 17),
                  //Read(12, 17), Read(12, 17)];
    //foreach (i, ref read; reads)
        //read.id = i;
    //auto opt = maxFlowOpt(reads, 2);
    //writeln(opt.tOpt);
//}

// TODO: graph doesn't allow duplicate edges
// -> allow multiple edges for the same graph
unittest
{
    auto reads = [Read(0, 10), Read(0, 11),
                  Read(20, 30), Read(20, 31),
                  Read(40, 50), Read(40, 51),
                  Read(0, 25), Read(26, 51)];
    foreach (i, ref read; reads)
        read.id = i;
    auto opt = maxFlowOpt(reads, 3);
    assert(opt.tOpt == 1);

    const(Read)*[] pruned = opt.flow.prune;
    foreach (i, prun; pruned)
        writeln(*prun);

    import std.array: byPair;
    foreach (k,vs; opt.flow.g.g.byPair)
    {
        foreach(v,e; vs.byPair)
        {
            if (k < v)
            {
                writefln("%2d-%2d: %d (flow: %d)", k, v, e.capacity, opt.flow.flow[e.cid]);
            }
        }
    }
}

    //auto reads = [Read(0, 10),
                  //Read(20, 30),
                  //Read(40, 50),
                  //Read(0, 25), Read(26, 50)];
// 3, tOpt = 1, no pruning



//unittest
//{
    //auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  //Read(2, 6), Read(4, 10)];
    //foreach (i, ref read; reads)
        //read.id = i;

    //auto opt = maxFlowOpt(reads, 3);
    //assert(opt.tOpt == 2);

    //const(Read)*[] pruned = opt.flow.prune;
    //assert(pruned.length == 2);
    //import std.array: byPair;

    //foreach (k,vs; opt.flow.g.g.byPair)
    //{
        //foreach(v,e; vs.byPair)
        //{
            //if (e.read != null)
            //{
                //writefln("%2d-%2d: %d (flow: %d)", k, v, e.capacity, opt.flow.flow[e.cid]);
            //}
        //}
    //}

    //auto expectedPrun = [4, 2];
    //// 1-3 and 2-6
    //foreach (i, prun; pruned)
        //assert(*prun == reads[expectedPrun[i]]);

    ////assert(maxFlowOpt(reads, 3).max == 3);
    ////assert(maxFlowOpt(reads, 6, 1) == 6);
    ////auto reads2 = [Read(1, 3), Read(2, 6), Read(4, 10)];
    ////assert(maxFlowOpt(reads2, 3, 1) == 3);
    ////assert(maxFlowOpt([], 3, 1) == 1);
//}
