ASM_FLAGS = -g dwarf2 -f elf64 
CXX_FLAGS = -m64 -L. -g -I../../include

all: test

clean:
	rm -f libhw.a
	rm -f libhw.o
	rm -f test.o
	rm -f test

test: libhw.a test.o
	g++ -o test $(CXX_FLAGS) test.o -lhw

test.o: test.cpp
	g++ -o test.o $(CXX_FLAGS) -c test.cpp

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: matrix.asm
	yasm -o libhw.o $(ASM_FLAGS) matrix.asm
