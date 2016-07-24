module pruner.strategies.pruning;

import pruner.app;
import pruner.formats;
import std.experimental.logger;

auto maxFlowPruning(R)(R reads, edge_t maxReadsPerPos)
{
    import pruner.coverage: breakPoints;
    struct Gen
    {
        typeof(breakPoints(R.init)) b;

        this(R reads)
        {
            b = breakPoints(reads);
        }

        bool empty()
        {
            return b.empty;
        }

        const(Read)[] front()
        {
            if (b.front.empty)
            {
                Read[] rs;
                return rs;
            }
            return maxFlowOptByRef(b.front, maxReadsPerPos).flow.prune;
        }

        void popFront()
        {
            b.popFront();
        }
    }
    return Gen(reads);
}

unittest
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10), Read(20, 30)];
    auto p = maxFlowPruning(reads, 3);
    assert(p.front == [Read(1, 10)]);
    p.popFront;
    assert(!p.empty);
    assert(p.front == []);
    p.popFront;
    assert(p.empty);
}
