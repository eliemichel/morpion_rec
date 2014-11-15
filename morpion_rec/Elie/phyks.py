import elie
import random
from utils import debug


class Escape(Exception):
    pass


def mark_random(preferred_pos, mark_pos):
    debug("caca")
    something_marked = False
    while len(preferred_pos) > 0:
        pos = random.sample(preferred_pos, 1)[0]
        preferred_pos.remove(pos)

    if mark_pos(pos):
        something_marked = True
    while not something_marked:
        if mark_pos((random.randint(0, 2), random.randint(0, 2))):
            something_marked = True


def play_next_subgrid(subgrid, my_marked_pos, his_marked_pos, mark_pos):
    debug("ok-1")
    winning_pos = elie.try_win(subgrid)
    if winning_pos is not None:
        mark_pos(winning_pos)
        return

    interesting_pos = set([(0, 0), (0, 2), (2, 0), (2, 2), (1, 1)])

    my_marked_pos = set(my_marked_pos)
    his_marked_pos = set(his_marked_pos)

    my_marked_interesting_pos = my_marked_pos.intersection(interesting_pos)
    his_marked_interesting_pos = his_marked_pos.intersection(interesting_pos)

    remaining_interesting_pos = (interesting_pos
                                 .difference(my_marked_pos, his_marked_pos))

    if len(my_marked_interesting_pos) == 0:
        playable_pos = interesting_pos.difference(set([(1, 1)]))
        mark_random(playable_pos, mark_pos)
        debug("ok1")
        return

    if len(my_marked_interesting_pos) == 1:
        # It should be a corner, then, try to mark the opposite corner
        pos = next(iter(my_marked_interesting_pos))
        debug("ok2")
        if not mark_pos((2 - pos[0], 2 - pos[1])):
            playable_pos = remaining_interesting_pos.difference(set[(2 - pos[0], 2 - pos[1])])
            mark_random(playable_pos, mark_pos)
            debug("ok3")
        return

    elif len(my_marked_interesting_pos) >= 2:
        # If len is 2
        # It should be opposite corners
        # Try to play in the middle, or one of the other corners

        # If len is >= 3
        # If we are here, we can't win right now,
        # so keep playing interesting pos if possible.
        playable_pos = interesting_pos.difference(my_marked_interesting_pos)
        debug("ok4")
        if not mark_pos((1, 1)):
            playable_pos.remove((1, 1))
            mark_random(playable_pos, mark_pos)
            debug("ok5")
        return
