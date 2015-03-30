ar: asm
	ar rcs libhw.a matrix.o

all: asm test.o
	g++ -m64 test.o matrix.o -o test

test.o: test.cpp include/matrix.h
	g++ --std=c++11 test.cpp -m64 -g -c -o test.o

asm: matrix.asm
	yasm -felf64 -gdwarf2 -Worphan-labels -Werror matrix.asm
