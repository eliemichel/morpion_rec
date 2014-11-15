import elie
import random
from utils import debug


class Escape(Exception):
    pass


def test_pos(subgrid, pos):
    x,y = pos
    return subgrid[x][y] == 0


def mark_random(preferred_pos, subgrid, morpion):
    debug("caca")
    something_marked = False
    checked = set()
    nice_pos = set()
    pos = None
    while len(preferred_pos) > 0:
        pos = random.sample(preferred_pos, 1)[0]
        checked.add(pos)
        preferred_pos.remove(pos)

        if test_pos(subgrid, pos):
            nice_pos.add(pos)
            if elie.check_next_win(morpion.grid, (morpion.last_x, morpion.last_y) + pos):
                something_marked = True
                return pos

    while not something_marked:
        if len(checked) == 9:
            break
        pos = (random.randint(0, 2), random.randint(0, 2))
        if pos in checked:
            continue
        checked.add(pos)
        if test_pos(subgrid, pos):
            nice_pos.add(pos)
            if elie.check_next_win(morpion.grid, (morpion.last_x, morpion.last_y) + pos):
                something_marked = True
                return pos

    if len(nice_pos) != 0:
        return random.sample(nice_pos, 1)[0]

    debug("pos:"+str(pos))
    debug("something_marked:"+str(something_marked))
    debug("cacabis")
    # Random in nice_pos
    return False


def play_next_subgrid(morpion, subgrid, my_marked_pos, his_marked_pos):
    debug("ok-1")
    winning_pos = elie.try_win(subgrid)
    if winning_pos is not None:
        if test_pos(subgrid, winning_pos):
            return winning_pos
        else:
            raise ValueError
    losing_pos = elie.try_win(subgrid, -1)
    if losing_pos is not None:
        if test_pos(subgrid, losing_pos):
            return losing_pos
        else:
            raise ValueError

    interesting_pos = set([(0, 0), (0, 2), (2, 0), (2, 2), (1, 1)])

    my_marked_pos = set(my_marked_pos)
    his_marked_pos = set(his_marked_pos)

    my_marked_interesting_pos = my_marked_pos.intersection(interesting_pos)
    his_marked_interesting_pos = his_marked_pos.intersection(interesting_pos)

    remaining_interesting_pos = (interesting_pos
                                 .difference(my_marked_pos, his_marked_pos))

    if len(my_marked_interesting_pos) == 0:
        playable_pos = interesting_pos.difference(set([(1, 1)]))
        debug("ok1")
        tried_random = mark_random(playable_pos, subgrid, morpion)
        if tried_random is False:
            return False
        else:
            return tried_random

    if len(my_marked_interesting_pos) == 1:
        # It should be a corner, then, try to mark the opposite corner
        pos = next(iter(my_marked_interesting_pos))
        debug("ok2")
        if(test_pos(subgrid, (2 - pos[0], 2 - pos[1])) is False or
           not elie.check_next_win(morpion.grid, (morpion.last_x, morpion.last_y, 2 - pos[0], 2 - pos[1]))):
            playable_pos = remaining_interesting_pos.difference(set([(2 - pos[0], 2 - pos[1])]))
            debug("ok2bis")
            tried_random = mark_random(playable_pos, subgrid, morpion)
            if tried_random is False:
                return False
            else:
                return tried_random
        debug((2 - pos[0], 2 - pos[1]))
        debug("ok2ter")
        return (2 - pos[0], 2 - pos[1])

    elif len(my_marked_interesting_pos) >= 2:
        # If len is 2
        # It should be opposite corners
        # Try to play in the middle, or one of the other corners

        # If len is >= 3
        # If we are here, we can't win right now,
        # so keep playing interesting pos if possible.
        playable_pos = interesting_pos.difference(my_marked_interesting_pos)
        debug("ok3")
        if(test_pos(subgrid, (1, 1)) is False or
           not elie.check_next_win(morpion.grid, (morpion.last_x, morpion.last_y, 1, 1))):
            try:
                playable_pos.remove((1, 1))
            except KeyError:
                pass
            debug("ok3bis")
            tried_random = mark_random(playable_pos, subgrid, morpion)
            debug("tried random:"+str(tried_random))
            if tried_random is False:
                return False
            else:
                return tried_random
        debug("debug ok3:"+str(test_pos(subgrid, (1, 1))))
        return (1, 1)
