import pruner.formats;

auto maxCov(Read[] reads)
{
    import std.algorithm: map, sort, maxPos;
    import std.range: array, chain;
    import std.typecons: Tuple;
    import accumulate;
    alias CovTuple = Tuple!(int, "index", int, "cov");
    auto start = reads.map!((a) => CovTuple(a.start, 1));
    auto end = reads.map!((a) => CovTuple(a.end, -1));
    auto a = start.chain(end)
                .array
                .sort!`a.index < b.index || (a.index == b.index) && a.cov < b.cov`()
                .release
                .map!`a.cov`
                .accumulate!`a + cast(int) b`(0);
    return a.maxPos.front;
}

unittest
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10)];
    assert(reads.maxCov == 4);
}
