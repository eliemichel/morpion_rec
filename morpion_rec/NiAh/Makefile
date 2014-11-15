C=gcc
CFLAGS=-W -Wall -O3
LDFLAGS=-lm
EXEC=player

.PHONY: clean mrproper

all: $(EXEC)

$(EXEC): ia.o main.o
	$(C) main.o ia.o -o $(EXEC) $(LDFLAGS) 

ia.o: ia.c ia.h
	$(C) -o ia.o -c ia.c $(CFLAGS) 

main.o: main.c main.h ia.o
	$(C) -o main.o -c main.c $(CFLAGS) 

clean:
	rm -rf *.o

mkproper: clean
	rm -rf $(EXEC)
