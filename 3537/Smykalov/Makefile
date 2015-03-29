ASM_FLAGS = -f elf64
CFLAGS = -O2 -L. -I.

all: test

test: libhw.a test.o
		g++ -o test $(CFLAGS) test.cpp -lhw

libhw.a: libhw.o
		ar rcs libhw.a libhw.o

libhw.o: matrix.asm
		yasm -o libhw.o $(ASM_FLAGS) matrix.asm

clean:
		rm -f libhw.a
		rm -f libhw.o
		rm -f test
