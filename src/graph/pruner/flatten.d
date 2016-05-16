module pruner.flatten;
import std.range;

/**
Reduces a range of ranges to a range
*/

struct Flatten(RoR)
{
    RoR r;
    alias EL = ElementType!(ElementType!RoR);

    this(RoR r)
    {
        this.r = r;
        skipEmpty();
    }

    private void skipEmpty()
    {
        while (!r.empty && r.front.empty)
        {
            r.popFront;
        }
    }

    @property EL front()
    {
        assert(!r.empty);
        return r.front.front;
    }

    void popFront()
    {
        assert(!r.empty);
        if (!r.front.empty)
            r.front.popFront;

        skipEmpty();
    }

    @property empty()
    {
        return r.empty;
    }

    typeof(this) save()
    {
        return typeof(this)(r.save);
    }
}

Flatten!RoR flatten(RoR)(RoR r)
{
    return Flatten!RoR(r);
}

unittest
{
    import std.range: iota;
    import std.algorithm.comparison: equal;
    assert([[0, 1, 2], [3, 4, 5]].flatten.equal(6.iota));
    assert([[], [0, 1, 2], []].flatten.equal(3.iota));
}
