module pruner.pruning;

import pruner.app;
import pruner.formats;

const(Read)*[] maxFlowPruning(R)(R reads, edge_t maxReadsPerPos)
{
    auto opt = maxFlowOpt(reads, maxReadsPerPos);
    return opt.flow.prune;
}
