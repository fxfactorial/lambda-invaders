SYN_EXTEN := camlp4o
PACKAGES := lambda-term lwt.syntax camomile
EXEC_NAME := lambda-invaders
FILES := utils.ml objects.ml main.ml

PACK_COMPILE_STR = ""
# THIS MAKEFILE DOESN'T WORK CORRECTLY

debug:
	ocamlfind ocamlc -g -syntax camlp4o -package lambda-term \
	-package lwt.syntax -package camomile -package core \
	-thread -linkpkg -o $(EXEC_NAME) $(FILES)
	@./$(EXEC_NAME)
	@cat log
	@rm -f log

compile_string:$(FILES)
	for pkg in packages; do \
		$(PACK_COMPILE_STR) += "-package " + $$pkg; \
	done


test:
	$(PACK_COMPILE_STR) += $(PACKAGES)
	@echo $(PACK_COMPILE_STR)

all:$(FILES) compile_string
	@echo $(PACK_COMPILE_STR)
	ocamlfind ocamlopt -syntax $(SYN_EXTEN) $(PACK_COMPILE_STR) -linkpkg \
	-o $(EXEC_NAME) $(FILES)

clean:
	@rm -f *.cmi *.cmo *.cmt *.cmx *.o log
	@rm -rf _build

