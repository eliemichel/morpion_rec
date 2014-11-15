import sys

debug = lambda msg: sys.stderr.write(str(msg) + '\n')

def get_by_tuple(l, t):
    for i in t:
        l = l[i]
    return l

def set_by_tuple(l, t, v):
    debug(l)
    for i in t[:-1]:
        l = l[i]
    l[t[-1]] = v
