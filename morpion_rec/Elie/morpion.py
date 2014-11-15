import phyks
import elie
from itertools import product
from utils import *


class Morpion:
    """IA for recursive morpion"""
    def __init__(self):
        self.last_x = 1
        self.last_y = 1
        self.grid = [[[[0, 0, 0], [0, 0, 0], [0, 0, 0]], [[0, 0, 0], [0, 0, 0], [0, 0, 0]], [[0, 0, 0], [0, 0, 0], [0, 0, 0]]], [[[0, 0, 0], [0, 0, 0], [0, 0, 0]], [[0, 0, 0], [0, 0, 0], [0, 0, 0]], [[0, 0, 0], [0, 0, 0], [0, 0, 0]]], [[[0, 0, 0], [0, 0, 0], [0, 0, 0]], [[0, 0, 0], [0, 0, 0], [0, 0, 0]], [[0, 0, 0], [0, 0, 0], [0, 0, 0]]]]

    def play(self, time):
        """Determine where to play
        @param time: Remaining global play time
        @return (x1, y1, x2, y2)"""
        print_grid(self.grid)
        subgrid = self.grid[self.last_x][self.last_y]
        new_x = 0
        new_y = 0
        def mark_pos(p):
            x,y = p
            if subgrid[x][y] != 0:
                return False
            new_x = x
            new_y = y
            return True

        my = [(x,y) for (x,y) in product(range(3), range(3)) if subgrid[x][y] == 1]
        his = [(x,y) for (x,y) in product(range(3), range(3)) if subgrid[x][y] == -1]

        phyks.play_next_subgrid(subgrid, my, his, mark_pos)
        cell = self.last_x, self.last_y, new_x, new_y

        debug("elie.check_next_win(self.grid, cell): " + str(elie.check_next_win(self.grid, cell)))

        return cell



    def tic(self, cell):
        """Play for local player
        @param cell: cell in which play"""
        if get_by_tuple(self.grid, cell) != 0:
            return False
        self.last_x = cell[2]
        self.last_y = cell[3]
        set_by_tuple(self.grid, cell, 1)
        return True

    def tac(self, cell):
        """Play for remote player
        @param cell: cell in which play"""
        if get_by_tuple(self.grid, cell) != 0:
            return False
        self.last_x = cell[2]
        self.last_y = cell[3]
        set_by_tuple(self.grid, cell, -1)
        return True

    def win(self):
        print("Fair enough")

    def lose(self):
        print("Fair enough")

    def tie(self):
        print("Fair enough")

    def cheater(self):
        print("Fair enough")



class ProtocolError(Exception):
    def __init__(self, msg):
        self.msg = msg

def run(MorpionClass):
    while True:
        l = input()

        if l == "Hello morpion_rec":
            game = MorpionClass()
            print("Hello morpion_rec")

        if l[:9] == "Your turn":
            try:
                time = float(l[10:])
            except ValueError:
                raise ProtocolError('Unable to parse remainig time in %s' % (l,))

            cell = game.play(time)
            if not game.tic(cell):
                raise ProtocolError('Attempt to play in an occupied cell in %s' % (l,))
            a,b,c,d = cell
            print('Play %d %d %d %d' % (a+1,b+1,c+1,d+1))

            l = input()
            if l != 'OK':
                raise ProtocolError('Turn not acknowledged (received %s)' % (l,))

        if l[:4] == "Play":
            try:
                x1 = int(l[5:6]) - 1
                y1 = int(l[7:8]) - 1
                x2 = int(l[9:10]) - 1
                y2 = int(l[11:12]) - 1
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
