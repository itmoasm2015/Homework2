libhw.a: matrix.o
	ar rcs libhw.a matrix.o

test: matrix.o test.o
	g++ -m64 test.o matrix.o -o test

test.o: test.cpp
	g++ --std=c++11 test.cpp -m64 -g -c -o test.o

matrix.o: matrix.asm
	yasm -felf64 -gdwarf2 -Worphan-labels -Werror matrix.asm
