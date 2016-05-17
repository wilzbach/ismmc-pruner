import pruner.formats;
import std.stdio;


// TODO: dirty hack - find a better solution
version (unittest) {
void main(){}
}
else
{
void main(string[] args)
{
    import std.getopt;

    enum Progs {maxflow, random}
    Progs progs;
    bool verbose;
    edge_t maxCoverage;

    auto helpInformation = getopt(
        args,
        "v|verbose", &verbose,
        "max-coverage|m", &maxCoverage,
        "p|program", &progs);

    if (helpInformation.helpWanted)
    {
      defaultGetoptPrinter("Some information about the program.",
        helpInformation.options);
    }

    auto reads = getReads(stdin);

    final switch (progs)
    {
        case Progs.maxflow:
            import pruner.pruning: maxFlowPruning;
            maxFlowPruning(reads, maxCoverage).outputReads(stdout);
            break;
        case Progs.random:
            import pruner.random: randomPruning;
            randomPruning(reads).outputReads(stdout);
            break;
    }
}
}

/**
Deserializes the reads from a text format (e.g. stdin)
*/
immutable(Read)[] getReads(File fileIn)
{
    import std.range: enumerate, dropOne;
    import std.algorithm: splitter, map;
    import std.conv: to;

    immutable(Read)[] reads;
    reads.reserve(20_000);
    foreach (i, ref line; fileIn.byLine.enumerate)
    {
        // chr, start, stop, id
        auto cread = line.splitter('\t').map!(to!uint);
        cread.dropOne;
        reads ~= Read(cread.dropOne.front, cread.dropOne.front, cread.dropOne.front);
    }
    return reads;
}

unittest
{
    // virtual file
    import std.process: pipe;
    auto p = pipe();
    p.writeEnd.writeln("0	10000	15000	0");
    p.writeEnd.close();
    getReads(p.readEnd);
}

/**
Serializes the reads to a text format
*/
void outputReads(R)(R rs, File outFile)
{
    foreach (const ref r; rs)
        outFile.writeln(r);
}

unittest
{
    // virtual file
    import std.process: pipe;
    auto p = pipe();
    outputReads([0, 1, 3], p.writeEnd);
    p.writeEnd.close();
    auto output = p.readEnd.byLineCopy;
    import std.algorithm: equal;
    assert(output.equal(["0", "1", "3"]));
}
