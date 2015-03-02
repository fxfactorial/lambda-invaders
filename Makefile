SYN_EXTEN := camlp4o
PACKAGES := lambda-term lwt.syntax camomile batteries
EXEC_NAME := lambda-invaders
FILES := l_utils.ml objects.ml main.ml

# for debugging, use this invocation
# ocamldebug `ocamlfind query -recursive -i-format camomile` lambda-invaders

all:$(FILES)
	ocamlfind ocamlopt -syntax $(SYN_EXTEN) -package lambda-term \
	-package lwt.syntax -package camomile -package batteries -thread -linkpkg \
	-o $(EXEC_NAME) $(FILES)

debug:
	ocamlfind ocamlc -g -safe-string -syntax camlp4o -package lambda-term \
	-package lwt.syntax -package camomile -package core -package batteries \
	-thread -linkpkg -o $(EXEC_NAME) $(FILES)
	@./$(EXEC_NAME)
	@cat log
	@rm -f log

clean:
	@rm -f *.cmi *.cmo *.cmt *.cmx *.o log
	@rm -rf _build

