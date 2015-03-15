ASM_FLAGS = -f elf64 -g dwarf2
CFLAGS = -g -L. -I../../include

all: tests

tests: libhw.a tests.o
	g++ -o tests $(CFLAGS) tests.o -lhw

tests.o: tests.cpp
	g++ -o tests.o $(CFLAGS) -c tests.cpp

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: libhw.asm
	yasm -o libhw.o $(ASM_FLAGS) libhw.asm

clean:
	rm -f libhw.a
	rm -f libhw.o
	rm -f tests.o
