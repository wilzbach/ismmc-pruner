module pruner.functions;

import pruner.formats;

// doesn't work anymore due to postblit-disabled Read

auto accumulateCov(Read[] reads)
{
    import std.algorithm: sort, map;
    import std.range: array;
    import std.typecons: Tuple;
    import pruner.accumulate;
    alias CovTuple = Tuple!(int, "index", int, "cov");

    CovTuple[] positions;
    foreach (ref read; reads)
    {
        // + 0 works around the fact that a.start is immutable
        positions ~= CovTuple(read.start + 0, 1);
        positions ~= CovTuple(read.end + 0, -1);
    }

    auto a = positions.array
                .sort!`a.index < b.index || (a.index == b.index) && a.cov < b.cov`()
                .release
                .accumulate!((a, b) => CovTuple(a.index, a.cov + b.cov))(CovTuple(-1, 0));
    return a;
}

unittest
{
    import std.algorithm: maxPos;
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10)];
    assert(reads.accumulateCov.maxPos.front.cov == 4);
}

unittest
{
    import std.algorithm: maxPos, minPos;
    auto reads = [Read(0, 8), Read(10, 12)];
    assert(reads.accumulateCov.maxPos.front.cov == 1);
    assert(reads.accumulateCov.minPos.front.cov == 0);
}
