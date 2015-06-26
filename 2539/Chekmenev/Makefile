all: test

ar: asm
	ar rcs libhw.a matrix.o

test: ar test.cpp
	g++ -g -std=c++11 -w -O3 -o  test test.cpp libhw.a

asm: matrix.asm
	yasm -felf64 -g dwarf2 matrix.asm

clean:
	rm libhw.a
	rm *.o
	rm test
