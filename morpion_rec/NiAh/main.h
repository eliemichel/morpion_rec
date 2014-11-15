/* IA pour morpion récursif - Alexis 
 * main.h
 * Définition des énumérations, typedef et autres */

#ifndef MAIN_H
#define MAIN_H

typedef enum {FREE, CROSS, CIRCLE} Dots;
typedef enum {I=0, II=1, III=2, IV = 3, V=4, VI=5, VII=6, VIII=7, IX=8, Z=-1} Boxes;
typedef Boxes Solutions[4][2];

int play(Dots grid[9][9], Boxes subgrid, Boxes move, Dots player);
void printGrid(Dots grid[9][9], Dots swon[9]);
void checkSolutions(Boxes a, Solutions sols);
void updateWon(Dots grid[9][9], Dots *won, Dots swon[9], Boxes subgrid, Boxes move);

#endif

