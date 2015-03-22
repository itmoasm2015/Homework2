all:
	yasm -gdwarf2 -felf64 -o matrix.o matrix.asm

test: all
	gcc -g -std=c99 -c -o test.o test.c
	gcc -o test matrix.o test.o
	./test
