ASM_FLAGS = -f elf64 -g dwarf2
#CFLAGS = -fsanitize=address -g -L. -I../../include
CFLAGS = -O2 -L. -I../../include

all: tests

tests: libhw.a tests.o tmatrix.o
	g++ -o tests $(CFLAGS) tests.o tmatrix.o -lhw

tests.o: tests.cpp
	g++ -o tests.o tests.cpp $(CFLAGS) -c 

tmatrix.o: tmatrix.cpp
	g++ -o tmatrix.o tmatrix.cpp $(CFLAGS) -c 
	
libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: libhw.asm
	yasm -o libhw.o $(ASM_FLAGS) libhw.asm

clean:
	rm -f libhw.a
	rm -f libhw.o
	rm -f tests.o
	rm -f tmatrix.o
	rm -f tests
