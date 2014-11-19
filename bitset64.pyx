"""
This module contains cython functions for making int64 work like a set.
"""
from math import log

#from cpython cimport map
#from array import array

#cdef array.array a = array('L', [1,2,3])
#print(a)

cpdef long subtract(long self, long other):
    return self - (self & other)


cpdef int ffs(long v):
    return int(log(v, 2))
    #return __builtin_ffs(b);


def iterate(long n):
    cdef long b
    while n:
        b = n & (~n + 1)
        yield b
        n ^= b


cpdef int length(long self):
    cdef result = 0
    for _ in iterate(self):
        result += 1
    return result


cpdef long join(args):
    cdef long v, result = 0
    for v in args:
        result |= v
    return result



def tostring(self):
    return 'BitSet{{{}}}'.format(', '.join(str(ffs(v)) for v in iterate(self)))


def subsets(long self, int minsize=0, int maxsize=-1):
    """Yield subbitsets from specified size ordered by size ascending."""
    if minsize < 0:
        minsize = length(self) + 1 + minsize
    if maxsize < 0:
        maxsize = length(self) + 1 + maxsize

    sets = [0L]
    for v in iterate(self):
        sets.extend([s | v for s in sets])

    return [s for s in sets if length(s) >= minsize and length(s) <= maxsize]

