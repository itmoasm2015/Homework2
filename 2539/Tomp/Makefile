all:
	yasm -gdwarf2 -felf64 -o matrix.o matrix.asm

test: all
	gcc -g -std=c99 -c test.c
	gcc -o test test.o matrix.o
