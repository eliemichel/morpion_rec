import sys
from itertools import product

debug = lambda msg: sys.stderr.write(msg + '\n')

def get_by_tuple(l, t):
	for i in t:
		l = l[i]
	return l

def set_by_tuple(l, t, v):
	for i in t[:-1]:
		l = l[i]
	l[t[-1]]

class Morpion:
	"""IA for recursive morpion"""
	def __init__(self, n=2):
		"""@param n: Number of recursive iterations"""
		self.iter = n
		self.grid = 0
		self.stack = []
		for k in range(self.iter*2):
			self.grid = [self.grid]*3

	def play(self, time):
		"""@param time: Remaining global play time"""
		coords = [range(3)]*self.iter*2
		for cell in product(*coords):
			if get_by_tuple(self.grid, cell) == 0:
				return cell

	def tic(self, cell):
		"""Play for local player
		@param cell: cell in which play"""
		if get_by_tuple(self.grid, cell) != 0:
			return False
		set_by_tuple(self.grid, cell, 1)
		return True

	def tac(self, cell):
		"""Play for remote player
		@param cell: cell in which play"""
		if get_by_tuple(self.grid, cell) != 0:
			return False
		set_by_tuple(self.grid, cell, -1)
		return True

	def win(self):
		pass

	def lose(self):
		pass

	def tie(self):
		pass

	def cheater(self):
		pass



class ProtocolError(Exception):
	def __init__(self, msg):
		self.msg = msg

def run(MorpionClass):
	while True:
		l = input()

		if l == "Hello morpion_rec":
			game = MorpionClass(2)
			print("Hello morpion_rec")

		if l[:9] == "Your turn":
			try:
				time = float(l[10:])
			except ValueError:
				raise ProtocolError('Unable to parse remainig time in %s' % (l,))

			cell = game.play(time)
			if not game.tic(cell):
				raise ProtocolError('Attempt to play in an occupied cell in %s' % (l,))
			print('Play %d %d %d %d' % cell)

			l = input()
			if l != 'OK':
				raise ProtocolError('Turn not acknowledged (received %s)' % (l,))

		if l[:4] == "Play":
			try:
				x1 = int(l[5:6])
				y1 = int(l[7:8])
				x2 = int(l[9:10])
				y2 = int(l[11:12])
			except ValueError:
				raise ProtocolError('Unable to parse played cell in %s' % (l,))

			if 0 <= x1 < 3 and 0 <= y1 < 3 and 0 <= x2 < 3 and 0 <= y2 < 3:
				if not game.tac((x1,y1,x2,y2)):
					raise ProtocolError('Attempt to play in an occupied cell in %s' % (l,))
			else:
				raise ProtocolError('Invalid cell coordinates in %s' % (l,))

		if l == "You win":
			game.win()

		if l == "You lose":
			game.lose()

		if l == "Tie":
			game.tie()

		if l == "Cheater!":
			game.cheater()

		if l == "quit":
			break

	debug("Good bye!")

if __name__ == '__main__':
	run(Morpion)
