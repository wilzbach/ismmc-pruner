module pruner.random;

import pruner.formats;

// TODO: integrate back into main interface
uint[] randomPruning(const(Read)[] reads)
{
    uint[] pruned;
    pruned.reserve(20_000);
    foreach (i, ref read; reads)
    {
        if (i % 2)
            pruned ~= cast(uint) i;
    }
    return pruned;
}
