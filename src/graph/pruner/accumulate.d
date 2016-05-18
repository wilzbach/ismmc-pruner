module pruner.accumulate;

// will be in Phobos 2.072

import std.functional: binaryFun;
import std.range;
import std.typecons;
import std.traits;

private template ReduceSeedType(E)
{
    static template ReduceSeedType(alias fun)
    {
        import std.algorithm.internal : algoFormat;

        alias ReduceSeedType = Unqual!(typeof(fun(lvalueOf!E, lvalueOf!E)));

        //Check the Seed type is useable.
        ReduceSeedType s = ReduceSeedType.init;
        static assert(is(typeof({ReduceSeedType s = lvalueOf!E;})) &&
            is(typeof(lvalueOf!ReduceSeedType = fun(lvalueOf!ReduceSeedType, lvalueOf!E))),
            algoFormat(
                "Unable to deduce an acceptable seed type for %s with element type %s.",
                fullyQualifiedName!fun,
                E.stringof
            )
        );
    }
}

/++
Similar to `fold`, but returns a range containing the successive reduced values.
The call $(D cumulativeFold!(fun)(range, seed)) first assigns `seed` to an
internal variable `result`, also called the accumulator.
The returned range contains the values $(D result = fun(result, x)) lazily
evaluated for each element `x` in `range`. Finally, the last element has the
same value as $(D fold!(fun)(seed, range)).
The one-argument version $(D cumulativeFold!(fun)(range)) works similarly, but
it returns the first element unchanged and uses it as seed for the next
elements.
This function is also known as
    $(WEB en.cppreference.com/w/cpp/algorithm/partial_sum, partial_sum),
    $(WEB docs.python.org/3/library/itertools.html#itertools.accumulate, accumulate),
    $(WEB hackage.haskell.org/package/base-4.8.2.0/docs/Prelude.html#v:scanl, scan),
    $(WEB mathworld.wolfram.com/CumulativeSum.html, Cumulative Sum).
Returns:
    The function returns a range containing the consecutive reduced values. If
    there is more than one `fun`, the element type will be $(XREF typecons,
    Tuple) containing one element for each `fun`.
See_Also:
    $(WEB en.wikipedia.org/wiki/Prefix_sum, Prefix Sum)
+/
template cumulativeFold(fun...)
if (fun.length >= 1)
{
    import std.meta : staticMap;
    private alias binfuns = staticMap!(binaryFun, fun);

    /++
    No-seed version. The first element of `r` is used as the seed's value.
    For each function `f` in `fun`, the corresponding seed type `S` is
    $(D Unqual!(typeof(f(e, e)))), where `e` is an element of `r`:
    `ElementType!R`.
    Once `S` has been determined, then $(D S s = e;) and $(D s = f(s, e);) must
    both be legal.
    Params:
        fun = one or more functions
        range = an input range as defined by `isInputRange`
    Returns:
        a range containing the consecutive reduced values.
    +/
    auto cumulativeFold(R)(R range)
    if (isInputRange!(Unqual!R))
    {
        return cumulativeFoldImpl(range);
    }

    /++
    Seed version. The seed should be a single value if `fun` is a single
    function. If `fun` is multiple functions, then `seed` should be a $(XREF
    typecons, Tuple), with one field per function in `f`.
    For convenience, if the seed is const, or has qualified fields, then
    `cumulativeFold` will operate on an unqualified copy. If this happens
    then the returned type will not perfectly match `S`.
    Params:
        fun = one or more functions
        range = an input range as defined by `isInputRange`
        seed = the initial value of the accumulator
    Returns:
        a range containing the consecutive reduced values.
    +/
    auto cumulativeFold(R, S)(R range, S seed)
    if (isInputRange!(Unqual!R))
    {
        static if (fun.length == 1)
            return cumulativeFoldImpl(range, seed);
        else
            return cumulativeFoldImpl(range, seed.expand);
    }

    private auto cumulativeFoldImpl(R, Args...)(R range, ref Args args)
    {
        import std.algorithm.internal : algoFormat;

        static assert(Args.length == 0 || Args.length == fun.length,
            algoFormat("Seed %s does not have the correct amount of fields (should be %s)",
                Args.stringof, fun.length));

        static if (args.length)
            alias State = staticMap!(Unqual, Args);
        else
            alias State = staticMap!(ReduceSeedType!(ElementType!R), binfuns);

        foreach (i, f; binfuns)
        {
            static assert(!__traits(compiles, f(args[i], e)) || __traits(compiles,
                    { args[i] = f(args[i], e); }()),
                algoFormat("Incompatible function/seed/element: %s/%s/%s",
                    fullyQualifiedName!f, Args[i].stringof, E.stringof));
        }

        static struct Result
        {
        private:
            R source;
            State state;

            this(R range, ref Args args)
            {
                source = range;
                if (source.empty)
                    return;

                foreach (i, f; binfuns)
                {
                    static if (args.length)
                        state[i] = f(args[i], source.front);
                    else
                        state[i] = source.front;
                }
            }

        public:
            @property bool empty()
            {
                return source.empty;
            }

            @property auto front()
            {
                assert(!empty);
                static if (fun.length > 1)
                {
                    import std.typecons : tuple;
                    return tuple(state);
                }
                else
                {
                    return state[0];
                }
            }

            void popFront()
            {
                source.popFront;

                if (source.empty)
                    return;

                foreach (i, f; binfuns)
                    state[i] = f(state[i], source.front);
            }

            static if (isForwardRange!R)
            {
                @property auto save()
                {
                    auto result = this;
                    result.source = source.save;
                    return result;
                }
            }

            static if (hasLength!R)
            {
                @property size_t length()
                {
                    return source.length;
                }
            }
        }

        return Result(range, args);
    }
}

///
@safe unittest
{
    import std.algorithm.comparison : max, min;
    import std.array : array;
    import std.math : approxEqual;
    import std.range : chain;

    int[] arr = [1, 2, 3, 4, 5];
    // Partial sum of all elements
    auto sum = cumulativeFold!((a, b) => a + b)(arr, 0);
    assert(sum.array == [1, 3, 6, 10, 15]);

    // Partial sum again, using a string predicate with "a" and "b"
    auto sum2 = cumulativeFold!"a + b"(arr, 0);
    assert(sum2.array == [1, 3, 6, 10, 15]);

    // Compute the partial maximum of all elements
    auto largest = cumulativeFold!max(arr);
    assert(largest.array == [1, 2, 3, 4, 5]);

    // Partial max again, but with Uniform Function Call Syntax (UFCS)
    largest = arr.cumulativeFold!max;
    assert(largest.array == [1, 2, 3, 4, 5]);

    // Partial count of odd elements
    auto odds = arr.cumulativeFold!((a, b) => a + (b & 1))(0);
    assert(odds.array == [1, 1, 2, 2, 3]);

    // Compute the partial sum of squares
    auto ssquares = arr.cumulativeFold!((a, b) => a + b * b)(0);
    assert(ssquares.array == [1, 5, 14, 30, 55]);

    // Chain multiple ranges into seed
    int[] a = [3, 4];
    int[] b = [100];
    auto r = cumulativeFold!"a + b"(chain(a, b));
    assert(r.array == [3, 7, 107]);

    // Mixing convertible types is fair game, too
    double[] c = [2.5, 3.0];
    auto r1 = cumulativeFold!"a + b"(chain(a, b, c));
    assert(approxEqual(r1, [3, 7, 107, 109.5, 112.5]));

    // To minimize nesting of parentheses, Uniform Function Call Syntax can be used
    auto r2 = chain(a, b, c).cumulativeFold!"a + b";
    assert(approxEqual(r2, [3, 7, 107, 109.5, 112.5]));
}

/**
Sometimes it is very useful to compute multiple aggregates in one pass.
One advantage is that the computation is faster because the looping overhead
is shared. That's why `cumulativeFold` accepts multiple functions.
If two or more functions are passed, `cumulativeFold` returns a $(XREF typecons,
Tuple) object with one member per passed-in function.
The number of seeds must be correspondingly increased.
*/
@safe unittest
{
    import std.algorithm : map, max, min;
    import std.math : approxEqual;
    import std.typecons : tuple;

    double[] a = [3.0, 4, 7, 11, 3, 2, 5];
    // Compute minimum and maximum in one pass
    auto r = a.cumulativeFold!(min, max);
    // The type of r is Tuple!(int, int)
    assert(approxEqual(r.map!"a[0]", [3, 3, 3, 3, 3, 2, 2]));     // minimum
    assert(approxEqual(r.map!"a[1]", [3, 4, 7, 11, 11, 11, 11])); // maximum

    // Compute sum and sum of squares in one pass
    auto r2 = a.cumulativeFold!("a + b", "a + b * b")(tuple(0.0, 0.0));
    assert(approxEqual(r2.map!"a[0]", [3, 7, 14, 25, 28, 30, 35]));      // sum
    assert(approxEqual(r2.map!"a[1]", [9, 25, 74, 195, 204, 208, 233])); // sum of squares
}

unittest
{
    import std.algorithm : equal, map, max, min;
    import std.conv : to;
    import std.range : chain;
    import std.typecons : tuple;

    double[] a = [3, 4];
    auto r = a.cumulativeFold!("a + b")(0.0);
    assert(r.equal([3, 7]));
    auto r2 = cumulativeFold!("a + b")(a);
    assert(r2.equal([3, 7]));
    auto r3 = cumulativeFold!(min)(a);
    assert(r3.equal([3, 3]));
    double[] b = [100];
    auto r4 = cumulativeFold!("a + b")(chain(a, b));
    assert(r4.equal([3, 7, 107]));

    // two funs
    auto r5 = cumulativeFold!("a + b", "a - b")(a, tuple(0.0, 0.0));
    assert(r5.equal([tuple(3, -3), tuple(7, -7)]));
    auto r6 = cumulativeFold!("a + b", "a - b")(a);
    assert(r6.equal([tuple(3, 3), tuple(7, -1)]));

    a = [1, 2, 3, 4, 5];
    // Stringize with commas
    auto rep = cumulativeFold!("a ~ `, ` ~ to!string(b)")(a, "");
    assert(rep.map!"a[2 .. $]".equal(["1", "1, 2", "1, 2, 3", "1, 2, 3, 4", "1, 2, 3, 4, 5"]));

    // Test for empty range
    a = [];
    assert(a.cumulativeFold!"a + b".empty);
    assert(a.cumulativeFold!"a + b"(2.0).empty);
}

@safe unittest
{
    import std.algorithm.comparison : max, min;
    import std.array : array;
    import std.math : approxEqual;
    import std.typecons : tuple;

    const float a = 0.0;
    const float[] b = [1.2, 3, 3.3];
    float[] c = [1.2, 3, 3.3];

    auto r = cumulativeFold!"a + b"(b, a);
    assert(approxEqual(r, [1.2, 4.2, 7.5]));

    auto r2 = cumulativeFold!"a + b"(c, a);
    assert(approxEqual(r2, [1.2, 4.2, 7.5]));

    const numbers = [10, 30, 20];
    enum m = numbers.cumulativeFold!(min).array;
    assert(m == [10, 10, 10]);
    enum minmax = numbers.cumulativeFold!(min, max).array;
    assert(minmax == [tuple(10, 10), tuple(10, 30), tuple(10, 30)]);
}

@safe unittest
{
    import std.algorithm : map;
    import std.math : approxEqual;
    import std.typecons : tuple;

    enum foo = "a + 0.5 * b";
    auto r = [0, 1, 2, 3];
    auto r1 = r.cumulativeFold!foo;
    auto r2 = r.cumulativeFold!(foo, foo);
    assert(approxEqual(r1, [0, 0.5, 1.5, 3]));
    assert(approxEqual(r2.map!"a[0]", [0, 0.5, 1.5, 3]));
    assert(approxEqual(r2.map!"a[1]", [0, 0.5, 1.5, 3]));
}

@safe unittest
{
    import std.algorithm.comparison : equal, max, min;
    import std.array : array;
    import std.typecons : tuple;

    //Seed is tuple of const.
    static auto minmaxElement(alias F = min, alias G = max, R)(in R range)
        @safe pure nothrow if (isInputRange!R)
    {
        return range.cumulativeFold!(F, G)(tuple(ElementType!R.max, ElementType!R.min));
    }

    assert(minmaxElement([1, 2, 3]).equal([tuple(1, 1), tuple(1, 2), tuple(1, 3)]));
}

@safe unittest //12569
{
    import std.algorithm.comparison : equal, max, min;
    import std.typecons : tuple;

    dchar c = 'a';

    assert(cumulativeFold!(min, max)("hello", tuple(c, c)).equal([tuple('a', 'h'),
        tuple('a', 'h'), tuple('a', 'l'), tuple('a', 'l'), tuple('a', 'o')]));
    static assert(!__traits(compiles, cumulativeFold!(min, max)("hello", tuple(c))));
    static assert(!__traits(compiles, cumulativeFold!(min, max)("hello", tuple(c, c, c))));

    //"Seed dchar should be a Tuple"
    static assert(!__traits(compiles, cumulativeFold!(min, max)("hello", c)));
    //"Seed (dchar) does not have the correct amount of fields (should be 2)"
    static assert(!__traits(compiles, cumulativeFold!(min, max)("hello", tuple(c))));
    //"Seed (dchar, dchar, dchar) does not have the correct amount of fields (should be 2)"
    static assert(!__traits(compiles, cumulativeFold!(min, max)("hello", tuple(c, c, c))));
    //"Incompatable function/seed/element: all(alias pred = "a")/int/dchar"
    static assert(!__traits(compiles, cumulativeFold!all("hello", 1)));
    static assert(!__traits(compiles, cumulativeFold!(all, all)("hello", tuple(1, 1))));
}

@safe unittest //13304
{
    int[] data;
    assert(data.cumulativeFold!((a, b) => a + b).empty);
}

@safe unittest
{
    import std.algorithm.comparison : equal;
    import std.internal.test.dummyrange : AllDummyRanges, propagatesLength,
        propagatesRangeType, RangeType;

    foreach (DummyType; AllDummyRanges)
    {
        DummyType d;
        auto m = d.cumulativeFold!"a * b";

        static assert(propagatesLength!(typeof(m), DummyType));
        static if (DummyType.rt <= RangeType.Forward)
            static assert(propagatesRangeType!(typeof(m), DummyType));

        assert(m.equal([1, 2, 6, 24, 120, 720, 5040, 40320, 362880, 3628800]));
    }
}
