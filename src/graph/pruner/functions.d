module pruner.functions;

import pruner.formats;
import std.experimental.logger;

struct CovTuple
{
    int index;
    int cov;
    Read read;

    string toString()
    {
        import std.format: format;
        if (read !is null)
            return format("(i: %d, cov: %d, {%d-%d})", index, cov, read.start, read.end);
        else
            return format("(i: %d, cov: %d)", index, cov);
    }
}

auto accumulateCov(Read[] reads)
{
    import std.algorithm: sort, map;
    import std.range: array;
    import std.typecons: Tuple;
    import pruner.accumulate;

    // TODO: use a heap
    CovTuple[] positions;
    foreach (read; reads)
    {
        // + 0 works around the fact that a.start is immutable
        positions ~= CovTuple(read.start + 0, 1, read);
        positions ~= CovTuple(read.end + 0, -1, null);
    }

    positions = positions
                .sort!`a.index < b.index || (a.index == b.index) && a.cov < b.cov`()
                .release;

    auto b = positions.cumulativeFold!((a, b) => CovTuple(b.index, a.cov + b.cov, b.read))
                        (CovTuple(-42, 0));
    return b;
}

unittest
{
    import pruner.algorithms: maxElement;
    auto reads = [Read(0, 8), Read(0, 2), Read(1, 3), Read(1, 10),
                  Read(2, 6), Read(4, 10)];

    import std.array: array;
    auto acc = reads.accumulateCov.array;
    assert(acc.maxElement!`a.cov`.cov == 4);
    // first element has by definition coverage of 1
    assert(acc[0].cov == 1);
    // last element has by definition coverage of 0
    assert(acc[$-1].cov == 0);
}

unittest
{
    import pruner.algorithms;
    auto reads = [Read(0, 8), Read(10, 12)];
    assert(reads.accumulateCov.maxElement!`a.cov`.cov == 1);
    assert(reads.accumulateCov.minElement!`a.cov`.cov == 0);
}

// TODO: refactor to use Fibers
auto breakPoints(Read[] reads)
{
    alias AccumulateReads = typeof(reads.accumulateCov);
    struct BreakPoint
    {
        AccumulateReads acc;
        Read _front;

        this(AccumulateReads acc)
        {
            this.acc = acc;
            _init();
        }

        @property bool empty()
        {
            return acc.empty || _front is null;
        }

        // searchs for the next read
        // sets invalid state if no read is found
        private void _init()
        {
            // TODO: this is really ugly
            while (!acc.empty)
            {
                if (acc.front.cov == 0)
                {
                    acc.popFront;
                    break;
                } else if (acc.front.read !is null)
                {
                    _front = acc.front.read;
                    acc.popFront;
                    break;
                }
                else
                {
                    acc.popFront;
                }
            }
        }
        @property Read front()
        {
            return _front;
        }

        void popFront()
        {
            assert(!empty);
            _front  = null;
            _init();
        }

        // critical to avoid accidental copies of the acc range
        @disable this(this);
    }

    // proxy that allows nested iterations
    struct BreakPoints
    {
        BreakPoint _front;

        this(Read[] reads)
        {
            _front = BreakPoint(reads.accumulateCov());
        }

        ref BreakPoint front()
        {
            return _front;
        }

        bool empty()
        {
            return _front.acc.empty && _front._front is null;
        }

        void popFront()
        {
            // TODO: avoid popFront being called on empty range
            // PROBLEM: BreakPoint empties the range
            //assert(!empty);
            _front._front = null;
            _front._init();
        }
    }
    import std.range.primitives: isInputRange;
    static assert(isInputRange!(BreakPoint));
    return BreakPoints(reads);
}

unittest
{
    auto reads = [Read(0, 8), Read(10, 12)];

    auto bPs = reads.breakPoints;
    ref firstComponent(){ return bPs.front; };
    assert(firstComponent.front == Read(0, 8));
    firstComponent.popFront();
    assert(firstComponent.empty);

    bPs.popFront();
    assert(!bPs.empty);

    ref secondComponent(){ return bPs.front; };
    assert(secondComponent.front == Read(10, 12));

    bPs.popFront();
    assert(bPs.empty);
}

unittest
{
    auto reads = [Read(0, 8), Read(4, 11), Read(10, 12)];
    auto bPs = reads.breakPoints;
    import std.range: walkLength;
    int c = 0;
    // manual loop
    while (!bPs.front.empty)
    {
        assert(bPs.front.front == reads[c++]);
        bPs.front.popFront();
    }
    assert(c == 3);

    bPs.popFront();
    assert(bPs.empty);
}
