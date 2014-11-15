/* IA pour morpion récursif - Alexis
 * ia.c
 * Fonctions nécéssaires à l'intelligence artificielle */

#include <stdlib.h>
#include <math.h>
#include "ia.h"

Dots chooseFirstSubgrid()
{
	return V;
}

Dots chooseFirstMove()
{
	return V;
}

int pickUpMove(Dots grid[9][9], Boxes subgrid, Dots player, Boxes *move, Boxes firstSubgrid)
{
	int i,j;

	if(subgrid == Z)
		return 1;

	// Cas général
	for(i=0;i<9;i++)
	{
		if(grid[subgrid][i] == FREE)
		{
			*move = i; 
			return 0;
		}
	}

	//Cas particulier où il n'y a pas de place dans la sous-grille (car c'est la première à avoir été jouée)
	for(i=0;i<9;i++)
	{
		for(j=0;j<9;j++)
		{
			if(grid[j][i] == FREE)
			{
				*move = i; 
				return 0;
			}
		}
	}
	return 1;
}

