/* IA pour morpion récursif - Alexis
 * ia.h
 * Définitions des fonctions nécéssaires à l'intelligence artificielle */

#ifndef IA_H
#define IA_H

#include "main.h"

Dots chooseFirstSubgrid();
Dots chooseFirstMove();
int pickUpMove(Dots grid[9][9], Boxes subgrid, Dots player, Boxes *move, Boxes firstSubgrid);

#endif

