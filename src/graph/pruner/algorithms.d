module pruner.algorithms;

import std.range;
import std.traits;
import std.functional;
import std.typecons;

// until D 2.072 is released

/**
Iterates the passed range and selects the extreme element with `less`.
If the extreme element occurs multiple time, the first occurrence will be
returned.
Params:
    map = custom accessor for the comparison key
    selector = custom mapping for the extrema selection
    seed = custom seed to use as initial element
    r = Range from which the extreme value will be selected
Returns:
    The extreme value according to `map` and `selector` of the passed-in values.
*/
private auto extremum(alias map = "a", alias selector = "a < b", Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range)
in
{
    assert(!r.empty, "r is an empty range");
}
body
{
    alias mapFun = unaryFun!map;
    alias Element = ElementType!Range;
    Unqual!Element seed = r.front;
    r.popFront();
    return extremum!(map, selector)(r, seed);
}

private auto extremum(alias map = "a", alias selector = "a < b", Range,
                      RangeElementType = ElementType!Range)
                     (Range r, RangeElementType seedElement)
    if (isInputRange!Range && !isInfinite!Range &&
        !is(CommonType!(ElementType!Range, RangeElementType) == void))
{
    alias mapFun = unaryFun!map;
    alias selectorFun = binaryFun!selector;

    alias Element = ElementType!Range;
    alias CommonElement = CommonType!(Element, RangeElementType);
    alias MapType = Unqual!(typeof(mapFun(CommonElement.init)));

    Unqual!CommonElement extremeElement = seedElement;
    MapType extremeElementMapped = mapFun(extremeElement);

    static if (isRandomAccessRange!Range && hasLength!Range)
    {
        foreach (const i; 0 .. r.length)
        {
            MapType mapElement = mapFun(r[i]);
            if (selectorFun(mapElement, extremeElementMapped))
            {
                extremeElement = r[i];
                extremeElementMapped = mapElement;
            }
        }
    }
    else
    {
        while (!r.empty)
        {
            MapType mapElement = mapFun(r.front);
            if (selectorFun(mapElement, extremeElementMapped))
            {
                extremeElement = r.front;
                extremeElementMapped = mapElement;
            }
            r.popFront();
        }
    }
    return extremeElement;
}

@safe pure nothrow unittest
{
    // allows a custom map to select the extremum
    assert([[0, 4], [1, 2]].extremum!"a[0]" == [0, 4]);
    assert([[0, 4], [1, 2]].extremum!"a[1]" == [1, 2]);

    // allows a custom selector for comparison
    assert([[0, 4], [1, 2]].extremum!("a[0]", "a > b") == [1, 2]);
    assert([[0, 4], [1, 2]].extremum!("a[1]", "a > b") == [0, 4]);
}

@safe pure nothrow unittest
{
    // allow seeds
    int[] arr;
    assert(arr.extremum(1) == 1);

    int[][] arr2d;
    assert(arr2d.extremum([1]) == [1]);

    // allow seeds of different types (implicit casting)
    assert(extremum([2, 3, 4], 1.5) == 1.5);
}

/**
Iterates the passed range and returns the minimal element.
A custom mapping function can be passed to `map`.
Complexity: O(n)
    Exactly `n - 1` comparisons are needed.
Params:
    map = custom accessor for the comparison key
    r = range from which the minimal element will be selected
    seed = custom seed to use as initial element
Returns: The minimal element of the passed-in range.
See_Also:
    $(XREF algorithm, comparison, min)
*/
auto minElement(alias map = "a", Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range)
{
    return extremum!map(r);
}

/// ditto
auto minElement(alias map = "a", Range, RangeElementType = ElementType!Range)
               (Range r, RangeElementType seed)
    if (isInputRange!Range && !isInfinite!Range &&
        !is(CommonType!(ElementType!Range, RangeElementType) == void))
{
    return extremum!map(r, seed);
}

///
@safe pure unittest
{
    import std.range: enumerate;

    assert([2, 1, 4, 3].minElement == 1);

    // allows to get the index of an element too
    assert([5, 3, 7, 9].enumerate.minElement!"a.value" == tuple(1, 3));

    // any custom accessor can be passed
    assert([[0, 4], [1, 2]].minElement!"a[1]" == [1, 2]);

    // can be seeded
    int[] arr;
    assert(arr.minElement(1) == 1);
}

