module pruner.graph;

struct TailEdge
{
    size_t capacity, cid;
}

/**
A very simple graph lib
*/
struct Graph(bool directed = true)
{
    import std.typecons;
    TailEdge[size_t][size_t] g;
    size_t cid = 0;

    void addEdge(size_t tail, size_t head, size_t capacity)
    {
        g[tail][head] = TailEdge(capacity, cid);
        static if (!directed)
            g[head][tail] = TailEdge(capacity, cid);

        cid++;
    }

    auto getEdgePairs(size_t v)
    {
        import std.array;
        return g[v].byPair;
    }

    TailEdge[] getEdgeTails(size_t v)
    {
        return g[v].values;
    }
}

alias Path = TailEdge[];



struct MaxFlow(Graph)
{
    import std.algorithm;
    Graph g;
    size_t[size_t] flow;
    size_t source, sink;

    this(ref Graph g, size_t source, size_t sink)
    {
        this.g = g;
        this.source = source;
        this.sink = sink;
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

    Path findPath(ref Graph g, size_t source, size_t sink, Path path)
    {
        if (source == sink)
            return path;
        foreach (edge; g.getEdgePairs(source))
        {
            int residual = edge[1].capacity - flow[edge];
            if (residual > 0 && !path.canFind(edge[1]))
            {
                auto result = findPath(g, edge[0], sink, path ~ [edge[1]]);
                if (result != null)
                    return result;
            }
        }
    }

    size_t maxFlow()
    {
        auto path = findPath(g, source, sink, []);
        while (path.length > 0)
        {
            auto flow = path.map!((x) => x.capacity - flow[x.cid]).minPos.front;
            foreach (edge; path)
            {
                this.flow[edge] += flow;
                this.flow[edge] -= flow;
            }
            path = findPath(g, source, sink, []);
        }
        return g.getEdgeTails(source).map!((x) => flow[x.cid]).sum;
    }
}

auto maxFlow(Graph)(ref Graph g, size_t source, size_t sink)
{
    auto f = MaxFlow!Graph(g);
    f.maxFlow();
    return 1;
}
