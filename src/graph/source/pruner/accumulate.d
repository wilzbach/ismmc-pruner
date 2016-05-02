module pruner.accumulate;

import std.range: ElementType;
private enum LastType {WITHIN, LAST, EMPTY};

/**
Accumulate the results of fold/reduce.
Instead of folding to one element, all intermediate result are returned too.

Params:
    r = range that should be accumulated
    seed = initial element of the accumulation
    fold = custom fold function

Returns:
    Accumulated range of all fold operations
*/
auto accumulate(alias fold = "a + b", Range, SeedType = ElementType!Range)(Range r, SeedType seed = SeedType.init)
{
    import std.functional: binaryFun;
    alias accumulateFun = binaryFun!fold;
    import std.range: isForwardRange, empty, popFront, front, save;

    static struct Accumulate
    {
        Range r;
        SeedType seed;
        LastType lastEl = LastType.WITHIN;

        ///
        this(Range r, SeedType seed)
        {
            this.seed = seed;
            this.r = r;
            if (!this.r.empty)
                this.popFront;
            else
                lastEl = LastType.LAST;
        }

        ///
        auto front()
        {
            return seed;
        }

        ///
        auto popFront()
        {
            with (LastType)
            final switch (lastEl)
            {
                case WITHIN:
                    seed = accumulateFun(seed, r.front);
                    r.popFront;
                    if (r.empty)
                        lastEl = LAST;
                    break;
                case LAST:
                    lastEl = EMPTY;
                    break;
                case EMPTY:
                    assert(0, "Popping an empty array");
            }
        }

        ///
        bool empty()
        {
            return lastEl == LastType.EMPTY;
        }

        static if (isForwardRange!Range)
        {
            ///
            typeof(this) save()
            {
                typeof(this) c = this;
                c.r = r.save;
                return c;
            }
        }
    }
    return Accumulate(r, seed);
}

///
unittest
{
    import std.algorithm: equal;
    assert([0, 1, 2, 3].accumulate.equal([0, 1, 3, 6]));

    import std.range: iota;
    import std.array: array;
    assert(iota(101).accumulate.array[$-1] == 5050);

    assert([1, 1, -1, -1].accumulate.equal([1, 2, 1, 0]));
}

unittest
{
    import std.range: dropOne;
    // save
    auto arr = [1, 1, -1, -1].accumulate;
    assert(arr.front == 1);
    assert(arr.dropOne.front == 2);
    assert(arr.front == 1);

    import std.algorithm: maxPos, minPos;
    assert(arr.maxPos.front == 2);
    assert(arr.minPos.front == 0);
}
