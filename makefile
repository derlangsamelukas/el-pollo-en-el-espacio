.PHONY: all build run client clean

m=make-parameter
i=define input-files
o=define output-file

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
	chicken-csi -e "($i ($m '($^))) ($o ($m \"$@\")) (load \"compile.scm\")"
