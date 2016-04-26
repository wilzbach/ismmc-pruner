#!/usr/bin/env python
# encoding: utf-8

from itertools import tee


def pairwise(iterable):
    """
    pairwise lazy iteration through a set
    will return n-1 pairs
    s -> (s0,s1), (s1,s2), (s2, s3), ...

    example:
    > [utils.pairwise([0,1,2,3])]
    [(0, 1), (1, 2), (2, 3)]
    """
    a, b = tee(iterable)
    next(b, None)
    return zip(a, b)
