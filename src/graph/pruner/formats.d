module pruner.formats;

alias edge_t = int;

// TODO: maybe better to use a class?
struct Read
{
    //uint chr; not needed atm

// HACK/TODO: having an immutable(Read)[] is not allowed
    immutable uint start;
    immutable uint end;
    size_t id;

    // prevent accidental copies
    // TODO: this makes it a non-copyable type, however it is a pain to work with
    // because most algorithms do automatic copies
    @disable this(this);
}

// TODO: if we would be able to do copies, this should be easier
bool equals(const(Read)*[] a, Read[] b)
{
    import std.range: empty, front, popFront;
    while (!a.empty)
    {
        if (b.empty) return false;
        if (*a.front != b.front) return false;
        a.popFront;
        b.popFront;
    }
    if (!b.empty) return false;
    return true;
}

unittest
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 10)];

    const(Read)*[] constReads = [&reads[0], &reads[2]];
    assert(!constReads.equals(reads));

    const(Read)*[] constReadsEqual = [&reads[0], &reads[1], &reads[2]];
    assert(constReadsEqual.equals(reads));
}

bool contains(const(Read)*[] reads, ref Read r)
{
    foreach (read; reads)
        if ((*read).start == r.start && (*read).end == r.end)
            return true;

    return false;
}

unittest
{
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10)];
    const(Read)*[] constReads = [&reads[0], &reads[2]];
    assert(constReads.contains(reads[0]));
    assert(!constReads.contains(reads[1]));
}
