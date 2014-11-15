from utils import *


def try_win_line(line, player=1):
	if line.count(player) == 2 and line.count(0) == 1:
		for i in range(3):
			if line[i] == 0:
				return i
	else:
		return None

def try_win(subgrid, player=1):
	for j in range(3):
		i = try_win_line([subgrid[j][i] for i in range(3)], player)
		if i is not None:
			return j, i

		i = try_win_line([subgrid[i][j] for i in range(3)], player)
		if i is not None:
			return i, j

	i = try_win_line([subgrid[i][i] for i in range(3)], player)
	if i is not None:
		return i, i

	i = try_win_line([subgrid[i][2-i] for i in range(3)], player)
	if i is not None:
		return i, 2-i

	return None

"""
def win(subgrid, player=-1):
	
	s = 0
	for j in range(3):
		if [subgrid[j][i] for i in range(3)].count(player) == 3:
			return True

		if [subgrid[i][j] for i in range(3)].count(player) == 3:
			s += 1

	i = [subgrid[i][i] for i in range(3)].count(player) == 3:
	if i is not None:
		return i, i

	i = try_win_line([subgrid[i][2-i] for i in range(3)], player)
	if i is not None:
		return i, 2-i

	return None
"""


def check_next_win(grid, cell):
	x1, y1, x2, y2 = cell

	subgrid = grid[x2][y2]

	return try_win(subgrid, -1) is None


