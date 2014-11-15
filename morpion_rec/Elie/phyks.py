import random

class Escape(Exception):
    pass

def mark_random(playable_pos):
    something_marked = False
    while len(playable_pos) > 0:
        pos = random.sample(playable_pos, 1)
        playable_pos.remove(pos)

    if mark_pos(pos):
        something_marked = True
        break
    while not something_marked:
        if mark_pos((random.randint(0, 2), random.randint(0, 2))):
            something_marked = True

def play_next_subgrid(subgrid, my_marked_pos, his_marked_pos, mark_pos):
    winning_pos = elie.try_win(subgrid)
    if winning_pos is not None:
        mark_pos(winning_pos)
        return

    interesting_pos = set([(0, 0), (0, 2), (2, 0), (2, 2), (1, 1)])

    my_marked_interesting_pos = my_marked_pos.intersection(interesting_pos)
    his_marked_interesting_pos = his_marked_pos.intersection(interesting_pos)

    remaining_interesting_pos = (interesting_pos
                                .difference(my_marked_pos)
                                .difference(his_marked_pos))

    if remaining_interesting_pos == interesting_pos:
        playable_pos = interesting_pos.difference(set([(1, 1)]))
        pos = random.sample(playable_pos, 1)
        mark_pos(pos)
        return

    if len(my_marked_interesting_pos) == 1:
        # It should be a corner, then, try to mark the opposite corner
        if not mark_pos((2 - pos[0], 2 - pos[1])):
            playable_pos = remaining_interesting_pos.difference(set[(2 - pos[0], 2 - pos[1])])
            mark_random(playable_pos)
        return

    if len(my_marked_interesting_pos) >= 2:
        # If len is 2
        # It should be opposite corners
        # Try to play in the middle, or one of the other corners

        # If len is >= 3
        # If we are here, we can't win right now,
        # so keep playing interesting pos if possible.
        playable_pos = interesting_pos.difference(my_marked_interesting_pos)
        if not mark_pos((1, 1)):
            playable_pos.remove((1, 1))
            mark_random(playable_pos)
        return
