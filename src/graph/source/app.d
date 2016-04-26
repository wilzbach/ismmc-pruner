import std.stdio;
import pruner.formats;
import pruner.graph;

void maxFlowOpt(Read[] reads, uint maxReadsPerPos, uint minReadsPerPos)
{
    import std.algorithm;
    import std.range;

    auto positions = reads.map!`a.start`.chain(reads.map!`a.end`).array.sort().release;
    auto backboneCapacity = maxReadsPerPos - minReadsPerPos;
    auto sourceSinkCapacity = maxReadsPerPos;
    auto readIntervalCapacity = 1;
    auto superSource = -1;
    auto superSink = positions[$-1] + 1;

    Graph!true g;

    // add backbone
    g.addEdge(superSource, positions[0], sourceSinkCapacity);
    g.addEdge(positions[$-1], superSink, sourceSinkCapacity);
    foreach (p0, p1; zip(positions, positions.save.dropOne))
        g.addEdge(p0, p1, backboneCapacity);

    // add intervals
    foreach (read; reads)
        g.addEdge(read.start, read.end, readIntervalCapacity);

    auto m = g.maxFlow(superSource, superSink);
    import std.stdio;
    writeln(m);
}

void main()
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10)];
    maxFlowOpt(reads, 3, 1);
}
