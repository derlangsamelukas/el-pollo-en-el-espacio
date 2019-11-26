.PHONY: all build run client clean

i=(import (chicken port)) (import spock)
o=with-output-to-file
l=(lambda (files) (lambda () (map (lambda (file) (spock (symbol->string file))) files)))

all: client build

build: ./a.out

run: client server/*.scm
	chicken-csi server/run.scm

client: ./public/index.js

clean:
	rm -f ./a.out
	rm -f public/index.js

./a.out: server/*.scm
	chicken-csc server/run.scm -o $@

./public/index.js: client/*.scm
	chicken-csi -e "$i ($o \"$@\" ($l '($^)))"
