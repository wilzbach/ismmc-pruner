import pruner.formats;

void randomSplitting(string[] args)
{
    import std.stdio;
    import std.conv;
    import std.typecons;
    import std.algorithm;
    import std.range;
    alias ChrRead = Tuple!(uint, "chr", uint, "start", uint, "stop", uint, "id");
    foreach (i, ref line; stdin.byLine.enumerate)
    {
        // chr, start, stop, id
        auto cread = line.splitter(" ").map!(to!uint);
        if (i % 2 != 0)
            writeln(i);
    }
}

version (unittest) {
void main(){}
}
else
{
void main(string[] args)
{
    import std.stdio;
    import std.conv;
    import std.typecons;
    import std.algorithm;
    import std.range;
    alias ChrRead = Tuple!(uint, "chr", uint, "start", uint, "stop", uint, "id");
    Read[] reads;
    reads.reserve(20_000);
    foreach (i, ref line; stdin.byLine.enumerate)
    {
        // chr, start, stop, id
        auto cread = line.splitter(" ").map!(to!uint);
        writeln(cread.save);
        reads ~= Read(cread.dropOne.front, cread.dropOne.front);
    }
    import pruner.app;
    auto opt = maxFlowOpt(reads, 3);
    const(Read)*[] pruned = opt.flow.prune;
    foreach (i, prun; pruned)
        writeln(i);
}
}
