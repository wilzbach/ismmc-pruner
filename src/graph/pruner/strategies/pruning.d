module pruner.strategies.pruning;

import pruner.app;
import pruner.formats;
import std.experimental.logger;

auto maxFlowPruning(R)(R reads, edge_t maxReadsPerPos)
{
    import pruner.coverage: breakPoints;
    import std.concurrency: Generator, yield;
    auto b = breakPoints(reads);

    // async, lazy range with Fibers
    return new Generator!(const(Read)[])(
    {
        while (!b.empty)
        {
            info("FRONT", b.front.front);
            // TODO: we should be able to save a range
            auto opt = maxFlowOptByRef(b.front, maxReadsPerPos);
            yield(prune(opt.flow));
            b.popFront();
        }
    });
}

unittest
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10), Read(20, 30)];
    auto p = maxFlowPruning(reads, 3);
    assert(p.front == [Read(2, 6), Read(1, 3)]);
    p.popFront;
    assert(!p.empty);
    assert(p.front == []);
    p.popFront;
    assert(p.empty);
}
