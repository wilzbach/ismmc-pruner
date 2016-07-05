module pruner.strategies.random;

import pruner.formats;

// TODO: integrate back into main interface
const(Read)*[] randomPruning(R)(R reads)
{
    const(Read)*[] pruned;
    pruned.reserve(20_000);
    foreach (i, ref read; reads)
    {
        if (i % 2)
            pruned ~= &read;
    }
    return pruned;
}
