module pruner.graph;

import pruner.formats;
import std.stdio;

class TailEdge
{
    edge_t capacity, cid, reverse_cid;
    const(Read)* read;

    this(edge_t capacity, edge_t cid, edge_t reverse_cid, const(Read)* read = null)
    {
        this.capacity = capacity;
        this.cid = cid;
        this.reverse_cid = reverse_cid;
        this.read = read;
    }

    override bool opEquals(Object rhs) @safe const pure nothrow
    {
       return this.cid == (cast(TailEdge) rhs).cid;
    }

    override string toString()
    {
        import std.format: format;
        return format("(cap: %s, cid: %s%s)", capacity, cid, read is null ? "" : " read");
    }

}

/**
A very simple graph lib
TODO: needs serious restructure
*/
class Graph(bool directed = true)
{
    import std.typecons;
    import std.container.slist;
    import std.range;
    alias SingleEdge = TailEdge[][edge_t];
    SingleEdge[edge_t] g;

    // increasing id - using for simple & fast hashing
    edge_t cid = 0;
    TailEdge[edge_t] cid_hashed;

    TailEdge addEdge(edge_t tail, edge_t head)
    {
        return addEdge(tail, head, 0);
    }

    TailEdge addEdge(edge_t tail, edge_t head, edge_t capacity, const(Read)* read = null)
    {
        auto e = new TailEdge(capacity, cid, cid + 1, read);
        g[tail][head]  ~= e;
        cid_hashed[cid++] = e;

        // TODO: Ford-Fulkerson modification
        auto eBack = new TailEdge(0, cid, cid - 1, null);
        g[head][tail] ~= eBack;
        cid_hashed[cid++] = eBack;

        return e;
    }

    // by edges
    int opApply(int delegate(ref TailEdge) dg)
    {
        import std.stdio;
        foreach (ts; g.byValue)
            foreach (es; ts.byValue)
                foreach (ref e; es)
                    if(auto b = dg(e))
                        return b;
        return 0;
    }

    // by edges of a source v
    auto getEdgePairs(edge_t v)
    {
        struct EdgePairs
        {
            SingleEdge* t;

            int opApply(int delegate(edge_t t, ref TailEdge) dg)
            {
                import std.array: byPair;
                foreach(target, edges; (*t).byPair)
                    foreach (ref edge; edges)
                        if (auto b = dg(target, edge))
                            return b;
                return 0;
            }
        }
        return EdgePairs(&g[v]);
    }

    // connected edges to a source v
    auto getEdgeTails(edge_t v)
    {
        import std.experimental.ndslice;
        import pruner.flatten;
        return g[v].values.flatten;
    }

    auto getEdgeByCid(edge_t cid)
    {
        // TODO: exception handling?
        return cid_hashed[cid];
    }

    void print()
    {
        // TODO rewrite toString
        // TODO: use custom sink
        import std.array;
        import std.stdio;
        foreach (k,vs; g.byPair)
        {
            foreach(v,es; vs.byPair)
            {
                foreach(e,es; vs)
                    writefln("%2d-%2d: %d", k, v, e);
            }
        }
    }
}

alias DGraph = Graph!true;

alias Path = TailEdge[];

struct MaxFlow(Graph)
{
    import std.algorithm;
    Graph g;
    edge_t[edge_t] flow;

    this(ref Graph g)
    {
        this.g = g;
        init();
    }

    // TODO: is this necessary?
    void init()
    {
        // iterate over all edges
        foreach (e; g)
        {
            flow[e.cid] = 0;
        }
    }

    Path findPath(edge_t source, edge_t sink, Path path = [])
    {
        if (source == sink)
            return path;
        foreach (target, edge; g.getEdgePairs(source))
        {
            edge_t residual = edge.capacity - flow[edge.cid];
            if (residual > 0 && !path.canFind(edge))
            {
                auto result = findPath(target, sink, path ~ [edge]);
                if (result !is null)
                {
                    return result;
                }
            }
        }
        return null;
    }

    edge_t maxFlow(edge_t source, edge_t sink)
    {
        auto path = findPath(source, sink);
        while (path != null)
        {
            auto flow = path.map!((x) => x.capacity - flow[x.cid]).minPos.front;
            foreach (edge; path)
            {
                this.flow[edge.cid] += flow;
                this.flow[edge.reverse_cid] -= flow;
            }
            path = findPath(source, sink);
        }
        return g.getEdgeTails(source).map!((x) => flow[x.cid]).sum;
    }
}

unittest
{
    import std.typecons;
    import std.algorithm.comparison: equal;
    DGraph g = new DGraph();
    auto edges = [[0, 2], [0, 1], [1, 3]];
    foreach (edge; edges)
        g.addEdge(edge[0], edge[1], 3);

    auto m = new MaxFlow!DGraph(g);
    // TODO: tail edge format is quite hard to read & debug -> remove
    assert(m.findPath(0, 2) == [new TailEdge(3, 0, 1)]);
    assert(m.findPath(0, 3) == [new TailEdge(3, 2, 3), new TailEdge(3, 4, 5)]);
}

auto maxFlow(Graph)(auto ref Graph g, edge_t source, edge_t sink)
{
    import std.typecons;
    auto f = MaxFlow!Graph(g);
    auto val = f.maxFlow(source, sink);
    import std.stdio;
    return tuple!("max", "flow")(val, f);
}
