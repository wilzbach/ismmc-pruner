module pruner.formats;

alias edge_t = long;

// TODO: maybe better to use a class?
class Read
{
    //uint chr; not needed atm

    // TODO: doubled security is probably unneeded
    // passing around const objects should be enough
    immutable edge_t start;
    immutable edge_t end;
    size_t id;

    this(edge_t start, edge_t end, size_t id = 0)
    {
        this.start = start;
        this.end = end;
        this.id = id;
    }

    static Read opCall(edge_t start, edge_t end, size_t id = 0)
    {
        return new Read(start, end, id);
    }

    override bool opEquals(Object o) const
    {
        if (auto r = cast(Read) o)
            return start == r.start && end == r.end && id == r.id;
        return false;
    }

    override string toString() const
    {
        import std.format: format;
        return format("(s: %d, t: %d, id: %d)", start, end, id);
    }
}

bool contains()(const(Read)[] reads, const Read r)
{
    foreach (read; reads)
        if (read.start == r.start && read.end == r.end)
            return true;

    return false;
}

unittest
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10)];
    const(Read)[] constReads = [reads[0], reads[2]];
    assert(constReads.contains(reads[0]));
    assert(!constReads.contains(reads[1]));

    assert(constReads.contains(Read(0, 8)));
    assert(!constReads.contains(Read(0, 9)));
}
