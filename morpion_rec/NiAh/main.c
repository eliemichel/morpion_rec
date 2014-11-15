/* IA pour morpion récursif - Alexis
 * main.c
 * Contient les fonctions principales */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "main.h"
#include "ia.h"

#define INPUT_LENGTH 50

int main()
{
	int i,j,k,l;

	char input[INPUT_LENGTH];
	float timeout;

	Dots grid[9][9]; //La grille
	Boxes subgrid, move, firstsubgrid;
	int firstMove=1;

	Dots won; //Si quelqu'un a gagné
	Dots swon[9]; //Qui a gagné les sous-grilles ?

	for(i=0;i<9;i++)
		for(j=0;j<9;j++)
			grid[i][j] = FREE;

	subgrid = Z;
	firstsubgrid=Z;

	won = FREE; // Personne n'a gagné ...
	for(i=0;i<9;i++)
		swon[i]=FREE;

	srand(time(NULL));

	/* Fin des initialisation */

	// Dis bonjour à Alex ...
	fgets(input, sizeof(input), stdin); 
	for(i=0;i<INPUT_LENGTH;i++){if(input[i]=='\n'){input[i]='\0';}}
	if(strcmp(input, "Hello morpion_rec") == 0)
	{
		printf("Hello morpion_rec\n");
    fflush(stdout);
	}
	else
	{
		printf("Who are you, crazy bastard?\n");
    fflush(stdout);
		return EXIT_FAILURE;
	}

	printGrid(grid, swon);

	// Boucle de jeu
	while(1)
	{
		while(1)
		{
			fgets(input, sizeof(input), stdin); 

			// Attendre pour jouer
			if(strstr(input,"Your turn")==input)
			{
				sscanf(input+10,"%f",&timeout);
				fprintf(stderr, "Timeout: %f\n", timeout);
				break;
			}

			//Attendre le coup de l'adversaire
			if(strstr(input,"Play")==input)
			{
				sscanf(input+5,"%d %d %d %d",&i,&j,&k,&l);
				subgrid=(i-1)+(j-1)*3;
				move = (k-1)+(l-1)*3;
				fprintf(stderr,"%d %d\n", subgrid, move);
				// L'adversaire joue les ronds
				if(firstMove)
				{
					firstsubgrid=subgrid;
					firstMove=0;
				}
				play(grid, subgrid, move, CIRCLE);
				updateWon(grid, &won, swon, subgrid, move);
				printGrid(grid, swon);
				subgrid=move;
				if(won == CIRCLE)
					fprintf(stderr, "You won :|");
			}

			// Attendre le résultat de la partie
			if(strstr(input,"You win")==input || strstr(input,"You lose")==input || strstr(input,"Tie")==input || strstr(input,"Cheater")==input)
			{
				printf("Fair enough\n");
        fflush(stdout);
				return EXIT_SUCCESS;
			}
		}

		// On joue toujours les croix
		if(firstMove)
		{
			firstsubgrid=chooseFirstSubgrid();
			subgrid=firstsubgrid;
			move=chooseFirstMove();
			firstMove=0;
		}
		else if(pickUpMove(grid, subgrid, CROSS, &move, firstsubgrid) != 0)
		{
			return EXIT_FAILURE;
		}

		play(grid, subgrid, move, CROSS);
		updateWon(grid, &won, swon, subgrid, move);
		printf("Play %d %d %d %d\n", subgrid%3+1, subgrid/3+1, move%3+1, move/3+1);
    fflush(stdout);
		
		subgrid=move;
		printGrid(grid, swon);
		if(won==CROSS)
			fprintf(stderr, "I won !!");
      fflush(stdout);
	}

	return EXIT_SUCCESS;
}

// Joue un coup sur la grille
int play(Dots grid[9][9], Boxes subgrid, Boxes move, Dots player) 
{
	if(subgrid == Z || move == Z || player == FREE || grid[subgrid][move] != FREE)
		return 1;
	grid[subgrid][move] = player;
	return 0;
}


// Les affichages se font dans stderr
void printGrid(Dots grid[9][9], Dots swon[9])
{
	int x,y, i,j;

	fprintf(stderr,"\n*********\n");
	for(x=0;x<9;x++)
	{
		for(y=0;y<9;y++)
		{
			i=(y/3)*3+(x/3);
			j=(y-(y/3)*3)*3+(x-(x/3)*3);
			fprintf(stderr,"%d", grid[i][j]);
		}
		fprintf(stderr,"\n");
	}
	fprintf(stderr,"*********\n");
	for(x=0;x<3;x++)
	{
		for(y=0;y<3;y++)
		{
			fprintf(stderr, "%d", swon[x+3*y]);
		}
		fprintf(stderr, "\n");
	}
	fprintf(stderr,"*********\n");
}

