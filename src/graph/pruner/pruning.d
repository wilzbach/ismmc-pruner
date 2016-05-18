module pruner.pruning;

import pruner.app;
import pruner.formats;

const(Read)*[] maxFlowPruning(R)(R reads, edge_t maxReadsPerPos)
{
    //const(Read)*[] prunes;

    //import pruner.functions;
    //auto accumulatedCov = reads.accumulateCov;
    //while (!accumulatedCov.empty)

    auto opt = maxFlowOpt(reads, maxReadsPerPos);
    return prune(opt.flow);
}

//unittest
//{
    //import std.algorithm: maxPos, minPos;
    //auto reads = [Read(0, 8), Read(10, 12)];
    //assert(reads.accumulateCov.maxPos.front == 1);
    //assert(reads.accumulateCov.minPos.front == 0);
//}
