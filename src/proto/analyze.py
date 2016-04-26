
def findMinMaxCov(reads):
    """
        TODO: more efficient sorting
        Finds the minimum and maximum coverage given reads
        returns (min_cov, max_cov)
    """

    # attention: sorting required O(n * log n)
    start, end = list(zip(*reads))
    # start and end need to be sorted
    start = list(sorted(start))
    end = list(sorted(end))

    start_i, end_i = (0, 0)
    max_cov = 0
    min_cov = len(start)
    c = 0
    while start_i < len(start) and end_i < len(end):
        if len(start) == start_i:
            # for starts we can reach the end of the array
            next_start = -1
        else:
            next_start = start[start_i]

        next_end = end[end_i]

        # either increment or decrement counter
        if next_start <= next_end or next_start == -1:
            c += 1
            start_i += 1
        else:
            c -= 1
            end_i += 1

        if next_start > 0:
            print(c)
            # skip the start
            max_cov = max(c, max_cov)
            min_cov = min(c, min_cov)

    return min_cov, max_cov
