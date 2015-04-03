ASMC=yasm -o
CC=gcc -o
ASM_FLAGS=-felf64 -gdwarf2
CXX_FLAGS=-std=c11 -g -L. -I.
ST_LIB=ar rcs

all: test

clean:
	rm -f libhw.a
	rm -f hw.o
	rm -f test

test: libhw.a
	$(CC) $@ $(CXX_FLAGS) test.c -lhw

libhw.a: hw.o
	$(ST_LIB) $@ $<

hw.o: matrix.asm
	$(ASMC) $@ $(ASM_FLAGS) $<
