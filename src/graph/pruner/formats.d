module pruner.formats;

alias edge_t = int;

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

bool equals()(auto ref const(Read)* a[], auto ref Read[] b)
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
