module pruner.app;

import std.stdio;
import pruner.formats;
import pruner.graph;
import pruner.output;
import std.experimental.logger;

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
    this(R)(auto ref R reads)
    {
        g = new DGraph();

        assert(!reads.empty, "No reads given");

        // add read intervals
        // foreach not possible due to non-copyable?
        while (!reads.empty)
        {
            import std.traits: isPointer;
            g.addEdge(reads.front.start, reads.front.end, readIntervalCapacity, reads.front);

            // + 0 works around the fact that a.start is immutable
            positions ~= reads.front.start + 0;
            positions ~= reads.front.end + 0;

            reads.popFront();
        }

        setPositions();
        addBackbone();
    }

    void setPositions()
    {
        // we can do only _one_ loop (moved to main loop)
        info("positions", positions);
        positions = positions.sort().release.uniq.array;
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
            infof("updating backbone with k=%d", m);
            auto lastFlow = g.maxFlow(superSource, superSink);
            infof("flow result: %d", lastFlow.max);

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

auto maxFlowOpt(R)(R reads, edge_t maxReadsPerPos)
{
    return maxFlowOptByRef(reads, maxReadsPerPos);
}

auto maxFlowOptByRef(R)(ref R reads, edge_t maxReadsPerPos)
{
    //infof("running maxFlow with %d reads", reads.length);
    auto m = MaxFlowOpt(reads);
    auto r = m.binarySearch(maxReadsPerPos);
    infof("tOpt: %d", r.tOpt);
    return r;
}

/**
Searches for all reads in the flow that are zero and can be removed.
*/
const(Read)[] prune(Flow)(Flow f)
{
    import std.array: byPair;
    // remove edges
    const(Read)[] pruned;
    // iterates over all edges in the flow
    foreach (edge, flowValue; f.flow.byPair)
    {
        if (flowValue == 0)
        {
            TailEdge e = f.g.getEdgeByCid(edge);
            if(e.read !is null)
            {
                pruned ~= e.read;
            }
        }
    }
    return pruned;
}

bool contains(const(Read)[] reads, Read target ) {
    import std.algorithm.searching : canFind;
    return reads.canFind!((read) => read.start == target.start && read.end == target.end);
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
    //printGraph(opt.flow.g, opt.flow, File("debug/paper_first_example.eps", "w"));

    auto pruned = opt.flow.prune;

    // TODO: Obs that the algorithm currently delete more than strictly needed.
    infof("%s", pruned);
    assert(pruned == [
                    Read(6, 11, 4),
                    Read(12, 17, 7),
                    Read(0, 5, 1)]);

    // A more ambitious implementation would satisfy those, including len==3
    assert(! contains(pruned, Read(0,7)));
    assert(! contains(pruned, Read(10,17)));
    assert(  contains(pruned, Read(0,5)));
    assert(  contains(pruned, Read(6,11)));
    assert(  contains(pruned, Read(12,17)));
    //assert(pruned.length == 3);

    writeln("Test 1 OK");
}

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

    auto pruned = opt.flow.prune;

    assert(pruned == [Read(0, 10, 0),
                          Read(20, 31, 3)]);
    writeln("Test 2 OK");
}

unittest
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10)];
    auto opt = maxFlowOpt(reads, 3);
    assert(opt.tOpt == 2);

    auto pruned = opt.flow.prune;
    assert(pruned.length == 2);

    assert(pruned == [Read(2, 6), Read(1, 3)]);

    //assert(maxFlowOpt(reads, 3).max == 3);
    //assert(maxFlowOpt(reads, 6, 1) == 6);
    //auto reads2 = [Read(1, 3), Read(2, 6), Read(4, 10)];
    //assert(maxFlowOpt(reads2, 3, 1) == 3);
    //assert(maxFlowOpt([], 3, 1) == 1);
    writeln("Test 3 OK");
}

unittest
{
  import std.random;
  import std.conv;
  auto reads_base = [Read(0, 51), Read(50, 101), Read(100, 151), Read(150, 201)];

  foreach (int n_extra ; [30]) {
    auto reads = reads_base;

    foreach (int left; [2, 52, 102, 152]){
      int right = left + 47;
      for (int i = 0; i < n_extra; i++) {
        auto sp = uniform(left, right - 1);
        auto ep = uniform(sp + 1, right);
        reads = reads ~ Read(sp,ep);
      }
    }
    foreach (i, ref read; reads)
      read.id = i;

    auto opt = maxFlowOpt(reads, 3);

    const(Read)[] pruned = opt.flow.prune;

    foreach (ref critical_read; reads_base) {
      assert(! contains(pruned,
                        Read(critical_read.start, critical_read.end)));
    }

    writeln("Pruned " ~ to!string(pruned.length) ~ " out of" ~ to!string(reads.length));
    writeln("OK\n");
  }
  writeln("Test 4 OK");
}
