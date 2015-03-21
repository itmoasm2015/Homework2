all:
	yasm -felf64 -gdwarf2 matrix.asm -o matrix.o
	gcc-4.9 matrix.o test.c -g -std=c11 -o test
	./test
