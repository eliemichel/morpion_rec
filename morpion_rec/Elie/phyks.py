import elie
import random
from utils import debug


class Escape(Exception):
    pass


def mark_random(preferred_pos, test_pos):
    debug("caca")
    something_marked = False
    checked = set()
    pos = None
    while len(preferred_pos) > 0:
        pos = random.sample(preferred_pos, 1)[0]
        checked.add(pos)
        preferred_pos.remove(pos)

        if test_pos(pos):
            something_marked = True
            return pos

    while not something_marked:
        if len(checked) == 9:
            break
        pos = (random.randint(0, 2), random.randint(0, 2))
        if pos in checked:
            continue
        checked.add(pos)
        if test_pos(pos):
            something_marked = True
            return pos

    debug("pos:"+str(pos))
    debug("something_marked:"+str(something_marked))
    debug("cacabis")
    return False


def play_next_subgrid(subgrid, my_marked_pos, his_marked_pos, test_pos):
    debug("ok-1")
    winning_pos = elie.try_win(subgrid)
    if winning_pos is not None:
        if test_pos(winning_pos):
            return winning_pos
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
        tried_random = mark_random(playable_pos, test_pos)
        if tried_random is False:
            return False
        else:
            return tried_random

    if len(my_marked_interesting_pos) == 1:
        # It should be a corner, then, try to mark the opposite corner
        pos = next(iter(my_marked_interesting_pos))
        debug("ok2")
        if not test_pos((2 - pos[0], 2 - pos[1])):
            playable_pos = remaining_interesting_pos.difference(set([(2 - pos[0], 2 - pos[1])]))
            debug("ok2bis")
            tried_random = mark_random(playable_pos, test_pos)
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
        if test_pos((1, 1)) is False:
            playable_pos.remove((1, 1))
            debug("ok3bis")
            tried_random = mark_random(playable_pos, test_pos)
            if tried_random is False:
                return False
            else:
                return tried_random
        return (1, 1)
