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


def print_grid(grid):
	for l in range(3):
		for j in range(3):
			s = ''
			for k in range(3):
				s += '|'.join([['x',' ','o'][grid[k][l][i][j]+1] for i in range(3)])
				if k != 2:
					s += ' || '
			debug(s)
			if j != 2:
				debug('----- || ----- || -----')
		if l != 2:
			debug('-----------------------')
			debug('-----------------------')


