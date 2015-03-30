all: asm test

ar: asm
	ar rcs libhw.a matrix.o

test: ar test.cpp
	g++ -o test test.cpp libhw.a

asm: matrix.asm
	yasm -felf64 -gdwarf2 matrix.asm

clean:
	rm libhw.a
	rm *.o
	rm test
