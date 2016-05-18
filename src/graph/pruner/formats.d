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
    @disable this(this);
}

bool equals()(const(Read)*[] a, Read[] b)
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
