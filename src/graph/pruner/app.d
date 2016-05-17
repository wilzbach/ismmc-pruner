module pruner.app;

import std.stdio;
import pruner.formats;
import pruner.graph;
import pruner.output;

struct MaxFlowOpt
{
    import std.algorithm;
    import std.range;
    import std.array;
    import std.typecons;

private:
    enum readIntervalCapacity = 1;
    enum edge_t superSource = -1;
    edge_t superSink;
    uint[] positions;
    DGraph g;

    TailEdge[] backbone;
    TailEdge superSourceEdge, superSinkEdge;

public:
    this(ref Read[] reads)
    {
        g = new DGraph();
        getPositions(reads);
        addBackbone();

        // add read intervals
        foreach (ref read; reads)
            g.addEdge(read.start, read.end, readIntervalCapacity, &read);
    }

    void getPositions(ref Read[] reads)
    {
        this.positions = reads.map!`a.start`
                          .chain(reads.map!`a.end`)
                          .array
                          .sort()
                          .release
                          .uniq
                          .array;
        superSink = positions[$-1] + 1;
    }

    // adds all edges of the backbone, capacity will be updates later
    void addBackbone()
    {
        // pairwise iteration
        foreach (p0, p1; zip(this.positions, this.positions.save.dropOne))
            backbone ~= g.addEdge(p0, p1, 42);

        // update super source, sink
        superSourceEdge = g.addEdge(superSource, positions[0]);
        superSinkEdge = g.addEdge(positions[$-1], superSink);
    }

    // updates capacity of backbone + super source, sink
    void updateBackbone(edge_t minReadsPerPos, edge_t maxReadsPerPos)
    {
        // k - t
        edge_t backboneCapacity = maxReadsPerPos - minReadsPerPos;

        // update super source, sink
        superSinkEdge.capacity = maxReadsPerPos;
        superSourceEdge.capacity = maxReadsPerPos;

        // loop through backbone
        foreach (ref edge; backbone)
        {
            edge.capacity = backboneCapacity;
        }
    }

    auto maxFlow()
    {
        //auto lastValidFlow = g.maxFlow(superSource, superSink);
        //auto lastValidK = lastValidFlow.max;
    }

    auto binarySearch(edge_t maxReadsPerPos)
    {
        uint l = 1, r = maxReadsPerPos;
        alias FlowTuple = typeof(g.maxFlow(0, 0));

        import std.stdio;
        FlowTuple lastValidFlow;
        uint lastValidK;

        // fake binary search
        while (l <= r)
        {
            auto m = (l + r) / 2;
            // maxFlow with k=maxReadsPerPos,t=m
            updateBackbone(m, maxReadsPerPos);
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
        // TODO: reruns the flow for the last valid k to update the graph (correct capacity)
        version (unittest)
            updateBackbone(lastValidK, maxReadsPerPos);
        return tuple!("tOpt", "flow")(lastValidK, lastValidFlow.flow);
    }
}

auto maxFlowOpt(ref Read[] reads, edge_t maxReadsPerPos)
{
    auto m = MaxFlowOpt(reads);
    return m.binarySearch(maxReadsPerPos);
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
            TailEdge e = f.g.getEdgeByCid(edge);
            if(e.read != null)
            {
                pruned ~= e.read;
            }
        }
    }
    return pruned;
}

// test with duplicates read
unittest
{
    auto reads = [Read(0, 5), Read(0, 5), Read(0, 7),
                  Read(6, 11), Read(6, 11),
                  Read(10, 17),
                  Read(12, 17), Read(12, 17)];
    foreach (i, ref read; reads)
        read.id = i;
    auto opt = maxFlowOpt(reads, 2);
    assert(opt.tOpt == 1);

    //printFlow(opt.flow, -1, [-2: true]);
    printGraph(opt.flow.g, opt.flow, File("test.eps", "w"));

    const(Read)*[] pruned = opt.flow.prune;
    import std.algorithm: map, equal;
    // print what's pruned
    pruned.map!`*a`.writeln;
}

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

    import std.algorithm: map, equal;
    assert(pruned.map!`*a`.equal([Read(0, 11, 1),
                                  Read(20, 31, 3),
                                  Read(40, 50, 4)]));
}

    //auto reads = [Read(0, 10),
                  //Read(20, 30),
                  //Read(40, 50),
                  //Read(0, 25), Read(26, 50)];
// 3, tOpt = 1, no pruning

unittest
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10)];
    foreach (i, ref read; reads)
        read.id = i;

    auto opt = maxFlowOpt(reads, 3);
    assert(opt.tOpt == 2);

    const(Read)*[] pruned = opt.flow.prune;
    assert(pruned.length == 2);

    import std.algorithm: map, equal;
    assert(pruned.map!`*a`.equal([Read(2, 6, 4), Read(1, 3, 2)]));

    //assert(maxFlowOpt(reads, 3).max == 3);
    //assert(maxFlowOpt(reads, 6, 1) == 6);
    //auto reads2 = [Read(1, 3), Read(2, 6), Read(4, 10)];
    //assert(maxFlowOpt(reads2, 3, 1) == 3);
    //assert(maxFlowOpt([], 3, 1) == 1);
}
