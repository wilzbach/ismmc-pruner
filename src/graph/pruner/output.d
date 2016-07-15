module pruner.output;

import pruner.graph;
import pruner.formats;
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

void printGraph(MaxFlow!DGraph flow, File output, string name = "MaxFlow graph")
{
    import std.process;
    import std.format: format;
    import std.conv: to;
    import std.array: byPair;
    import std.algorithm: map, max, joiner;
    import pruner.utils.algorithms : maxElement;

    auto pipes = pipeProcess(["dot", "-Teps"], Redirect.all);
    auto file = pipes.stdin;

    auto graph = flow.g;

    file.writefln(`digraph "%s" {`, name);
    file.writeln("rankdir = LR;");
    file.writeln("overlap = scalexy;");
    // global attributes
    // splines=ortho
    file.writeln("graph [nodesep=0.4, ranksep=0.4]");
    file.writeln(`node[fontsize=25, penwidth=1, shape="record"]`);
    file.writeln(`edge[fontsize=25, penwidth=1]`);

    // source & sink
    file.writeln(`-1 [label="s", shape="oval"];`);
    edge_t maxEdge = -1;
    foreach (vs; graph.g.values)
        maxEdge = max(maxEdge, maxElement(vs.keys));

    file.writeln(`%d [label="t", shape="oval"];`.format(maxEdge));
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
                    attrs["label"] = format("%d / %d", flow.flow[edge.cid], edge.capacity);
                    attrs["style"] = edge.read ? "solid" : "dashed";

                    if (flow.flow[edge.cid] == 0)
                    {
                        attrs["color"] = edge.read ? "red" : "grey";
                        attrs["fontcolor"] = edge.read ? "red" : "grey";
                    }

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
    {
        stderr.writeln("Compilation failed!");
        foreach (line; pipes.stderr.byLine)
            stderr.writeln(line);
    }

    // TODO: write directly to this file
    foreach (line; pipes.stdout.byLine)
        output.writeln(line);
}
