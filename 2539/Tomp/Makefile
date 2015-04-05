all: matrix.o
	ar rcs libhw.a matrix.o

matrix.o:
	yasm -gdwarf2 -felf64 -o matrix.o matrix.asm

test: all
	gcc -g -std=c99 -L. -o test test.c -lhw
