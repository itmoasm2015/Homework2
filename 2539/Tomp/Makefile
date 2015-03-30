all:
	yasm -gdwarf2 -felf64 -o matrix.o matrix.asm

test: all
	ghc --make -o test test.hs matrix.o
	./test
