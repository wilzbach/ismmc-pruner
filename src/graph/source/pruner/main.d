import pruner.formats;

void main(string[] args)
{
    import std.stdio;
    import std.conv;
    import std.typecons;
    import std.algorithm;
    import std.range;
    alias ChrRead = Tuple!(uint, "chr", uint, "start", uint, "stop", uint, "id");
    foreach (i, ref line; stdin.byLine.enumerate)
    {
        // chr, start, stop, id
        auto cread = line.splitter(" ").map!(to!uint);
        if (i % 2 != 0)
            writeln(i);
    }
}