@safe pure unittest
{
    import std.range: enumerate, iota;
    // supports mapping
    assert([3, 4, 5, 1, 2].enumerate.minElement!"a.value" == tuple(3, 1));
    assert([5, 2, 4].enumerate.minElement!"a.value" == tuple(1, 2));

    // forward ranges
    assert(iota(1, 5).minElement() == 1);
    assert(iota(2, 5).enumerate.minElement!"a.value" == tuple(0, 2));

    // should work with const
    const(int)[] immArr = [2, 1, 3];
    assert(immArr.minElement == 1);

    // should work with immutable
    immutable(int)[] immArr2 = [2, 1, 3];
    assert(immArr2.minElement == 1);

    // with strings
    assert(["b", "a", "c"].minElement == "a");

    // with all dummy ranges
    import std.internal.test.dummyrange;
    foreach (DummyType; AllDummyRanges)
    {
        DummyType d;
        assert(d.minElement == 1);
    }
}

@nogc @safe nothrow pure unittest
{
    static immutable arr = [7, 3, 4, 2, 1, 8];
    assert(arr.minElement == 1);

    static immutable arr2d = [[1, 9], [3, 1], [4, 2]];
    assert(arr2d.minElement!"a[1]" == arr2d[1]);
}

/**
Iterates the passed range and returns the maximal element.
A custom mapping function can be passed to `map`.
Complexity:
    Exactly `n - 1` comparisons are needed.
Params:
    map = custom accessor for the comparison key
    r = range from which the maximum will be selected
    seed = custom seed to use as initial element
Returns: The maximal element of the passed-in range.
See_Also:
    $(XREF algorithm, comparison, max)
*/
auto maxElement(alias map = "a", Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range &&
        !is(CommonType!(ElementType!Range, RangeElementType) == void))
{
    return extremum!(map, "a > b")(r);
}

/// ditto
auto maxElement(alias map = "a", Range, RangeElementType = ElementType!Range)
               (Range r, RangeElementType seed)
    if (isInputRange!Range && !isInfinite!Range)
{
    return extremum!(map, "a > b")(r, seed);
}

///
@safe pure unittest
{
    import std.range: enumerate;
    assert([2, 1, 4, 3].maxElement == 4);

    // allows to get the index of an element too
    assert([2, 1, 4, 3].enumerate.maxElement!"a.value" == tuple(2, 4));

    // any custom accessor can be passed
    assert([[0, 4], [1, 2]].maxElement!"a[1]" == [0, 4]);

    // can be seeded
    int[] arr;
    assert(arr.minElement(1) == 1);
}

@safe pure unittest
{
    import std.range: enumerate, iota;

    // supports mapping
    assert([3, 4, 5, 1, 2].enumerate.maxElement!"a.value" == tuple(2, 5));
    assert([5, 2, 4].enumerate.maxElement!"a.value" == tuple(0, 5));

    // forward ranges
    assert(iota(1, 5).maxElement() == 4);
    assert(iota(2, 5).enumerate.maxElement!"a.value" == tuple(2, 4));
    assert(iota(4, 14).enumerate.maxElement!"a.value" == tuple(9, 13));

    // should work with const
    const(int)[] immArr = [2, 3, 1];
    assert(immArr.maxElement == 3);

    // should work with immutable
    immutable(int)[] immArr2 = [2, 3, 1];
    assert(immArr2.maxElement == 3);

    // with strings
    assert(["a", "c", "b"].maxElement == "c");

    // with all dummy ranges
    import std.internal.test.dummyrange;
    foreach (DummyType; AllDummyRanges)
    {
        DummyType d;
        assert(d.maxElement == 10);
    }
}

@nogc @safe nothrow pure unittest
{
    static immutable arr = [7, 3, 8, 2, 1, 4];
    assert(arr.maxElement == 8);

    static immutable arr2d = [[1, 3], [3, 9], [4, 2]];
    assert(arr2d.maxElement!"a[1]" == arr2d[1]);
}
