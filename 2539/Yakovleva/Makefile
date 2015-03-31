ASM_FLAGS = -f elf64 -g dwarf2

all: matrix

matrix:	matrix.o test.o

matrix.o: matrix.asm
	yasm -o matrix.o $(ASM_FLAGS) matrix.asm
	ar rcs libhw.a matrix.o

test.o: test.cpp matrix.asm
	g++ -o test.o -O2 -L. -c test.cpp
	g++ -o test -L. -O2 test.o -lhw

clean:
	rm -f libhw.a
	rm -f matrix.o
	rm -f test.o
	rm -f test

