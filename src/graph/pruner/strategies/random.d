module pruner.strategies.random;

import pruner.formats;

// TODO: integrate back into main interface
const(Read)[] randomPruning(R)(R reads)
{
    const(Read)[] pruned;
    pruned.reserve(20_000);
    import std.random;
    foreach (i, ref read; reads)
    {
        if (uniform01() > 0.01)
            pruned ~= read;
    }
    return pruned;
}
