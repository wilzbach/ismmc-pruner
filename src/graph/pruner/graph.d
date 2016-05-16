module pruner.graph;

import pruner.formats;

alias edge_t = int;

struct TailEdge
{
    edge_t capacity, cid, reverse_cid;
    const(Read)* read;
}

/**
A very simple graph lib
*/
struct Graph(bool directed = true)
{
    import std.typecons;
    TailEdge[edge_t][edge_t] g;
    edge_t cid = 0;

    void addEdge(edge_t tail, edge_t head)
    {
        addEdge(tail, head, 0);
    }

    void addEdge(edge_t tail, edge_t head, edge_t capacity, const(Read)* read = null)
    {
        g[tail][head] = TailEdge(capacity, cid, cid + 1, read);
        cid_hashed[cid++] = &g[tail][head];

        // TODO: Ford-Fulkerson modification
        g[head][tail] = TailEdge(0, cid, cid - 1);
        cid_hashed[cid++] = &g[head][tail];

    }

    void updateEdge(edge_t tail, edge_t head, edge_t capacity, const(Read)* read = null)
    {
        if (! (tail in g && head in g[tail]))
            addEdge(tail, head, capacity, read);
        g[tail][head].capacity = capacity;
    }

    auto getEdgePairs(edge_t v)
    {
        import std.array;
        return g[v].byPair;
    }

    TailEdge[] getEdgeTails(edge_t v)
    {
        return g[v].values;
    }

    TailEdge*[edge_t] cid_hashed;

    auto getEdgeByCid(edge_t cid)
    {
        TailEdge* e = null;
        return cid_hashed[cid];
    }

    void print()
    {
        // TODO rewrite toString
        import std.array;
        import std.stdio;
        foreach (k,vs; g.byPair)
        {
            foreach(v,e; vs.byPair)
            {
                writefln("%2d-%2d: %d", k, v, e.capacity);
            }
        }
    }
}

alias DGraph = Graph!true;
alias UGraph = Graph!true;

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

    void init()
    {
        import std.array;
        foreach (ts; g.g.byValue)
        {
            foreach(t; ts.byValue)
            {
                flow[t.cid] = 0;
            }
        }
    }

    Path findPath(edge_t source, edge_t sink, Path path = [])
    {
        if (source == sink)
            return path;
        foreach (tailEdge, ref edge; g.getEdgePairs(source))
        {
            edge_t residual = edge.capacity - flow[edge.cid];
            if (residual > 0 && !path.canFind(edge))
            {
                auto result = findPath(tailEdge, sink, path ~ [edge]);
                if (result != null)
                    return result;
            }
        }
        return null;
    }

    edge_t maxFlow(edge_t source, edge_t sink)
    {
        auto path = findPath(source, sink);
        import std.stdio;
        int n;
        while (path != null)
        {
            auto flow = path.map!((x) => x.capacity - flow[x.cid]).minPos.front;
            foreach (ref edge; path)
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
    DGraph g;
    auto edges = [[0, 2], [0, 1], [1, 3]];
    foreach (edge; edges)
        g.addEdge(edge[0], edge[1], 3);

    auto m = MaxFlow!DGraph(g);
    // TODO: tail edge format is quite hard to read & debug -> remove
    assert(m.findPath(0, 2) == [TailEdge(3, 0, 1)]);
    assert(m.findPath(0, 3) == [TailEdge(3, 2, 3), TailEdge(3, 4, 5)]);
}

auto maxFlow(Graph)(ref Graph g, edge_t source, edge_t sink)
{
    import std.typecons;
    auto f = MaxFlow!Graph(g);
    auto val = f.maxFlow(source, sink);
    return tuple!("max", "flow")(val, f);
}
