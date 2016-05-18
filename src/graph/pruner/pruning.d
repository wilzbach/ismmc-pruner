module pruner.pruning;

import pruner.app;
import pruner.formats;
import std.experimental.logger;

const(Read)[] maxFlowPruning(R)(R reads, edge_t maxReadsPerPos)
{
    const(Read)[] prunes;
    import pruner.functions: breakPoints;
    auto b = breakPoints(reads);
    while (!b.empty)
    {
        auto opt = maxFlowOptByRef(b.front, maxReadsPerPos);
        info("opt calcualted");
        // TODO: make lazy
        prunes ~= prune(opt.flow);
        info("pruning done");
        // TODO: we should be able to save a range
        //b.popFront();
    }
    return prunes;
}

unittest
{
    auto reads = [Read(0, 8), Read(4, 11), Read(10, 12)];
    auto p = maxFlowPruning(reads, 3);
    info("prunes", p.length);
}
