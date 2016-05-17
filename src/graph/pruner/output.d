module pruner.output;

import pruner.graph;
import std.stdio;

void printFlow(MaxFlow!DGraph flow, edge_t source, bool[size_t] seen, size_t indent = 0)
{
    import std.range: repeat;
    foreach (target, edge; flow.g.getEdgePairs(source))
    {
        if (source < target && edge.cid !in seen)
        {
            seen[edge.cid] = true;
            string isRead = edge.read ? " read" : "";
            writefln("%s%2d-%2d: (cap: %s, flow: %d, cid: %s)%s", ' '.repeat(indent), source, target, edge.capacity, flow.flow[edge.cid], edge.cid, isRead);
            printFlow(flow, target, seen, indent + 2);
        }
    }

}

string uniqueTempPath()
{
    import std.file, std.uuid;
    import std.path: buildPath;
    return buildPath(tempDir(), randomUUID().toString());
}

void printGraph(DGraph graph, MaxFlow!DGraph flow, File output, string name = "MaxFlow graph")
{
    import std.process;
    import std.format: format;
    import std.conv: to;
    import std.array: byPair;
    import std.algorithm: map, joiner;
    //auto tmpFile = uniqueTempPath();
    auto pipes = pipeProcess(["dot", "-Tps"], Redirect.all);
    auto file = pipes.stdin;

    file.writefln("digraph %s {", name);
    file.writeln("rankdir = LR;");
    {
        void printEdge(edge_t source, bool[size_t] seen)
        {
            foreach (target, edge; graph.getEdgePairs(source))
            {
                if (source < target && edge.cid !in seen)
                {
                    seen[edge.cid] = true;

                    // edge label properties
                    string[string] attrs;
                    attrs["label"] = to!string(flow.flow[edge.cid]);
                    //attrs["color"] = edge.read ? "red" : "grey";
                    attrs["style"] = edge.read ? "solid" : "dashed";

                    // convert labels to string
                    auto attrsStr = attrs.byPair.map!((t) => format(`%s = "%s"`, t[0], t[1])).joiner(",");

                    file.writefln(`%s -> %s [%s];`, source, target, attrsStr);
                    printEdge(target, seen);
                }
            }
        }
        printEdge(-1, [-2: true]);
    }
    file.writeln("}");
    file.close();

    if (wait(pipes.pid) != 0)
        writeln("Compilation failed!");

    // TODO: write directly to this file
    foreach (line; pipes.stdout.byLine)
        output.writeln(line);
}
