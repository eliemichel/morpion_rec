
all: player

player: *.ml lib/*.ml
	ocamlbuild $(NAME).native
	cp $(NAME).native player
	rm $(NAME).native

clean:
	rm -r _build
	rm player
