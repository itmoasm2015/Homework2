all:
	yasm -felf64 -gdwarf2 matrix.asm -o matrix.o
	gcc matrix.o test.c -g -std=c11 -o test
	
    
run: all
	./test
