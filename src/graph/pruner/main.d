import pruner.formats;
import std.stdio;
import std.experimental.logger;

// TODO: dirty hack - find a better solution
version (unittest) {
void main(){}
}
else
{
void main(string[] args)
{
    import std.getopt;
    import core.stdc.stdlib: exit;
    import std.exception: enforce;

    enum Progs {maxflow, random}
    Progs progs;
    bool verbose;
    edge_t maxCoverage;

    auto helpInformation = getopt(
        args,
        std.getopt.config.required,
        "max-coverage|m", &maxCoverage,
        "v|verbose", &verbose,
        "p|program", &progs);

    if (helpInformation.helpWanted)
    {
        defaultGetoptPrinter("Some information about the program.",
            helpInformation.options);
        exit(1);
    }

    auto reads = getReads(stdin);

    final switch (progs)
    {
        case Progs.maxflow:
            info("start maxflow");
            import pruner.strategies.pruning: maxFlowPruning;
            // we may have multiple components
            foreach (rs; maxFlowPruning(reads, maxCoverage))
            {
                rs.outputReads(stdout);
            }
            break;
        case Progs.random:
            info("start random");
            import pruner.strategies.random: randomPruning;
            randomPruning(reads).outputReads(stdout);
            break;
    }
}
}

/**
Deserializes the reads from a text format (e.g. stdin)
*/
auto getReads(File fileIn)
{
    import std.range: enumerate, dropOne;
    import std.algorithm: splitter, map, move, moveEmplace;
    import std.conv: to;

    // TODO: make reads immutable by default
    Read[] reads;
    reads.reserve(20_000);
    foreach (i, ref line; fileIn.byLine.enumerate)
    {
        // chr, start, stop, id
        auto cread = line.splitter('\t').map!(to!edge_t);
        cread.popFront;
        edge_t start = cread.front;
        cread.popFront;
        edge_t end = cread.front;
        cread.popFront;
        edge_t id = cread.front;
        auto r = new Read(start, end, id);
        // read is not-copyable, but moveable
         ++reads.length;
        move(r, reads[$-1]);
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
void outputReads(R)(R reads, File outFile)
{
    import std.algorithm : sort;

    // sorting required
    import std.traits : Unqual;

    Read[] ps = new Read[reads.length];
    foreach (i, ref r; reads)
        ps[i] = Read(r.start, r.end, r.id);

    ps.sort!(`a.id < b.id`);

    foreach (const ref r; ps)
        outFile.writeln(r.id);
}

unittest
{
    import std.algorithm: equal, map;
    import std.process: pipe;
    import std.range: array;

    const(Read)[] reads = [Read(10, 20, 0), Read(20, 30, 1), Read(30, 40, 3)];
    const(Read)[] constReads;
    foreach (ref r; reads)
        constReads ~= r;
    auto p = pipe();

    outputReads(constReads, p.writeEnd);
    p.writeEnd.close();

    auto output = p.readEnd.byLineCopy;
    assert(output.equal(["0", "1", "3"]));
}