void checkSolutions(Boxes a, Solutions sols)
{
	switch(a)
	{
		case I:
			sols[0][0] = II; sols[0][1] = III;
			sols[1][0] = IV; sols[1][1] = VII;
			sols[2][0] = V; sols[2][1] = IX;
			sols[3][0] = Z; sols[3][1] = Z;
			break;
		case II:
			sols[0][0] = I; sols[0][1] = III;
			sols[1][0] = V; sols[1][1] = VIII;
			sols[2][0] = Z; sols[2][1] = Z;
			sols[3][0] = Z; sols[3][1] = Z;
			break;
		case III:
			sols[0][0] = I; sols[0][1] = II;
			sols[1][0] = VI; sols[1][1] = IX;
			sols[2][0] = V; sols[2][1] = VII;
			sols[3][0] = Z; sols[3][1] = Z;
			break;
		case IV:
			sols[0][0] = I; sols[0][1] = VII;
			sols[1][0] = V; sols[1][1] = VI;
			sols[2][0] = Z; sols[2][1] = Z;
			sols[3][0] = Z; sols[3][1] = Z;
			break;
		case V:
			sols[0][0] = II; sols[0][1] = VIII;
			sols[1][0] = I; sols[1][1] = IX;
			sols[2][0] = IV; sols[2][1] = VI;
			sols[3][0] = VII; sols[3][1] = III;
			break;
		case VI:
			sols[0][0] = IV; sols[0][1] = V;
			sols[1][0] = III; sols[1][1] = IX;
			sols[2][0] = Z; sols[2][1] = Z;
			sols[3][0] = Z; sols[3][1] = Z;
			break;
		case VII:
			sols[0][0] = I; sols[0][1] = IV;
			sols[1][0] = VIII; sols[1][1] = IX;
			sols[2][0] = V; sols[2][1] = III;
			sols[3][0] = Z; sols[3][1] = Z;
			break;
		case VIII:
			sols[0][0] = II; sols[0][1] = V;
			sols[1][0] = VII; sols[1][1] = IX;
			sols[2][0] = Z; sols[2][1] = Z;
			sols[3][0] = Z; sols[3][1] = Z;
			break;
		case IX:
			sols[0][0] = III; sols[0][1] = VI;
			sols[1][0] = VII; sols[1][1] = VIII;
			sols[2][0] = I; sols[2][1] = V;
			sols[3][0] = Z; sols[3][1] = Z;
			break;
		default:
			sols[0][0] = Z; sols[0][1] = Z;
			sols[1][0] = Z; sols[1][1] = Z;
			sols[2][0] = Z; sols[2][1] = Z;
			sols[3][0] = Z; sols[3][1] = Z;
			break;
	}
}

void updateWon(Dots grid[9][9], Dots *won, Dots swon[9], Boxes subgrid, Boxes move)
{
	int i;
	Dots player = grid[subgrid][move];
	Solutions sols;

	fprintf(stderr, "Start update\n");

	//Si la sous-grille n'est pas déja attribuée ...
	if(swon[subgrid] != FREE)
		return;	

	// On vérifie d'abord la petite grille
	checkSolutions(move, sols);
	fprintf(stderr, "For %d %d: ", subgrid, move);
	for(i=0;i<4;i++)
	{
		if(sols[i][0]==Z)
			break;

		if(grid[subgrid][ sols[i][0]  ] == player && grid[subgrid][ sols[i][1]  ] == player)
		{
			fprintf(stderr, "check %d %d -> OK ; ", sols[i][0], sols[i][1]);
			swon[subgrid] = player;
			break;
		}
		else
			fprintf(stderr, "check %d %d -> Fail ; ", sols[i][0], sols[i][1]);
	}	
	// On vérifie ensuite la grande grille si besoin
	if(swon[subgrid] == player)
	{
		fprintf(stderr, "\nFor %d: ", subgrid);
		checkSolutions(subgrid, sols);
		for(i=0;i<4;i++)
		{
			if(sols[i][0] == Z)
				break;
			if(swon[ sols[i][0]  ] == player && swon[ sols[i][1]  ] == player)
			{
				fprintf(stderr, "check %d %d -> OK ; ", sols[i][0], sols[i][1]);
				*won = player;
				break;
			}
			else
				fprintf(stderr, "check %d %d -> Fail ; ", sols[i][0], sols[i][1]);
		}
	}	
	fprintf(stderr, "\nEnd update\n");
}
