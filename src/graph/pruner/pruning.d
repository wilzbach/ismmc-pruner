module pruner.pruning;

import pruner.app;
import pruner.formats;
import std.experimental.logger;

const(Read)*[] maxFlowPruning(R)(R reads, edge_t maxReadsPerPos)
{
    //const(Read)*[] prunes;
    auto opt = maxFlowOpt(reads, maxReadsPerPos);
    return prune(opt.flow);
}
